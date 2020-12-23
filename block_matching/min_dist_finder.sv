module min_dist_finder #(
    parameter blk_h = 16,
    parameter search_blk_w = 64,
    parameter search_blk_h = 16,
    parameter blk_size = 256,
    parameter blk_sz_log = $clog2(blk_size)
    )
    (
    input                   clk,
    input                   reset,
    
    input [blk_size - 1:0]   xors,
    input [7:0]              sum,
    input [15:0]             out_coords,
    input [15:0]             blk_index_o,
    input                    sum_valid,
    
    output logic [blk_size - 1:0]   min_xors,
    output logic [7:0]              min_sum,
    output logic [7:0]              min_sumh,
    output logic [15:0]             min_out_coords,
    output logic [15:0]             min_blk_index_o,
    output logic                    min_sum_valid
    );
    
    logic [1:0][7:0]    last_out_coords;
    assign last_out_coords[1] = search_blk_h - blk_h - 1; // vertical
    assign last_out_coords[0] = 0;//search_blk_w - blk_w - 1; // horizontal
    logic min_sum_sent;
    
    always @(posedge clk) begin
        if (reset) begin
            min_sum_valid   <= 0;
            min_sum_sent    <= 0;
            min_sum         <= 16'hFFFF;
        end else begin
            if (sum_valid) begin
                if ((min_sum_sent) || (sum < min_sum)) begin
                    min_sum_sent    <= 0;
                    min_sumh        <= min_sum;
                    min_sum         <= sum;
                    min_xors        <= xors;
                    min_out_coords  <= {8'hFF, out_coords[7:0]};
                    min_blk_index_o <= blk_index_o;
                end
                
                if (out_coords == last_out_coords) begin
                    if (min_blk_index_o[11:0] == 12'h000) begin
                        min_out_coords  <= 16'hFFFF;
                    end
                    min_sum_valid   <= 1;
                end else begin
                    min_sum_valid   <= 0;
                end
            end
            
            if (min_sum_valid) begin
                min_sum_valid   <= 0;
                min_sum_sent    <= 1;
            end
        end
    end
endmodule