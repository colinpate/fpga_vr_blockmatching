module pixel_processor #(
    parameter disp_bits = 5,
    parameter dec_factor = 2
    ) (
    input clk,
    input reset,
    
    input [dec_factor - 1:0]    pixels_in,
    input [disp_bits - 1:0]     disp_in,
    input [7:0]                 conf_in,
    input                       disp_conf_valid,
    
    output [7 + disp_bits:0]    disp_conf_out,
    output [7:0]                conf_out,
    output logic                out_valid
    );
    
    logic [dec_factor - 1:0][dec_factor - 1:0] pixels_in_sreg;
    logic [2:0] pop_count_result;
    
    pop_count pc1(
        .in     (pixels_in_sreg),
        .out    (pop_count_result)
    );
    
    logic [7:0] conf_result;
    logic [$clog2(dec_factor) - 1:0]    shift_counter;
    logic                   conf_result_valid;
    logic [7:0]             conf_result_reg;
    logic [7:0]             conf_reg;
    logic [disp_bits - 1:0] disp_reg;
    
    // Stage 1 of the pipeline
    assign conf_result = pop_count_result * ((conf_reg >> $clog2(dec_factor * dec_factor)) - 1);
    assign conf_result_valid = disp_conf_valid && (shift_counter == (dec_factor - 1));
    
    // Stage 2 of the pipeline
    assign disp_conf_out = disp_reg * conf_result_reg;
    assign conf_out = conf_result_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            shift_counter   <= 0;
            conf_result_reg <= 0;
            out_valid       <= 0;
            disp_reg        <= 0;
            conf_reg        <= 0;
        end else begin
            // Pipeline stage 1
            disp_reg        <= disp_in;
            conf_reg        <= conf_in;
            if (disp_conf_valid) begin
                pixels_in_sreg  <= {pixels_in_sreg[dec_factor - 2:0], (~pixels_in)};
                if (shift_counter == (dec_factor - 1)) begin
                    shift_counter   <= 0;
                end else begin
                    shift_counter   <= shift_counter + 1;
                end
            end
            
            // Pipeline stage 2
            conf_result_reg <= conf_result;
            out_valid       <= conf_result_valid;
        end
    end
endmodule