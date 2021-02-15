`timescale 1 ps / 1 ps

module xors_to_stream_tb;
    //clock and reset signal declaration
    logic clk50, clk48;
    logic reset;
    logic wr_enable;
    
    parameter blk_w = 16;
    
    parameter third_width = 240;
    parameter third_height = 480;
    parameter third_end_address = third_width * third_height / blk_w; // 16 is wr port width
 
    parameter decimate_factor = 2;
    parameter result_per_read = 24;
    
    always #6250ps clk50 = ~clk50;
    always #10000ps clk48 = ~clk48;
    
    int File, c;
    logic unsigned [15:0] pixel, fmems [$:third_end_address];
    logic [third_end_address - 1:0][15:0] img_data;
    
    int File_out;
    logic unsigned [23:0] pixel_out, fmems_out [$:third_end_address];
    logic [third_end_address*blk_w - 1:0] result_data;
    initial begin
        File = $fopen("stimulus_in_xor.bin", "rb");
        if (!File)
            $display("Could not open \"result.dat\"");
        else begin
            while (!$feof(File)) begin
                c = $fscanf(File, "%c%c", pixel[7:0], pixel[15:8]);
                fmems.push_back(pixel);
            end
            $fclose(File);
        end
        for (int i = 0; i < third_end_address; i++) begin
            img_data[i] = fmems[i];
        end
        
        File_out = $fopen("compare_out_r.bin", "rb");
        if (!File_out)
            $display("Could not open \"result.dat\"");
        else begin
            while (!$feof(File_out)) begin
                c = $fscanf(File_out, "%c%c%c", pixel_out[7:0], pixel_out[15:8], pixel_out[23:16]);
                fmems_out.push_back(pixel_out);
            end
            $fclose(File_out);
        end
        for (int i = 0; i < third_end_address*blk_w/result_per_read; i++) begin
            result_data[i*result_per_read+:result_per_read] = fmems_out[i];
        end
    
        clk50 = 0;
        clk48 = 0;
        reset = 0;
        wr_enable = 0;
        
        #100ns reset = 1;
        #100ns wr_enable = 1;
        
        #60000ns;
        
        $stop;
    end
    
    parameter blk_h = 16;
 
    logic pix_stream_data;
    logic pix_stream_valid;
    logic [7:0] blk_counter;
    integer blk_index;
    int out_counter;
    logic [blk_h - 1:0][blk_w - 1:0] xors_in;
    logic xors_valid;
    assign xors_valid = (blk_counter == 255);
    
    always_comb begin
        for (int i = 0; i < blk_h; i += 1) begin
            xors_in[i] = img_data[blk_index * blk_h + i];
        end
    end
    
    always @(posedge clk50) begin
        if (~reset) begin
            blk_counter <= 0;
            blk_index   <= 0;
            out_counter <= 0;
        end else begin
            blk_counter <= blk_counter + 1;
            if (blk_counter == 255) begin
                blk_counter <= 0;
                blk_index   <= blk_index + 1;
            end
            
            if (pix_stream_valid) begin
                if (result_data[out_counter] != pix_stream_data) begin
                    $error("Bad expected %01x got %01x", result_data[out_counter], pix_stream_data);
                    //$display("Erro expected %01x got %01x", result_data[out_counter], pix_stream_data);
                end else begin
                    $display("Good expected %01x got %01x", result_data[out_counter], pix_stream_data);
                end
                out_counter <= out_counter + 1;
            end
        end
    end
    
    logic [7:0] conf_data;
    logic [7:0] disp_data;
    
    xors_to_stream #(
        .blk_w              (16),
        .decimate_factor    (decimate_factor)
    ) x2s (
        .clk    (clk50),
        .reset  (~reset),
        .xors_in    (xors_in),
        .xors_valid (xors_valid),
        .confidence (blk_index),
        .min_coords (blk_index),
        .pix_stream_data    (pix_stream_data),
        .pix_stream_valid   (pix_stream_valid),
        .fifo_almost_full_in    (1'b0)
        //.conf_out           (conf_data),
        //.disp_out           (disp_data)
    );
    
    logic [13:0] disp_conf_out;
    logic [7:0] conf_out;
    logic out_valid;
    
    pixel_processor p (
        .clk    (clk50),
        .reset  (~reset),
        .pixels_in  (pix_stream_data),
        .disp_in    (disp_data),
        .conf_in    (conf_data),
        .disp_conf_valid    (pix_stream_valid),
        .disp_conf_out      (disp_conf_out),
        .out_ready          (1'b1)
        //.conf_out           (conf_out),
        //.out_valid          (out_valid)
    );
 
endmodule