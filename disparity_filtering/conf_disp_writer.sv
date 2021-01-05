module conf_disp_writer #(
    parameter disp_bits = 5,
    parameter mat_width = 120,
    parameter mat_height = 240
    ) (
    input clk,
    input reset,
    
    input [disp_bits - 1:0] disp_in,
    input [7:0]             conf_in,
    input                   disp_conf_valid,
    
    
    