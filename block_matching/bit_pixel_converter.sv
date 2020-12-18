module gray_pixel_to_bit_pixel #(
        parameter frame_width = 240,
        parameter frame_height = 480
        )(
        input                   clk,
        input                   reset,
        
        input [7:0]             pixel_data,
        input                   pixel_valid,
        
        output logic [4:0]      bits_out,
        output logic            bits_valid
    );