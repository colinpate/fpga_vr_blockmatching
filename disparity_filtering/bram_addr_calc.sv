module bram_addr_calc #(
    parameter width = 120,
    parameter height = 240,
    parameter frame_size = width * height,
    parameter addr_w = $clog2(frame_size)
    ) (
        input                       clk,
        input                       reset,
        input                       go,
        input                       vertical,
        output logic [addr_w - 1:0] addr,
        output                      line_first_addr,
        output                      line_last_addr,
        output                      frame_last_addr
    );
    
    localparam last_addr_in_frame = frame_size - 1;
    
    logic [$clog2(width) - 1:0]     col;
    logic [$clog2(height) - 1:0]    row;
    
    assign frame_last_addr = (addr == last_addr_in_frame);
    assign line_first_addr = vertical ? (row == 0) : (col == 0);
    assign line_last_addr = vertical ? (row == (height - 1)) : (col == (width - 1));
    
    always @(posedge clk) begin
        if (reset) begin
            col             <= 0;
            row             <= 0;
            addr            <= 0;
        end else begin
            if (go) begin
                if (addr == last_addr_in_frame) begin
                    addr            <= 0;
                    col             <= 0;
                    row             <= 0;
                end else begin
                    if (vertical) begin
                        if (row == (height - 1)) begin
                            addr    <= col + 1;
                            col     <= col + 1;
                            row     <= 0;
                        end else begin
                            addr    <= addr + width;
                            row     <= row + 1;
                        end
                    end else begin
                        addr    <= addr + 1;
                        if (col == (width - 1)) begin
                            col <= 0;
                            row <= row + 1;
                        end else begin
                            col <= col + 1;
                        end
                    end
                end
            end
        end
    end
endmodule