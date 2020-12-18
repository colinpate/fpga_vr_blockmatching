module bit_pixel_rotator #(
    parameter frame_width = 128,
    parameter frame_height = 128,
    )
    (
    input               clk,
    input               reset,
    
    input [15:0]        bit_pix,
    input               bit_pix_valid,
    
    output logic [15:0] pix_out,
    output logic        pix_out_val;
    );
    
    //16-pixel lines get clocked in row-by-row
    //starting from upper left which is actually the upper right
    //first in bit 0 is pixel (x,y) = (cols - 1, 0)
    //first in bit 15 is pixel (x,y) = (cols - 1, 15)
    
    //2nd in bit 0 is pixel (x, y) = (cols - 2, 0)
    //2nd in bit 15 is pixel (x, y) = (cols - 2, 15)
    
    //cols in bit 0 is pixel (x, y) = (cols - 1, 16)
    //cols in bit 15 is pixel (x, y) = (cols - 1, 31)
    
    //x = cols - (incounter % cols)
    //y = floor(incounter / cols) * 16 + bitpos
    
    logic [15:0][15:0]  in_sreg;
    logic [15:0][15:0]  out_sreg;
    logic [15:0][15:0]  in_sreg_shifted;
    logic [15:0][15:0]  out_sreg_shifted;
    logic [3:0]         in_val_cntr;
    logic [3:0]         out_val_cntr;
    logic               switch_now;
    
    assign pix_out_val  = (out_val_cntr != 4'hF) || (switch_now);
    
    assign in_sreg_shifted[15] = bit_pix;
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : shift1
            if (i < 15) begin
                assign in_sreg_shifted[i] = in_sreg[i + 1];
            end
            assign out_sreg_shifted[i]  = {1'b0, out_sreg[i][15:1]};
            assign pix_out[i]           = out_sreg[i][0];
        end
    endgenerate
    
    always @(posedge clk) begin
        if (reset) begin
            in_val_cntr     <= 0;
            out_val_cntr    <= 4'hF;
            switch_now      <= 0;
        end else begin
            if (bit_pix_valid) begin
                in_sreg     <= in_sreg_shifted;
                in_val_cntr <= in_val_cntr + 1;
                if (in_val_cntr == 4'hF) begin
                    out_sreg        <= in_sreg;
                    switch_now      <= 1;
                end else begin
                    switch_now      <= 0;
                end
            end else begin
                switch_now  <= 0;
            end
            
            if (out_val_cntr == 4'hF) begin
                if (switch_now) begin
                    out_val_cntr    <= 1;
                end
            end else begin
                out_val_cntr    <= out_val_cntr + 1;
                out_sreg        <= out_sreg_shifted; 
            end
        end         
    end
endmodule
    