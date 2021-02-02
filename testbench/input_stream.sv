`timescale 1 ps / 1 ps

module input_stream #(
    parameter data_width = 8,
    parameter data_len = 1,
    parameter file_path = "stimulus_in.bin"
    ) (
    input       clk,
    input       reset,
    
    output                       data_out_valid,
    input                        data_out_ready,
    output [data_width - 1:0]    data_out
    );
    
    localparam bytes_per_data = data_width / 8;
    
    int File, c;
    logic unsigned [7:0] pixel, fmems [$:data_len*bytes_per_data];
    logic [data_len - 1:0][data_width - 1:0] compare_data_array;
    
    initial begin
        File = $fopen(file_path, "rb");
        if (!File)
            $display("Could not open \"result.dat\"");
        else begin
            while (!$feof(File)) begin
                c = $fscanf(File, "%c", pixel[7:0]);
                fmems.push_back(pixel);
            end
            $fclose(File);
        end
        for (int i = 0; i < data_len; i++) begin
            for (int i2 = 0; i2 < bytes_per_data; i2++) begin
                compare_data_array[i][i2*8+:8] = fmems[i*bytes_per_data+i2];
            end
        end
    end
 
    int out_counter;
    
    assign data_out_valid = ~reset;
    assign data_out = compare_data_array[out_counter];
 
    always @(posedge clk) begin
        if (reset) begin
            out_counter      <= 0;
        end else begin
            if (data_out_ready) begin
                if (out_counter == (data_len - 1)) begin
                    out_counter <= 0;
                end else begin
                    out_counter <= out_counter + 1;
                end
            end
        end
    end
endmodule