//`default_nettype none
module filt_bram_reader_writer #(
    parameter width = 120,
    parameter height = 240,
    parameter frame_size = width * height,
    parameter addr_w = $clog2(frame_size),
    parameter disp_bits = 5,
    parameter num_passes = 15
    ) (
        input clk,
        input reset,
        
        input   start,
        input   index_in,
        output  idle,
        
        output [addr_w - 1:0]       rd_addr,
        output                      rd_index,
        input [disp_bits + 15:0]    rd_data,
        
        output [addr_w - 1:0]       wr_addr,
        output                      wr_index,
        output [disp_bits + 15:0]   wr_data,
        output                      wr_ena
    );
    
    logic   index_reg;
    
    logic [$clog2(num_passes):0]    read_pass_cntr; // count down
    logic   read_go;
    logic   read_vertical;
    logic   read_line_first_addr;
    logic   read_line_last_addr;
    logic   read_frame_last_addr;
    logic   read_line_first_addr_d1;
    logic   read_line_last_addr_d1;
    logic   read_frame_last_addr_d1;
    logic   filter_in_valid;
    
    logic   write_vertical;
    logic   wr_frame_last_addr;
    logic   filter_out_valid;
    
    assign idle = (read_pass_cntr == 0);
    assign read_go = (read_pass_cntr != 0);
    assign wr_ena = filter_out_valid;
    assign rd_index = index_reg;
    assign wr_index = index_reg;
    
    bram_addr_calc #(
        .width  (width),
        .height (height)
    ) bram_addr_calc_read (
        .clk                (clk),
        .reset              (reset),
        .go                 (read_go),
        .vertical           (read_vertical),
        .addr               (rd_addr),
        .line_first_addr    (read_line_first_addr),
        .line_last_addr     (read_line_last_addr),
        .frame_last_addr    (read_frame_last_addr)
    );
    
    bram_addr_calc #(
        .width  (width),
        .height (height)
    ) bram_addr_calc_write (
        .clk                (clk),
        .reset              (reset),
        .go                 (filter_out_valid),
        .vertical           (write_vertical),
        .addr               (wr_addr),
        .frame_last_addr    (wr_frame_last_addr)
    );
    
    always @(posedge clk) begin
        if (reset) begin
            index_reg               <= 1'b1;
        
            read_vertical           <= 0;
            read_pass_cntr          <= 0;
            read_line_first_addr_d1 <= 0;
            read_line_last_addr_d1  <= 0;
            read_frame_last_addr_d1 <= 0;
            filter_in_valid         <= 0;
            
            write_vertical          <= 0;
        end else begin
            read_line_first_addr_d1 <= read_line_first_addr;
            read_line_last_addr_d1  <= read_line_last_addr;
            read_frame_last_addr_d1 <= read_frame_last_addr;
            filter_in_valid         <= read_go;
            
            if (read_pass_cntr == 0) begin
                if (start) begin
                    read_pass_cntr  <= num_passes;
                    index_reg       <= index_in;
                end
            end else begin
                // We're running
                if (read_frame_last_addr) begin // End of the frame
                    read_vertical   <= ~read_vertical; // Flip from vert/horiz or vice versa
                    read_pass_cntr  <= read_pass_cntr - 1;
                end
                
                if (wr_frame_last_addr) begin
                    write_vertical  <= ~write_vertical;
                end
            end
        end
    end
    
    // Filters go here
    assign wr_data = rd_data;//{rd_data[disp_bits + 15 : 8], rd_data[7:0] + 1};
    assign filter_out_valid = filter_in_valid;
    
endmodule