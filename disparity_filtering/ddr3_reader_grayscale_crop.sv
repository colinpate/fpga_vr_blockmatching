//`define SIM

module ddr3_reader_grayscale_crop
    #(
    parameter frame_width = 768,
    parameter crop_width = 240,
    parameter frame_lines = 480,
    parameter i_am_left = 1,
    parameter decimate_factor = 2
    )
    (
        input                   pclk,
        input                   pclk_reset,
        
        output logic [7:0]      pixel_data,
        output                  pixel_valid,
        input                   pixel_ready,
        
        input                   ddr3clk,
        input                   ddr3clk_reset,
        
        output logic [26:0]     ddr3_address,
        input [255:0]           ddr3_readdata,
        output logic            ddr3_read,
        input                   ddr3_waitrequest,
        input                   ddr3_readdatavalid,
        output logic [4:0]      ddr3_burstcount,
        
        input [28:0]            address_in_data,
        input                   address_in_valid
    );
    
    localparam read_pix_width = 16;
    
    localparam pixels_per_rd = 256 / read_pix_width;
    localparam pix_rd_log = $clog2(pixels_per_rd);
    
    localparam burst_len = crop_width / pixels_per_rd;
    localparam line_address_jump = (frame_width / pixels_per_rd) * decimate_factor;
    
    assign ddr3_burstcount = burst_len;
    
    typedef enum {ST_CLEAR_FIFO, ST_IDLE, ST_WAIT_FIFO, ST_READ} statetype;
    statetype state;
    
    typedef enum {OST_IDLE, OST_WAIT_FIFO, OST_SEND_FRAME} statetype_out;
    statetype_out out_state;
    
    logic [255:0]   fifo_q;
    logic           fifo_rdempty;
    logic           fifo_rd;
    logic [7:0]     fifo_wrlevel;
    logic           fifo_aclr;
    logic           fifo_wrfull;
    logic           fifo_almost_full;
    logic           fifo_wrempty;
    logic [8:0]     fifo_cnt;
    
    logic [7:0]     frame_number;
    
    ddr3reader_dcfifo_showahead ddr3reader_dcfifo_inst( //256-bit, at least 256-word, dual clock FIFO, show ahead
        .wrclk          (ddr3clk),
        .rdclk          (pclk),
        .aclr           (fifo_aclr),
        .wrreq          (ddr3_readdatavalid),
        .rdreq          (fifo_rd),
        .wrusedw        (fifo_wrlevel),
        .rdempty        (fifo_rdempty),
        .data           (ddr3_readdata),
        .q              (fifo_q),
        .wrfull         (fifo_wrfull),
        .wrempty        (fifo_wrempty)
        );
    
    logic [15:0]    send_count;
    logic [255:0]   fifo_pixout;
    
    assign fifo_pixout = fifo_q[255:0];
    
    logic [255:0]               pix_sreg;
    logic [pix_rd_log - 1:0]    pix_index;
    logic                       fifo_rdv;
    
    assign pixel_data = pix_sreg[7:0];
    assign pixel_valid = (out_state == OST_SEND_FRAME);
    //assign pixel_valid = 1'b1; // DEBUG
    
    always @(posedge pclk)
    begin
        if (pclk_reset) begin
            fifo_rd             <= 0;
            out_state           <= OST_IDLE;
            frame_number        <= 0;
            pix_sreg            <= 0;
            pix_index           <= 0;
        end else begin
            fifo_rd             <= 0;
            
            /*if (pixel_ready) begin // DEBUG
                if (pix_sreg[7:0] == 239) begin
                    pix_sreg[7:0]   <= 0;
                end else begin
                    pix_sreg[7:0] <= pix_sreg[7:0] + 1;
                end
            end*/
            
            case (out_state)
                OST_IDLE: begin
                    out_state           <= OST_WAIT_FIFO;
                    frame_number        <= frame_number + 1;
                end
                
                OST_WAIT_FIFO: begin
                    if (!fifo_rdempty) begin
                        out_state       <= OST_SEND_FRAME;
                        fifo_rd         <= 1; // Ack the FIFO because it's a show-ahead
                        pix_index       <= 0;
                        pix_sreg        <= fifo_pixout;
                    end
                end
                
                OST_SEND_FRAME: begin
                    fifo_rd     <= 0;
                    if (pixel_ready) begin
                        if (pix_index == (pixels_per_rd - 1)) begin
                            pix_index   <= 0;
                            if (fifo_rdempty) begin
                                out_state   <= OST_WAIT_FIFO;
                            end else begin
                                pix_sreg        <= fifo_pixout;
                                fifo_rd         <= 1;
                            end
                        end else begin
                            pix_index   <= pix_index + 1;
                            pix_sreg    <= pix_sreg[255:read_pix_width];
                        end
                    end
                end
            endcase
        end
    end
    
    logic               address_fifo_empty;
    logic               address_fifo_read;
    logic [28:0]        address_fifo_q;
    logic [26:0]        address_fifo_addr_out;
    logic [1:0]         address_fifo_third_out;
    
    scfifo_wrapper #(
        .width  (29),
        .depth  (8)
    ) address_fifo (
        .clock  (ddr3clk),
        .data   (address_in_data),
        .wrreq  (address_in_valid),
        .sclr   (ddr3clk_reset),
        .q      (address_fifo_q),
        .rdreq  (address_fifo_read),
        .empty  (address_fifo_empty)
    );
    
    logic [$clog2(frame_lines) - 1:0]   line_number;
    logic [7:0]                         clear_fifo_count;
    logic                               read_this_third;
    
    assign ddr3_read = (state == ST_READ);
    //assign ddr3_read = 1'b0;// DEBUG
    assign address_fifo_addr_out = address_fifo_q[26:0];
    assign address_fifo_third_out = address_fifo_q[28:27];
    assign read_this_third = ((i_am_left && (address_fifo_third_out == 2'b00)) || ((!i_am_left) && (address_fifo_third_out == 2'b10)));
    
    always @(posedge ddr3clk)
    begin
        if (ddr3clk_reset) begin
            state               <= ST_CLEAR_FIFO;
            address_fifo_read   <= 0;
            fifo_cnt            <= 0;
            fifo_aclr           <= 1;
            clear_fifo_count    <= 0;
            ddr3_address        <= 0;
        end else begin
            fifo_aclr   <= 0;
            
            if (ddr3_read && (!ddr3_waitrequest)) begin
                if (ddr3_readdatavalid) begin
                    fifo_cnt  <= fifo_cnt + burst_len - 1;
                end else begin
                    fifo_cnt  <= fifo_cnt + burst_len;
                end
            end else begin
                if (ddr3_readdatavalid) begin
                    if (fifo_cnt != 0) begin
                        fifo_cnt    <= fifo_cnt - 1;
                    end
                end
            end
            
            case (state)
                ST_CLEAR_FIFO: begin
                    if (clear_fifo_count == 8'h30) begin
                        state   <= ST_IDLE;
                    end else begin
                        clear_fifo_count    <= clear_fifo_count + 1;
                    end
                end
                
                ST_IDLE: begin
                    address_fifo_read   <= 0;
                    if (!address_fifo_empty) begin
                        address_fifo_read      <= 1;
                        if (read_this_third) begin
                            state                  <= ST_WAIT_FIFO;
                            ddr3_address           <= address_fifo_addr_out;
                            line_number            <= 0;
                        end
                    end
                end
                
                ST_WAIT_FIFO: begin
                    address_fifo_read  <= 0;
                    if ((fifo_wrlevel < 128) && (fifo_cnt < (128 - burst_len))) begin
                        state                   <= ST_READ;
                    end
                end
                
                ST_READ: begin
                    if (!ddr3_waitrequest) begin
                        if (line_number == (frame_lines  - decimate_factor)) begin
                            state   <= ST_IDLE;
                        end else begin
                            state           <= ST_WAIT_FIFO;
                            line_number     <= line_number + decimate_factor;
                            ddr3_address    <= ddr3_address + line_address_jump;
                        end
                    end
                end
            endcase
        end
    end
endmodule