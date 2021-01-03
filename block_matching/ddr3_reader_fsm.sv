module ddr3_reader_fsm #(
    parameter test_mode = 0,
    parameter center_w = 304,
    parameter third_w = 240
    )(
    input               clk,
    input               reset,
    
    input [31:0]        cam_0_start,
    input [1:0]         cam_0_ptr_data,
    input               cam_0_ptr_valid,
    output logic        cam_0_ptr_ready,
    
    input [31:0]        cam_1_start,
    input [1:0]         cam_1_ptr_data,
    input               cam_1_ptr_valid,
    output logic        cam_1_ptr_ready,
    
    output logic [28:0] read_addr_data,
    output logic        read_addr_valid,
    input               read_addr_ready
    );
    
    typedef enum {ST_IDLE, ST_ADD1, ST_ADD2, ST_CHOOSE_NEXT} statetype;
    statetype state;
    
    //Camera 0 = start 0 + 
    /*
    for i in range(8):
        out_addr_left = start[i - 1]/4 + frame_size*(start[i-1]%4) + third_size*2
        out_addr_center = start[i]/4 + frame_size*(start[i]%4) + third_size
        out_addr_right = start[i + 1]/4 + frame_size*(start[i+1]%4)
        
    */
    
    localparam center_pad = (center_w - third_w) / 16 / 2; // start the center third early by this much
    
    const logic [15:0]    center_offset = (third_w / 16) - center_pad;
    const logic [15:0]    right_offset  = third_w * 2 / 16;
    
    //Pointers shifted left 17
    logic                   cam_ptr_ready;
    logic [1:0][26:0]       cam_bases;
    logic [26:0]            out_addr;
    logic [1:0][1:0]        cam_ptrs;
    const logic [3:0][16:0] quarter_sizes = {17'h10E00, 17'h0B400, 17'h05A00, 17'h00000}; // index * 768 * 480 * 2bytes_per_pix / 32bytes_per_addr (index * 737280 / 16)
    const logic [2:0][15:0] third_sizes   = {16'h0000, center_offset, right_offset}; // index * 240 * 2bytes_per_pix / 32bytes_per_addr
    
    logic [2:0] cam_index;
    logic [2:0] center_cam_index;
    logic [1:0] third_index;
    logic [1:0] frame_cntr_reg;
    
    assign cam_0_ptr_ready = cam_ptr_ready;
    assign cam_1_ptr_ready = cam_ptr_ready;
    assign read_addr_valid = (state == ST_CHOOSE_NEXT);
    assign read_addr_data  = {third_index, out_addr};
    
    always @(posedge clk) begin
        if (reset) begin
            cam_ptr_ready   <= 0;
            state           <= ST_IDLE;
            frame_cntr_reg  <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if ((cam_1_ptr_data != frame_cntr_reg) || (test_mode == 1)) begin
                    //if ((cam_1_ptr_valid && cam_0_ptr_valid) || (test_mode == 1)) begin
                        /*if (test_mode == 1) begin
                            cam_bases   <= {cam_1_start[31:5], cam_0_start[31:5]};
                        end else begin
                            cam_bases           <= {cam_1_start[31:5] + (cam_1_ptr_data << 17), cam_0_start[31:5] + (cam_0_ptr_data << 17)};
                        end*/
                        cam_bases           <= {cam_1_start[31:5], cam_0_start[31:5]}; // Pointer is just a counter for now.
                        frame_cntr_reg      <= cam_1_ptr_data;
                        
                        center_cam_index    <= 0;
                        cam_index           <= 7;
                        third_index         <= 0;
                        cam_ptr_ready       <= 1;
                        state               <= ST_ADD1;
                    end
                end
                
                ST_ADD1: begin
                    cam_ptr_ready   <= 0;
                    out_addr        <= cam_bases[cam_index[2]] + quarter_sizes[cam_index[1:0]];
                    state           <= ST_ADD2;
                end
                
                ST_ADD2: begin
                    out_addr    <= out_addr + third_sizes[third_index];
                    state       <= ST_CHOOSE_NEXT;
                end
                
                ST_CHOOSE_NEXT: begin
                    if (read_addr_ready) begin
                        if (third_index == 2'b10) begin
                            if (center_cam_index == 7) begin
                                state   <= ST_IDLE;
                            end else begin
                                center_cam_index    <= center_cam_index + 1;
                                cam_index           <= center_cam_index;
                                third_index         <= 0;
                                state               <= ST_ADD1;
                            end
                        end else begin
                            cam_index   <= cam_index + 1;
                            third_index <= third_index + 1;
                            state       <= ST_ADD1;
                        end
                    end
                end
            endcase
        end
    end
endmodule
        