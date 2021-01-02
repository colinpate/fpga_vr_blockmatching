module block_match_new #(
    parameter rd_port_w = 8,
    parameter block_width = 16,
    parameter block_height = 16,
    parameter search_blk_w = 64,
    parameter search_blk_h = 16,
    parameter third_w = 240,
    parameter center_w = 304
    )
    (
        input           clk,
        input           reset,
        input           start,
        output logic    done,
        
        output logic [15:0]     blk_rd_addr,
        input [rd_port_w - 1:0] blk_rd_data,
        
        output logic            srch_read,
        output logic [15:0]     srch_rd_addr,
        input [rd_port_w - 1:0] srch_rd_data,
        
        input [15:0]            blk_start_address,
        input [15:0]            srch_start_address,
        input [15:0]            blk_index,
        
        output logic [block_width*block_height - 1:0]          blk_block,
        output logic [block_width*block_height - 1:0]          srch_block,
        output logic [15:0]                                 coords_out,
        output logic [15:0]                                 blk_index_o,
        output logic                                        blks_valid
    );
    
    localparam blk_addr_w = block_width / rd_port_w;
    localparam srch_addr_w = search_blk_w / rd_port_w;
    localparam third_addr_w = third_w / rd_port_w;
    localparam blk_addr_row_inc = third_addr_w - blk_addr_w + 1;
    localparam center_addr_w = center_w / rd_port_w;
    localparam srch_addr_row_inc = center_addr_w - srch_addr_w + 1;
    
    typedef enum {ST_SRCH_IDLE, ST_FILL_SRCH, ST_WAIT_SHIFT} statetype_srchfiller;
    statetype_srchfiller srchfill_state;
    
    typedef enum {ST_BLK_IDLE, ST_FILL_BLK, ST_BLK_DONE} statetype_blkfiller;
    statetype_blkfiller blkfill_state;
    
    typedef enum {ST_IDLE, ST_WAIT_FILL, ST_WAIT_SRCH_LEFT, ST_SHIFT_LEFT_PREP, ST_SHIFT_LEFT, ST_WAIT_SRCH_RIGHT, ST_SHIFT_RIGHT, ST_DONE} statetype_rowshifter;
    statetype_rowshifter rowshifter_state;
    
    logic [block_height - 1:0][block_width - 1:0] blk_block_i;
    logic [block_height - 1:0][block_width - 1:0] srch_block_i;
    assign blk_block = blk_block_i;
    assign srch_block = srch_block_i;
    
    logic [block_height - 1:0][search_blk_w - 1:0] srch_area;
    logic [search_blk_w - 1:0]  srch_area_next_row;
    
    always_comb begin
        for (int i = 0; i < block_height; i++) begin
            srch_block_i[i] = srch_area[i][block_width - 1:0];
        end
    end
    
    logic [7:0] blk_rd_row;
    logic [7:0] blk_rd_col;
    logic blk_read;
    logic blk_rdv;
    logic [7:0] srch_rd_row;
    logic [7:0] srch_rd_col;
    logic [31:0] srch_start_address_i;
    logic [31:0] blk_start_address_i;
    //logic srch_read;
    logic srch_rdv;
    logic [blk_addr_w - 1:0]    blk_line_valid;
    logic [srch_addr_w - 1:0]   srch_line_valid;
    logic srch_read_rev;
    
    logic [7:0] shift_col;
    logic [7:0] shift_row;
    
    logic start_flop;
    
    assign done = (rowshifter_state == ST_IDLE);
    
    logic [block_width - 1:0] next_blk_line;
    generate
        if (block_width == rd_port_w) begin
            assign next_blk_line = blk_rd_data;
        end else begin
            assign next_blk_line[block_width - 1:block_width - rd_port_w] = blk_rd_data;
            assign next_blk_line[block_width - rd_port_w - 1:0] = blk_block_i[block_height - 1][block_width - 1:rd_port_w];
        end
    endgenerate
    
    always @(posedge clk)
    begin
        if (reset) begin
            blkfill_state       <= ST_BLK_IDLE;
            blk_read            <= 0;
            blk_rdv             <= 0;
            blk_line_valid      <= 0;
        end else begin
            blk_rdv <= blk_read;
            
            if (blk_rdv) begin
                //blk_block_i[block_height - 1][block_width - 1:block_width - rd_port_w]  <= blk_rd_data;
                //blk_block_i[block_height - 1][block_width - rd_port_w - 1:0]            <= blk_block_i[block_height - 1][block_width - 1:rd_port_w];
                blk_block_i[block_height - 1]       <= next_blk_line;
                if (block_width > rd_port_w) begin // If this isn't true, blk_line_valid is 1 bit so we shift every time
                    blk_line_valid[blk_addr_w - 1]      <= 1'b1;
                    if (&blk_line_valid) begin
                        blk_line_valid[blk_addr_w - 2:0]    <= 0;
                        blk_block_i[block_height - 2:0]         <= blk_block_i[block_height - 1:1];
                    end else begin
                        blk_line_valid[blk_addr_w - 2:0]    <= blk_line_valid[blk_addr_w - 1:1];
                    end
                end else begin
                    blk_block_i[block_height - 2:0]         <= blk_block_i[block_height - 1:1];
                end
            end
            
            case (blkfill_state)
                ST_BLK_IDLE: begin
                    if (rowshifter_state == ST_WAIT_FILL) begin
                        blk_rd_row      <= 0;
                        blk_rd_col      <= 0;
                        blk_rd_addr     <= blk_start_address_i;
                        blk_read        <= 1;
                        blk_line_valid  <= 0;
                        blkfill_state   <= ST_FILL_BLK;
                    end
                end
                
                ST_FILL_BLK: begin
                    if (blk_rd_col == (blk_addr_w - 1)) begin
                        blk_rd_col  <= 0;
                        if (blk_rd_row == (block_height - 1)) begin
                            blk_rd_row      <= 0;
                            blk_read        <= 0;
                            blkfill_state   <= ST_BLK_DONE;
                        end else begin
                            blk_rd_row      <= blk_rd_row + 1;
                            blk_read        <= 1;
                            blk_rd_addr     <= blk_rd_addr + blk_addr_row_inc;
                        end
                    end else begin
                        blk_rd_col  <= blk_rd_col + 1;
                        blk_read    <= 1;
                        blk_rd_addr <= blk_rd_addr + 1;
                    end
                end
                
                ST_BLK_DONE: begin
                    if (rowshifter_state != ST_WAIT_FILL) begin
                        blkfill_state   <= ST_BLK_IDLE;
                    end
                end
            endcase
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            srchfill_state      <= ST_SRCH_IDLE;
            srch_read           <= 0;
            srch_rdv            <= 0;
            //srch_line_valid     <= 0;
            srch_read_rev <= 0;
        end else begin
            srch_rdv <= srch_read;
            
            /*if (srch_rdv) begin
                srch_area_next_row[search_blk_w - 1:search_blk_w - rd_port_w]   <= srch_rd_data;
                srch_line_valid[srch_addr_w - 1]      <= 1'b1;
                if (&srch_line_valid) begin
                    srch_line_valid[srch_addr_w - 2:0]  <= 0;
                    srch_area[block_size - 1:0]        <= {srch_area_next_row, srch_area[block_size - 1:1]};
                end else begin
                    srch_line_valid[srch_addr_w - 2:0]                  <= srch_line_valid[srch_addr_w - 1:1];
                    srch_area_next_row[search_blk_w - rd_port_w - 1:0]  <= srch_area_next_row[search_blk_w - 1:rd_port_w];
                end
            end*/
            
            case (srchfill_state)
                ST_SRCH_IDLE: begin
                    if (rowshifter_state == ST_WAIT_FILL) begin
                        srch_rd_row     <= 0;
                        srch_rd_col     <= 0;
                        srch_rd_addr    <= srch_start_address_i;
                        srch_read       <= 1;
                        srchfill_state  <= ST_FILL_SRCH;
                    end
                end
                
                ST_FILL_SRCH: begin
                    if (srch_rd_col == (srch_addr_w - 1)) begin
                        srch_rd_col  <= 0;
                        if (srch_rd_row == (search_blk_h - 1)) begin
                            srch_read       <= 0;
                            srchfill_state  <= ST_SRCH_IDLE;
                        end else begin
                            srch_rd_row      <= srch_rd_row + 1;
                            
                            if ((srch_rd_row >= (block_height - 1)) && (srch_rd_row[0])) begin
                                srch_read_rev   <= 1;
                                srch_rd_addr    <= srch_rd_addr + srch_addr_row_inc + (srch_addr_w - blk_addr_w);
                            end else begin
                                srch_read_rev   <= 0;
                                if (srch_read_rev) begin
                                    srch_rd_addr    <= srch_rd_addr + srch_addr_row_inc + blk_addr_w;
                                end else begin
                                    srch_rd_addr    <= srch_rd_addr + srch_addr_row_inc;
                                end
                            end
                            
                            if (srch_rd_row >= (block_height)) begin
                                srch_read        <= 0;
                                srchfill_state   <= ST_WAIT_SHIFT;
                            end else begin
                                srch_read        <= 1;
                            end
                        end
                    end else begin
                        srch_rd_col  <= srch_rd_col + 1;
                        srch_read    <= 1;
                        if ((srch_read_rev) && (srch_rd_col == (blk_addr_w - 1))) begin
                            srch_rd_addr    <= srch_rd_addr - srch_addr_w + 1;
                        end else begin
                            srch_rd_addr <= srch_rd_addr + 1;
                        end
                    end
                end
                    
                ST_WAIT_SHIFT: begin
                    if ((rowshifter_state == ST_WAIT_SRCH_LEFT) || (rowshifter_state == ST_WAIT_SRCH_RIGHT)) begin
                        srchfill_state  <= ST_FILL_SRCH;
                        srch_read       <= 1;
                    end
                end
            endcase
        end
    end
    
    assign coords_out = {shift_row, shift_col};
    assign blks_valid = (rowshifter_state == ST_SHIFT_RIGHT) || (rowshifter_state == ST_SHIFT_LEFT);
    
    always @(posedge clk) begin
        if (reset) begin
            rowshifter_state    <= ST_IDLE;
            shift_col           <= 0;
            shift_row           <= 0;
            //blks_valid          <= 0;
            blk_index_o         <= 0;
            start_flop          <= 0;
            srch_line_valid     <= 0;
        end else begin
            start_flop  <= start;
            
            if (srch_rdv) begin
                srch_area_next_row[search_blk_w - 1:search_blk_w - rd_port_w]   <= srch_rd_data;
                srch_area_next_row[search_blk_w - rd_port_w - 1:0]              <= srch_area_next_row[search_blk_w - 1:rd_port_w];
                srch_line_valid[srch_addr_w - 1]      <= 1'b1;
                if (&srch_line_valid) begin
                    srch_line_valid[srch_addr_w - 2:0]  <= 0;
                    srch_area[block_height - 1:0]       <= {srch_area_next_row, srch_area[block_height - 1:1]};
                end else begin
                    srch_line_valid[srch_addr_w - 2:0]                  <= srch_line_valid[srch_addr_w - 1:1];
                end
            end
            
            case (rowshifter_state)
                ST_IDLE: begin
                    //blks_valid  <= 0;
                    if (start_flop) begin
                        srch_start_address_i    <= srch_start_address;
                        blk_start_address_i     <= blk_start_address;
                        rowshifter_state        <= ST_WAIT_FILL;
                        srch_line_valid         <= 0;
                        blk_index_o             <= blk_index;
                    end
                end
                
                ST_WAIT_FILL: begin
                    if ((blkfill_state == ST_BLK_DONE) && (srchfill_state == ST_WAIT_SHIFT)) begin
                        shift_col           <= 0;
                        shift_row           <= 0;
                        rowshifter_state    <= ST_SHIFT_RIGHT;
                    end
                end
                
                ST_SHIFT_RIGHT: begin
                    for (int i = 0; i < block_height; i++) begin
                        srch_area[i] <= {srch_area[i][0], srch_area[i][search_blk_w - 1:1]};
                    end
                    //blks_valid  <= 1;
                    //coords_out  <= {shift_row, shift_col};
                    
                    if (shift_col == (search_blk_w - block_width - 1)) begin
                        if (shift_row == (search_blk_h - 1 - block_height)) begin
                            rowshifter_state    <= ST_IDLE;
                        end else begin
                            shift_row           <= shift_row + 1;
                            rowshifter_state    <= ST_WAIT_SRCH_LEFT;
                        end
                    end else begin
                        shift_col   <= shift_col + 1;
                        /*for (int i = 0; i < block_size; i++) begin
                            srch_area[i] <= {srch_area[i][0], srch_area[i][search_blk_w - 1:1]};
                        end*/
                    end
                end
                
                ST_WAIT_SRCH_LEFT: begin
                    //blks_valid  <= 0;
                    if (srch_rdv) begin // shift left 1 early
                        rowshifter_state    <= ST_SHIFT_LEFT_PREP;
                    end
                end
                
                ST_SHIFT_LEFT_PREP: begin
                    for (int i = 0; i < block_height; i++) begin
                        srch_area[i] <= {srch_area[i][search_blk_w - 2:0], srch_area[i][search_blk_w - 1]};
                    end
                    rowshifter_state    <= ST_SHIFT_LEFT;
                end
                    
                
                ST_SHIFT_LEFT: begin
                    /*for (int i = 0; i < block_size; i++) begin
                        srch_area[i] <= {srch_area[i][search_blk_w - 2:0], srch_area[i][search_blk_w - 1]};
                    end*/
                    //blks_valid  <= 1;
                    //coords_out  <= {shift_row, shift_col};
                    
                    if (shift_col == 0) begin
                        if (shift_row == (search_blk_h - block_height - 1)) begin
                            rowshifter_state    <= ST_IDLE;
                        end else begin
                            shift_row           <= shift_row + 1;
                            rowshifter_state    <= ST_WAIT_SRCH_RIGHT;
                        end
                    end else begin
                        shift_col   <= shift_col - 1;
                        for (int i = 0; i < block_height; i++) begin
                            srch_area[i] <= {srch_area[i][search_blk_w - 2:0], srch_area[i][search_blk_w - 1]};
                        end
                    end
                end
                
                ST_WAIT_SRCH_RIGHT: begin
                    //blks_valid  <= 0;
                    if (srch_rdv) begin
                        rowshifter_state    <= ST_SHIFT_RIGHT;
                    end
                end
            endcase
        end
    end
endmodule