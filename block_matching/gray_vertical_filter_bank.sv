module gray_vertical_filter_bank #(
    parameter n_filters = 16,
    parameter radius = 8,
    parameter frame_lines = 480
    )
    (
    input               clk,
    input               reset,
    
    input [263:0]       pixel_in,
    input               pixel_in_valid,
    
    output logic [23:0] bit_pixels,
    output logic        bit_pixels_valid
    );
    
    logic [15:0][1:0][7:0]   pixels_in;
    logic [7:0] info_in;
    assign pixels_in = pixel_in[255:0];
    assign info_in = pixel_in[263:256];
    logic [15:0][8:0] pixels_to_filters;
    logic [15:0][8:0] pixels_to_pad;
    
    int gval_cnt;
    int bval_cnt;
    
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : split1
            assign pixels_to_pad[i] = pixels_in[i][0];
            assign pixels_to_filters[i] = pixels_in[i][1];
        end
    endgenerate
    
    logic [15:0]        filters_valid;
    logic [15:0][7:0]   filters_out;
    
    local_average_filter_v2 #(.radius(radius)) local_average_filter_inst[n_filters - 1:0](
        .clk(clk),
        .reset(reset),
        
        .pixel          (pixels_to_filters),
        .pixel_valid    (pixel_in_valid),
        
        .local_average  (filters_out),
        .local_average_valid    (filters_valid)
        );
    
    logic [15:0]        out_valid;
    logic [15:0][16:0]  out_data;
    logic [15:0]        bit_pix_i;
    
    generate
        for (i = 0; i < 16; i++) begin : split2
            assign bit_pix_i[i] = out_data[i][7:0] > out_data[i][15:8];
        end
    endgenerate
    
    //Local average is the top 8 bits
    /*generate
        for (i = 0; i < 8; i++) begin : split2
            assign bit_pix_i[i*2] = out_data[i][7:0] > out_data[i][15:8];
            assign bit_pix_i[i*2] = out_data[i][7:0] > out_data[i][15:8];
        end
    endgenerate*/
    
    local_average_pad_v2 #(.radius(radius), .frame_width(frame_lines)) local_average_pad_inst[n_filters - 1:0](
        .clk(clk),
        .reset(reset),
        
        .pixel(pixels_to_pad),
        .pixel_valid(pixel_in_valid),
        
        .local_average(filters_out),
        .local_average_valid(filters_valid),
        
        .out_data(out_data),
        .out_valid(out_valid)
    );
    
    logic [7:0] info_fifo_q;
    
    gray_info_fifo gray_info_fifo_inst(
        .clock          (clk),
        .sclr           (reset),
        .wrreq          (pixel_in_valid),
        .rdreq          (out_valid),
        .data           (info_in),
        .q              (info_fifo_q)
        );
    
    always @(posedge clk) begin
        if (reset) begin
            gval_cnt            <= 0;
            bval_cnt            <= 0;
            bit_pixels_valid    <= 0;
        end else begin
            if (pixel_in_valid) gval_cnt    <= gval_cnt + 1;
            if (bit_pixels_valid) bval_cnt  <= bval_cnt + 1;
            bit_pixels_valid    <= out_valid[0];
            bit_pixels          <= {info_fifo_q, bit_pix_i};
        end
    end
endmodule