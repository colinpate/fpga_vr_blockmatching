// soc_system_sys_3.v

// Generated using ACDS version 18.1 625

//`default_nettype none
`timescale 1 ps / 1 ps
module block_matching_system #(
    parameter blk_w = 16,
    parameter blk_h = 16,
    parameter search_blk_h = 24,
    parameter search_blk_w = 48,
    parameter third_w = 240,
    parameter third_h = 480,
    parameter center_w = 304,
    parameter decimate_factor = 2,
    parameter output_confidence = 0
    ) (
		input  wire         clk_clk,                
		input  wire         reset_reset_n,                                          //                                         reset.reset_n                               //                                           clk.clk
		input  wire [15:0]  bit_pix_bram_mod_0_wr_address,   
		input  wire [1:0]   bit_pix_bram_mod_0_wr_third,                          //                         bit_pix_bram_mod_0_wr.address
		input  wire [15:0]  bit_pix_bram_mod_0_wr_writedata,                       //                                              .writedata
		input  wire         bit_pix_bram_mod_0_wr_write,                           //                                              .write
		output wire         blk_match_ctrl_fsm_0_bm_status_conduit_bm_idle,        //        blk_match_ctrl_fsm_0_bm_status_conduit.bm_idle
		output wire         blk_match_ctrl_fsm_0_bm_status_conduit_bm_working_buf, //                                              .bm_working_buf
		input  wire [3:0]   blk_match_ctrl_fsm_0_bm_status_conduit_image_number,   //                                              .image_number
		//output wire [15:0]  min_dist_finder_left_out_conduit_blk_index,            //              min_dist_finder_left_out_conduit.blk_index
		//output wire [7:0]   min_dist_finder_left_out_conduit_sum,                  //                                              .sum
		//output wire [7:0]   min_dist_finder_left_out_conduit_data,                 //                                              .data
		//output wire [7:0]   min_dist_finder_left_out_conduit_average_sum,          //                                              .average_sum
		output wire         min_dist_finder_right_avalon_streaming_source_valid,   // min_dist_finder_right_avalon_streaming_source.valid
		output wire [15:0]  min_dist_finder_right_avalon_streaming_source_data,    //                                              .data
		//output wire [15:0]  min_dist_finder_right_out_conduit_blk_index,           //             min_dist_finder_right_out_conduit.blk_index
		//output wire [7:0]   min_dist_finder_right_out_conduit_sum,                 //                                              .sum
		//output wire [7:0]   min_dist_finder_right_out_conduit_data,                //                                              .data
		//output wire [7:0]   min_dist_finder_right_out_conduit_average_sum,         //                                              .average_sum
        output wire         min_dist_finder_left_avalon_streaming_source_valid, // min_dist_finder_left:min_sum_valid -> avalon_st_adapter:in_0_valid
        output wire  [15:0] min_dist_finder_left_avalon_streaming_source_data,  // min_dist_finder_left:min_out_coords -> avalon_st_adapter:in_0_data
        
        input   [7:0]   gray_pixel_left_data,
        input           gray_pixel_left_valid,
        output          gray_pixel_left_ready,
        
        input   [7:0]   gray_pixel_right_data,
        input           gray_pixel_right_valid,
        output          gray_pixel_right_ready,
        
        output wire [15:0]  disparity_out_left,
        output wire         disparity_valid_left,
        input wire          disparity_ready_left,
        output wire [15:0]  disparity_out_right,
        output wire         disparity_valid_right,
        input wire         disparity_ready_right
	);

    localparam blk_size = blk_w * blk_h;
    // This is the frame height less the padding at the top and bottom
    localparam blocks_per_col = (third_h - (search_blk_h - blk_h)) / blk_h;
    localparam frame_wr_height = blocks_per_col * blk_h;
    //Unused atm
    wire [7:0]   min_dist_finder_left_out_conduit_sum;
    wire [7:0]   min_dist_finder_right_out_conduit_sum;

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
    
    wire [15:0] min_dist_finder_left_out_conduit_blk_index;
    wire [15:0] min_dist_finder_right_out_conduit_blk_index;
    
    logic [3:0] image_index_counter_left;
    logic [3:0] image_index_counter_right;

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
        .image_index_counter_left  (image_index_counter_left),
        .image_index_counter_right (image_index_counter_right),
		.srch_addr_right (blk_match_ctrl_fsm_0_right_control_srch_addr),          //     right_control.srch_addr
		.bm_start_right  (blk_match_ctrl_fsm_0_right_control_start),              //                  .start
		.blk_addr_right  (blk_match_ctrl_fsm_0_right_control_blk_addr),           //                  .blk_addr
		.blk_index_right (blk_match_ctrl_fsm_0_right_control_blk_index),          //                  .blk_index
		.bm_idle         (blk_match_ctrl_fsm_0_bm_status_conduit_bm_idle),        // bm_status_conduit.bm_idle
		.bm_working_buf  (blk_match_ctrl_fsm_0_bm_status_conduit_bm_working_buf), //                  .bm_working_buf
		.img_number_in   (blk_match_ctrl_fsm_0_bm_status_conduit_image_number)    //                  .image_number
	);

    logic [15:0] min_out_coords_left;
    logic [7:0] conf_out_left;
    logic [blk_size-1:0]    min_xors_left;
    logic                   min_sum_valid_left;

    disparity_gen_system #(
        .blk_w          (blk_w),
		.blk_h          (blk_h),
		.search_blk_w (search_blk_w),
		.search_blk_h (search_blk_h),
		.center_w     (center_w),
		.third_w      (third_w),
		.third_h      (third_h),
        .output_confidence  (output_confidence)
    ) disparity_gen_left (
        .clk_clk                                    (clk_clk),                                     //          clock.clk
		.reset_reset_n                              (reset_reset_n),          //          reset.reset
		.blk_match_ctrl_fsm_0_control_blk_index     (blk_match_ctrl_fsm_0_left_control_blk_index), //   ctrl_conduit.blk_index
		.blk_match_ctrl_fsm_0_control_start         (blk_match_ctrl_fsm_0_left_control_start),     //               .start
		.blk_match_ctrl_fsm_0_control_done          (blk_match_left_ctrl_conduit_done),            //               .done
		.blk_match_ctrl_fsm_0_control_blk_addr      (blk_match_ctrl_fsm_0_left_control_blk_addr),  //               .blk_addr
		.blk_match_ctrl_fsm_0_control_srch_addr     (blk_match_ctrl_fsm_0_left_control_srch_addr), //               .srch_addr
		.blk_match_srch_master_address              (blk_match_left_srch_master_address),          //    srch_master.address
		.bit_pix_bram_mod_0_center_rd_readdata      (bit_pix_bram_mod_0_centerleft_rd_readdata),   //               .readdata
		.blk_match_blk_master_address               (blk_match_left_blk_master_address),           //     blk_master.address
		.bit_pix_bram_mod_0_rd_readdata             (bit_pix_bram_mod_0_left_rd_readdata),          //               .readdata
        
        //.min_dist_finder_avalon_streaming_source_valid  (min_dist_finder_left_avalon_streaming_source_valid), Crop this now
        .min_dist_finder_avalon_streaming_source_data   (min_dist_finder_left_avalon_streaming_source_data),
        
        .min_dist_finder_out_conduit_blk_index          (min_dist_finder_left_out_conduit_blk_index),
        .min_dist_finder_out_conduit_sum                (min_dist_finder_left_out_conduit_sum),
        .confidence                                     (conf_out_left),
        .min_out_coords                                 (min_out_coords_left),
        .min_xors                                       (min_xors_left),
        .min_sum_valid                                  (min_sum_valid_left)
    );
    
    logic cropped_blk_valid_left;
    
    block_cropper #(
        .i_am_left      (1),
        .center_width   (center_w),
        .third_width    (third_w),
        .blk_w          (blk_w)
    ) blk_cropper_left (
        .blk_index_in   (min_dist_finder_left_out_conduit_blk_index),
        .blk_in_valid   (min_sum_valid_left),
        .blk_out_valid  (cropped_blk_valid_left)
    );
    
    assign min_dist_finder_left_avalon_streaming_source_valid = cropped_blk_valid_left;
    
    disparity_filtering_system #(
        .blk_w              (blk_w),
        .blk_h              (blk_h),
        .decimate_factor    (decimate_factor),
        .frame_w            (third_w),
        .frame_h            (third_h),
        .search_blk_w       (search_blk_w),
        .frame_wr_height    (frame_wr_height)
    ) disparity_filter_left (
        .clk                (clk_clk),
        .reset              (~reset_reset_n),
        .xors_in            (min_xors_left),
        .confidence         (conf_out_left),
        
        .image_index_counter     (image_index_counter_left),
        
        .gray_pixel_data    (gray_pixel_left_data),
        .gray_pixel_valid   (gray_pixel_left_valid),
        .gray_pixel_ready   (gray_pixel_left_ready),
        
        .min_coords         (min_out_coords_left),
        .xors_valid         (cropped_blk_valid_left),
        .disparity          (disparity_out_left),
        .disparity_valid    (disparity_valid_left),
        .disparity_ready    (disparity_ready_left)
    );
    
    logic [15:0] min_out_coords_right;
    logic [7:0] conf_out_right;
    logic [blk_size-1:0]    min_xors_right;
    logic                   min_sum_valid_right;

    disparity_gen_system #(
        .blk_w          (blk_w),
		.blk_h          (blk_h),
		.search_blk_w (search_blk_w),
		.search_blk_h (search_blk_h),
		.center_w     (center_w),
		.third_w      (third_w),
		.third_h      (third_h),
        .output_confidence  (output_confidence)
    ) disparity_gen_right (
        .clk_clk                                    (clk_clk),                                     //          clock.clk
		.reset_reset_n                              (reset_reset_n),          //          reset.reset
		.blk_match_ctrl_fsm_0_control_blk_index     (blk_match_ctrl_fsm_0_right_control_blk_index), //   ctrl_conduit.blk_index
		.blk_match_ctrl_fsm_0_control_start         (blk_match_ctrl_fsm_0_right_control_start),     //               .start
		//.blk_match_ctrl_fsm_0_control_done          (blk_match_right_ctrl_conduit_done),            //               .done
		.blk_match_ctrl_fsm_0_control_blk_addr      (blk_match_ctrl_fsm_0_right_control_blk_addr),  //               .blk_addr
		.blk_match_ctrl_fsm_0_control_srch_addr     (blk_match_ctrl_fsm_0_right_control_srch_addr), //               .srch_addr
		.blk_match_srch_master_address              (blk_match_right_srch_master_address),          //    srch_master.address
		.bit_pix_bram_mod_0_center_rd_readdata      (bit_pix_bram_mod_0_centerleft_rd_readdata),   //               .readdata
		.blk_match_blk_master_address               (blk_match_right_blk_master_address),           //     blk_master.address
		.bit_pix_bram_mod_0_rd_readdata             (bit_pix_bram_mod_0_right_rd_readdata),          //               .readdata
        
        //.min_dist_finder_avalon_streaming_source_valid  (min_dist_finder_right_avalon_streaming_source_valid), Crop this now
        .min_dist_finder_avalon_streaming_source_data   (min_dist_finder_right_avalon_streaming_source_data),
        
        .min_dist_finder_out_conduit_blk_index          (min_dist_finder_right_out_conduit_blk_index),
        .min_dist_finder_out_conduit_sum                (min_dist_finder_right_out_conduit_sum),
        .confidence                                     (conf_out_right),
        .min_out_coords                                 (min_out_coords_right),
        .min_xors                                       (min_xors_right),
        .min_sum_valid                                  (min_sum_valid_right)
    );
    
    logic cropped_blk_valid_right;
    
    block_cropper #(
        .i_am_left      (0),
        .center_width   (center_w),
        .third_width    (third_w),
        .blk_w          (blk_w)
    ) blk_cropper_right (
        .blk_index_in   (min_dist_finder_right_out_conduit_blk_index),
        .blk_in_valid   (min_sum_valid_right),
        .blk_out_valid  (cropped_blk_valid_right)
    );
    
    assign min_dist_finder_right_avalon_streaming_source_valid = cropped_blk_valid_right;
    
    disparity_filtering_system #(
        .blk_w              (blk_w),
        .blk_h              (blk_h),
        .decimate_factor    (decimate_factor),
        .frame_w            (third_w),
        .frame_h            (third_h),
        .search_blk_w       (search_blk_w),
        .frame_wr_height    (frame_wr_height)
    ) disparity_filter_right (
        .clk                (clk_clk),
        .reset              (~reset_reset_n),
        .xors_in            (min_xors_right),
        .confidence         (conf_out_right),
        
        .image_index_counter     (image_index_counter_right),
        
        .gray_pixel_data    (gray_pixel_right_data),
        .gray_pixel_valid   (gray_pixel_right_valid),
        .gray_pixel_ready   (gray_pixel_right_ready),
        
        .min_coords         (min_out_coords_right),
        .xors_valid         (cropped_blk_valid_right),
        .disparity          (disparity_out_right),
        .disparity_valid    (disparity_valid_right),
        .disparity_ready    (1'b1)//disparity_ready_right)
    );
endmodule
