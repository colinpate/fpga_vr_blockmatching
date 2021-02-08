`timescale 1 ps / 1 ps

module block_match_system_tb;
    //clock and reset signal declaration
    logic clk50, clk48;
    logic reset;
    logic wr_enable;
    
    parameter third_width = 240;
    parameter third_height = 480;
    parameter center_width = 304;
    parameter num_blocks = 900/2;
    parameter third_end_address = third_width * third_height / 16; // 16 is wr port width
    parameter center_end_address = center_width * third_height / 16; // 16 is wr port width
    parameter buf_wr_length = ((third_width * third_height) * 2 + (center_width * third_height)) / 16; // 16 is wr port width
    
    always #6250ps clk50 = ~clk50;
    always #10000ps clk48 = ~clk48;
    
    int File, c;
    logic unsigned [15:0] pixel, fmems [$:buf_wr_length];
    logic [buf_wr_length - 1:0][15:0] img_data;
    
    int File_out;
    logic unsigned [15:0] pixel_out, fmems_out [$:num_blocks];
    logic [num_blocks - 1:0][15:0] result_data;
    initial begin
        File = $fopen("stimulus_in.bin", "rb");
        if (!File)
            $display("Could not open \"result.dat\"");
        else begin
            while (!$feof(File)) begin
                c = $fscanf(File, "%c%c", pixel[7:0], pixel[15:8]);
                fmems.push_back(pixel);
            end
            $fclose(File);
        end
        for (int i = 0; i < buf_wr_length; i++) begin
            img_data[i] = fmems[i];
        end
        
        File_out = $fopen("compare_out_l.bin", "rb");
        if (!File_out)
            $display("Could not open \"result.dat\"");
        else begin
            while (!$feof(File_out)) begin
                c = $fscanf(File_out, "%c%c", pixel_out[15:8], pixel_out[7:0]);
                fmems_out.push_back(pixel_out);
            end
            $fclose(File_out);
        end
        for (int i = 0; i < num_blocks; i++) begin
            result_data[i] = fmems_out[i];
        end
    
        clk50 = 0;
        clk48 = 0;
        reset = 0;
        wr_enable = 0;
        
        #100ns reset = 1;
        #100ns wr_enable = 1;
        
        #500000ns;
        
        $stop;
    end
 
    logic [15:0]                    pix_out_addr;
    logic                           buf_out_index;
    logic [1:0]                     third_index_in;
    logic [15:0]                    wr_addr;
    logic [15:0]                    pix_out;
    int                             image_number;
    //logic [5:0]                     blk_col;
    
    logic [15:0]                    dist_left_data;
    logic                           dist_left_valid;
    int out_counter;
    int data_count;
    logic [15:0] end_address_i;
    assign end_address_i = (third_index_in == 2'b01) ? center_end_address : third_end_address;
    
    //assign pix_out_addr     = {buf_out_index, third_index_in, wr_addr};
    assign pix_out_addr     = buf_out_index ? end_address_i + wr_addr : wr_addr;
    assign pix_out = img_data[data_count];
    
    always @(posedge clk50) begin
        if (~reset) begin
            wr_addr   <= 0;
            buf_out_index   <= 0;
            third_index_in  <= 0;
            image_number    <= 0;
            out_counter     <= 0;
            data_count      <= 0;
        end else begin
            if (wr_enable) begin
                if (wr_addr == (end_address_i - 1)) begin
                    wr_addr    <= 0;
                    if (third_index_in == 2) begin
                        third_index_in  <= 0;
                        data_count     <= 0;
                        image_number    <= image_number + 1;
                        buf_out_index   <= ~buf_out_index;
                    end else begin
                        third_index_in  <= third_index_in + 1;
                        data_count     <= data_count + 1;
                    end
                end else begin
                    wr_addr    <= wr_addr + 1;
                    data_count <= data_count + 1;
                end
            end
            
            if (dist_left_valid) begin
                //if (blk_col < 15) begin
                    if (result_data[out_counter] != dist_left_data) begin
                        $error("Bad expected %04x got %04x index %d", result_data[out_counter], dist_left_data, out_counter);
                    end else begin
                        $display("Good expected %04x got %04x", result_data[out_counter], dist_left_data);
                    end
                    if (out_counter == (num_blocks - 1)) begin
                        out_counter <= 0;
                    end else begin
                        out_counter <= out_counter + 1;
                    end
                //end
            end
        end
    end
    
    block_matching_system #(
        .output_confidence  (0),
        .decimate_factor    (2)
    ) u0 (
        .clk_clk                                      (clk50),                                      //                                  clk.clk
        .reset_reset_n                                (reset),                                //                                reset.reset_n
        .bit_pix_bram_mod_0_wr_address                (pix_out_addr),                //                bit_pix_bram_mod_0_wr.address
        .bit_pix_bram_mod_0_wr_third                  (third_index_in),                //                bit_pix_bram_mod_0_wr.address
        .bit_pix_bram_mod_0_wr_writedata              (pix_out),              //                                     .writedata
        .bit_pix_bram_mod_0_wr_write                  (wr_enable),                  //                                     .write
        
        .gray_pixel_left_valid  (1'b1),
        .gray_pixel_right_valid (1'b1),
        
        .disparity_ready_left   (1'b0),
        .disparity_ready_right  (1'b0),
        
        .blk_match_ctrl_fsm_0_bm_status_conduit_image_number   (image_number),
        .min_dist_finder_left_avalon_streaming_source_valid  (dist_left_valid),  // min_dist_finder_left_avalon_streaming_source.valid
        .min_dist_finder_left_avalon_streaming_source_data   (dist_left_data)   //                                              .data
        //.min_dist_finder_right_avalon_streaming_source_valid (dist_left_valid), // min_dist_finder_right_avalon_streaming_source.valid
        //.min_dist_finder_right_avalon_streaming_source_data  (dist_left_data)   //      //  
    );
    
    output_compare #(
        .data_width (8),
        .data_len   (15*30),
        .file_path  ("confidence_l.bin")
    ) ocfloop  (
        .clk    (clk50),
        .reset  (~reset),
        .data_in_valid  (u0.cropped_blk_valid_left),
        .data_in        (u0.disparity_gen_left.min_dist_finder.confidence)
    );
    
    output_compare #(
        .data_width (256),
        .data_len   (15*30),
        .file_path  ("xors_left.bin")
    ) output_compare_left_xors  (
        .clk    (clk50),
        .reset  (~reset),
        .data_in_valid  (u0.cropped_blk_valid_left),
        .data_in        (u0.disparity_gen_left.min_dist_finder.min_xors)
    );

endmodule