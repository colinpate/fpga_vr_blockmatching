// pclk_clkctrl.v

// Generated using ACDS version 18.1 625

`timescale 1 ps / 1 ps
module pclk_clkctrl (
		input  wire  inclk,  //  altclkctrl_input.inclk
		output wire  outclk  // altclkctrl_output.outclk
	);

	pclk_clkctrl_altclkctrl_0 altclkctrl_0 (
		.inclk  (inclk),  //  altclkctrl_input.inclk
		.outclk (outclk)  // altclkctrl_output.outclk
	);

endmodule
