module block_match_ctrl_fsm_new #(
    parameter rd_port_w = 8,
    parameter bit_frame_w = 960,
    parameter bit_frame_h = 540,
    //parameter block_size = 16,
    parameter block_width = 16,
    parameter block_height = 16,
    parameter search_blk_w = 64,
    parameter search_blk_h = 32
    )
    (
    input               reset,
    input               clk,
    
    output              bm_idle,
    output              bm_working_buf,
    input [3:0]         img_number_in,
    
    output logic [15:0] blk_addr_left,
    output logic [15:0] blk_addr_right,
    output logic [15:0] srch_addr_left,
    output logic [15:0] srch_addr_right,
    output logic        bm_start_left,
    output logic        bm_start_right,
    input               bm_done,
    
    output logic [15:0]  blk_index_left,
    output logic [15:0]  blk_index_right
    );
    
    //In the left one, everything is shifted right so the block should be on the right of the search window
    //Block address = search address + (frame_w * ((srch_h - blk_h) / 2)) + (srch_w - blk_w)
    //In the right one, everything is shifted left so the block should be on the left of the search window
    //Block address = search address + (frame_w * ((srch_h - blk_h) / 2))
    
    localparam frame_addr_w              = bit_frame_w / rd_port_w;
    localparam blk_addr_w                = block_width / rd_port_w;
    localparam srch_addr_w               = search_blk_w / rd_port_w;
    localparam blocks_per_row            = (bit_frame_w - search_blk_w) / block_width;
    localparam blocks_per_col            = (bit_frame_h - search_blk_h) / block_height;
    localparam blk_row_addr_offset       = (frame_addr_w * (block_height - 1)) + blk_addr_w;
    localparam row_addr_offset           = frame_addr_w * block_height;
    
    localparam right_blk_offset      = frame_addr_w * ((search_blk_h - block_height) / 2);
    localparam left_blk_offset       = right_blk_offset + srch_addr_w - blk_addr_w;
    
    typedef enum {ST_IDLE, ST_WAITBM, ST_STARTBM} statetype;
    statetype state;
    
    logic [5:0]     blk_col; //64*8=512 max pixels
    logic [5:0]     blk_row;
    
    //logic [15:0]    blk_row_addr;
    logic [14:0]    srch_row_addr;
    logic [14:0]    srch_addr;
    logic [3:0]     img_number;
    
    assign bm_working_buf = img_number[0];
    assign bm_idle = (state == ST_IDLE) && bm_done;
    
    assign srch_addr_left = {img_number[0], srch_addr};
    assign srch_addr_right = {img_number[0], srch_addr};
    
    assign blk_addr_left[15] = img_number[0];
    assign blk_addr_right[15] = img_number[0];
    assign blk_addr_left[14:0] = srch_addr + left_blk_offset;
    assign blk_addr_right[14:0] = srch_addr + right_blk_offset;
    
    assign bm_start_left = (state == ST_STARTBM);
    assign bm_start_right = (state == ST_STARTBM);
    
    assign blk_index_left = {img_number, blk_row, blk_col};
    assign blk_index_right = blk_index_left;
    
    always @(posedge clk)
    begin
        if (reset) begin
            state               <= ST_IDLE;
            img_number          <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if ((img_number_in != img_number) && (bm_done)) begin
                        state           <= ST_STARTBM;
                        srch_row_addr   <= row_addr_offset;
                        srch_addr       <= 0;
                        blk_col         <= 0;
                        blk_row         <= 0;
                    end
                end
                
                ST_WAITBM: begin
                    if (bm_done) begin
                        state       <= ST_STARTBM;
                    end
                end
                
                ST_STARTBM: begin
                    if (!bm_done) begin
                        if (blk_col == (blocks_per_row - 1)) begin
                            blk_col <= 0;
                            if (blk_row == (blocks_per_col - 1)) begin
                                state       <= ST_IDLE;
                                img_number  <= img_number + 1;
                            end else begin
                                blk_row         <= blk_row + 1;
                                //blk_addr        <= blk_row_addr;
                                srch_addr       <= srch_row_addr;
                                //blk_row_addr    <= blk_row_addr + row_addr_offset;
                                srch_row_addr   <= srch_row_addr + row_addr_offset;
                                state           <= ST_WAITBM;
                            end
                        end else begin
                            blk_col     <= blk_col + 1;
                            //blk_addr    <= blk_addr + blk_addr_w;
                            srch_addr   <= srch_addr + blk_addr_w;
                            state       <= ST_WAITBM;
                        end
                    end
                end
            endcase
        end
    end
endmodule