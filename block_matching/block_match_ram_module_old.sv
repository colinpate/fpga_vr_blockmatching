module block_match_ram_module (
    input           clk,
    input           reset,
    
    input [18:0]    wr_address,
    input           write,
    input [1:0]     wr_data,
    
    input [15:0]    rd_address_left,
    output logic [7:0]  rd_data_left,
    
    input [15:0]    rd_address_centerleft,
    output logic [7:0]  rd_data_centerleft,
    
    input [15:0]    rd_address_right,
    output logic [7:0]  rd_data_right,
    
    input [15:0]    rd_address_centerright,
    output logic [7:0]  rd_data_centerright
    );
    
    assign rd_data_centerright = rd_data_centerleft;
    
    bit_pix_bram bram_left(
        .clock      (clk),
        .wraddress  ({wr_address[18], wr_address[15:0]}),
        .wren       (write && (wr_address[17:16] == 2'b00)),
        .data       (wr_data),
        .rdaddress  ({rd_address_left[15], rd_address_left[13:0]}),
        .q          (rd_data_left)
        );
        
    bit_pix_bram bram_center(
        .clock      (clk),
        .wraddress  ({wr_address[18], wr_address[15:0]}),
        .wren       (write && (wr_address[17:16] == 2'b01)),
        .data       (wr_data),
        .rdaddress  ({rd_address_centerleft[15], rd_address_centerleft[13:0]}),
        .q          (rd_data_centerleft)
        );
        
    bit_pix_bram bram_right(
        .clock      (clk),
        .wraddress  ({wr_address[18], wr_address[15:0]}),
        .wren       (write && (wr_address[17:16] == 2'b10)),
        .data       (wr_data),
        .rdaddress  ({rd_address_right[15], rd_address_right[13:0]}),
        .q          (rd_data_right)
        );
endmodule