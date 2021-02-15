module bit_pixel_rotator_bram #(
    parameter third_cols = 240,
    parameter center_cols = 304,
    parameter third_rows = 480,
    parameter num_pix = 16,
    parameter test_mode = 0
    )
    (
    input               clk,
    input               reset,
    
    input [23:0]        bit_pix, // num_pix + 8 wide
    input               bit_pix_valid,
    output logic        fifo_almost_full,
    
    output logic [15:0] pix_out, // num_pix wide
    output logic        pix_out_wren,
    output logic [15:0] pix_out_addr, // 1 + 2 + $clog2(third_cols * third_rows / num_pix) wide
    output logic [1:0]  pix_out_third,
    
    output logic [3:0]  image_number,
    input               bm_idle,
    input               bm_working_buf,
    
    output logic [15:0] pix_out_b, // num_pix wide
    output logic        pix_out_wren_b,
    output logic [15:0] pix_out_addr_b, // 1 + 2 + $clog2(third_cols * third_rows / num_pix) wide
    output logic [1:0]  pix_out_third_b,
    
    output logic [3:0]  image_number_b
    );
    
    assign pix_out_b = pix_out;
    assign pix_out_wren_b = pix_out_wren;
    assign pix_out_addr_b = pix_out_addr;
    assign pix_out_third_b = pix_out_third;
    assign image_number_b = image_number;
    
    localparam third_wr_cols = third_cols / num_pix;
    localparam center_wr_cols = center_cols / num_pix;
    localparam wr_rows = third_rows;
    
    //16-pixel lines get clocked in row-by-row
    //starting from upper left which is actually the upper right
    //first in bit 0 is pixel (x,y) = (cols - 1, 0)
    //first in bit 15 is pixel (x,y) = (cols - 1, 15)
    
    //2nd in bit 0 is pixel (x, y) = (cols - 2, 0)
    //2nd in bit 15 is pixel (x, y) = (cols - 2, 15)
    
    //cols in bit 0 is pixel (x, y) = (cols - 1, 16)
    //cols in bit 15 is pixel (x, y) = (cols - 1, 31)
    
    //x = cols - (incounter % cols)
    //y = floor(incounter / cols) * 16 + bitpos
    
    //there are to be 6 buffers: each 240 by 480
    //2 sets of 3, one for writing and one for reading (alternate)
    //Each set has left, center, right
    //FSM controls DDR3 reader, reads cam n center, cam n-1 right, cam n+1 left
    //Single BRAM writer that writes at (480*720*8*30fps)=82.94MP/s
    //Just run at 100MHz and have it do 2 pixels/beat
    //2 block matchers that read in the same section of the center thing
    //after 240 by 480 pixels, switch to the next buffer
    //after 3 sections of 240 by 480 pixels, switch cameras
    //4 cameras per buffer writer
    //each camera has the same address in each buffer
    
    //DDR3 reader control FSM:
    //Gets start addresses from DDR3 writers
    //When both are valid, starts DDR3 reader 24 times
    
    //BRAM writer:
    //If SOF and third index 0, increment image count
    
    //BRAM reader control FSM:
    //If image count not equal to current, do stuff then increment image count
    
    //Data_in: {6, 5, 4}: camera index, {3, 2}: third index, {1}: sof, {0}: eof
    
    typedef enum {ST_IDLE, ST_STALL} statetype;
    statetype state;
    
    //logic [7:0]     image_number;
    logic                           buf_out_index;
    //logic [1:0]                     third_index;
    logic [1:0]                     third_index_in;
    logic [$clog2(center_wr_cols) - 1:0]   write_col;
    logic [$clog2(wr_rows) - 1:0]   write_row;
    logic [15:0]                    wr_addr;
    logic                           sof;
    logic                           eof;
    logic                           writing_center;
    logic [$clog2(center_wr_cols):0]wr_cols;
    
    logic               pix_fifo_rd;
    logic [23:0]        pix_fifo_q;
    logic [15:0]        fifo_out_pix;
    logic [8:0]         fifo_usedw;
    logic               fifo_empty;
    logic [15:0]        wr_base_addr;
    logic [15:0]        next_wr_base_addr;
    logic [15:0]        next_third_base_addr;
    
    logic               bm_working_buf_reg;
    logic [3:0]         bm_image_counter;
    logic [3:0]         prev_image_number;
    
    assign prev_image_number = image_number - 1;
    
    assign pix_out_wren     = (state == ST_IDLE) && (~fifo_empty);
    assign pix_out          = test_mode ? {buf_out_index, third_index_in, wr_addr[12:0]} : fifo_out_pix;
    assign pix_fifo_rd      = pix_out_wren;
    //assign pix_out_addr     = {buf_out_index, third_index_in, wr_addr};
    assign pix_out_addr     = wr_addr;
    assign pix_out_third    = third_index_in;
    assign fifo_out_pix     = pix_fifo_q[15:0];
    assign sof              = pix_fifo_q[17];
    assign third_index_in   = pix_fifo_q[19:18];
    assign fifo_almost_full = fifo_usedw > 256;
    assign writing_center   = (third_index_in == 2'b01);
    assign wr_cols          = writing_center ? center_wr_cols : third_wr_cols;
    localparam third_offset = third_wr_cols * wr_rows;
    localparam center_offset = center_wr_cols * wr_rows;
    assign wr_base_addr     = buf_out_index ? (writing_center ? center_offset : third_offset) : 0;
    assign next_third_base_addr = buf_out_index ? (writing_center ? third_offset : center_offset) : 0; // Used when we're at left or center
    assign next_wr_base_addr = (~buf_out_index) ? third_offset : 0; // Always gonna be a third cuz used when we're at the right third
    
    //int valid_cnt;
    
    bit_pix_fifo bit_pix_fifo_inst( //24-bit, 512-word, single clock, show ahead fifo
        .clock          (clk),
        .sclr           (reset),
        .wrreq          (bit_pix_valid),
        .rdreq          (pix_fifo_rd),
        .data           (bit_pix),
        .q              (pix_fifo_q),
        .empty          (fifo_empty),
        .usedw          (fifo_usedw)
        );
        
    always @(posedge clk) begin
        if (reset) begin
            state               <= ST_IDLE;
            buf_out_index       <= 0;
            write_col           <= 0;
            write_row           <= 0;
            wr_addr             <= 0;
            image_number        <= 0;
            bm_working_buf_reg  <= 1'b0;
            bm_image_counter    <= 0;
        end else begin
            if (bm_working_buf_reg == (~bm_working_buf)) begin
                bm_image_counter    <= bm_image_counter + 1;
                bm_working_buf_reg  <= bm_working_buf;
            end
            
            case (state)
                ST_IDLE: begin
                    if (~fifo_empty) begin // That means the FIFO has been read and the BRAM is being written
                        if (write_row == (wr_rows - 1)) begin
                            write_row   <= 0;
                            if (write_col == (wr_cols - 1)) begin
                                write_col   <= 0;
                                if (third_index_in == 2'b10) begin
                                    wr_addr         <= next_wr_base_addr;
                                    //if (bm_idle || (bm_working_buf != (!buf_out_index))) begin
                                    if (bm_image_counter != prev_image_number) begin
                                        // Block matching FSM is waiting for new frames, or its not working on buffer we want next.
                                        // If we just finished frame 1, and it's still running, it'll be on frame 0
                                        // But if we just finished frame 1, and it's done, it'll be on frame 1 so we can start frame 2
                                        buf_out_index   <= !buf_out_index;
                                        image_number    <= image_number + 1;
                                    end else begin //If we finish and the BMFSM is still not on our last frame, we have to wait
                                        // Block matching FSM is working on the buffer we want to write to :(
                                        state           <= ST_STALL;
                                    end
                                end else begin
                                    // We're not finishing up the last third so go to the beginning of the next
                                    wr_addr    <= next_third_base_addr;
                                end
                            end else begin
                                write_col   <= write_col + 1;
                                wr_addr     <= wr_base_addr + write_col + 1; // The address of the first row of a column is just the index of the column
                            end
                        end else begin
                            write_row   <= write_row + 1;
                            wr_addr     <= wr_addr + wr_cols; // Increment to next row of this column
                        end
                    end
                end
                
                ST_STALL: begin
                    //if (bm_idle || (bm_working_buf != (!buf_out_index))) begin
                    if (bm_image_counter != prev_image_number) begin
                        buf_out_index   <= !buf_out_index;
                        image_number    <= image_number + 1;
                        state           <= ST_IDLE;
                    end
                end
            endcase
        end
    end
endmodule
    