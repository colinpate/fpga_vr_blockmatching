module block_match_ram_module #(
    parameter third_width = 240,
    parameter third_height = 480,
    parameter center_width = 304, // 240 + 32 + 32
    parameter rd_width = 8,
    parameter wr_width = 16,
    parameter wr_ad_w = $clog2(third_width * third_height * 2 / wr_width),
    parameter rd_ad_w = $clog2(third_width * third_height * 2 / rd_width),
    parameter center_wr_ad_w = $clog2(center_width * third_height * 2 / wr_width),
    parameter center_rd_ad_w = $clog2(center_width * third_height * 2 / rd_width)
    ) (
    input           clk,
    input           reset,
    
    //input [wr_ad_w - 1:0]    wr_address,
    input [15:0]    wr_address,
    input [1:0]     wr_third,
    input           write,
    input [wr_width - 1:0]    wr_data,
    
    //input [rd_ad_w - 1:0]    rd_address_left,
    input [15:0]    rd_address_left,
    output logic [rd_width - 1:0]  rd_data_left,
    
    //input [rd_ad_w - 1:0]    rd_address_centerleft,
    input [15:0]    rd_address_centerleft,
    output logic [rd_width - 1:0]  rd_data_centerleft,
    
    //input [rd_ad_w - 1:0]    rd_address_right,
    input [15:0]    rd_address_right,
    output logic [rd_width - 1:0]  rd_data_right,
    
    //input [rd_ad_w - 1:0]    rd_address_centerright,
    input [15:0]    rd_address_centerright,
    output logic [rd_width - 1:0]  rd_data_centerright
    );
    
    assign rd_data_centerright = rd_data_centerleft;
    
    localparam third_write_words = third_width * third_height * 2 / wr_width;
    localparam third_read_words = third_width * third_height * 2 / rd_width;
    localparam center_write_words = center_width * third_height * 2 / wr_width;
    localparam center_read_words = center_width * third_height * 2 / rd_width;
    
    bram_wrapper #(
        .wr_addr_w  (wr_ad_w),
        .rd_addr_w  (rd_ad_w),
        .wr_data_w  (wr_width),
        .rd_data_w  (rd_width),
        .wr_word_depth  (third_write_words),
        .rd_word_depth  (third_read_words)
    ) bram_left ( 
        .clk      (clk),
        .wr_addr  ((wr_third == 2'b00) ? wr_address : 0),
        .wren       (write && (wr_third == 2'b00)),
        .wr_data       (wr_data),
        .rd_addr  (rd_address_left),
        .rd_data          (rd_data_left)
        );
        
    bram_wrapper #(
        .wr_addr_w  (center_wr_ad_w),
        .rd_addr_w  (center_rd_ad_w),
        .wr_data_w  (wr_width),
        .rd_data_w  (rd_width),
        .wr_word_depth  (center_write_words),
        .rd_word_depth  (center_read_words)
    )  bram_center(
        .clk      (clk),
        .wr_addr  (wr_address),
        .wren       (write && (wr_third == 2'b01)),
        .wr_data       (wr_data),
        .rd_addr  (rd_address_centerleft),
        .rd_data          (rd_data_centerleft)
        );
        
    bram_wrapper #(
        .wr_addr_w  (wr_ad_w),
        .rd_addr_w  (rd_ad_w),
        .wr_data_w  (wr_width),
        .rd_data_w  (rd_width),
        .wr_word_depth  (third_write_words),
        .rd_word_depth  (third_read_words)
    )  bram_right(
        .clk      (clk),
        .wr_addr  ((wr_third == 2'b10) ? wr_address : 0),
        .wren       (write && (wr_third == 2'b10)),
        .wr_data       (wr_data),
        .rd_addr  (rd_address_right),
        .rd_data          (rd_data_right)
        );
endmodule