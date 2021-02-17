//`default_nettype none
module bram_reader_out #(
    parameter width = 120,
    parameter height = 240,
    parameter frame_size = width * height,
    parameter addr_bits = $clog2(frame_size),
    parameter data_width = 21
    ) (
        input clk,
        input reset,
        output [data_width - 1:0]   out_data,
        output                      out_valid,
        input                       out_ready,
        
        input                       start,
        input                       bram_index_in,
        output                      idle,
        
        output logic                    rd_bram_index,
        input [data_width - 1:0]        rd_data,
        output logic [addr_bits - 1:0]  rd_address
    );
    
    localparam fifo_depth = 8;
    
    typedef enum {ST_IDLE, ST_WAIT_FIFO, ST_RUNNING} statetype;
    statetype state;
    
    logic read_data_valid;
    logic fifo_almost_full;
    logic fifo_empty;
    logic [$clog2(fifo_depth) - 1:0] fifo_level;
    
    assign idle = (state == ST_IDLE);
    assign fifo_almost_full = fifo_level > (fifo_depth - 4);
    assign out_valid = !fifo_empty;
    
    scfifo_wrapper #(
        .width  (data_width),
        .depth  (fifo_depth)
    ) output_fifo (
        .clock      (clk),
        //.data       ((rd_address < 16) ? 0 : rd_data),
        .data       (rd_data),
        .rdreq      (out_ready && (!fifo_empty)),
        .sclr       (reset),
        .wrreq      (read_data_valid),
        .empty      (fifo_empty),
        .q          (out_data),
        .usedw      (fifo_level)
    );
    
    always @(posedge clk) begin
        if (reset) begin
            rd_address      <= 0;
            rd_bram_index   <= 0;
            read_data_valid <= 0;
            state           <= ST_IDLE;
        end else begin
            read_data_valid <= (state == ST_RUNNING);
            
            case (state)
                ST_IDLE: begin
                    if (start) begin
                        state           <= ST_WAIT_FIFO;
                        rd_address      <= 0;
                        rd_bram_index   <= bram_index_in;
                    end
                end
                
                ST_WAIT_FIFO: begin
                    if (!fifo_almost_full) begin
                        state   <= ST_RUNNING;
                    end
                end
                
                ST_RUNNING: begin
                    if (rd_address == (frame_size - 1)) begin
                        state       <= ST_IDLE;
                        rd_address  <= 0;
                    end else begin
                        rd_address  <= rd_address + 1;
                        if (fifo_almost_full) begin
                            state       <= ST_WAIT_FIFO;
                        end
                    end
                end
            endcase
        end
    end
endmodule
                    
            