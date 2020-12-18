module local_average_filter #(
    parameter radius = 8,
    parameter frame_width = 128
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
    
    localparam filter_width = radius * 2
    
    parameter shift = $clog2(filter_width);
    
    logic [7:0]      average_pixel;
    logic [7:0]      pixel_i;
    logic            sof_i;
    
    assign pixel_i          = pixel[7:0];
    assign sof_i            = pixel[8];
    assign out_pixel        = pixel_sreg[filter_width - 1];
    assign out_pixel_valid  = pixel_valid;
    assign local_average    = average_pixel;   
    
    logic [15:0]        pixel_in_count;
    logic [15:0]        pixel_out_count;
    logic [15:0]        sum;
    logic [7:0]         average;
    logic [filter_width-1:0][7:0] pixel_sreg;
    
    assign average = sum >> shift;
    //logic [8:0] center_pixel_i;
    
    //assign center_pixel_i = (pixel_sreg[radius] + pixel_sreg[radius - 1]) >> 1;
    
    always @(posedge clk)
    begin
        if (reset) begin
            pixel_in_count      <= 0;
            sum                 <= 0;
            local_average_valid <= 0;
        end else begin
            if (pixel_valid) begin
                pixel_sreg          <= {pixel_sreg[filter_width - 2:0], pixel_i};
                
                if (pixel_in_count < filter_width) begin
                    sum                     <= sum + pixel_i;
                    local_average_valid     <= 0;
                    pixel_in_count          <= pixel_in_count + 1;
                end else begin
                    average_pixel       <= average;
                    //center_pixel        <= center_pixel_i;
                    local_average_valid <= 1;
                    if ((pixel_in_count == (frame_width - 1)) || sof_i)  begin
                        sum                 <= 0;
                        pixel_in_count      <= 0;
                    end else begin
                        sum                 <= (sum + pixel_i) - pixel_sreg[filter_width - 1];
                        pixel_in_count      <= pixel_in_count + 1;
                    end
                end
            end else begin
                local_average_valid <= 0;
            end
        end
    end
endmodule