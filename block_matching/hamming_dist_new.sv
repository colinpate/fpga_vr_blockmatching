module hamming_dist_new #(
    parameter blk_size = 256,
    parameter lut_bits_in = 4,
    parameter num_luts = blk_size / lut_bits_in,
    parameter blk_sz_log = $clog2(blk_size)
    )
    (
    input                   clk,
    input                   reset,
    input [blk_size - 1:0]  left,
    input [blk_size - 1:0]  right,
    input [15:0]            in_coords,
    input [15:0]            blk_index_i,
    input                   blks_valid,
    
    output logic [blk_size - 1:0]   xors,
    output logic [7:0]              sum,
    output logic [15:0]             out_coords,
    output logic [15:0]             blk_index_o,
    output logic                    sum_valid
    );
    
    logic [num_luts - 1:0][2:0] lut_outs;
    logic [num_luts - 1:0][2:0] lut_out_sreg;
    logic                       lut_outs_valid;
    logic [15:0]                blk_index_d1;
    logic [1:0][7:0]            in_coords_d1;
    
    logic [blk_size - 1:0]  xor_sreg;
    logic [blk_size - 1:0]  xor_sreg_d1;
    logic                   xor_sreg_valid;
    logic [15:0]            blk_index_d2;
    logic [1:0][7:0]        in_coords_d2;
    
    logic [blk_sz_log - 1:0]    sum_i;
    
    pop_count pop_count_inst[num_luts - 1:0] (
        .in({1'b0, xor_sreg[blk_size - 2:0]}), // Cut one bit off so the diff can't be the full block size.
        .out(lut_outs)
        );
    
    always @(posedge clk)
    begin
        if (reset) begin
            xor_sreg_valid  <= 0;
            lut_outs_valid  <= 0;
            sum_valid       <= 0;
        end else begin
            xor_sreg        <= left ^ right;
            xor_sreg_valid  <= blks_valid;
            in_coords_d1    <= in_coords;
            blk_index_d1    <= blk_index_i;
            
            xor_sreg_d1     <= xor_sreg;
            lut_out_sreg    <= lut_outs;
            lut_outs_valid  <= xor_sreg_valid;
            in_coords_d2    <= in_coords_d1;
            blk_index_d2    <= blk_index_d1;
            
            xors            <= xor_sreg_d1;
            sum             <= sum_i;
            sum_valid       <= lut_outs_valid;
            out_coords      <= in_coords_d2;
            blk_index_o     <= blk_index_d2;
        end
    end
    
    always_comb begin
        sum_i = 0;
        for (int i = 0; i < num_luts; i++) begin
            sum_i = sum_i + lut_out_sreg[i];
        end
    end
endmodule