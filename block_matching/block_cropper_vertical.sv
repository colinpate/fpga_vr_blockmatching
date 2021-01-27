//`default_nettype none
module block_cropper_vertical #(
        parameter blk_h = 16,
        parameter third_h = 480,
        parameter srch_blk_h = 24
    ) (
        input [15:0]    blk_index_in,
        input [15:0]    coords_in,
        input           blk_in_valid,
        output          blk_out_valid
    );
    
    localparam min_row = (srch_blk_h - blk_h) / 2;
    localparam max_row = srch_blk_h - min_row - 1;
    localparam last_blk_row = (third_h / blk_h) - 1;
    
    logic [5:0] blk_row;
    assign blk_row = blk_index_in[11:6];
    logic [7:0] current_row;
    assign current_row = coords_in[15:8];
    
    logic above_min;
    assign above_min = !((blk_row == 0) && (current_row < min_row));
    logic below_max;
    assign below_max = !((blk_row == last_blk_row) && (current_row > max_row));
    assign blk_out_valid = blk_in_valid && above_min && below_max;
endmodule
    