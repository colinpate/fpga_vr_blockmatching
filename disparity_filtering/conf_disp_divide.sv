//`default_nettype none
module conf_disp_divide #(
    parameter disp_bits = 5
    ) (
        input clk,
        input reset,
        input [7:0]                 in_conf,
        input [7 + disp_bits:0]     in_conf_disp,
        input                       in_valid,
        output [disp_bits - 1:0]    out_disp,
        output                      out_valid
    );
    
    // wire
    logic [7 + disp_bits:0] result;
    
    //pipeline stage 1
    logic valid_in_reg;
    logic [7 + disp_bits:0] conf_disp_in_reg;
    logic [7:0]             conf_in_reg;
    
    // pipeline stage 2
    logic in_valid_d1;
    
    // stage 3
    logic in_valid_d2;
    
    // stage 3
    logic in_valid_d3;
    
    // stage 3
    logic in_valid_d4;
    
    // stage 4
    logic valid_reg;
    logic [7 + disp_bits:0] result_reg;
    
    
    assign out_disp     = (result_reg >= (1 << disp_bits)) ? (1 << disp_bits) - 1 : result_reg;
    assign out_valid    = valid_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            valid_in_reg        <= 0;
            conf_disp_in_reg    <= 0;
            conf_in_reg         <= 0;
        
            in_valid_d1         <= 0;
            in_valid_d2         <= 0;
            in_valid_d3         <= 0;
            in_valid_d4         <= 0;
            
            result_reg          <= 0;
            valid_reg           <= 0;
        end else begin
            valid_in_reg        <= in_valid;
            conf_disp_in_reg    <= in_conf_disp;
            conf_in_reg         <= in_conf + 1;
            
            in_valid_d1 <= valid_in_reg;
            in_valid_d2 <= in_valid_d1;
            in_valid_d3 <= in_valid_d2;
            in_valid_d4 <= in_valid_d3;
            
            valid_reg   <= in_valid_d4;
            result_reg  <= result;
        end
    end
    
    pipelined_divide_5bitdisp divider (
        .clock  (clk),
        .denom  (conf_in_reg),
        .numer  (conf_disp_in_reg),
        .quotient   (result)
    );
        
    
    /*lpm_divide	LPM_DIVIDE_component (
				.denom (conf_in_reg),
				.numer (conf_disp_in_reg),
				.quotient (result),
				//.remain (sub_wire1),
				.aclr (1'b0),
				.clken (1'b1),
				.clock (1'b0));
	defparam
		LPM_DIVIDE_component.lpm_drepresentation = "UNSIGNED",
		LPM_DIVIDE_component.lpm_hint = "MAXIMIZE_SPEED=6,LPM_REMAINDERPOSITIVE=TRUE",
		LPM_DIVIDE_component.lpm_nrepresentation = "UNSIGNED",
		LPM_DIVIDE_component.lpm_type = "LPM_DIVIDE",
		LPM_DIVIDE_component.lpm_widthd = 8,
		LPM_DIVIDE_component.lpm_widthn = 8 + disp_bits;*/
        
endmodule