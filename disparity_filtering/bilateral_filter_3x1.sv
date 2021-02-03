module bilateral_filter_3x1 #(
    parameter disp_bits = 5,
    parameter gray_threshold = 5
    )   (
        input                       clk,
        input                       reset,
        
        input [disp_bits - 1:0]     disparity_in,
        input [7:0]                 confidence_in,
        input [7:0]                 gray_in,
        input                       first_pixel_in_line,
        input                       last_pixel_in_line,
        input                       last_pixel_in_frame,
        input                       in_valid,
        
        output [7:0]                disparity_out,
        output [7:0]                confidence_out,
        output [7:0]                gray_out,
        output                      out_valid
    );
    
    /* The pipeline
    
    We have shift registers shifting downwards. 2 first, then 1, then 0 is oldest
    
    If first_in_line in center, ignore [0]. Shift in normally. Output becomes valid when second pixel is shifted in
    If last_in_line in center, ignore [2]
    
    
    */
    
    int i;
    
    // Pipeline stage 0
    logic [7:0]                     gray_in_adj;
    
    // Clamp gray_in to be between (threshold, 255 - threshold)
    //  so we can't overflow or underflow when checking the grayscale matchingness
    //assign gray_in_lo_bound = 
    //assign gray_in_up_bound = 
    //assign gray_in_adj = gray_in < gray_threshold ? gray_threshold : 
    //                     gray_in > (255 - gray_threshold) ? (255 - gray_threshold) : gray_in;
    
    // Pipeline stage 1
    logic [2:0]                     first_sreg;
    logic [2:0]                     last_sreg;
    logic [2:0]                     frame_last_sreg;
    logic [2:0]                     valid_sreg;
    logic [2:0][7:0]                gray_sreg;
    logic [2:0][7:0]                conf_sreg;
    logic [2:0][disp_bits - 1:0]    disp_sreg;
    logic                           sregs_valid;
    logic [7:0]                     gray_upbound_reg; // Corresponds to the first gray pixel ([2] in the sreg)
    logic [7:0]                     gray_lobound_reg;
    logic [7:0]                     gray_upbound_reg_d1; // Corresponds to the center gray pixel ([1] in the sreg)
    logic [7:0]                     gray_lobound_reg_d1;
    
    logic                           ignore_0;
    logic                           ignore_2;
    logic                           gray_ignore_2;
    logic                           gray_ignore_0;
    logic [1:0]                     valid_count;
    
    assign gray_ignore_0 = (gray_sreg[0] > gray_upbound_reg_d1) || (gray_sreg[0] < gray_lobound_reg_d1);
    assign gray_ignore_2 = (gray_sreg[2] > gray_upbound_reg_d1) || (gray_sreg[2] < gray_lobound_reg_d1);
    assign ignore_0 = first_sreg[1] || gray_ignore_0;
    assign ignore_2 = last_sreg[1] || gray_ignore_2;
    assign valid_count = 3 - ignore_0 - ignore_2;
    
    // Pipeline stage 2
    logic [2:0][7:0]                gray_sreg_d1;
    logic [2:0][7 + disp_bits:0]    conf_disp_reg;
    logic [2:0][7 + disp_bits:0]    conf_reg_d1;
    logic                           sregs_valid_d1;
    logic [1:0]                     valid_count_d1;
    
    // Pipeline stage 3
    logic [9 + disp_bits:0]         conf_disp_acc;
    logic [9:0]                     conf_acc;
    logic [7:0]                     gray_d2;
    logic [1:0]                     valid_count_d2;
    logic                           accs_valid;
    
    
    // Pipeline stage infinity
    assign out_valid = accs_valid;
    assign gray_out = gray_d2;
    assign disparity_out = conf_disp_acc / conf_acc;
    assign confidence_out = conf_acc / valid_count_d2; 
    
    always @(posedge clk) begin
        if (reset) begin
            first_sreg      <= 0;
            last_sreg       <= 0;
            frame_last_sreg <= 0;
            valid_sreg      <= 0;
            gray_sreg       <= 0;
            conf_sreg       <= 0;
            disp_sreg       <= 0;
            sregs_valid     <= 0;
            gray_lobound_reg    <= 0;
            gray_upbound_reg    <= 0;
            gray_upbound_reg_d1 <= 0;
            gray_lobound_reg_d1 <= 0;
            
            gray_sreg_d1    <= 0;
            conf_reg_d1     <= 0;
            conf_disp_reg   <= 0;
            sregs_valid_d1  <= 0;
            valid_count_d1  <= 0;
            
            conf_disp_acc   <= 0;
            conf_acc        <= 0;
            gray_d2         <= 0;
            valid_count_d2  <= 0;
            accs_valid      <= 0;
        end else begin
            sregs_valid     <= 1'b0;
            sregs_valid_d1  <= 1'b0;
            accs_valid      <= 1'b0;
            // Pipeline stage 1
            if (in_valid || frame_last_sreg[2]) begin
                first_sreg      <= {first_pixel_in_line, first_sreg[2:1]};
                last_sreg       <= {last_pixel_in_line, last_sreg[2:1]};
                frame_last_sreg <= {last_pixel_in_frame, frame_last_sreg[2:1]};
                gray_sreg       <= {gray_in, gray_sreg[2:1]};
                conf_sreg       <= {confidence_in, conf_sreg[2:1]};
                disp_sreg       <= {disparity_in, disp_sreg[2:1]};
                valid_sreg      <= {in_valid, valid_sreg[2:1]};
                sregs_valid     <= 1'b1;
                
                gray_lobound_reg    <= (gray_in < gray_threshold) ? 0 : (gray_in - gray_threshold);
                gray_upbound_reg    <= (gray_in > (255 - gray_threshold)) ? 255 : (gray_in + gray_threshold);
                gray_lobound_reg_d1 <= gray_lobound_reg;
                gray_upbound_reg_d1 <= gray_upbound_reg;
            end
            
            if (sregs_valid) begin
                if (valid_sreg[1]) begin
                    gray_sreg_d1 <= gray_sreg;
                    
                    conf_disp_reg[2]    <= ignore_2 ? 0 : (conf_sreg[2] * disp_sreg[2]);
                    conf_disp_reg[1]    <= conf_sreg[1] * disp_sreg[1];
                    conf_disp_reg[0]    <= ignore_0 ? 0 : (conf_sreg[0] * disp_sreg[0]);
                    
                    conf_reg_d1[2]      <= ignore_2 ? 0 : conf_sreg[2];
                    conf_reg_d1[1]      <= conf_sreg[1];
                    conf_reg_d1[0]      <= ignore_0 ? 0 : conf_sreg[0];
                    
                    valid_count_d1      <= valid_count;
                    
                    sregs_valid_d1      <= 1'b1;
                end
            end
            
            if (sregs_valid_d1) begin
                valid_count_d2  <= valid_count_d1;
                conf_acc        <= conf_reg_d1[2] + conf_reg_d1[1] + conf_reg_d1[0];
                conf_disp_acc   <= conf_disp_reg[2] + conf_disp_reg[1] + conf_disp_reg[0];
                gray_d2         <= gray_sreg_d1[1];
                accs_valid      <= 1;
            end
        end
    end
endmodule