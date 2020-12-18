module bit_pixel_writer #(
    parameter third_cols = 240,
    parameter third_rows = 480
    )
    (
    input               clk,
    input               reset,
    
    input [23:0]        bit_pix,
    input               bit_pix_valid,
    output logic        fifo_almost_full,
    
    output logic [1:0]  pix_out,
    output logic        pix_out_wren,
    output logic [18:0] pix_out_addr,
    
    output logic [3:0]  image_number
    );
    
    localparam wr_cols = third_cols / 2;
    localparam wr_rows = third_rows;
    localparam row_inc = (2 * wr_cols) - 1;
    
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
    
    typedef enum {ST_IDLE, ST_WAIT_FIFO, ST_READ_FIFO, ST_READ_SECOND_ROW, ST_WRITE} statetype;
    statetype state;
    
    //logic [7:0]     image_number;
    logic           buf_out_index;
    logic [1:0]     third_index;
    logic [1:0]     third_index_in;
    logic [7:0]     write_col;
    logic [8:0]     write_row;
    logic [15:0]    next_col_addr;
    logic [15:0]    next_row_addr;
    logic [15:0]    wr_addr;
    logic           sof;
    logic           eof;
    
    logic               pix_fifo_rd;
    logic [23:0]        pix_fifo_q;
    logic [15:0]        fifo_out_pix;
    logic [8:0]         pix_fifo_level;
    logic [1:0][15:0]   pix_out_sreg;
    
    assign pix_out_wren     = (state == ST_WRITE);
    assign pix_out          = {pix_out_sreg[1][0], pix_out_sreg[0][0]};
    assign pix_fifo_rd      = (state == ST_READ_FIFO) || (state == ST_READ_SECOND_ROW);
    assign pix_out_addr     = {buf_out_index, third_index, wr_addr};
    assign fifo_out_pix     = pix_fifo_q[15:0];
    assign sof              = pix_fifo_q[17];
    assign third_index_in   = pix_fifo_q[19:18];
    assign fifo_almost_full = pix_fifo_level[8];
    
    int valid_cnt;
    
    bit_pix_fifo bit_pix_fifo_inst( //24-bit, 512-word, single clock, show ahead fifo
        .clock          (clk),
        .sclr           (reset),
        .wrreq          (bit_pix_valid),
        .rdreq          (pix_fifo_rd),
        .data           (bit_pix),
        .q              (pix_fifo_q),
        .usedw          (pix_fifo_level)
        );
        
    always @(posedge clk) begin
        if (reset) begin
            state           <= ST_IDLE;
            buf_out_index   <= 1;
            write_col       <= 0;
            write_row       <= 0;
            image_number    <= 0;
            valid_cnt       <= 0;
        end else begin
            if (bit_pix_valid) valid_cnt    <= valid_cnt + 1;
            case (state)
                ST_IDLE: begin
                    if (pix_fifo_level > 1) begin
                        if (third_index_in == 0) begin
                            buf_out_index   <= !buf_out_index;
                        end
                        third_index     <= third_index_in;
                        pix_out_sreg[1] <= fifo_out_pix;
                        wr_addr         <= wr_cols - 1;
                        next_col_addr   <= wr_cols - 2;
                        write_col       <= wr_cols - 1;
                        write_row       <= 0;
                        state           <= ST_READ_FIFO;
                    end
                end
                
                ST_WAIT_FIFO: begin
                    if (pix_fifo_level > 1) begin 
                        state   <= ST_READ_FIFO;
                    end
                end
                
                ST_READ_FIFO: begin //fifo read is 1, data valid next clock
                    pix_out_sreg[1] <= fifo_out_pix;
                    state           <= ST_READ_SECOND_ROW;
                end
                
                ST_READ_SECOND_ROW: begin //data now valid, fifo read is 1 to empty it wout
                    pix_out_sreg[0] <= fifo_out_pix;
                    state           <= ST_WRITE;
                end
                
                ST_WRITE: begin
                    pix_out_sreg[0] <= {1'b0, pix_out_sreg[0][15:1]};
                    pix_out_sreg[1] <= {1'b0, pix_out_sreg[1][15:1]};
                    
                    if (write_row[3:0] == 4'hF) begin // end of this 16-pixel mini col
                        if (write_col == 0) begin // end of this row of mini cols
                            if (write_row == (wr_rows - 1)) begin // all done
                                state       <= ST_IDLE;
                                if (third_index == 2'b10) begin
                                    image_number    <= image_number + 1;
                                end
                            end else begin
                                state       <= ST_WAIT_FIFO;
                            end
                            write_col       <= wr_cols - 1;
                            write_row[8:4]  <= write_row[8:4] + 1;
                            wr_addr         <= wr_addr + row_inc;
                            next_col_addr   <= wr_addr + row_inc - 1;
                        end else begin
                            write_col       <= write_col - 1;
                            wr_addr         <= next_col_addr;
                            next_col_addr   <= next_col_addr - 1;
                            state           <= ST_WAIT_FIFO;
                        end
                        write_row[3:0]  <= 0;
                    end else begin
                        wr_addr         <= wr_addr + wr_cols;
                        write_row[3:0]  <= write_row + 1;
                    end
                end
            endcase
        end
    end
endmodule
    