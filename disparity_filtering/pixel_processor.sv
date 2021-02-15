module pixel_processor #(
    parameter disp_bits = 5,
    parameter dec_factor = 2,
    parameter dec_frame_width = 240
    ) (
    input clk,
    input reset,
        
    input                       pixels_in,
    input [disp_bits - 1:0]     disp_in,
    input [7:0]                 conf_in,
    input                       disp_conf_valid,
    output logic                fifo_almost_full,
    
    output [7 + disp_bits:0]    disp_conf_out,
    output logic                out_valid,
    input                       out_ready
    );
    
    localparam frac_bits = 8;
    localparam frac_factor = (1 << frac_bits) / (dec_factor * dec_factor);
    localparam fifo_depth = dec_frame_width * 8;
    
    logic [$clog2(fifo_depth) - 1:0] fifo_usedw;
    
    assign fifo_almost_full = fifo_usedw > (fifo_depth - 16);
    
    logic [7:0] conf_result;
    logic [$clog2(dec_factor * dec_factor) - 1:0]    input_counter;
    logic [$clog2(dec_factor * dec_factor):0]   pop_count_reg;
    logic [$clog2(dec_factor * dec_factor):0]   pop_count_next;
    logic                   conf_result_valid;
    logic                   conf_result_valid_d1;
    logic [7:0]             conf_result_reg;
    logic [7 + frac_bits:0] conf_reg; // 8p8 fixed point
    logic [disp_bits - 1:0] disp_reg;
    logic [disp_bits - 1:0] disp_reg_d1;
    logic                   fifo_wr;
    logic                   fifo_empty;
    
    // Stage 1 of the pipeline
    assign conf_result = (pop_count_next * conf_reg) >> frac_bits; // 8p8 * 3p0 >> 8 = 11p0 but pop_count_sum * frac_factor can't be more than 256 so it's okay
    assign conf_result_valid = disp_conf_valid && (input_counter == ((dec_factor * dec_factor) - 1));
    assign pop_count_next = pop_count_reg + (pixels_in ? 0 : 1); // Invert the pixel because we want confidence to be higher if XOR = 0
    
    always @(posedge clk) begin
        if (reset) begin
            pop_count_reg   <= 0;
            input_counter   <= 0;
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
            conf_reg                <= (conf_in << 1) * frac_factor; //8p0 * 0p8 = 8p8
            if (disp_conf_valid) begin
                if (input_counter == ((dec_factor * dec_factor) - 1)) begin
                    input_counter   <= 0;
                    pop_count_reg   <= 0;
                end else begin
                    input_counter   <= input_counter + 1;
                    pop_count_reg   <= pop_count_next;
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
        .depth  (fifo_depth) // pretty much arbitrary
    ) output_fifo (
        .clock  (clk),
        .data   ({disp_reg_d1, conf_result_reg}),
        .wrreq  (fifo_wr),
        .empty  (fifo_empty),
        .q      (disp_conf_out),
        .usedw  (fifo_usedw),
        .sclr   (reset),
        .rdreq  (out_ready && (!fifo_empty))
    );
endmodule