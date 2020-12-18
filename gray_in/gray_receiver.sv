module gray_receiver
    #(parameter frame_width = 480,
    parameter frame_lines = 2880
    )
    (
        input                   pclk,
        input                   pclk_reset,
        
        input [7:0]             pixel_data,
        input                   pixel_valid,
        
        output logic [8:0]      pixel_out,
        output logic            pixel_out_valid
    );
    
    parameter frame_length = frame_width * frame_lines * 4;
    
    typedef enum {ST_IDLE, ST_OUTPUT} statetype;
    statetype state;
    
    logic [4:0][7:0] received_bytes;
    const logic [3:0][7:0] header = {8'h71, 8'h8E, 8'hE8, 8'h17};
    
    logic [20:0]    pixel_in_ct;
    logic           sof;
    
    logic [7:0]     pixel_sync;
    logic [7:0]     pixel_i;
    logic           pixel_valid_sync;
    logic           pixel_valid_i;
    
    assign pixel_out_valid = pixel_valid_i && (state == ST_OUTPUT);
    //assign pixel_out = {sof, pixel_i};
    assign pixel_out = (pixel_in_ct < 32) ? {sof, 8'hFF} : {sof, pixel_i};
    
    always @(posedge pclk)
    begin
        pixel_valid_sync    <= pixel_valid;
        pixel_sync          <= pixel_data;
        
        pixel_valid_i       <= pixel_valid_sync;
        pixel_i             <= pixel_sync;
    
        if (pclk_reset) begin
            state               <= ST_IDLE;
            received_bytes      <= 0;
            sof                 <= 0;
        end else begin
            if (pixel_valid_i) begin
                received_bytes  <= {pixel_i, received_bytes[4:1]};
            end
            
            case (state)
                ST_IDLE: begin
                    if ({pixel_i, received_bytes[4:2]} == header) begin
                        state       <= ST_OUTPUT;
                        pixel_in_ct <= 0;
                        sof         <= 1;
                    end
                end
                
                ST_OUTPUT: begin
                    if (pixel_valid_i) begin
                        sof <= 0;
                        
                        if (pixel_in_ct == (frame_length - 1)) begin
                        //if (pixel_in_ct == (frame_length + 7)) begin
                            state       <= ST_IDLE;
                        end else begin
                            pixel_in_ct <= pixel_in_ct + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule