// soc_system_sys_3.v

// Generated using ACDS version 18.1 625

`timescale 1 ps / 1 ps
module block_matching_system #(
    parameter blk_w = 16,
    parameter blk_h = 16,
    parameter search_blk_h = 24,
    parameter search_blk_w = 48,
    parameter third_w = 240,
    parameter third_h = 480,
    parameter center_w = 304
    ) (
		input  wire [15:0]  bit_pix_bram_mod_0_wr_address,   
		input  wire [1:0]   bit_pix_bram_mod_0_wr_third,                          //                         bit_pix_bram_mod_0_wr.address
		input  wire [15:0]  bit_pix_bram_mod_0_wr_writedata,                       //                                              .writedata
		input  wire         bit_pix_bram_mod_0_wr_write,                           //                                              .write
		output wire         blk_match_ctrl_fsm_0_bm_status_conduit_bm_idle,        //        blk_match_ctrl_fsm_0_bm_status_conduit.bm_idle
		output wire         blk_match_ctrl_fsm_0_bm_status_conduit_bm_working_buf, //                                              .bm_working_buf
		input  wire [3:0]   blk_match_ctrl_fsm_0_bm_status_conduit_image_number,   //                                              .image_number
		input  wire         clk_clk,                                               //                                           clk.clk
		/*output wire [7:0]   ddr3_writer_supersimple_0_avalon_master_burstcount,    //       ddr3_writer_supersimple_0_avalon_master.burstcount
		input  wire         ddr3_writer_supersimple_0_avalon_master_waitrequest,   //                                              .waitrequest
		output wire         ddr3_writer_supersimple_0_avalon_master_write,         //                                              .write
		output wire [26:0]  ddr3_writer_supersimple_0_avalon_master_address,       //                                              .address
		output wire [255:0] ddr3_writer_supersimple_0_avalon_master_writedata,     //                                              .writedata
		input  wire         ddr3_writer_supersimple_0_ddr3clk_clk,                 //             ddr3_writer_supersimple_0_ddr3clk.clk
		input  wire         ddr3_writer_supersimple_0_ddr3clk_reset_reset,*/         //       ddr3_writer_supersimple_0_ddr3clk_reset.reset
		output wire [15:0]  min_dist_finder_left_out_conduit_blk_index,            //              min_dist_finder_left_out_conduit.blk_index
		output wire [7:0]   min_dist_finder_left_out_conduit_sum,                  //                                              .sum
		output wire [7:0]   min_dist_finder_left_out_conduit_data,                 //                                              .data
		output wire [7:0]   min_dist_finder_left_out_conduit_average_sum,          //                                              .average_sum
		output wire         min_dist_finder_right_avalon_streaming_source_valid,   // min_dist_finder_right_avalon_streaming_source.valid
		output wire [15:0]  min_dist_finder_right_avalon_streaming_source_data,    //                                              .data
		output wire [15:0]  min_dist_finder_right_out_conduit_blk_index,           //             min_dist_finder_right_out_conduit.blk_index
		output wire [7:0]   min_dist_finder_right_out_conduit_sum,                 //                                              .sum
		output wire [7:0]   min_dist_finder_right_out_conduit_data,                //                                              .data
		output wire [7:0]   min_dist_finder_right_out_conduit_average_sum,         //                                              .average_sum
        output wire         min_dist_finder_left_avalon_streaming_source_valid, // min_dist_finder_left:min_sum_valid -> avalon_st_adapter:in_0_valid
        output wire  [15:0] min_dist_finder_left_avalon_streaming_source_data,  // min_dist_finder_left:min_out_coords -> avalon_st_adapter:in_0_data
		input  wire         reset_reset_n                                          //                                         reset.reset_n
	);

    localparam blk_size = blk_w * blk_h;

	wire    [7:0] bit_pix_bram_mod_0_centerleft_rd_readdata;          // bit_pix_bram_mod_0:rd_data_centerleft -> blk_match_left:srch_rd_data
	wire   [15:0] blk_match_left_srch_master_address;                 // blk_match_left:srch_rd_addr -> bit_pix_bram_mod_0:rd_address_centerleft
	wire    [7:0] bit_pix_bram_mod_0_centerright_rd_readdata;         // bit_pix_bram_mod_0:rd_data_centerright -> blk_match_right:srch_rd_data
	wire   [15:0] blk_match_right_srch_master_address;                // blk_match_right:srch_rd_addr -> bit_pix_bram_mod_0:rd_address_centerright
	wire   [15:0] blk_match_ctrl_fsm_0_right_control_srch_addr;       // blk_match_ctrl_fsm_0:srch_addr_right -> blk_match_right:srch_start_address
	wire   [15:0] blk_match_ctrl_fsm_0_right_control_blk_index;       // blk_match_ctrl_fsm_0:blk_index_right -> blk_match_right:blk_index
	wire          blk_match_ctrl_fsm_0_right_control_start;           // blk_match_ctrl_fsm_0:bm_start_right -> blk_match_right:start
	wire   [15:0] blk_match_ctrl_fsm_0_right_control_blk_addr;        // blk_match_ctrl_fsm_0:blk_addr_right -> blk_match_right:blk_start_address
	wire          hamming_dist_left_out_conduit_valid;                // hamming_dist_left:sum_valid -> min_dist_finder_left:sum_valid
	wire   [15:0] hamming_dist_left_out_conduit_blk_coords;           // hamming_dist_left:out_coords -> min_dist_finder_left:out_coords
	wire   [15:0] hamming_dist_left_out_conduit_blk_index;            // hamming_dist_left:blk_index_o -> min_dist_finder_left:blk_index_o
	wire    [7:0] hamming_dist_left_out_conduit_sum;                  // hamming_dist_left:sum -> min_dist_finder_left:sum
	wire          blk_match_left_result_conduit_blks_valid;           // blk_match_left:blks_valid -> hamming_dist_left:blks_valid
	wire  [blk_size-1:0] blk_match_left_result_conduit_srch_block;           // blk_match_left:srch_block -> hamming_dist_left:left
	wire   [15:0] blk_match_left_result_conduit_blk_index;            // blk_match_left:blk_index_o -> hamming_dist_left:blk_index_i
	wire   [15:0] blk_match_left_result_conduit_coords_out;           // blk_match_left:coords_out -> hamming_dist_left:in_coords
	wire  [blk_size-1:0] blk_match_left_result_conduit_blk_block;            // blk_match_left:blk_block -> hamming_dist_left:right
	wire   [15:0] blk_match_ctrl_fsm_0_left_control_srch_addr;        // blk_match_ctrl_fsm_0:srch_addr_left -> blk_match_left:srch_start_address
	wire   [15:0] blk_match_ctrl_fsm_0_left_control_blk_index;        // blk_match_ctrl_fsm_0:blk_index_left -> blk_match_left:blk_index
	wire          blk_match_ctrl_fsm_0_left_control_start;            // blk_match_ctrl_fsm_0:bm_start_left -> blk_match_left:start
	wire   [15:0] blk_match_ctrl_fsm_0_left_control_blk_addr;         // blk_match_ctrl_fsm_0:blk_addr_left -> blk_match_left:blk_start_address
	wire          blk_match_left_ctrl_conduit_done;                   // blk_match_left:done -> blk_match_ctrl_fsm_0:bm_done
	wire    [7:0] bit_pix_bram_mod_0_left_rd_readdata;                // bit_pix_bram_mod_0:rd_data_left -> blk_match_left:blk_rd_data
	wire   [15:0] blk_match_left_blk_master_address;                  // blk_match_left:blk_rd_addr -> bit_pix_bram_mod_0:rd_address_left
	wire          hamming_dist_right_out_conduit_valid;               // hamming_dist_right:sum_valid -> min_dist_finder_right:sum_valid
	wire   [15:0] hamming_dist_right_out_conduit_blk_coords;          // hamming_dist_right:out_coords -> min_dist_finder_right:out_coords
	wire   [15:0] hamming_dist_right_out_conduit_blk_index;           // hamming_dist_right:blk_index_o -> min_dist_finder_right:blk_index_o
	wire    [7:0] hamming_dist_right_out_conduit_sum;                 // hamming_dist_right:sum -> min_dist_finder_right:sum
	wire          blk_match_right_result_conduit_blks_valid;          // blk_match_right:blks_valid -> hamming_dist_right:blks_valid
	wire  [blk_size-1:0] blk_match_right_result_conduit_srch_block;          // blk_match_right:srch_block -> hamming_dist_right:left
	wire   [15:0] blk_match_right_result_conduit_blk_index;           // blk_match_right:blk_index_o -> hamming_dist_right:blk_index_i
	wire   [15:0] blk_match_right_result_conduit_coords_out;          // blk_match_right:coords_out -> hamming_dist_right:in_coords
	wire  [blk_size-1:0] blk_match_right_result_conduit_blk_block;           // blk_match_right:blk_block -> hamming_dist_right:right
	wire    [7:0] bit_pix_bram_mod_0_right_rd_readdata;               // bit_pix_bram_mod_0:rd_data_right -> blk_match_right:blk_rd_data
	wire   [15:0] blk_match_right_blk_master_address;                 // blk_match_right:blk_rd_addr -> bit_pix_bram_mod_0:rd_address_right
	//wire          min_dist_finder_left_avalon_streaming_source_valid; // min_dist_finder_left:min_sum_valid -> avalon_st_adapter:in_0_valid
	//wire   [15:0] min_dist_finder_left_avalon_streaming_source_data;  // min_dist_finder_left:min_out_coords -> avalon_st_adapter:in_0_data
	//wire          avalon_st_adapter_out_0_valid;                      // avalon_st_adapter:out_0_valid -> ddr3_writer_supersimple_0:pixel_valid
	//wire   [15:0] avalon_st_adapter_out_0_data;                       // avalon_st_adapter:out_0_data -> ddr3_writer_supersimple_0:pixel
	//wire          avalon_st_adapter_out_0_ready;                      // ddr3_writer_supersimple_0:pixel_ready -> avalon_st_adapter:out_0_ready
	//wire          rst_controller_reset_out_reset;                     // rst_controller:reset_out -> [avalon_st_adapter:in_rst_0_reset, bit_pix_bram_mod_0:reset, ddr3_writer_supersimple_0:pclk_reset, min_dist_finder_left:reset, min_dist_finder_right:reset]
	//wire          rst_controller_001_reset_out_reset;                 // rst_controller_001:reset_out -> [blk_match_ctrl_fsm_0:reset, blk_match_left:reset, blk_match_right:reset, hamming_dist_left:reset, hamming_dist_right:reset]

	block_match_ram_module #(
        .third_width    (third_w),
        .third_height   (third_h),
        .center_width   (center_w)
    ) bit_pix_bram_mod_0 (
		.clk                    (clk_clk),                                    //          clock.clk
		.reset                  (~reset_reset_n),             //          reset.reset
		.wr_address             (bit_pix_bram_mod_0_wr_address),              //          reset.reset
		.wr_third               (bit_pix_bram_mod_0_wr_third),             //             wr.address
		.wr_data                (bit_pix_bram_mod_0_wr_writedata),            //               .writedata
		.write                  (bit_pix_bram_mod_0_wr_write),                //               .write
		.rd_address_left        (blk_match_left_blk_master_address),          //        left_rd.address
		.rd_data_left           (bit_pix_bram_mod_0_left_rd_readdata),        //               .readdata
		.rd_address_right       (blk_match_right_blk_master_address),         //       right_rd.address
		.rd_data_right          (bit_pix_bram_mod_0_right_rd_readdata),       //               .readdata
		.rd_data_centerleft     (bit_pix_bram_mod_0_centerleft_rd_readdata),  //  centerleft_rd.readdata
		.rd_address_centerleft  (blk_match_left_srch_master_address),         //               .address
		.rd_data_centerright    (bit_pix_bram_mod_0_centerright_rd_readdata), // centerright_rd.readdata
		.rd_address_centerright (blk_match_right_srch_master_address)         //               .address
	);

	block_match_ctrl_fsm_new #(
		.rd_port_w    (8),
		.third_w      (third_w),
		.center_w     (center_w),
		.third_h      (third_h),
		.block_width  (blk_w),
		.block_height (blk_h),
		.search_blk_w (search_blk_w),
		.search_blk_h (search_blk_h)
	) blk_match_ctrl_fsm_0 (
		.reset           (~reset_reset_n),                    //             reset.reset
		.clk             (clk_clk),                                               //             clock.clk
		.srch_addr_left  (blk_match_ctrl_fsm_0_left_control_srch_addr),           //      left_control.srch_addr
		.bm_start_left   (blk_match_ctrl_fsm_0_left_control_start),               //                  .start
		.blk_index_left  (blk_match_ctrl_fsm_0_left_control_blk_index),           //                  .blk_index
		.blk_addr_left   (blk_match_ctrl_fsm_0_left_control_blk_addr),            //                  .blk_addr
		.bm_done         (blk_match_left_ctrl_conduit_done),                      //                  .done
		.srch_addr_right (blk_match_ctrl_fsm_0_right_control_srch_addr),          //     right_control.srch_addr
		.bm_start_right  (blk_match_ctrl_fsm_0_right_control_start),              //                  .start
		.blk_addr_right  (blk_match_ctrl_fsm_0_right_control_blk_addr),           //                  .blk_addr
		.blk_index_right (blk_match_ctrl_fsm_0_right_control_blk_index),          //                  .blk_index
		.bm_idle         (blk_match_ctrl_fsm_0_bm_status_conduit_bm_idle),        // bm_status_conduit.bm_idle
		.bm_working_buf  (blk_match_ctrl_fsm_0_bm_status_conduit_bm_working_buf), //                  .bm_working_buf
		.img_number_in   (blk_match_ctrl_fsm_0_bm_status_conduit_image_number)    //                  .image_number
	);

	block_match_new #(
		.rd_port_w    (8),
		.block_width  (blk_w),
		.block_height (blk_h),
		.search_blk_w (search_blk_w),
		.search_blk_h (search_blk_h),
		.center_w     (center_w),
		.third_w      (third_w)
	) blk_match_left (
		.clk                (clk_clk),                                     //          clock.clk
		.reset              (~reset_reset_n),          //          reset.reset
		.blk_index          (blk_match_ctrl_fsm_0_left_control_blk_index), //   ctrl_conduit.blk_index
		.start              (blk_match_ctrl_fsm_0_left_control_start),     //               .start
		.done               (blk_match_left_ctrl_conduit_done),            //               .done
		.blk_start_address  (blk_match_ctrl_fsm_0_left_control_blk_addr),  //               .blk_addr
		.srch_start_address (blk_match_ctrl_fsm_0_left_control_srch_addr), //               .srch_addr
		.blk_block          (blk_match_left_result_conduit_blk_block),     // result_conduit.blk_block
		.blk_index_o        (blk_match_left_result_conduit_blk_index),     //               .blk_index
		.srch_block         (blk_match_left_result_conduit_srch_block),    //               .srch_block
		.coords_out         (blk_match_left_result_conduit_coords_out),    //               .coords_out
		.blks_valid         (blk_match_left_result_conduit_blks_valid),    //               .blks_valid
		.srch_rd_addr       (blk_match_left_srch_master_address),          //    srch_master.address
		.srch_rd_data       (bit_pix_bram_mod_0_centerleft_rd_readdata),   //               .readdata
		.blk_rd_addr        (blk_match_left_blk_master_address),           //     blk_master.address
		.blk_rd_data        (bit_pix_bram_mod_0_left_rd_readdata)          //               .readdata
	);

	block_match_new #(
		.rd_port_w    (8),
		.block_width  (blk_w),
		.block_height (blk_h),
		.search_blk_w (search_blk_w),
		.search_blk_h (search_blk_h),
		.center_w     (center_w),
		.third_w      (third_w)
    ) blk_match_right (
		.clk                (clk_clk),                                      //          clock.clk
		.reset              (~reset_reset_n),           //          reset.reset
		.blk_index          (blk_match_ctrl_fsm_0_right_control_blk_index), //   ctrl_conduit.blk_index
		.start              (blk_match_ctrl_fsm_0_right_control_start),     //               .start
		.done               (),                                             //               .done
		.blk_start_address  (blk_match_ctrl_fsm_0_right_control_blk_addr),  //               .blk_addr
		.srch_start_address (blk_match_ctrl_fsm_0_right_control_srch_addr), //               .srch_addr
		.blk_block          (blk_match_right_result_conduit_blk_block),     // result_conduit.blk_block
		.blk_index_o        (blk_match_right_result_conduit_blk_index),     //               .blk_index
		.srch_block         (blk_match_right_result_conduit_srch_block),    //               .srch_block
		.coords_out         (blk_match_right_result_conduit_coords_out),    //               .coords_out
		.blks_valid         (blk_match_right_result_conduit_blks_valid),    //               .blks_valid
		.srch_rd_addr       (blk_match_right_srch_master_address),          //    srch_master.address
		.srch_rd_data       (bit_pix_bram_mod_0_centerright_rd_readdata),   //               .readdata
		.blk_rd_addr        (blk_match_right_blk_master_address),           //     blk_master.address
		.blk_rd_data        (bit_pix_bram_mod_0_right_rd_readdata)          //               .readdata
	);

	hamming_dist_new #(
		.blk_size    (blk_size),
		.lut_bits_in (4)
	) hamming_dist_left (
		.clk         (clk_clk),                                  //       clock.clk
		.reset       (~reset_reset_n),       //       reset.reset
		.blk_index_o (hamming_dist_left_out_conduit_blk_index),  // out_conduit.blk_index
		.sum_valid   (hamming_dist_left_out_conduit_valid),      //            .valid
		.sum         (hamming_dist_left_out_conduit_sum),        //            .sum
		.xors        (),                                         //            .xors
		.out_coords  (hamming_dist_left_out_conduit_blk_coords), //            .blk_coords
		.right       (blk_match_left_result_conduit_blk_block),  //  in_conduit.blk_block
		.left        (blk_match_left_result_conduit_srch_block), //            .srch_block
		.blk_index_i (blk_match_left_result_conduit_blk_index),  //            .blk_index
		.blks_valid  (blk_match_left_result_conduit_blks_valid), //            .blks_valid
		.in_coords   (blk_match_left_result_conduit_coords_out)  //            .coords_out
	);

	hamming_dist_new #(
		.blk_size    (blk_size),
		.lut_bits_in (4)
	) hamming_dist_right (
		.clk         (clk_clk),                                   //       clock.clk
		.reset       (~reset_reset_n),        //       reset.reset
		.blk_index_o (hamming_dist_right_out_conduit_blk_index),  // out_conduit.blk_index
		.sum_valid   (hamming_dist_right_out_conduit_valid),      //            .valid
		.sum         (hamming_dist_right_out_conduit_sum),        //            .sum
		.xors        (),                                          //            .xors
		.out_coords  (hamming_dist_right_out_conduit_blk_coords), //            .blk_coords
		.right       (blk_match_right_result_conduit_blk_block),  //  in_conduit.blk_block
		.left        (blk_match_right_result_conduit_srch_block), //            .srch_block
		.blk_index_i (blk_match_right_result_conduit_blk_index),  //            .blk_index
		.blks_valid  (blk_match_right_result_conduit_blks_valid), //            .blks_valid
		.in_coords   (blk_match_right_result_conduit_coords_out)  //            .coords_out
	);

	min_dist_finder #(
		.blk_h        (blk_h),
		.blk_w        (blk_w),
		.search_blk_w (search_blk_w),
		.search_blk_h (search_blk_h),
        .output_confidence  (1)
	) min_dist_finder_left (
		.clk             (clk_clk),                                            //                   clock.clk
		.reset           (~reset_reset_n),                     //                   reset.reset
		.min_blk_index_o (min_dist_finder_left_out_conduit_blk_index),         //             out_conduit.blk_index
		.min_sum         (min_dist_finder_left_out_conduit_sum),               //                        .sum
		.min_sumh        (min_dist_finder_left_out_conduit_data),              //                        .data
		.average_sum     (min_dist_finder_left_out_conduit_average_sum),       //                        .average_sum
		.sum             (hamming_dist_left_out_conduit_sum),                  //              in_conduit.sum
		.out_coords      (hamming_dist_left_out_conduit_blk_coords),           //                        .blk_coords
		.sum_valid       (hamming_dist_left_out_conduit_valid),                //                        .valid
		.blk_index_o     (hamming_dist_left_out_conduit_blk_index),            //                        .blk_index
		.min_sum_valid   (min_dist_finder_left_avalon_streaming_source_valid), // avalon_streaming_source.valid
		.min_out_coords  (min_dist_finder_left_avalon_streaming_source_data)   //                        .data
	);

	min_dist_finder #(
		.blk_h        (blk_h),
		.blk_w        (blk_w),
		.search_blk_w (search_blk_w),
		.search_blk_h (search_blk_h),
        .output_confidence  (1)
	) min_dist_finder_right (
		.clk             (clk_clk),                                             //                   clock.clk
		.reset           (~reset_reset_n),                      //                   reset.reset
		.min_blk_index_o (min_dist_finder_right_out_conduit_blk_index),         //             out_conduit.blk_index
		.min_sum         (min_dist_finder_right_out_conduit_sum),               //                        .sum
		.min_sumh        (min_dist_finder_right_out_conduit_data),              //                        .data
		.average_sum     (min_dist_finder_right_out_conduit_average_sum),       //                        .average_sum
		.sum             (hamming_dist_right_out_conduit_sum),                  //              in_conduit.sum
		.out_coords      (hamming_dist_right_out_conduit_blk_coords),           //                        .blk_coords
		.sum_valid       (hamming_dist_right_out_conduit_valid),                //                        .valid
		.blk_index_o     (hamming_dist_right_out_conduit_blk_index),            //                        .blk_index
		.min_sum_valid   (min_dist_finder_right_avalon_streaming_source_valid), // avalon_streaming_source.valid
		.min_out_coords  (min_dist_finder_right_avalon_streaming_source_data)   //                        .data
	);

endmodule
