module xors_to_stream #(
    parameter blk_w = 16,
    parameter blk_h = 16,
    parameter blk_size = blk_w * blk_h,
    parameter decimate_factor = 2,
    parameter frame_w = 240,
    parameter search_blk_w = 48
    ) (
    input       clk,
    input       reset,
    
    input [blk_size - 1:0]  xors_in,
    input [7:0]             confidence,
    input [15:0]            min_coords,
    input                   xors_valid,
    input                   fifo_almost_full_in,
    
    output [decimate_factor - 1:0]  pix_stream_data,
    output [7:0]                    conf_out,
    output [7:0]                    disp_out,
    output                          pix_stream_valid
    );
    
    localparam max_disparity = search_blk_w - blk_w;
    localparam disparity_bits = $clog2(max_disparity);
    
    localparam blocks_per_row = frame_w / blk_w;
    localparam frame_wr_addr_w = frame_w / blk_w;
    localparam frame_rd_addr_w = frame_w / decimate_factor;
    localparam frame_h = blk_h * 3;
    localparam bram_num_bits = frame_w * frame_h;
    localparam bram_wr_num_words = bram_num_bits / blk_w;
    localparam bram_rd_num_words = bram_num_bits / decimate_factor;
    localparam bram_wr_frame_size = frame_wr_addr_w * frame_h;
    localparam bram_rd_frame_size = frame_rd_addr_w * frame_h;
    localparam bram_wr_addr_w = $clog2(bram_wr_num_words);
    localparam bram_rd_addr_w = $clog2(bram_rd_num_words);
    
    logic                           writing_buf_index;
    logic [bram_wr_addr_w - 1:0]    bram_wr_addr;
    logic [bram_wr_addr_w - 1:0]    bram_wr_addr_next_block;
    logic                           reading_buf_index;
    logic [bram_rd_addr_w - 1:0]    bram_rd_addr;
    logic [blk_w - 1:0]             bram_wr_data;
    logic                           bram_wren;
    logic [decimate_factor - 1:0]   bram_rd_data;
    
    // We can expect a new 16x16 block every 8*32 = 256 cycles.
    // It takes us 128 cycles to read out a block.
    // We read out the blocks after receiving a whole row of them.
    
    bram_wrapper #(
        .wr_addr_w  (bram_wr_addr_w),
        .rd_addr_w  (bram_rd_addr_w),
        .wr_data_w  (blk_w),
        .rd_data_w  (decimate_factor),
        .wr_word_depth  (bram_wr_num_words),
        .rd_word_depth  (bram_rd_num_words)
    ) xor_bram (
        .clk        (clk),
        .wr_addr    (bram_wr_addr),
        .rd_addr    (bram_rd_addr),
        .wren       (bram_wren),
        .wr_data    (bram_wr_data),
        .rd_data    (bram_rd_data)
    );
    
    logic [disparity_bits - 1:0]            min_disparity;
    logic [$clog2(blocks_per_row) - 1:0]    rd_current_blk_col;
    logic [$clog2(blocks_per_row) - 1:0]    blk_col;
    logic [1:0]                             wr_row_of_block;
    logic [$clog2(frame_rd_addr_w) - 1:0]   read_col;
    logic [$clog2(frame_h) - $clog2(blk_h) - 1:0]   read_blk_row;
    assign min_disparity = min_coords;
    
    localparam conf_dist_bram_size = blk_w * blocks_per_row * (frame_h / blk_h);
    localparam conf_dist_bram_wr_words = conf_dist_bram_size / blk_w;
    localparam conf_dist_bram_rd_words = conf_dist_bram_size / decimate_factor;
    
    bram_wrapper #(
        .wr_addr_w  ($clog2(conf_dist_bram_wr_words)), // Plus 1 for ping-pong buffering
        .rd_addr_w  ($clog2(conf_dist_bram_rd_words)),
        .wr_data_w  ((disparity_bits + 8) * blk_w), // 8 bit confidence
        .rd_data_w  ((disparity_bits + 8) * decimate_factor),
        .wr_word_depth  (conf_dist_bram_wr_words),
        .rd_word_depth  (conf_dist_bram_rd_words)
    ) conf_dist_ram (
        .clk        (clk),
        .wr_addr    ((wr_row_of_block * blocks_per_row) + blk_col),
        .rd_addr    ((read_blk_row * frame_rd_addr_w) + read_col),
        .wren       (xors_valid),
        .wr_data    ({blk_w{confidence, min_disparity}}),
        .rd_data    ({conf_out, disp_out[disparity_bits - 1:0]})
    );
        
    // End inline RAM definition
        
    // Writing logic
    logic [blk_h - 1:0][blk_w - 1:0]    xor_array;
    
    logic [bram_wr_addr_w - 1:0] bram_wr_addr_i;
    
    logic [$clog2(blk_h) - 1:0] blk_wr_row;
    logic                       state_write_block;
    
    assign bram_wr_data = xor_array[blk_wr_row];
    assign bram_wren = (state_write_block == 1'b1);
    
    //logic [1:0][blocks_per_row - 1:0][disparity_bits - 1:0]   disp_array;
    //logic [1:0][blocks_per_row - 1:0][7:0]   conf_array;
    
    // Reading logic
    logic [bram_rd_addr_w - 1:0] bram_rd_addr_col;
    
    logic                                   state_read_buf;
    logic [$clog2(decimate_factor) - 1:0]   read_small_row;
    logic [$clog2(frame_h) - 1:0]           read_row;
    logic                                   blk_read;
    logic                                   blk_rdv;
    logic                                   writer_is_ahead;
    
    assign rd_current_blk_col = read_col >> $clog2(blk_w / decimate_factor); // Get the index of the block we're reading from
    assign read_blk_row = read_row >> $clog2(blk_h);
    assign writer_is_ahead = (reading_buf_index != writing_buf_index) || (wr_row_of_block > read_blk_row);
    assign blk_read = (state_read_buf == 1'b1) && writer_is_ahead && (!fifo_almost_full_in);
    
    assign pix_stream_data = bram_rd_data;
    assign pix_stream_valid = blk_rdv;
    
    always @(posedge clk) begin
        if (reset) begin
            writing_buf_index   <= 0;
            blk_wr_row          <= 0;
            wr_row_of_block     <= 0;
            state_write_block   <= 0;
            blk_col             <= 0;
            bram_wr_addr        <= 0;
            bram_wr_addr_next_block <= 1;
            
            bram_rd_addr      <= 0;
            bram_rd_addr_col    <= 0;
            state_read_buf      <= 0;
            reading_buf_index   <= 0;
            read_small_row      <= 0;
            read_row            <= 0;
            blk_rdv             <= 0;
            read_col            <= 0;
        end else begin
            case (state_write_block)
                1'b0: begin
                    if (xors_valid) begin
                        xor_array           <= xors_in;
                        state_write_block   <= 1'b1;
                        blk_wr_row          <= 0;
                    end
                end
                
                1'b1: begin
                    if (blk_wr_row == (blk_h - 1)) begin
                        if (blk_col == (blocks_per_row - 1)) begin // End of buffer, reset
                            blk_col             <= 0;
                            if (wr_row_of_block == 2) begin
                                wr_row_of_block     <= 0;
                                bram_wr_addr        <= 0;
                                bram_wr_addr_next_block <= 1;
                                writing_buf_index   <= ~writing_buf_index;
                            end else begin
                                wr_row_of_block     <= wr_row_of_block + 1;
                                bram_wr_addr        <= bram_wr_addr + 1; // first address of next row of blocks
                                bram_wr_addr_next_block <= bram_wr_addr + 2; // first address of second block in the next row
                            end
                        end else begin
                            blk_col         <= blk_col + 1;
                            bram_wr_addr    <= bram_wr_addr_next_block;
                            bram_wr_addr_next_block <= bram_wr_addr_next_block + 1;
                        end
                        state_write_block   <= 1'b0;
                    end else begin
                        blk_wr_row          <= blk_wr_row + 1;
                        bram_wr_addr        <= bram_wr_addr + frame_wr_addr_w;
                    end
                end
            endcase
            
            blk_rdv <= blk_read;
            
            case (state_read_buf)
                1'b0: begin
                    if (writer_is_ahead) begin
                        state_read_buf      <= 1'b1;
                        bram_rd_addr      <= 0;
                        bram_rd_addr_col    <= 0;
                        read_small_row      <= 0;
                        read_row            <= decimate_factor;
                        read_col            <= 0;
                    end
                end
                
                1'b1: begin
                    if (writer_is_ahead && (!fifo_almost_full_in)) begin
                        if (read_small_row == (decimate_factor - 1)) begin
                            read_small_row  <= 0;
                            if (read_col == (frame_rd_addr_w - 1)) begin // We're at the end of the row
                                read_col    <= 0;
                                if (bram_rd_addr == ((frame_rd_addr_w * frame_h) - 1)) begin // We're at the end of the buffer
                                    read_row            <= decimate_factor;
                                    state_read_buf      <= 1'b0;
                                    reading_buf_index   <= ~reading_buf_index;
                                end else begin // We're just at the end of the row
                                    read_row            <= read_row + decimate_factor;
                                    bram_rd_addr        <= bram_rd_addr + 1; // Go to beginning of next row
                                    bram_rd_addr_col    <= bram_rd_addr_col + (frame_rd_addr_w * (decimate_factor - 1)) + 1; // Go to beginning 2 rows down
                                end
                            end else begin // We're somewhere in the middle of the row
                                read_col            <= read_col + 1;
                                bram_rd_addr      <= bram_rd_addr_col + 1; // Go to beginning of next row
                                bram_rd_addr_col    <= bram_rd_addr_col + 1; // Go to beginning 2 rows down
                            end
                        end else begin // We're in the middle of the tiny chunk
                            read_small_row      <= read_small_row + 1;
                            bram_rd_addr      <= bram_rd_addr + frame_rd_addr_w; // Go down one row
                        end
                    end
                end
            endcase
        end
    end
    
    // Create a stream of disparities and confidences from the thingy.
    // BRAM with blk_w wr_port_w, frame_width*blk_h bits, decimate_factor rd_port_w
    // Write state: Once xors_valid, write blk_h times, incrementing write address by frame_width
    // After that increment the column address. If col addr hits the number of columns, go to the
    // read state. 
    // Read state: Read decimate_factor times from each column, add em up. Stream out until we hit the end then go to the write state.
endmodule