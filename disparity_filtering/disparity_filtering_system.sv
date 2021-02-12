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
        
        output [3:0]            image_index_counter,
        
        input [7:0]             gray_pixel_data,
        input                   gray_pixel_valid,
        output                  gray_pixel_ready,
    
        output [15:0]           disparity,
        output                  disparity_valid,
        input                   disparity_ready
    );
    
    localparam disp_bits = $clog2(search_blk_w - blk_w);
    
    logic [7:0] conf_data;
    logic [7:0] disp_data;
    
    logic                           pix_stream_data;
    logic                           pix_stream_valid;
    logic pix_proc_fifo_almost_full;
    
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
        .fifo_almost_full_in    (pix_proc_fifo_almost_full),
        .pix_stream_data    (pix_stream_data),
        .pix_stream_valid   (pix_stream_valid),
        .conf_out           (conf_data),
        .disp_out           (disp_data)
    );
    
    logic [7 + disp_bits:0] disp_conf_out;
    logic out_valid;
    logic out_ready;
    
    pixel_processor #(
        .dec_factor (decimate_factor),
        .disp_bits  (disp_bits),
        .dec_frame_width    (frame_w / decimate_factor)
    ) p (
        .clk    (clk),
        .reset  (reset),
        .pixels_in  (pix_stream_data),
        .disp_in    (disp_data),
        .conf_in    (conf_data),
        .disp_conf_valid    (pix_stream_valid),
        .fifo_almost_full   (pix_proc_fifo_almost_full),
        .disp_conf_out      (disp_conf_out),
        .out_valid          (out_valid),
        .out_ready          (out_ready)
    );
    
    logic [7:0] downsample_pix_data;
    logic       downsample_pix_valid;
    logic       downsample_pix_ready;
    
    downsample_1d #(
        .dec_factor (decimate_factor),
        .in_width   (frame_w),
        .in_height  (frame_h)
    ) downsample_2d_inst (
        .clk        (clk),
        .reset      (reset),
        .in_data    (gray_pixel_data),
        .in_valid   (gray_pixel_valid),
        .in_ready   (gray_pixel_ready),
        .out_data   (downsample_pix_data),
        .out_valid  (downsample_pix_valid),
        .out_ready  (downsample_pix_ready)
    );
    
    bram_filter_system #(
        .dec_frame_w    (frame_w / decimate_factor),
        .dec_frame_h    (frame_h / decimate_factor),
        .disp_bits      (disp_bits)
    ) bfs (
        .clk    (clk),
        .reset  (reset),
        .disp_conf_in_data  (disp_conf_out),
        .disp_conf_in_valid (out_valid),
        .disp_conf_in_ready (out_ready),
        .gray_in_data       (downsample_pix_data),
        .gray_in_ready      (downsample_pix_ready),
        .gray_in_valid      (downsample_pix_valid),
        .out_data           (disparity),
        .image_index_counter     (image_index_counter),
        .out_valid          (disparity_valid),
        .out_ready          (disparity_ready)
    );
    
endmodule