module downsample_1d #(
        parameter dec_factor = 2,
        parameter in_width = 240,
        parameter in_height = 480
    ) (
        input           clk,
        input           reset,
        input [7:0]     in_data,
        input           in_valid,
        output logic    in_ready,
        output [7:0]    out_data,
        output          out_valid,
        input           out_ready
    );
    
    logic [$clog2(dec_factor) - 1:0]    out_x;
    
    assign out_data = in_data;
    assign out_valid = in_valid && (out_x == 0);
    assign in_ready = out_ready || (out_x != 0);
    
    always @(posedge clk) begin
        if (reset) begin
            out_x   <= 0;
        end else begin
            if (in_valid && in_ready) begin
                if (out_x == (dec_factor - 1)) begin
                    out_x   <= 0;
                end else begin
                    out_x   <= out_x + 1;
                end
            end
        end 
    end
endmodule