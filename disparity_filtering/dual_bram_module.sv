module dual_bram_module #(
    parameter frame_w = 80,
    parameter frame_h = 160,
    parameter disp_bits = 5,
    parameter bram_addr_w = -1
    ) (
        input clk,
    
        input logic                       bram_writer_index,
        
        input logic [7 + disp_bits:0]     cd_writer_wr_data,
        input logic [bram_addr_w - 1:0]   cd_writer_wr_address,
        input logic                       cd_writer_wr_ena,
        
        input logic [7:0]                 gray_writer_wr_data,
        input logic [bram_addr_w - 1:0]   gray_writer_wr_address,
        input logic                       gray_writer_wr_ena,

        // filter bram writer data
        input logic                       filt_wr_index,
        input logic [15 + disp_bits:0]    filt_wr_data,
        input logic [bram_addr_w - 1:0]   filt_wr_address,
        input logic                       filt_wr_ena,
        
        input logic                       filt_rd_index,
        output logic [15 + disp_bits:0]   filt_rd_data,
        input logic [bram_addr_w - 1:0]   filt_rd_address,
        
        // out bram reader data
        input logic                       out_rd_index,
        output logic [15 + disp_bits:0]   out_rd_data,
        input logic [bram_addr_w - 1:0]   out_rd_address
    );
    
    localparam frame_size = frame_w * frame_h;
    
    // Signals to the BRAM modules
    logic [1:0][bram_addr_w - 1:0]  cd_wr_addresses;
    logic [1:0][7 + disp_bits:0]    cd_wr_datas;
    logic [1:0]                     cd_wr_enas;
    
    logic [1:0][bram_addr_w - 1:0]  gray_wr_addresses;
    logic [1:0][7:0]                gray_wr_datas;
    logic [1:0]                     gray_wr_enas;
    
    logic [1:0][bram_addr_w - 1:0]  bram_rd_addresses;
    logic [1:0][15 + disp_bits:0]   bram_rd_datas;
    
    logic [1:0][bram_addr_w - 1:0]  cd_rd_addresses;
    logic [1:0][7 + disp_bits:0]    cd_rd_datas;
    
    logic [1:0][bram_addr_w - 1:0]  gray_rd_addresses;
    logic [1:0][7:0]                gray_rd_datas;
    
    // gray is always bottom 8 bits
    
    assign bram_rd_datas[0] = {cd_rd_datas[0], gray_rd_datas[0]};
    assign bram_rd_datas[1] = {cd_rd_datas[1], gray_rd_datas[1]};
    assign cd_rd_addresses = bram_rd_addresses;
    assign gray_rd_addresses = bram_rd_addresses;
    
    always_comb begin
        cd_wr_addresses     = 'b0;
        gray_wr_addresses   = 'b0;
        
        bram_rd_addresses   = 'b0;
        
        cd_wr_enas          = 'b0;
        gray_wr_enas        = 'b0;
        
        cd_wr_datas         = 'b0;
        gray_wr_datas       = 'b0;
        
        out_rd_data         = 'b0;
        filt_rd_data        = 'b0;
        
        // Multiplex the read ports
        if ((out_rd_index == 1'b1) && (filt_rd_index == 1'b0)) begin
            bram_rd_addresses[1]    = out_rd_address;
            out_rd_data             = bram_rd_datas[1];
            
            bram_rd_addresses[0]    = filt_rd_address;
            filt_rd_data            = bram_rd_datas[0];
        end else if ((out_rd_index == 1'b0) && (filt_rd_index == 1'b1)) begin
            bram_rd_addresses[0]    = out_rd_address;
            out_rd_data             = bram_rd_datas[0];
            
            bram_rd_addresses[1]    = filt_rd_address;
            filt_rd_data            = bram_rd_datas[1];
        end
        
        // Multiplex the write ports
        if ((bram_writer_index == 1'b1) && (filt_wr_index == 1'b0)) begin
            cd_wr_addresses[1]      = cd_writer_wr_address;
            cd_wr_datas[1]          = cd_writer_wr_data;
            cd_wr_enas[1]           = cd_writer_wr_ena;
            
            gray_wr_addresses[1]    = gray_writer_wr_address;
            gray_wr_datas[1]        = gray_writer_wr_data;
            gray_wr_enas[1]         = gray_writer_wr_ena;
            
            cd_wr_addresses[0]      = filt_wr_address;
            cd_wr_datas[0]          = filt_wr_data[15 + disp_bits:8];
            cd_wr_enas[0]           = filt_wr_ena;
            
            gray_wr_addresses[0]    = filt_wr_address;
            gray_wr_datas[0]        = filt_wr_data[7:0];
            gray_wr_enas[0]         = filt_wr_ena;
        end else if ((bram_writer_index == 1'b0) && (filt_wr_index == 1'b1)) begin
            cd_wr_addresses[0]      = cd_writer_wr_address;
            cd_wr_datas[0]          = cd_writer_wr_data;
            cd_wr_enas[0]           = cd_writer_wr_ena;
            
            gray_wr_addresses[0]    = gray_writer_wr_address;
            gray_wr_datas[0]        = gray_writer_wr_data;
            gray_wr_enas[0]         = gray_writer_wr_ena;
            
            cd_wr_addresses[1]      = filt_wr_address;
            cd_wr_datas[1]          = filt_wr_data[15 + disp_bits:8];
            cd_wr_enas[1]           = filt_wr_ena;
            
            gray_wr_addresses[1]    = filt_wr_address;
            gray_wr_datas[1]        = filt_wr_data[7:0];
            gray_wr_enas[1]         = filt_wr_ena;
        end
    end
    
    bram_wrapper #(
        .wr_addr_w  (bram_addr_w),
        .rd_addr_w  (bram_addr_w),
        .wr_data_w  (8 + disp_bits),
        .rd_data_w  (8 + disp_bits),
        .wr_word_depth  (frame_size),
        .rd_word_depth  (frame_size)
    ) bram_modules_cd[1:0] (
        .clk        (clk),
        .wr_addr    (cd_wr_addresses),
        .rd_addr    (cd_rd_addresses),
        .wren       (cd_wr_enas),
        .wr_data    (cd_wr_datas),
        .rd_data    (cd_rd_datas)
    );
    
    bram_wrapper #(
        .wr_addr_w  (bram_addr_w),
        .rd_addr_w  (bram_addr_w),
        .wr_data_w  (8),
        .rd_data_w  (8),
        .wr_word_depth  (frame_size),
        .rd_word_depth  (frame_size)
    ) bram_modules_gray[1:0] (
        .clk        (clk),
        .wr_addr    (gray_wr_addresses),
        .rd_addr    (gray_rd_addresses),
        .wren       (gray_wr_enas),
        .wr_data    (gray_wr_datas),
        .rd_data    (gray_rd_datas)
    );
endmodule