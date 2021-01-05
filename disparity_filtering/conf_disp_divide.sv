module conf_disp_divide #(
    parameter data_width = 21
    ) (
        input clk,
        input reset,
        input [data_width - 1:0]    in_data,
        input                       in_valid,
    )