//`default_nettype none
module local_average_pad_v2 #(
    parameter radius = 8,
    parameter frame_width = 768,
    parameter frame_lines = 480
    )
    (
	input               reset,
	input               clk,
    input [8:0]         pixel,
    input               pixel_valid,
    input [7:0]         local_average,
    input               local_average_valid,
    output logic [16:0] out_data,
    output logic        out_valid
    );
    
    logic [3:0]                 valid_counter;
    logic [8:0]                 fifo_q;
    
    //logic [radius - 1:0][7:0]   local_average_sreg;
    
    assign out_data = {fifo_q[8], local_average, fifo_q[7:0]};
    assign out_valid = pixel_valid && (valid_counter == (radius - 1));
    
    local_average_pad_fifo lapf1(
        .clock  (clk),
        .data   (pixel),
        .rdreq  (pixel_valid && (valid_counter == (radius - 1))),
        .sclr   (reset),
        .wrreq  (pixel_valid),
        .q      (fifo_q)
    );
    
    always @(posedge clk)
    begin
        if (reset) begin
            //local_average_sreg      <= 0;
            valid_counter           <= 0;
        end else begin
            if (pixel_valid) begin
                if (valid_counter < (radius - 1)) begin
                    valid_counter   <= valid_counter + 1;
                end
            end
        end
    end
                
    /*logic [radius - 1:0][8:0]   pixel_sreg;
    
    //assign out_valid = (valid_counter == (radius - 1)) && pixel_valid;
    assign out_valid = pixel_valid;
    
    //assign out_data = {pixel_sreg[0][8], local_average, pixel_sreg[0][7:0]};
    assign out_data = {pixel[8], local_average, pixel_sreg[0][7:0]};
    //assign out_data = {pixel[8], pixel_sreg[0], pixel[7:0]};
    
    always @(posedge clk)
    begin
        if (reset) begin
            pixel_sreg      <= 0;
            valid_counter   <= 0;
        end else begin
            if (pixel_valid) begin
                if (valid_counter < (radius - 1)) begin
                    valid_counter   <= valid_counter + 1;
                end
                pixel_sreg  <= {pixel, pixel_sreg[radius - 1:1]};
                //pixel_sreg  <= {local_average, pixel_sreg[radius - 1:1]};
            end
        end
    end*/
    
    
    
endmodule