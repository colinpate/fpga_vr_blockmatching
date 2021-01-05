module filter_and_pad_bank #(
    parameter disp_bits = 5,
    parameter line_len = 120,
    parameter num_filters = 4,
    parameter filter_radius = 2
    ) (
        input       clk,
        input       reset,
    
        input [7 + disp_bits:0] disp_conf_in,
        input [7:0]             conf_in,
        input                   conf_in_valid,
        
        output [7 + disp_bits:0]    disp_conf_out,
        output [7:0]                conf_out,
        output                      conf_out_valid
    );
    
    // How long is the combined filter's impulse response
    localparam overall_len = 1 + (num_filters * ((filter_radius * 2) - 1)); 
    localparam overall_rad = overall_len / 2;
    localparam c_width = 8;
    localparam cd_width = 8 + disp_bits;
    
    typedef enum {ST_IN_REC, ST_IN_PAD} statetype_in;
    statetype_in in_state;
    
    typedef enum {ST_OUT_HEAD, ST_OUT_SEND, ST_OUT_FOOT} statetype_out;
    statetype_out out_state;
    
    
    logic [c_width - 1:0]   conf_result;
    logic [cd_width - 1:0]  conf_dist_result;
    
    logic [num_filters - 1:0][cd_width - 1:0]   cd_filter_inputs;
    logic [num_filters - 1:0]                   cd_f_in_valid;
    logic [num_filters - 1:0][cd_width - 1:0]   cd_filter_outputs;
    logic [num_filters - 1:0]                   cd_f_out_valid;
    
    logic [num_filters - 1:0][c_width - 1:0]    c_filter_inputs;
    logic [num_filters - 1:0][c_width - 1:0]    c_filter_outputs;
    
    logic fifo_empty;
    logic fifo_rdreq;
    logic fifo_out_valid;
    logic [7 + disp_bits:0] fifo_disp_conf_out;
    logic [7:0]             fifo_conf_out;
    logic [$clog2(line_len) - 1:0]      in_rec_counter;
    logic [$clog2(overall_len) - 1:0]   in_pad_counter;
    
    scfifo_wrapper #(
        .depth  (line_len),
        .width  (8 + 8 + disp_bits)
    ) dfpf ( // Showahead, at least line length deep
        .clock  (clk),
        .data   ({disp_conf_in, conf_in}),
        .rdreq  (fifo_rdreq),
        .sclr   (reset),
        .empty  (fifo_empty),
        .wrreq  (conf_in_valid),
        .q      ({fifo_disp_conf_out, fifo_conf_out})
    );
    
    assign fifo_rdreq = (in_state == ST_IN_REC);
    assign fifo_out_valid = fifo_rdreq && (~fifo_empty);
    assign cd_f_in_valid[0] = (in_state == ST_IN_PAD) || fifo_out_valid;
    assign cd_filter_inputs[0] = (in_state == ST_IN_PAD) ? 0 : fifo_disp_conf_out;
    assign c_filter_inputs[0] = (in_state == ST_IN_PAD) ? 0 : fifo_conf_out;
    
    always @(posedge clk) begin
        if (reset) begin
            in_state        <= ST_IN_REC;
            in_rec_counter  <= 0;
            in_pad_counter  <= 0;
        end else begin
            case (in_state)
                ST_IN_REC: begin
                    if (fifo_out_valid) begin
                        if (in_rec_counter == (line_len - 1)) begin
                            in_state        <= ST_IN_PAD;
                            in_rec_counter  <= 0;
                        end else begin
                            in_rec_counter  <= in_rec_counter + 1;
                        end
                    end
                end
                
                ST_IN_PAD: begin
                    if (in_pad_counter == (overall_len - 1)) begin
                        in_state        <= ST_IN_REC;
                        in_pad_counter  <= 0;
                    end else begin
                        in_pad_counter  <= in_pad_counter + 1;
                    end
                end
            endcase
        end
    end
    
    genvar i;
    generate
        for (i = 1; i < num_filters; i += 1) begin
            assign cd_filter_inputs[i] = cd_filter_outputs[i - 1];
            assign c_filter_inputs[i] = c_filter_outputs[i - 1];
            assign cd_f_in_valid[i] = cd_f_out_valid[i - 1];
        end
    endgenerate
    
    boxcar_filter #(
        .radius (filter_radius),
        .bits   (cd_width)
    ) cd_filter[num_filters - 1:0](
        .clk                    (clk),
        .reset                  (reset),
        .pixel                  (cd_filter_inputs),
        .pixel_valid            (cd_f_in_valid),
        .local_average          (cd_filter_outputs),
        .local_average_valid    (cd_f_out_valid)
    );
    
    boxcar_filter #(
        .radius (filter_radius),
        .bits   (c_width)
    ) c_filter[num_filters - 1:0](
        .clk                    (clk),
        .reset                  (reset),
        .pixel                  (c_filter_inputs),
        .pixel_valid            (cd_f_in_valid),
        .local_average          (c_filter_outputs),
        .local_average_valid    ()
    );
    
    logic [$clog2(overall_len) - 1:0]   out_pad_counter;
    logic [$clog2(line_len) - 1:0]      out_send_counter;
    
    assign conf_out_valid = cd_f_out_valid[num_filters - 1] && (out_state == ST_OUT_SEND);
    assign disp_conf_out = cd_filter_outputs[num_filters - 1];
    assign conf_out = c_filter_outputs[num_filters - 1];
    
    always @(posedge clk) begin
        if (reset) begin
            out_state           <= ST_OUT_HEAD;
            out_send_counter    <= 0;
            out_pad_counter     <= 0;
        end else begin
            case (out_state)
                ST_OUT_HEAD: begin
                    if (cd_f_out_valid[num_filters - 1]) begin
                        out_pad_counter <= out_pad_counter + 1;
                        if (out_pad_counter == (overall_rad - 1)) begin
                            out_state       <= ST_OUT_SEND;
                        end
                    end
                end
                
                ST_OUT_SEND: begin
                    if (cd_f_out_valid[num_filters - 1]) begin
                        if (out_send_counter == (line_len - 1)) begin
                            out_state           <= ST_OUT_FOOT;
                            out_send_counter    <= 0;
                        end else begin
                            out_send_counter    <= out_send_counter + 1;
                        end
                    end
                end
                
                ST_OUT_FOOT: begin
                    if (cd_f_out_valid[num_filters - 1]) begin
                        if (out_pad_counter == (overall_len - 1)) begin
                            out_state       <= ST_OUT_HEAD;
                            out_pad_counter <= 0;
                        end else begin
                            out_pad_counter <= out_pad_counter + 1;
                        end
                    end
                end
            endcase
        end
    end
    
endmodule
                