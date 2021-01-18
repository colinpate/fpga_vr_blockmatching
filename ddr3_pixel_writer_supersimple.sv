//`define SIM

module ddr3_pixel_writer_supersimple
    #(parameter in_width = 16,
    parameter burst_len = 8,
    parameter num_pixels = 2764800,
    parameter start_address = 32'h36000000
    )
    (
    input                   pclk,
    input                   pclk_reset,
    input [in_width - 1:0]  pixel,
    input                   pixel_valid,
    output                  pixel_ready,
	
    input                       ddr3_clk,
    input                       ddr3_clk_reset,
    output logic [26:0]         ddr3_write_address,
    output logic [255:0]        ddr3_write_data,
    output logic                ddr3_write,
    input                       ddr3_waitrequest,
    output logic [7:0]          ddr3_burstcount,
	
    output logic [7:0]          fifo_level
    );
    
    localparam pixels_per_write = 256 / in_width;
    localparam pix_per_wr_log = $clog2(pixels_per_write);
    localparam burst_log = $clog2(burst_len);
    
    assign ddr3_burstcount = burst_len;
    
    const logic [31:0] start_address_i  = start_address;
    
    localparam num_writes = num_pixels / pixels_per_write / burst_len;
    
    typedef enum {ST_IDLE, ST_WAIT_FIFO, ST_FIRST_READ, ST_WAIT_WRITE} statetype;
    statetype state;
    
    logic [255:0]                    pixel_sreg;
    logic [pix_per_wr_log - 1:0]     pixel_index;
    logic [31:0]                     write_counter;
    
    logic           fifo_write;
    logic           fifo_read;
    logic           fifo_read_ena;
    logic           fifo_empty;
    logic           fifo_wrfull;
    logic           fifo_rdfull;
    logic [255:0]   fifo_data;
    logic           fifo_aclr;
    logic     [7:0] fifo_wrusedw;
    
    logic [burst_log - 1:0] burst_index;
    
    ddr3_writer_fifo ddr3_write_fifo_inst(
        .aclr       ( fifo_aclr ),
        .data       ( pixel_sreg ),
        .rdclk      ( ddr3_clk ),
        .rdreq      ( fifo_read ),
        .wrclk      ( pclk ),
        .wrreq      ( fifo_write ),
        .q          ( fifo_data ),
        .rdempty    ( fifo_empty ),
        .rdusedw    ( fifo_level ),
        .wrfull     ( fifo_wrfull ),
        .rdfull     ( fifo_rdfull ),
        .wrusedw    ( fifo_wrusedw )
    );
    
    assign pixel_ready = (~fifo_wrfull) && !(fifo_wrusedw == 8'hFF);
    
    assign ddr3_write_data = fifo_data;
    assign fifo_read    = ((state == ST_FIRST_READ) || ((fifo_read_ena) && (ddr3_write) && (!ddr3_waitrequest)));
    assign ddr3_write   = (state == ST_WAIT_WRITE);
    
    always @(posedge pclk)
    begin
        if (pclk_reset) begin
            pixel_index     <= 0;
            fifo_write      <= 0;
            fifo_aclr       <= 1;
        end else begin
            fifo_aclr       <= 0;
            
            if (pixel_valid) begin
                pixel_sreg  <= {pixel, pixel_sreg[255:in_width]}; //ARGB
                pixel_index <= pixel_index + 1;
                if (pixel_index == (pixels_per_write - 1)) begin
                    fifo_write <= 1;
                end else begin
                    fifo_write <= 0;
                end
            end else begin
                fifo_write <= 0;
            end
        end
    end
    
    always @(posedge ddr3_clk)
    begin
        if (ddr3_clk_reset) begin
            state               <= ST_IDLE;
            ddr3_write_address  <= 0;
            write_counter       <= 0;
            burst_index         <= 0;
            fifo_read_ena       <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    state           <= ST_WAIT_FIFO;
                    
                    ddr3_write_address  <= start_address_i[31:5];
                    
                    burst_index     <= 0;
                    fifo_read_ena   <= 0;
                    
                    write_counter   <= 0;
                end
                
                ST_WAIT_FIFO: begin
                    if ((fifo_level > (burst_len - 1)) || (fifo_rdfull)) begin
                        state   <= ST_FIRST_READ;
                    end
                end
                
                ST_FIRST_READ: begin
                    state           <= ST_WAIT_WRITE;
                    fifo_read_ena   <= 1;
                end
                
                ST_WAIT_WRITE: begin
                    if (!ddr3_waitrequest) begin
                        if (burst_index == (burst_len - 1)) begin
                            write_counter   <= write_counter + 1;
                            if (write_counter == (num_writes - 1)) begin
                                state               <= ST_IDLE;
                            end else begin
                                state               <= ST_WAIT_FIFO;
                                ddr3_write_address  <= ddr3_write_address + burst_len;
                            end
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