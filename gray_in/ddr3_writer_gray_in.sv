//`define SIM

module ddr3_writer_gray_in
    #(parameter in_width = 16,
    parameter rotate_buffers = 0,
    parameter burst_len = 8,
    parameter frame_width = 768,
    parameter frame_lines = 480,
    parameter burst_log = $clog2(burst_len)
    )
    (
        input                   pclk,
        input                   pclk_reset,
        
        input [16:0]            pixel_data,
        input                   pixel_valid,
        
        input                   ddr3_clk,
        input                   ddr3clk_reset,
        output logic [26:0]     ddr3_write_address,
        output logic [255:0]    ddr3_write_data,
        output logic            ddr3_write,
        input                   ddr3_waitrequest,
        output logic [3:0]      ddr3_burstcount,
        
        output logic            fifo_almost_full,
        
        output logic [1:0]      pointer_data,
        output logic            pointer_valid,
        
        input   [31:0]          start_address_i
    );
    
    parameter pixels_per_write = 256 / in_width;
    parameter pix_per_wr_log = $clog2(pixels_per_write);
    assign ddr3_burstcount = burst_len;
    
    parameter frame_num_writes = (frame_width * frame_lines * 4) / (pixels_per_write);
    parameter frame_num_bursts = (frame_width * frame_lines * 4) / (pixels_per_write * burst_len);
    
    typedef enum {ST_IDLE, ST_WAIT_SOF, ST_CHECK_SOF, ST_WAIT_WRITE} statetype;
    statetype state;
    
    
    logic [15:0]                     pixel;
    logic [255:0]                    pixel_sreg;
    logic [pix_per_wr_log - 1:0]     pixel_index;
    
    logic sof_in, sof_recd;
    
    assign pixel    = pixel_data[15:0];
    assign sof_in   = pixel_data[16];
    
    logic           fifo_aclr;
    logic           fifo_write;
    logic           fifo_read;
    logic           fifo_read_ena;
    logic           fifo_rdfull;
    logic [256:0]   fifo_data;
    logic [7:0]     fifo_wrlevel;
    logic [7:0]     fifo_level;
    assign fifo_almost_full = fifo_wrlevel[7] && fifo_wrlevel[6];
    
    ddr3_writer_fifo_showahead ddr3_write_fifo_inst( //257-bit dual clock showahead 256-word FIFO
        .aclr       ( fifo_aclr ),
        .data       ( {sof_recd, pixel_sreg} ),
        .rdclk      ( ddr3_clk ),
        .rdreq      ( fifo_read ),
        .wrclk      ( pclk ),
        .wrreq      ( fifo_write ),
        .q          ( fifo_data ),
        .rdusedw    ( fifo_level ),
        .rdfull     ( fifo_rdfull ),
        .wrusedw    ( fifo_wrlevel )
    );
    
    always @(posedge pclk)
    begin
        if (pclk_reset) begin
            pixel_index     <= 0;
            fifo_write      <= 0;
            fifo_aclr       <= 1;
            sof_recd        <= 0;
        end else begin
            fifo_aclr       <= 0;
            
            if (fifo_write) sof_recd  <= 0; // Reset this
            
            if (pixel_valid) begin
                pixel_sreg  <= {pixel, pixel_sreg[255:in_width]}; //ARGB
                if (sof_in) begin
                    sof_recd    <= 1; // Set this
                    pixel_index <= 1; // Always want the SOF to be the first pixel in the 256-bit write.
                end else begin
                    if (pixel_index == (pixels_per_write - 1)) begin
                        pixel_index <= 0;
                    end else begin
                        pixel_index <= pixel_index + 1;
                    end
                end
                if (pixel_index == (pixels_per_write - 1)) begin
                    // Debug
                    if (sof_recd) begin
                        pixel_sreg  <= 256'd0;
                    end
                    fifo_write <= 1;
                end else begin
                    fifo_write <= 0;
                end
            end else begin
                fifo_write <= 0;
            end
        end
    end
    
    logic [burst_log - 1:0] burst_index;
    logic [3:0][26:0]       start_addresses;
    //logic [8:0]             end_address; // 27 - 18 bits = 9 bits
    logic                   sof_read;
    logic                   wait_for_sof;
    logic                   burn_stream;
    logic [$clog2(frame_num_writes) - 1:0] write_counter;
    logic [$clog2(frame_num_bursts) - 1:0] burst_counter;
    
    assign sof_read         = fifo_data[256];
    assign ddr3_write_data  = fifo_data[255:0];
    assign wait_for_sof     = (state == ST_WAIT_SOF);
    assign burn_stream      = wait_for_sof && (~sof_read);
    assign fifo_read        = (ddr3_write && (~ddr3_waitrequest)) || burn_stream;
    assign ddr3_write       = (state == ST_WAIT_WRITE);
    
    always @(posedge ddr3_clk)
    begin
        if (ddr3clk_reset) begin
            state               <= ST_IDLE;
            ddr3_write_address  <= 0;
            
            pointer_data        <= (rotate_buffers == 1) ? 2'b11 : 2'b00;
            pointer_valid       <= 0;
            write_counter       <= 0;
            burst_counter       <= 0;
            burst_index         <= 0;
            
            start_addresses[0]  <= start_address_i[31:5] + 20'h00000; //480w * 2880h * 2bytes/pix / 32byte/write
            start_addresses[1]  <= start_address_i[31:5] + 20'h20000; //18 bits
            start_addresses[2]  <= start_address_i[31:5] + 20'h40000;
            start_addresses[3]  <= start_address_i[31:5] + 20'h60000;
            //end_address         <= start_addresses[0][26:18] + 9'h1;
        end else begin
            pointer_valid   <= 0;
            
            case (state)
                ST_IDLE: begin
                    pointer_valid <= 0;
                    //if ((fifo_level > (burst_len - 1)) || (fifo_rdfull)) begin
                    ddr3_write_address  <= start_addresses[0];
                    state               <= ST_WAIT_SOF;
                    //end
                end
                
                ST_WAIT_SOF: begin
                    if (sof_read && ((fifo_level > 0) || fifo_rdfull)) begin
                        burst_counter       <= 0;
                        burst_index         <= 0;
                        state               <= ST_CHECK_SOF;
                    end
                end
                
                ST_CHECK_SOF: begin
                    // If SOF is active and we're not at address 0, set the address back to 0.
                    // If we're at address 0 and SOF is not active, burn the stream until SOF is active
                
                    if (burst_counter == frame_num_bursts) begin // Last burst just concluded, stay in this state but reset counters.
                        state               <= ST_WAIT_SOF;
                        ddr3_write_address  <= start_addresses[0];
                        pointer_valid       <= 1;
                        burst_counter       <= 0;
                        if (rotate_buffers == 1) begin
                            start_addresses     <= {start_addresses[0], start_addresses[3:1]};
                            pointer_data        <= pointer_data + 1;
                        end
                    end else begin
                        if ((fifo_level > (burst_len - 1)) || (fifo_rdfull)) begin
                            state               <= ST_WAIT_WRITE;
                            burst_index         <= 0;
                            burst_counter       <= burst_counter + 1;
                            if (burst_counter > 0) begin
                                ddr3_write_address  <= ddr3_write_address + burst_len;
                            end
                        end
                    end 
                end
                
                ST_WAIT_WRITE: begin
                    if (!ddr3_waitrequest) begin
                        if (burst_index == (burst_len - 1)) begin
                            burst_index         <= 0;
                            state               <= ST_CHECK_SOF;
                        end else begin
                            burst_index     <= burst_index + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule