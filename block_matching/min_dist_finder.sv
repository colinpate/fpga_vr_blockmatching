module min_dist_finder #(
    parameter blk_h = 16,
    parameter blk_w = 16,
    parameter search_blk_w = 64,
    parameter search_blk_h = 16,
    parameter blk_size = blk_h * blk_w,
    parameter blk_sz_log = $clog2(blk_size),
    parameter output_confidence = 0,
    parameter third_h = 480
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
    output logic [7:0]              confidence,
    output logic [15:0]             stream_out,
    output logic                    stream_out_valid,
    output logic [15:0]             min_out_coords,
    output logic [15:0]             min_blk_index_o,
    output logic                    min_sum_valid
    );
    
    localparam num_sums = (search_blk_h - blk_h) * (search_blk_w - blk_w);
    localparam num_sum_bits = $clog2(num_sums);
    localparam num_sums_inv = (1 << (num_sum_bits + 8)) / num_sums; // 0pN fixed-point
    localparam blk_bits = $clog2(blk_size);
    /* num_sums is 192
    num_sum_bits will be 8
    inv will be 1 << 16 / 192 = 341
    sum_sum is 128*192 = 24576
    product is 8380416
    shift right num_sum_bits + 8
    */
    
    logic [15 + num_sum_bits:0] avg_sum_i;
    logic [7:0]                 average_sum;
    logic [num_sum_bits + blk_bits - 1:0]  sum_sum;
    logic [1:0][7:0]            last_out_coords;
    logic                       min_sum_sent;
    logic [15:0]                min_out_coords_i;
    logic cropped_hamming_dist_valid;
    
    block_cropper_vertical #( // make sure we're not in the weird region at the top or bottom of the frame
        .blk_h      (blk_h),
        .third_h    (third_h),
        .srch_blk_h (search_blk_h)
    ) bcv (
        .blk_index_in   (blk_index_o),
        .coords_in      (out_coords),
        .blk_in_valid   (sum_valid),
        .blk_out_valid  (cropped_hamming_dist_valid)
    );
    
    assign last_out_coords[1] = search_blk_h - blk_h - 1; // vertical
    assign last_out_coords[0] = 0;//search_blk_w - blk_w - 1; // horizontal
    assign avg_sum_i = num_sums_inv * sum_sum; // 0pN * Yp0 = YpN
    assign average_sum = avg_sum_i >> (num_sum_bits + 8); // Yp0
    assign confidence = average_sum - min_sum;
    assign min_out_coords = min_out_coords_i;
    assign stream_out_valid = min_sum_valid;
    generate
        if (output_confidence) begin
            assign stream_out = {confidence[7:0], min_out_coords_i[4:0], 3'b000}; // Just send the X coord for now
        end else begin
            assign stream_out = min_out_coords_i; // Just send the X coord for now
        end
    endgenerate
    
    always @(posedge clk) begin
        if (reset) begin
            min_sum_valid   <= 0;
            min_sum_sent    <= 0;
            min_sum         <= 16'hFFFF;
            sum_sum         <= 0;
            min_out_coords_i<= 0;
        end else begin
            if (sum_valid) begin
                if ((min_sum_sent) || ((sum < min_sum) && cropped_hamming_dist_valid)) begin
                    min_sum_sent    <= 0;
                    min_sumh        <= min_sum;
                    min_sum         <= cropped_hamming_dist_valid ? sum : (blk_size - 1); // Do max possible sum if outside valid area.
                    min_xors        <= xors;
                    min_out_coords_i<= out_coords;
                    min_blk_index_o <= blk_index_o;
                end
                if (min_sum_sent) begin
                    sum_sum <= sum;
                end else begin
                    sum_sum <= sum_sum + sum;
                end
                
                if (out_coords == last_out_coords) begin
                    if (min_blk_index_o[11:0] == 12'h000) begin
                        min_out_coords_i <= 16'hFFFF;
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