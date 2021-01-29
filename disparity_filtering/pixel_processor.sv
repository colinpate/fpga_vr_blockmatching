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
    output logic                out_valid,
    input                       out_ready
    );
    
    localparam num_pop_counts = (dec_factor * dec_factor) / 4;
    localparam frac_bits = 8;
    localparam frac_factor = (1 << frac_bits) / (dec_factor * dec_factor);
    
    logic [dec_factor - 1:0][dec_factor - 1:0] pixels_in_sreg;
    logic [num_pop_counts - 1:0][2:0] pop_count_result;
    logic [num_pop_counts * 4 - 1:0] pop_count_input;
    logic [$clog2(dec_factor * dec_factor) - 1:0]   pop_count_sum;
    
    assign pop_count_input = pixels_in_sreg;
    
    pop_count pc1[num_pop_counts - 1:0](
        .in     (pop_count_input),
        .out    (pop_count_result)
    );
    
    always_comb begin
        pop_count_sum = 0;
        for (int i = 0; i < num_pop_counts; i++) begin
            pop_count_sum = pop_count_sum + pop_count_result[i];
        end
    end
    
    logic [7:0] conf_result;
    logic [$clog2(dec_factor) - 1:0]    shift_counter;
    logic                   conf_result_valid;
    logic                   conf_result_valid_d1;
    logic [7:0]             conf_result_reg;
    logic [7 + frac_bits:0] conf_reg; // 8p8 fixed point
    logic [disp_bits - 1:0] disp_reg;
    logic [disp_bits - 1:0] disp_reg_d1;
    logic                   fifo_wr;
    logic                   fifo_empty;
    
    // Stage 1 of the pipeline
    assign conf_result = (pop_count_sum * conf_reg) >> frac_bits;
    assign conf_result_valid = disp_conf_valid && (shift_counter == (dec_factor - 1));
    
    // Stage 2 of the pipeline
    assign disp_conf_out = ;
    
    always @(posedge clk) begin
        if (reset) begin
            shift_counter   <= 0;
            conf_result_reg <= 0;
            fifo_wr         <= 0;
            disp_reg        <= 0;
            disp_reg_d1     <= 0;
            conf_result_valid_d1    <= 0;
            conf_reg        <= 0;
        end else begin
            // Pipeline stage 1
            conf_result_valid_d1    <= conf_result_valid;
            disp_reg                <= disp_in;
            conf_reg                <= conf_in * frac_factor; //8p0 * 0p8
            if (disp_conf_valid) begin
                pixels_in_sreg  <= {pixels_in_sreg[dec_factor - 2:0], (~pixels_in)};
                if (shift_counter == (dec_factor - 1)) begin
                    shift_counter   <= 0;
                end else begin
                    shift_counter   <= shift_counter + 1;
                end
            end
            
            // Pipeline stage 2
            disp_reg_d1     <= disp_reg;
            conf_result_reg <= conf_result;
            fifo_wr         <= conf_result_valid_d1;
        end
    end
    
    assign out_valid = !fifo_empty;
    
    scfifo_wrapper #(
        .width  (disp_bits + 8),
        .depth  (128) // pretty much arbitrary
    ) output_fifo (
        .clock  (clk),
        .data   ({disp_reg_d1, conf_result_reg}),
        .wrreq  (fifo_wr),
        .empty  (fifo_empty),
        .q      (disp_conf_out),
        .sclr   (reset),
        .rdreq  (out_ready && (!fifo_empty))
    );
endmodule