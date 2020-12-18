module local_average_filter_v2 #(
    parameter radius = 8
    )
    (
	input                   reset,
	input                   clk,
    input [8:0]             pixel,
    input                   pixel_valid,
    output logic [8:0]      out_pixel,
    output logic            out_pixel_valid,
    output logic [7:0]      local_average,
    output logic            local_average_valid
    );
    
    localparam filter_width = radius * 2;
    
    parameter shift = $clog2(filter_width);
    
    logic [8:0]      pixel_reg;
    logic            pixel_valid_reg;
    logic [7:0]      average_pixel;
    logic [7:0]      pixel_i;
    logic            sof_i;
    
    assign pixel_i          = pixel[7:0];
    assign sof_i            = pixel[8];
    assign out_pixel        = pixel_reg;
    assign out_pixel_valid  = pixel_valid_reg;
    assign local_average    = average_pixel;   
    
    logic [15:0]        sum;
    logic [7:0]         average;
    logic [filter_width-1:0][7:0] pixel_sreg;
    
    assign average = sum >> shift;
    
    always @(posedge clk)
    begin
        if (reset) begin
            pixel_reg           <= 0;
            pixel_sreg          <= 0;
            average_pixel       <= 0;
            local_average_valid <= 0;
            pixel_valid_reg     <= 0;
            sum                 <= 0;
        end else begin
            if (pixel_valid) begin
                pixel_reg           <= pixel;
                pixel_sreg[filter_width - 1 : 1] <= pixel_sreg[filter_width - 2:0];
                pixel_sreg[0]                    <= pixel_i;
                average_pixel       <= average;
                local_average_valid <= 1;
                pixel_valid_reg     <= 1;
                sum                 <= (sum + pixel_i) - pixel_sreg[filter_width - 1];
            end else begin
                local_average_valid <= 0;
                pixel_valid_reg     <= 0;
            end
        end
    end
endmodule