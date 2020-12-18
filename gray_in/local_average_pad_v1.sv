module local_average_pad #(
    parameter radius = 8,
    parameter frame_width = 768,
    parameter frame_lines = 480
    )
    (
	input               reset,
	input               clk,
    input [8:0]         pixel,
    input               pixel_valid,
    input [7:0]         local_average,
    input               local_average_valid,
    output logic [16:0] out_data,
    output logic        out_valid
    );
    
    /*receive:
    2R counts of pixel
    local average of the 2R
    
    3R-length pixel shift reg
    R-length local average shift reg
    
    at first local average, output R times with first R pixels
    at last local average, output R times with last R pixels
    
    so pixels are delayed 16
    local average is delayed 16 then 24
    */
    
    assign out_valid = pixel_valid;
    assign out_data = {pixel[8], local_average, pixel[7:0]};
    
    typedef enum {ST_WAIT_FOR_SOF, ST_IDLE, ST_LEAD_EDGE, ST_MID, ST_TRAIL_EDGE} statetype;
    statetype state;
    
    logic read_pix_fifo;
    logic read_avg_fifo;
    logic read_fifos;
    logic avg_fifo_empty;
    logic pix_fifo_empty;
    logic pix_fifo_valid;
    logic sof_i;
    logic clear_fifos;
    
    localparam frame_num_pix = frame_width * frame_lines;
    
    local_average_pad_fifo avg_fifo(
        .clock          (clk),
        .sclr           (reset || clear_fifos),
        .wrreq          (local_average_valid),
        .rdreq          (read_avg_fifo),
        .empty          (avg_fifo_empty),
        .data           ({1'b0, local_average}),
        .q              (out_data[15:8])
    );
    
    local_average_pad_fifo pix_fifo(
        .clock          (clk),
        .sclr           (reset || clear_fifos),
        .wrreq          (pixel_valid),
        .rdreq          (read_pix_fifo),
        .empty          (pix_fifo_empty),
        .data           (pixel),
        .q              ({out_data[16], out_data[7:0]})
    );
    
    logic [9:0] pixel_out_count;
    logic [20:0] frame_pixel_count;
    
    assign read_fifos       = ((state == ST_IDLE) || (state == ST_MID)) && (!avg_fifo_empty) && (!pix_fifo_empty);
    assign read_pix_fifo    = read_fifos || (((state == ST_LEAD_EDGE) || (state == ST_TRAIL_EDGE)) && (!pix_fifo_empty));
    assign read_avg_fifo    = read_fifos || (pixel_out_count == (radius - 1));// || ((state == ST_MID) && (!avg_fifo_empty));
    assign out_valid        = (pix_fifo_valid);// && (avg_fifo_valid || (state == ST_LEAD_EDGE) || (state == ST_TRAIL_EDGE));
    assign sof_i            = pixel[8];
    
    always @(posedge clk)
    begin
        if (reset) begin
            pixel_out_count     <= 0;
            state               <= ST_WAIT_FOR_SOF;
            pix_fifo_valid      <= 0;
            clear_fifos         <= 0;
            frame_pixel_count   <= 0;
        end else begin
            pix_fifo_valid <= read_pix_fifo && (!pix_fifo_empty);
            if (pixel_valid) frame_pixel_count  <= frame_pixel_count + 1;
        
            case (state)
                ST_WAIT_FOR_SOF: begin
                    clear_fifos <= 0;
                    if (sof_i && pixel_valid) begin
                        frame_pixel_count   <= 1;
                        state               <= ST_IDLE;
                    end
                end
            
                ST_IDLE: begin
                    if (read_fifos) begin
                        state           <= ST_LEAD_EDGE;
                        pixel_out_count <= 0;
                    end
                end
                
                ST_LEAD_EDGE: begin
                    if (out_valid) pixel_out_count <= pixel_out_count + 1;
                    
                    if (pixel_out_count == (radius - 1)) begin
                        state   <= ST_MID;
                    end
                end
                
                ST_MID: begin
                    if (out_valid) pixel_out_count <= pixel_out_count + 1;
                    
                    if (pixel_out_count == (frame_width - radius - 1)) begin
                        state   <= ST_TRAIL_EDGE;
                    end
                end
                
                ST_TRAIL_EDGE: begin
                    if (out_valid) pixel_out_count <= pixel_out_count + 1;
                    
                    if (pixel_out_count == (frame_width - 1)) begin
                        if (frame_pixel_count >= frame_num_pix - 1) begin
                            state       <= ST_WAIT_FOR_SOF;
                            clear_fifos <= 1;
                        end else begin
                            state   <= ST_IDLE;
                        end
                    end
                end
            endcase
        end
    end
endmodule