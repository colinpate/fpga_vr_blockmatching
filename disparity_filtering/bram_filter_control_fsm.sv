//`default_nettype none

/*
This module controls the modules that talk to the BRAM where the depth is filtered.
That would be:
    1. The writer that takes the grayscale data and depth+conf data and writes both to the BRAM
    2. The reader that reads the gray/depth/conf data from the BRAM and feeds it to the filter(s)
    3. The writer that receives the gray/depth/conf data from the filters and writes it back to the BRAM
    4. The reader that reads the filtered depth data from the BRAM and sends it out of the system.
There are two separate BRAMs, each with one read port and one write port. These are accessed in a ping-pong fashion,
where parts 1 and 4 are done on the one BRAM while parts 2 and 3 are done on the other - they switch back and forth.
*/

module bram_filter_control_fsm (
        input clk,
        input reset,
        
        output logic [3:0]  image_index_counter,
        
        output  bram_writer_2in_start,
        output  bram_writer_2in_index,
        input   bram_writer_2in_idle,
        
        output  filt_bram_rw_start,
        output  filt_bram_rw_index,
        input   filt_bram_rw_idle,
        
        output  out_bram_reader_start,
        output  out_bram_reader_index,
        input   out_bram_reader_idle
    );
    
    logic index_io; // The BRAM index to send to modules 1 and 4
    logic index_filt; // The BRAM index to send to modules 2 and 3 (should be opposite of the io index)
    logic first_frame_complete; // Set to 1 once we've been running for 1 frame (time to start the filters)
    logic second_frame_complete; // Set to 1 once we've been running for 2 frames (time to start the reader)
    logic fsms_running;
    logic fsms_idle;
    
    typedef enum {ST_IDLE, ST_START_FSMS, ST_WAIT_DONE} statetype;
    statetype state;
    
    assign bram_writer_2in_index = index_io;
    assign out_bram_reader_index = index_io;
    assign filt_bram_rw_index = index_filt;
    
    assign bram_writer_2in_start = (state == ST_START_FSMS);
    assign filt_bram_rw_start = (state == ST_START_FSMS) && first_frame_complete;
    assign out_bram_reader_start = (state == ST_START_FSMS) && second_frame_complete;
    
    assign fsms_running = (!bram_writer_2in_idle) && ((!first_frame_complete) || (!filt_bram_rw_idle)) && ((!second_frame_complete) || (!out_bram_reader_idle));
    assign fsms_idle = bram_writer_2in_idle && ((!first_frame_complete) || filt_bram_rw_idle) && ((!second_frame_complete) || (out_bram_reader_idle));
    
    always @(posedge clk) begin
        if (reset) begin
            state           <= ST_IDLE;
            index_io        <= 1'b0;
            index_filt      <= 1'b1;
            first_frame_complete    <= 1'b0;
            second_frame_complete   <= 1'b0;
            image_index_counter     <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    state   <= ST_START_FSMS;
                end
                
                ST_START_FSMS: begin
                    if (fsms_running) begin
                        state   <= ST_WAIT_DONE;
                    end
                end
                
                ST_WAIT_DONE: begin
                    if (fsms_idle) begin // Everything is done
                        image_index_counter     <= image_index_counter + 1;
                        state                   <= ST_START_FSMS;
                        index_filt  <= index_io;
                        index_io    <= index_filt;
                        first_frame_complete    <= 1'b1;
                        if (first_frame_complete) begin
                            second_frame_complete   <= 1'b1;
                        end
                    end
                end
            endcase
        end
    end
endmodule
                    
            