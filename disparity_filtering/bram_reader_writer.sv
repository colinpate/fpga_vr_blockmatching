module bram_reader_writer #(
    parameter width = 120,
    parameter height = 240,
    parameter data_width = 21
    ) (
        input clk,
        input reset,
        input [data_width - 1:0]    in_data,
        input                       in_valid,
        
        output [data_width - 1:0]   out_data,
        output                      out_valid
    );
    
    localparam frame_size = width * height;
    
    logic [$clog2(frame_size):0]    wr_address;
    logic [$clog2(frame_size):0]    wr_address_i;
    logic [1:0]                     wr_image_index;
    
    logic [$clog2(frame_size):0]    rd_address;
    logic [$clog2(frame_size):0]    rd_address_i;
    logic [1:0]                     rd_image_index;
    logic [$clog2(width) - 1:0]     rd_col;
    logic [$clog2(height) - 1:0]    rd_row;
    logic                           st_rd_running;
    logic                           rd_data_valid;
    logic                           rd_ena;
    
    assign out_valid    = rd_data_valid;
    assign wr_address_i = wr_image_index[0] ? wr_address + frame_size : wr_address;
    assign rd_address_i = rd_image_index[0] ? rd_address + frame_size : rd_address;
    
    bram_wrapper #(
        .wr_addr_w($clog2(frame_size) + 1),
        .rd_addr_w($clog2(frame_size) + 1),
        .wr_data_w(data_width),
        .rd_data_w(data_width),
        .wr_word_depth(frame_size * 2),
        .rd_word_depth(frame_size * 2)
    ) bw1 (
        .clk        (clk),
        .wr_addr    (wr_address_i),
        .rd_addr    (rd_address_i),
        .wren       (in_valid),
        .wr_data    (in_data),
        .rd_data    (out_data)
    );
    
    always @(posedge clk) begin
        if (reset) begin
            wr_address  <= 0;
            rd_address  <= 0;
            rd_col      <= 0;
            rd_row      <= 0;
            st_rd_running   <= 0;
            wr_image_index  <= 0;
            rd_image_index  <= 0;
            rd_data_valid   <= 0;
            rd_ena          <= 0;
        end else begin
            rd_data_valid   <= st_rd_running && rd_ena;
        
            if (in_valid) begin
                if (wr_address == (frame_size - 1)) begin
                    wr_address      <= 0;
                    wr_image_index  <= wr_image_index + 1;
                end else begin
                    wr_address  <= wr_address + 1;
                end
            end
            
            if (st_rd_running) begin
                if (rd_ena) begin
                    rd_ena  <= 0;
                    if (rd_address == (frame_size - 1)) begin
                        st_rd_running   <= 0;
                        rd_image_index  <= rd_image_index + 1;
                    end else begin
                        if (rd_row == (height - 1)) begin
                            rd_address  <= rd_col + 1;
                            rd_col      <= rd_col + 1;
                            rd_row      <= 0;
                        end else begin
                            rd_address  <= rd_address + width;
                            rd_row      <= rd_row + 1;
                        end
                    end
                end else begin
                    rd_ena  <= 1;
                end
            end else begin
                if (rd_image_index != wr_image_index) begin
                    st_rd_running   <= 1;
                    rd_ena          <= 1;
                    rd_address      <= 0;
                    rd_col          <= 0;
                    rd_row          <= 0;
                end
            end
        end
    end
endmodule
                    
            