module downsample_2d #(
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
    
    logic [$clog2(in_width) - 1:0]  col;
    logic [$clog2(dec_factor) - 1:0]    out_x;
    logic [$clog2(dec_factor) - 1:0]    out_y;
    
    assign out_data = in_data;
    assign out_valid = in_valid && (out_x == 0) && (out_y == 0);
    assign in_ready = out_ready || ((out_x != 0) || (out_y != 0));
    
    always @(posedge clk) begin
        if (reset) begin
            col <= 0;
            out_x   <= 0;
            out_y   <= 0;
        end else begin
            if (in_valid && in_ready) begin
                if (col == (in_width - 1)) begin
                    col <= 0;
                    if (out_y == (dec_factor - 1)) begin
                        out_y <= 0;
                    end else begin
                        out_y <= out_y + 1;
                    end
                end else begin
                    col <= col + 1;
                end
                if (out_x == (dec_factor - 1)) begin
                    out_x   <= 0;
                end else begin
                    out_x   <= out_x + 1;
                end
            end
        end 
    end
endmodule