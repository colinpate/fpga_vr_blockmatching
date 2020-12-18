//`define SIM

module ddr3_reader_grayfilter
    #(parameter in_width = 16,
    parameter frame_width = 480,
    parameter frame_lines = 720,
    parameter burst_len = 1,
    parameter burst_log = $clog2(burst_len)
    )
    (
        input                   pclk,
        input                   pclk_reset,
        
        output logic [263:0]    pixel_data,
        output                  pixel_valid,
        input                   pix_fifo_almost_full;
        
        input                   ddr3clk,
        input                   ddr3clk_reset,
        
        output logic [26:0]     ddr3_address,
        input [255:0]           ddr3_readdata,
        output logic            ddr3_read,
        input                   ddr3_waitrequest,
        input                   ddr3_readdatavalid,
        output logic [3:0]      ddr3_burstcount,
        
        input [26:0]            start_in,
        input [1:0]             pointer_data,
        input                   pointer_valid
    );
    
    parameter pixels_per_rd     = 256 / in_width;
    parameter line_len          = frame_width / pixels_per_rd;
    parameter pix_rd_log        = $clog2(pixels_per_rd);
    assign ddr3_burstcount      = burst_len;
    
    typedef enum {ST_IDLE, ST_SEND_SOF, ST_WAIT_FIFO, ST_READ, ST_LAST_READ} statetype;
    statetype state;
    
    typedef enum {OST_IDLE, OST_SEND_HEADER, OST_WAIT_FIFO, OST_WAIT_READ, OST_SEND_FRAME} statetype_out;
    statetype_out out_state;
    
    logic [263:0]   fifo_wrdata;
    logic [263:0]   fifo_q;
    logic           fifo_rdempty;
    logic           fifo_rd;
    logic [7:0]     fifo_wrlevel;
    logic           fifo_aclr;
    logic           fifo_wrreq;
    logic [7:0]     info_fifo_q;
    
    assign fifo_wrreq   = ddr3_readdatavalid || (state == ST_SEND_SOF);
    assign fifo_wrdata  = {info_fifo_q, ddr3_readdata};
    
    ddr3reader_dcfifo ddr3reader_dcfifo_inst( //264-bit, 256-word, dual clock FIFO
        .wrclk          (ddr3clk),
        .rdclk          (pclk),
        .aclr           (fifo_aclr),
        .wrreq          (fifo_wrreq),
        .rdreq          (fifo_rd),
        .wrusedw        (fifo_wrlevel),
        .rdempty        (fifo_rdempty),
        .data           (fifo_wrdata),
        .q              (fifo_q)
        );
    
    logic fifo_rdv;
    
    assign pixel_data = fifo_q;
    assign pixel_valid = fifo_rdv;
    
    always @(posedge pclk)
    begin
        if (pclk_reset) begin
            fifo_aclr           <= 1;
            fifo_rd             <= 0;
        end else begin
            fifo_aclr           <= 0;
            fifo_rdv            <= fifo_rd && (!fifo_rdempty);
            fifo_rd             <= !pix_fifo_almost_full;
        end
    end
    
    logic [3:0]         ptrfifo_rdempty;
    logic               ptrfifo_rd;
    logic [3:0][1:0]    ptrfifo_q;
    
    gray_ptr_fifo gray_ptr_fifo_inst( //2-bit, 4-word, single clock, show-ahead FIFO
        .clock          (ddr3clk),
        .sclr           (ddr3clk_reset),
        .wrreq          (pointer_valid),
        .rdreq          (ptrfifo_rd),
        .empty          (ptrfifo_rdempty),
        .data           (pointer_data),
        .q              (ptrfifo_q)
        );
    
    logic [7:0] info_fifo_data;
    logic sof_bit;
    logic eof_bit;
    logic [9:0]     line_number;
    logic [7:0]     col_number;
    logic [1:0]     cam_index;
    assign sof_bit = (line_number == 0) && (col_number == 0);
    assign eof_bit = (line_number == (frame_lines - 1)) && (col_number == (frame_cols - 1));
    assign info_fifo_data = {4'h0, cam_index, sof_bit, eof_bit};
    
    gray_info_fifo gray_info_fifo_inst( //8-bit, 64-word, single clock, show-ahead FIFO
        .clock          (ddr3clk),
        .sclr           (ddr3clk_reset),
        .wrreq          (ddr3_read && (!ddr3_waitrequest)),
        .rdreq          (ddr3_readdatavalid),
        .data           (info_fifo_data),
        .q              (info_fifo_q)
        );
    
    logic [26:0]   start_address;
    logic [26:0]   col_address;
    
    assign start_address = start_in + (ptrfifo_q << 14);
    
    
    assign ddr3_read = (state == ST_READ);
    assign fifo_almost_full = fifo_wrlevel[7];
    
    always @(posedge ddr3clk)
    begin
        if (ddr3clk_reset) begin
            state               <= ST_IDLE;
            ptrfifo_rd          <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (!(|ptrfifo_rdempty)) begin
                        state           <= ST_WAIT_FIFO;
                        ddr3_address    <= start_address;
                        col_address     <= start_address + burst_len;
                        line_number     <= 0;
                        col_number      <= 0;
                        cam_index       <= 0;
                        ptrfifo_rd      <= 1;
                    end
                end
                
                /*ST_SEND_SOF: begin
                    state   <= ST_WAIT_FIFO;
                end*/
                
                ST_WAIT_FIFO: begin
                    ptrfifo_rd  <= 0;
                    if (!fifo_almost_full) begin
                        state   <= ST_READ;
                    end
                end
                
                ST_READ: begin
                    if (!ddr3_waitrequest) begin
                        if (line_number == (frame_lines - 1)) begin
                            line_number <= 0;
                            
                            if (col_number == (frame_cols - 1)) begin
                                col_number  <= 0;
                                cam_index   <= cam_index + 1;
                                
                                if (cam_index == 2'b11) begin
                                    state           <= ST_IDLE;
                                end else begin
                                    state           <= ST_WAIT_FIFO;
                                    ddr3_address    <= ddr3_address + burst_len; // Start on the next frame cuz we're currently at the last pixel of the current frame.
                                    col_address     <= ddr3_address + (burst_len * 2); // Second col of next frame
                                end
                            end else begin
                                state           <= ST_WAIT_FIFO;
                                col_number      <= col_number + 1;
                                ddr3_address    <= col_address;
                                col_address     <= col_address + burst_len;
                            end
                        end else begin
                            state           <= ST_WAIT_FIFO;
                            line_number     <= line_number + 1;
                            //ddr3_address    <= ddr3_address + (line_len - burst_len);
                            ddr3_address    <= ddr3_address + line_len; // Go to the next row down in this column.
                        end
                    end
                end
            endcase
        end
    end
endmodule