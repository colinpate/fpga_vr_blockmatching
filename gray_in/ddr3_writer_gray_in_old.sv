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
    
    typedef enum {ST_IDLE, ST_FIRST_READ, ST_CHECK_SOF, ST_WAIT_WRITE} statetype;
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
    
    ddr3_writer_fifo ddr3_write_fifo_inst( //257-bit dual clock 256-word FIFO
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
                pixel_index <= pixel_index + 1;
                if (pixel_index == (pixels_per_write - 1)) begin
                    fifo_write <= 1;
                end else begin
                    fifo_write <= 0;
                end
                if (sof_in) sof_recd    <= 1; // Set this
            end else begin
                fifo_write <= 0;
            end
        end
    end
    
    logic [burst_log - 1:0] burst_index;
    logic [3:0][26:0]       start_addresses;
    logic [8:0]             end_address; // 27 - 18 bits = 9 bits
    logic                   sof_read;
    logic [$clog2(frame_num_writes) - 1:0] write_counter;
    logic [$clog2(frame_num_bursts) - 1:0] burst_counter;
    
    assign sof_read         = fifo_data[256];
    assign ddr3_write_data  = fifo_data[255:0];
    assign fifo_read        = ((state == ST_FIRST_READ) || ((fifo_read_ena) && (ddr3_write) && (!ddr3_waitrequest)));
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
            
            start_addresses[0]  <= start_address_i[31:5] + 20'h00000; //480w * 2880h * 2bytes/pix / 32byte/write
            start_addresses[1]  <= start_address_i[31:5] + 20'h20000; //18 bits
            start_addresses[2]  <= start_address_i[31:5] + 20'h40000;
            start_addresses[3]  <= start_address_i[31:5] + 20'h60000;
            end_address         <= start_addresses[0][26:18] + 9'h1;
        end else begin
            
            case (state)
                ST_IDLE: begin
                    pointer_valid <= 0;
                    if ((fifo_level > (burst_len - 1)) || (fifo_rdfull)) begin
                        state           <= ST_FIRST_READ;
                        
                        burst_index     <= 0;
                        fifo_read_ena   <= 0;
                    end
                end
                
                ST_FIRST_READ: begin
                    state           <= ST_CHECK_SOF;
                    fifo_read_ena   <= 1;
                end
                
                ST_CHECK_SOF: begin
                    state   <= ST_WAIT_WRITE;
                
                    if ((sof_read) || (burst_counter == (frame_num_bursts - 1))) begin
                        ddr3_write_address  <= start_addresses[0];
                        end_address         <= start_addresses[0][26:18] + 9'h1;
                        pointer_valid       <= 1;
                        burst_counter       <= 0;
                        if (rotate_buffers == 1) begin
                            start_addresses     <= {start_addresses[0], start_addresses[3:1]};
                            pointer_data        <= pointer_data + 1;
                        end
                    end else begin
                        burst_counter       <= burst_counter + 1;
                        ddr3_write_address  <= ddr3_write_address + burst_len;
                    end
                end
                
                ST_WAIT_WRITE: begin
                    if (!ddr3_waitrequest) begin
                        if (burst_index == (burst_len - 1)) begin
                            state               <= ST_IDLE;
                        end else begin
                            if (burst_index == (burst_len - 2)) begin
                                fifo_read_ena   <= 0;
                            end
                        end
                        burst_index     <= burst_index + 1;
                    end
                end
            endcase
        end
    end
endmodule