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
        output                   a_ready,
        
        input [b_width - 1:0]    b_data,
        input                    b_valid,
        output                   b_ready,
        
        input                   start,
        input                   bram_index_in,
        output                  idle,
        
        output logic                        wr_bram_index,
        output [a_width - 1:0]              a_wr_data,
        output logic [addr_bits - 1:0]      a_wr_address,
        output                              a_wr_ena,
        output [b_width - 1:0]              b_wr_data,
        output logic [addr_bits - 1:0]      b_wr_address,
        output                              b_wr_ena
    );
    
    typedef enum {ST_IDLE, ST_RUNNING} statetype;
    statetype state;
    
    logic   a_done;
    logic   b_done;
    
    assign idle = (state == ST_IDLE);
    assign a_ready = (state == ST_RUNNING) && (!a_done);
    assign b_ready = (state == ST_RUNNING) && (!b_done);
    assign a_wr_data = a_data;
    assign b_wr_data = b_data;
    assign a_wr_ena = (state == ST_RUNNING) && a_valid && (!a_done);
    assign b_wr_ena = (state == ST_RUNNING) && b_valid && (!b_done);
    
    always @(posedge clk) begin
        if (reset) begin
            a_wr_address    <= 0;
            b_wr_address    <= 0;
            wr_bram_index   <= 0;
            state           <= ST_IDLE;
            a_done          <= 0;
            b_done          <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (start) begin
                        state           <= ST_RUNNING;
                        a_wr_address    <= 0;
                        b_wr_address    <= 0;
                        a_done          <= 0;
                        b_done          <= 0;
                        wr_bram_index   <= bram_index_in;
                    end
                end
                
                ST_RUNNING: begin
                    if (a_done && b_done) begin
                        state   <= ST_IDLE;
                    end else begin
                        if ((!a_done) && a_wr_ena) begin
                            a_wr_address    <= a_wr_address + 1;
                            if (a_wr_address == (frame_size - 1)) begin
                                a_done  <= 1'b1;
                            end
                        end
                        if ((!b_done) && b_wr_ena) begin
                            b_wr_address    <= b_wr_address + 1;
                            if (b_wr_address == (frame_size - 1)) begin
                                b_done  <= 1'b1;
                            end
                        end
                    end
                end
            endcase
        end
    end
endmodule
                    
            