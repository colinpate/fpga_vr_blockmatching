module bram_filter_system #(
        parameter dec_frame_w = 120,
        parameter dec_frame_h = 240,
        parameter disp_bits = 5
    ) (
        input                   clk,
        input                   reset,
        
        input [disp_bits + 7:0] disp_conf_in_data,
        input                   disp_conf_in_valid,
        output                  disp_conf_in_ready,
        
        input [7:0]             gray_in_data,
        input                   gray_in_valid,
        output                  gray_in_ready,
        
        output [3:0]            image_index_counter,
        
        output [15:0]           out_data,
        output                  out_valid,
        input                   out_ready
    );
    
    localparam frame_size = dec_frame_w * dec_frame_h;
    localparam bram_addr_w = $clog2(frame_size);
    
    // bram_writer_2in control
    logic bram_writer_2in_start;
    logic bram_writer_2in_index_in;
    logic bram_writer_2in_idle;
    
    // bram_writer_2in data outputs
    logic                       bram_writer_index_out;
    logic [15 + disp_bits:0]    bram_writer_wr_data;
    logic [bram_addr_w - 1:0]   bram_writer_wr_address;
    logic                       bram_writer_wr_ena;

    // filter bram writer control
    logic filt_bram_rw_start;
    logic filt_bram_rw_index;
    logic filt_bram_rw_idle;
    
    // filter bram writer data
    logic                       filt_wr_index;
    logic [15 + disp_bits:0]    filt_wr_data;
    logic [bram_addr_w - 1:0]   filt_wr_address;
    logic                       filt_wr_ena;
    
    logic                       filt_rd_index_out;
    logic [15 + disp_bits:0]    filt_rd_data;
    logic [bram_addr_w - 1:0]   filt_rd_address;
    
    
    // out bram reader control
    logic out_bram_reader_start;
    logic out_bram_reader_index;
    logic out_bram_reader_idle;
    
    // out bram reader data
    logic                       out_rd_index_out;
    logic [15 + disp_bits:0]    out_rd_data;
    logic [bram_addr_w - 1:0]   out_rd_address;
    
    // Signals to the BRAM modules
    logic [1:0][bram_addr_w - 1:0]  bram_wr_addresses;
    logic [1:0][15 + disp_bits:0]   bram_wr_datas;
    logic [1:0]                     bram_wr_enas;
    
    logic [1:0][bram_addr_w - 1:0]  bram_rd_addresses;
    logic [1:0][15 + disp_bits:0]   bram_rd_datas;
    
    // The block match control FSM waits for filtering_done to start the
    // next frame of block matches.
    // This isn't set to be the idle bits because they get restarted automatically
    // even before the next frame of block matching starts, so we'd have a lockout
    //assign filtering_done = (bram_writer_wr_address == 0) && (out_rd_address == 0);
    
    bram_filter_control_fsm bram_filter_control_fsm_inst (
        .clk                (clk),
        .reset              (reset),
        
        .image_index_counter    (image_index_counter),
        
        .bram_writer_2in_start  (bram_writer_2in_start),
        .bram_writer_2in_index  (bram_writer_2in_index_in),
        .bram_writer_2in_idle   (bram_writer_2in_idle),
        
        .filt_bram_rw_start     (filt_bram_rw_start),
        .filt_bram_rw_index     (filt_bram_rw_index),
        .filt_bram_rw_idle      (filt_bram_rw_idle),
        
        .out_bram_reader_start  (out_bram_reader_start),
        .out_bram_reader_index  (out_bram_reader_index),
        .out_bram_reader_idle   (out_bram_reader_idle)
    );
    
    bram_writer_2in #(
        .width      (dec_frame_w),
        .height     (dec_frame_h),
        .a_width    (8 + disp_bits), // disp_conf
        .b_width    (8) // grayscale pixels
    ) bram_writer_gray_disp_conf (
        .clk        (clk),
        .reset      (reset),
        
        .a_data     (disp_conf_in_data),
        .a_valid    (disp_conf_in_valid),
        .a_ready    (disp_conf_in_ready),
        
        .b_data     (gray_in_data),
        .b_valid    (gray_in_valid),
        .b_ready    (gray_in_ready),
        
        .start          (bram_writer_2in_start),
        .bram_index_in  (bram_writer_2in_index_in),
        .idle           (bram_writer_2in_idle),
        
        .wr_bram_index  (bram_writer_index_out),
        .wr_data        (bram_writer_wr_data), // {disp, conf, gray}
        .wr_address     (bram_writer_wr_address),
        .wr_ena         (bram_writer_wr_ena)
    );
    
    filt_bram_reader_writer #(
        .width  (dec_frame_w),
        .height (dec_frame_h),
        .disp_bits  (disp_bits),
        .num_passes (30), // Dependent on timing really
        .gray_threshold (10)
    ) fbrw_inst (
        .clk        (clk),
        .reset      (reset),
        
        .start      (filt_bram_rw_start),
        .index_in   (filt_bram_rw_index),
        .idle       (filt_bram_rw_idle),
        
        .rd_addr    (filt_rd_address),
        .rd_index   (filt_rd_index_out),
        .rd_data    (filt_rd_data),
        
        .wr_addr    (filt_wr_address),
        .wr_index   (filt_wr_index),
        .wr_data    (filt_wr_data),
        .wr_ena     (filt_wr_ena)
    );
    
    logic [15 + disp_bits:0]    bram_reader_output;
    // 20:16 are disparity, 15:8 are confidence, 7:0] are grayscale
    assign out_data = {bram_reader_output[20:16], 3'b000, bram_reader_output[7:0]};
    
    bram_reader_out #(
        .width  (dec_frame_w),
        .height (dec_frame_h),
        .data_width (16 + disp_bits)
    ) bram_reader_out_inst (
        .clk        (clk),
        .reset      (reset),
        .out_data   (bram_reader_output),
        .out_valid  (out_valid),
        .out_ready  (out_ready),
        .start      (out_bram_reader_start),
        .bram_index_in  (out_bram_reader_index),
        .idle           (out_bram_reader_idle),
        .rd_bram_index  (out_rd_index_out),
        .rd_data        (out_rd_data),
        .rd_address     (out_rd_address)
    );
    
    always_comb begin
        bram_wr_addresses = 'b0;
        bram_rd_addresses = 'b0;
        bram_wr_enas = 'b0;
        bram_wr_datas = 'b0;
        
        out_rd_data = 'b0;
        filt_rd_data = 'b0;
        
        // Multiplex the read ports
        if ((out_bram_reader_index == 1'b1) && (filt_rd_index_out == 1'b0)) begin
            bram_rd_addresses[1]    = out_rd_address;
            out_rd_data             = bram_rd_datas[1];
            
            bram_rd_addresses[0]    = filt_rd_address;
            filt_rd_data            = bram_rd_datas[0];
        end else if ((out_bram_reader_index == 1'b0) && (filt_rd_index_out == 1'b1)) begin
            bram_rd_addresses[0]    = out_rd_address;
            out_rd_data             = bram_rd_datas[0];
            
            bram_rd_addresses[1]    = filt_rd_address;
            filt_rd_data            = bram_rd_datas[1];
        end
        
        // Multiplex the write ports
        if ((bram_writer_index_out == 1'b1) && (filt_wr_index == 1'b0)) begin
            bram_wr_addresses[1]    = bram_writer_wr_address;
            bram_wr_datas[1]        = bram_writer_wr_data;
            bram_wr_enas[1]         = bram_writer_wr_ena;
            
            bram_wr_addresses[0]    = filt_wr_address;
            bram_wr_datas[0]        = filt_wr_data;
            bram_wr_enas[0]         = filt_wr_ena;
        end else if ((bram_writer_index_out == 1'b0) && (filt_wr_index == 1'b1)) begin
            bram_wr_addresses[0]    = bram_writer_wr_address;
            bram_wr_datas[0]        = bram_writer_wr_data;
            bram_wr_enas[0]         = bram_writer_wr_ena;
            
            bram_wr_addresses[1]    = filt_wr_address;
            bram_wr_datas[1]        = filt_wr_data;
            bram_wr_enas[1]         = filt_wr_ena;
        end
    end
    
    bram_wrapper #(
        .wr_addr_w  (bram_addr_w),
        .rd_addr_w  (bram_addr_w),
        .wr_data_w  (16 + disp_bits),
        .rd_data_w  (16 + disp_bits),
        .wr_word_depth  (frame_size),
        .rd_word_depth  (frame_size)
    ) bram_modules[1:0] (
        .clk        (clk),
        .wr_addr    (bram_wr_addresses),
        .rd_addr    (bram_rd_addresses),
        .wren       (bram_wr_enas),
        .wr_data    (bram_wr_datas),
        .rd_data    (bram_rd_datas)
    );
endmodule
    