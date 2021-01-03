//`define SIM

module bit_pixel_reader
    #(
    parameter third_width = 240,
    parameter third_height = 480,
    parameter center_width = 304
    )
    (
    input                   pclk,
    input                   pclk_reset,
    output [63:0]           bit_pixels,
    output logic            pixels_valid,
    input                   pixels_ready,
    
    input   [3:0]           image_number,
	
    output [15:0]    rd_address_left,
    input logic [7:0]  rd_data_left,
    
    output [15:0]    rd_address_centerleft,
    input logic [7:0]  rd_data_centerleft,
    
    output [15:0]    rd_address_right,
    input logic [7:0]  rd_data_right,
    
    output [15:0]    rd_address_centerright,
    input logic [7:0]  rd_data_centerright
    );
    
    typedef enum {ST_IDLE, ST_READING} statetype;
    statetype state;
    
    localparam third_reads = third_width * third_height / 8; // 8 pixels per read
    localparam center_reads = center_width * third_height / 8; // 8 pixels per read
    
    logic [1:0] third_index;
    logic [3:0] image_number_reg;
    logic [15:0] read_address_i;
    logic [15:0] end_address_i;
    logic [15:0] start_address_i;
    logic        buf_index;
    logic [7:0] rd_data_i;
    logic rd_ena;
    
    assign end_address_i = (third_index == 2'b01) ? (buf_index ? center_reads * 2 : center_reads)
                                                    : (buf_index ? third_reads * 2 : third_reads);
    assign start_address_i = (third_index == 2'b01) ? (buf_index ? center_reads : 0)
                                                    : (buf_index ? third_reads : 0);
    
    assign rd_address_left = read_address_i;
    assign rd_address_centerleft = read_address_i;
    assign rd_address_centerright = read_address_i;
    assign rd_address_right = read_address_i;
    
    always_comb begin
        case (third_index)
            2'b00: rd_data_i = rd_data_left;
            2'b01: rd_data_i = rd_data_centerleft;
            2'b10: rd_data_i = rd_data_right;
            default: rd_data_i = 8'hF0;
        endcase
    end
    
    assign rd_ena = (state == ST_READING) && pixels_ready;
    
    assign bit_pixels = (read_address_i == start_address_i) ? 64'hFFFFFFFFFFFFFFFF : {rd_data_i[7], 7'h00, rd_data_i[6], 7'h00, rd_data_i[5], 7'h00, rd_data_i[4], 7'h00, rd_data_i[3], 7'h00, rd_data_i[2], 7'h00, rd_data_i[1], 7'h00, rd_data_i[0], 7'h00};
    
    always @(posedge pclk)
    begin
        if (pclk_reset) begin
            third_index         <= 0;
            image_number_reg    <= 0;
            read_address_i      <= 0;
            pixels_valid        <= 0;
            buf_index           <= 0;
            state               <= ST_IDLE;
        end else begin
            pixels_valid    <= rd_ena;
            
            case (state)
                ST_IDLE: begin
                    if (image_number != image_number_reg) begin
                        image_number_reg    <= image_number;
                        state               <= ST_READING;
                        third_index         <= 0;
                        read_address_i      <= start_address_i; // offset the address
                    end
                end
                
                ST_READING: begin
                    //pixels_valid    <= 0;
                    if (pixels_ready) begin
                        //pixels_valid    <= 1;
                        if (read_address_i == (end_address_i - 1)) begin
                            if (third_index == 2'b00) begin // Center is next
                                read_address_i <= buf_index ? center_reads : 0;
                            end else begin
                                read_address_i  <= buf_index ? third_reads : 0;
                            end
                            if (third_index == 2'b10) begin
                                state               <= ST_IDLE;
                                third_index         <= 0;
                                buf_index           <= !buf_index;
                            end else begin
                                third_index         <= third_index + 1;
                            end
                        end else begin
                            read_address_i  <= read_address_i + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule