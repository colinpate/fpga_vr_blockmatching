//`default_nettype none
module disparity_filtering_system #(
    parameter blk_w = 16,
    parameter blk_h = 16,
    parameter decimate_factor = 2,
    parameter frame_w = 240,
    parameter frame_h = 480,
    parameter frame_wr_height = 480,
    parameter search_blk_w = 48,
    parameter blk_size = blk_w * blk_h
    ) (
        input       clk,
        input       reset,
        
        input [blk_size - 1:0]  xors_in,
        input [7:0]             confidence,
        input [15:0]            min_coords,
        input                   xors_valid,
    
        output [15:0]           disparity,
        output                  disparity_valid
    );
    
    localparam disp_bits = $clog2(search_blk_w - blk_w);
    
    logic [7:0] conf_data;
    logic [7:0] disp_data;
    
    logic [decimate_factor - 1:0]   pix_stream_data;
    logic                           pix_stream_valid;
    
    xors_to_stream #(
        .blk_w              (blk_w),
        .blk_h              (blk_h),
        .decimate_factor    (decimate_factor),
        .frame_w            (frame_w),
        .search_blk_w       (search_blk_w)
    ) x2s (
        .clk    (clk),
        .reset  (reset),
        .xors_in    (xors_in),
        .xors_valid (xors_valid),
        .confidence (confidence),
        .min_coords (min_coords),
        .pix_stream_data    (pix_stream_data),
        .pix_stream_valid   (pix_stream_valid),
        .conf_out           (conf_data),
        .disp_out           (disp_data)
    );
    
    logic [7 + disp_bits:0] disp_conf_out;
    logic [7:0] conf_out;
    logic out_valid;
    
    pixel_processor #(
        .dec_factor (decimate_factor),
        .disp_bits  (disp_bits)
    ) p (
        .clk    (clk),
        .reset  (reset),
        .pixels_in  (pix_stream_data),
        .disp_in    (disp_data),
        .conf_in    (conf_data),
        .disp_conf_valid    (pix_stream_valid),
        .disp_conf_out      (disp_conf_out),
        .conf_out           (conf_out),
        .out_valid          (out_valid)
    );
 
    logic [7 + disp_bits:0] dc_to_bram;
    logic [7:0] c_to_bram;
    logic valid_to_bram;
    
    filter_and_pad_bank #(
        .disp_bits  (disp_bits),
        .line_len   (frame_w / decimate_factor),
        .num_filters    (4),
        .filter_radius  (2)
    ) f (
        .clk    (clk),
        .reset  (reset),
        .disp_conf_in   (disp_conf_out),
        .conf_in        (conf_out),
        .conf_in_valid  (out_valid),
        
        .disp_conf_out  (dc_to_bram),
        .conf_out       (c_to_bram),
        .conf_out_valid (valid_to_bram)
    );
    /*assign dc_to_bram = disp_conf_out;
    assign c_to_bram = conf_out;
    assign valid_to_bram = out_valid;*/
    
    logic [7 + disp_bits:0]    dc_from_bram;
    logic [7:0]     c_from_bram;
    logic valid_from_bram;
    
    bram_reader_writer #(
        .width  (frame_w / decimate_factor),
        .height (frame_h / decimate_factor),
        .wr_height  (frame_wr_height / decimate_factor),
        .data_width (16 + disp_bits)
    ) brw1 (
        .clk    (clk),
        .reset  (reset),
        .in_data    ({dc_to_bram, c_to_bram}),
        .in_valid   (valid_to_bram),
        .out_data   ({dc_from_bram, c_from_bram}),
        .out_valid  (valid_from_bram)
    );
    
    logic [7 + disp_bits:0]    dc_to_div;
    logic [7:0]     c_to_div;
    logic valid_to_div;
    
    filter_and_pad_bank #(
        .disp_bits  (disp_bits),
        .line_len   (frame_h / decimate_factor),
        .num_filters    (4),
        .filter_radius  (2)
    )f2(
        .clk    (clk),
        .reset  (reset),
        .disp_conf_in   (dc_from_bram),
        .conf_in        (c_from_bram),
        .conf_in_valid  (valid_from_bram),
        
        .disp_conf_out  (dc_to_div),
        .conf_out       (c_to_div),
        .conf_out_valid (valid_to_div)
    );
    /*assign dc_to_div = dc_from_bram;
    assign c_to_div = c_from_bram;
    assign valid_to_div = valid_from_bram;*/
    
    conf_disp_divide #(
        .disp_bits  (disp_bits)
    )cdd(
        .clk    (clk),
        .reset  (reset),
        .in_conf    (c_to_div),
        .in_conf_disp   (dc_to_div),
        .in_valid   (valid_to_div),
        .out_disp   (disparity[7:3]),
        .out_conf   (disparity[15:8]),
        .out_valid  (disparity_valid)
    );
    //assign disparity = c_to_div;
    //assign disparity_valid = valid_to_div;
endmodule