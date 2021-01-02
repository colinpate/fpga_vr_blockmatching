//`define SIM

module ddr3_reader_grayfilter_short
    #(parameter in_width = 16,
    parameter frame_third_width = 240,
    parameter center_width = 304,
    parameter frame_lines = 480,
    parameter frame_full_width = 768,
    parameter burst_len = 1,
    parameter burst_log = $clog2(burst_len)
    )
    (
        input                   pclk,
        input                   pclk_reset,
        
        output logic [263:0]    pixel_data,
        output                  pixel_valid,
        input                   pix_fifo_almost_full,
        
        input                   ddr3clk,
        input                   ddr3clk_reset,
        
        output logic [26:0]     ddr3_address,
        input [255:0]           ddr3_readdata,
        output logic            ddr3_read,
        input                   ddr3_waitrequest,
        input                   ddr3_readdatavalid,
        output logic [3:0]      ddr3_burstcount,
        
        input [28:0]            start_data,
        input                   start_valid,
        output logic            start_ready
    );
    
    parameter pixels_per_rd     = 256 / in_width;
    parameter full_line_len     = frame_full_width / pixels_per_rd;
    parameter pix_rd_log        = $clog2(pixels_per_rd);
    parameter frame_third_cols  = frame_third_width / pixels_per_rd;
    parameter center_cols       = center_width / pixels_per_rd;
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
    
    logic [7:0] info_fifo_data;
    logic sof_bit;
    logic eof_bit;
    logic [9:0]     line_number;
    logic [7:0]     col_number;
    logic [2:0]     cam_index;
    logic [1:0]     third_index;
    logic [$clog2(center_cols) - 1:0]   current_end_col;
    assign current_end_col = (third_index == 2'b01) ? center_cols - 1 : frame_third_cols - 1;
    assign sof_bit = (line_number == 0) && (col_number == 0);
    assign eof_bit = (line_number == (frame_lines - 1)) && (col_number == current_end_col);
    assign info_fifo_data = {1'b0, cam_index, third_index, sof_bit, eof_bit};
    
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
    
    assign start_address = start_data[26:0];
    
    assign ddr3_read = (state == ST_READ);
    assign fifo_almost_full = |fifo_wrlevel;
    
    always @(posedge ddr3clk)
    begin
        if (ddr3clk_reset) begin
            state               <= ST_IDLE;
            start_ready         <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (start_valid) begin
                        state           <= ST_WAIT_FIFO;
                        ddr3_address    <= start_address;
                        col_address     <= start_address + burst_len;
                        third_index     <= start_data[28:27];
                        line_number     <= 0;
                        col_number      <= 0;
                        cam_index       <= 0;
                        start_ready     <= 1;
                    end
                end
                
                ST_WAIT_FIFO: begin
                    start_ready <= 0;
                    if (!fifo_almost_full) begin
                        state   <= ST_READ;
                    end
                end
                
                ST_READ: begin
                    if (!ddr3_waitrequest) begin
                        if (line_number == (frame_lines - 1)) begin
                            line_number <= 0;
                            if (col_number == current_end_col) begin
                                    state <= ST_IDLE;
                            end else begin
                                state           <= ST_WAIT_FIFO;
                                col_number      <= col_number + 1;
                                ddr3_address    <= col_address;
                                col_address     <= col_address + burst_len;
                            end
                        end else begin
                            state           <= ST_WAIT_FIFO;
                            line_number     <= line_number + 1;
                            ddr3_address    <= ddr3_address + full_line_len;
                        end
                    end
                end
            endcase
        end
    end
endmodule