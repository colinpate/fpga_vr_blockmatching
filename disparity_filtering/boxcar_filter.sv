module boxcar_filter #(
    parameter radius = 8,
    parameter bits = 8,
    parameter dec_ratio = 1
    )
    (
	input                   reset,
	input                   clk,
    input [bits - 1:0]      pixel,
    input                   pixel_valid,
    output logic [bits - 1:0]   local_average,
    output logic                local_average_valid
    );
    
    localparam filter_width = radius * 2;
    
    parameter shift = $clog2(filter_width);
    
    logic [bits - 1:0]      average_pixel;
    
    
    logic [bits + $clog2(radius):0]        sum;
    logic [bits - 1:0]         average;
    logic [filter_width-1:0][bits - 1:0] pixel_sreg;
    
    assign average = sum >> shift;
    assign local_average    = average;
    
    logic [$clog2(dec_ratio) - 1:0] dec_counter;
    
    always @(posedge clk)
    begin
        if (reset) begin
            pixel_sreg          <= 0;
            local_average_valid           <= 0;
            sum                 <= 0;
            dec_counter         <= 0;
        end else begin
            if (pixel_valid) begin
                pixel_sreg[filter_width - 1 : 1]    <= pixel_sreg[filter_width - 2:0];
                pixel_sreg[0]                       <= pixel;
                sum                                 <= (sum + pixel) - pixel_sreg[filter_width - 1];
                if (dec_ratio > 1) begin
                    if (dec_counter == (dec_ratio - 1)) begin
                        dec_counter         <= 0;
                        local_average_valid <= 1;
                    end else begin
                        dec_counter         <= dec_counter + 1;
                        local_average_valid <= 0;
                    end
                end else begin
                    local_average_valid <= 1;
                end
            end else begin
                local_average_valid <= 0;
            end
        end
    end
endmodule