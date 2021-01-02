module bram_wrapper #(
        parameter wr_addr_w = -1,
        parameter rd_addr_w = -1,
        parameter wr_data_w = -1,
        parameter rd_data_w = -1,
        parameter wr_word_depth = 1 << wr_addr_w,
        parameter rd_word_depth = 1 << rd_addr_w
    ) (
        input                       clk,
        input [wr_addr_w - 1:0]     wr_addr,
        input [rd_addr_w - 1:0]     rd_addr,
        input                       wren,
        input [wr_data_w - 1:0]     wr_data,
        output [rd_data_w - 1:0]    rd_data
    );
    
    // Try definining RAM inline
    altsyncram	altsyncram_component (
				.address_a (wr_addr),
				.address_b (rd_addr),
				.clock0 (clk),
				.data_a (wr_data),
				.wren_a (wren),
				.q_b (rd_data),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({8{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
    defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = wr_word_depth,
		altsyncram_component.numwords_b = rd_word_depth,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = wr_addr_w,
		altsyncram_component.widthad_b = rd_addr_w,
		altsyncram_component.width_a = wr_data_w,
		altsyncram_component.width_b = rd_data_w,
		altsyncram_component.width_byteena_a = 1;
endmodule