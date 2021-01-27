module block_match_ctrl_fsm_new #(
    parameter rd_port_w = 8,
    parameter third_w = 240,
    parameter center_w = 304,
    parameter third_h = 480,
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
    
    localparam frame_addr_w              = third_w / rd_port_w;
    localparam center_addr_w             = center_w / rd_port_w;
    localparam blk_addr_w                = block_width / rd_port_w;
    localparam srch_addr_w               = search_blk_w / rd_port_w;
    
    localparam num_pad_blocks = ((center_w - third_w) / block_width) / 2;
    localparam third_blocks_per_row      = third_w / block_width;
    localparam center_blocks_per_row     = third_blocks_per_row + num_pad_blocks;
    //localparam blocks_per_col            = (third_h - (search_blk_h - block_height)) / block_height;
    localparam blocks_per_col            = third_h / block_height;
    
    // How much to add to the third addr to get to the next row of blocks
    localparam third_row_addr_offset     = frame_addr_w * block_height;
    // How much to add to the center addr to get to the next row of blocks
    localparam center_row_addr_offset    = center_addr_w * block_height;
    
    localparam initial_search_address   = -1 * center_addr_w * ((search_blk_h - block_height) / 2);
    localparam initial_l_blk_address    = 0; //frame_addr_w * ((search_blk_h - block_height) / 2);
    localparam right_blk_offset         = srch_addr_w - blk_addr_w;
    
    typedef enum {ST_IDLE, ST_WAITBM, ST_STARTBM} statetype;
    statetype state;
    
    logic [5:0]     blk_col; //64*8=512 max pixels
    logic [5:0]     blk_row;
    
    logic [15:0]    l_blk_row_addr;
    logic [15:0]    l_blk_addr;
    logic [15:0]    srch_row_addr;
    logic [15:0]    srch_addr;
    logic [15:0]    srch_buf_offset;
    logic [15:0]    blk_buf_offset;
    logic [3:0]     img_number;
    
    assign bm_working_buf = img_number[0];
    assign bm_idle = (state == ST_IDLE) && bm_done;
    
    assign srch_addr_left = srch_addr;
    assign srch_addr_right = srch_addr;
    assign blk_addr_left = l_blk_addr;
    assign blk_addr_right = l_blk_addr - right_blk_offset;
    
    assign srch_buf_offset       = img_number[0] ? center_addr_w * third_h : 0;
    assign blk_buf_offset        = img_number[0] ? frame_addr_w * third_h : 0;
    
    // The left block is shifted to the right, so we'll start it early and end early
    assign bm_start_left = (state == ST_STARTBM);// && (blk_col < third_blocks_per_row);
    // The right block is shifted to the left, so we'll start it late and end late
    assign bm_start_right = (state == ST_STARTBM);// && (blk_col >= num_pad_blocks);
    
    assign blk_index_left = {img_number, blk_row, blk_col};
    assign blk_index_right = blk_index_left;
    
    always @(posedge clk)
    begin
        if (reset) begin
            state               <= ST_IDLE;
            img_number          <= 0;
            l_blk_addr          <= 0;
            l_blk_row_addr      <= 0;
            srch_addr           <= 0;
            srch_row_addr       <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if ((img_number_in != img_number) && (bm_done)) begin
                        state           <= ST_STARTBM;
                        srch_row_addr   <= initial_search_address + center_row_addr_offset + srch_buf_offset;
                        srch_addr       <= initial_search_address + srch_buf_offset;
                        l_blk_row_addr  <= initial_l_blk_address + third_row_addr_offset + blk_buf_offset;
                        l_blk_addr      <= initial_l_blk_address + blk_buf_offset;
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
                        if (blk_col == (center_blocks_per_row - 1)) begin
                            blk_col <= 0;
                            if (blk_row == (blocks_per_col - 1)) begin
                                state       <= ST_IDLE;
                                img_number  <= img_number + 1;
                            end else begin
                                blk_row         <= blk_row + 1;
                                srch_addr       <= srch_row_addr;
                                srch_row_addr   <= srch_row_addr + center_row_addr_offset;
                                l_blk_addr      <= l_blk_row_addr;
                                l_blk_row_addr  <= l_blk_row_addr + third_row_addr_offset;
                                state           <= ST_WAITBM;
                            end
                        end else begin
                            blk_col     <= blk_col + 1;
                            l_blk_addr  <= l_blk_addr + blk_addr_w; // increment 1 block col
                            srch_addr   <= srch_addr + blk_addr_w; // increment 1 block col
                            state       <= ST_WAITBM;
                        end
                    end
                end
            endcase
        end
    end
endmodule