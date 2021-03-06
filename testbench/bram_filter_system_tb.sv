`timescale 1 ps / 1 ps

module bram_filter_system_tb;
    //clock and reset signal declaration
    logic clk50;
    logic reset;
    always #5ns clk50 = ~clk50;
    
    logic [3:0] foo;
    logic [3:0] foo2;
    logic gray_wr_enable;
    
    initial begin
        gray_wr_enable = 0;
        clk50 = 0;
        reset = 1;
        
        foo = 4'hF;
        foo2 = 4'h0;
        #100ns reset = 0;
        /*if (foo != (foo2 - 1)) begin
            $error("BAD!!! %08x %04x", (foo2 - 1), foo);
        end else begin
            $display("Good :)");
            $stop;
        end*/
        
        
        #9800us;
        
        $stop;
    end
    
    parameter frame_w = 240;
    parameter frame_h = 480;
    parameter dec_factor = 3; // Make sure to change this in the python
    parameter dec_frame_w = frame_w / dec_factor;
    parameter dec_frame_h = frame_h / dec_factor;
 
    logic [15:0]    disp_conf_in;
    logic           disp_conf_in_valid;
    logic           disp_conf_in_ready;
    
    logic [7:0]     gray_in;
    logic           gray_in_valid;
    logic           gray_in_ready;
 
    logic out_valid;
    logic [7:0] out_data;
    
    
    logic [7:0]     grayds_in;
    logic           grayds_in_valid;
    logic           grayds_in_ready;
    
    always @(posedge clk50) gray_wr_enable <= ~gray_wr_enable;
    
    /*downsample_2d #(
        .dec_factor (dec_factor),
        .in_width   (frame_w),
        .in_height  (frame_h)
    ) ds2d (
        .clk    (clk50),
        .reset  (reset),
        .in_data    (gray_in),
        .in_valid   (gray_in_valid),
        .in_ready   (gray_in_ready),
        .out_data   (grayds_in),
        .out_valid  (grayds_in_valid),
        .out_ready  (grayds_in_ready)
    );*/
    
    input_stream #(
        .data_width (8),
        .data_len   (dec_frame_w * dec_frame_h),
        .file_path  ("gray_in_data.bin")
    ) input_stream_gray (
        .clk    (clk50),
        .reset  (reset),
        .data_out_valid (gray_in_valid),
        .data_out_ready (gray_in_ready && gray_wr_enable),
        .data_out       (gray_in)
    );
    
    input_stream #(
        .data_width (16),
        .data_len   (dec_frame_w * dec_frame_h),
        .file_path  ("disp_conf_in_data.bin")
    ) input_stream_disp_conf (
        .clk    (clk50),
        .reset  (reset),
        .data_out_valid (disp_conf_in_valid),
        .data_out_ready (disp_conf_in_ready && gray_wr_enable),
        .data_out       (disp_conf_in)
    );
 
    bram_filter_system #(
        .dec_frame_w    (dec_frame_w),
        .dec_frame_h    (dec_frame_h),
        .disp_bits      (5)
    ) bfs1 (
        .clk    (clk50),
        .reset  (reset),
        .disp_conf_in_data  (disp_conf_in),
        .disp_conf_in_valid (disp_conf_in_valid && gray_wr_enable),
        .disp_conf_in_ready (disp_conf_in_ready),
        .gray_in_data       (gray_in),
        .gray_in_valid      (gray_in_valid && gray_wr_enable),
        .gray_in_ready      (gray_in_ready),
        .out_ready          (1'b1),
        .out_valid          (out_valid),
        .out_data           (out_data)
    );
    
    /*output_compare #(
        .data_width (8),
        .data_len   (dec_frame_w * dec_frame_h),
        .file_path  ("gray_in_data.bin")
    ) ocfloop  (
        .clk    (clk50),
        .reset  (reset),
        .data_in_valid  (out_valid),
        .data_in        (out_data)
    );*/
    
    output_compare #(
        .data_width (16),
        .data_len   (dec_frame_w * dec_frame_h),
        .file_path  ("filtered_disp_conf_data.bin")
    ) output_compare_stuff  (
        .clk    (clk50),
        .reset  (reset),
        .data_in_valid  (out_valid),
        .data_in        ({3'b000, bfs1.bram_reader_output[20:8]})
    );
    

endmodule