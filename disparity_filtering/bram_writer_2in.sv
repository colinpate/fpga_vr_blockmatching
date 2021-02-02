//`default_nettype none
module bram_writer_2in #(
    parameter width = 120,
    parameter height = 240,
    parameter frame_size = width * height,
    parameter addr_bits = $clog2(frame_size),
    parameter a_width = 13,
    parameter b_width = 8
    ) (
        input clk,
        input reset,
        input [a_width - 1:0]    a_data,
        input                    a_valid,
        input                    a_ready,
        
        input [b_width - 1:0]    b_data,
        input                    b_valid,
        input                    b_ready,
        
        input                   start,
        input                   bram_index_in,
        output                  idle,
        
        output logic                        wr_bram_index,
        output [a_width + b_width - 1:0]    wr_data,
        output logic [addr_bits - 1:0]      wr_address,
        output                              wr_ena
    );
    
    typedef enum {ST_IDLE, ST_WAIT_DATA, ST_RUNNING} statetype;
    statetype state;
    
    assign idle = (state == ST_IDLE);
    assign b_ready = (state == ST_RUNNING);
    assign a_ready = (state == ST_RUNNING);
    assign wr_data = {a_data, b_data};
    assign wr_ena = (state == ST_RUNNING);
    
    always @(posedge clk) begin
        if (reset) begin
            wr_address      <= 0;
            wr_bram_index   <= 0;
            state           <= ST_IDLE;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (start) begin
                        state           <= ST_WAIT_DATA;
                        wr_address      <= 0;
                        wr_bram_index   <= bram_index_in;
                    end
                end
                
                ST_WAIT_DATA: begin
                    if (a_valid && b_valid) begin
                        state   <= ST_RUNNING;
                    end
                end
                
                ST_RUNNING: begin
                    if (wr_address == (frame_size - 1)) begin
                        state   <= ST_IDLE;
                    end else begin
                        state       <= ST_WAIT_DATA;
                        wr_address  <= wr_address + 1;
                    end
                end
            endcase
        end
    end
endmodule
                    
            