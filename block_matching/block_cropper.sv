//`default_nettype none
module block_cropper #(
    parameter i_am_left = 0,
    parameter center_width = 304,
    parameter third_width = 240,
    parameter blk_w = 16
    ) (
        input [15:0]    blk_index_in,
        input           blk_in_valid,
        output          blk_out_valid
    );
    
    localparam num_extra_blks = (center_width - third_width) / blk_w / 2;
    localparam total_blk_cols = (third_width / blk_w) + num_extra_blks;
    localparam min_col = i_am_left ? 0 : num_extra_blks;
    localparam max_col = i_am_left ? total_blk_cols - num_extra_blks : total_blk_cols;
    
    logic [5:0] blk_col;
    assign blk_col = blk_index_in[5:0];
    
    assign blk_out_valid = blk_in_valid && (blk_col >= min_col) && (blk_col < max_col);
endmodule
    