module pop_count(
    input [3:0] in,
    output logic [2:0] out
    );
    
    always_comb begin
        out = 3'b000;
        case(in)
            4'b0000:
                out = 3'b000;
            4'b0001:
                out = 3'b001;
            4'b0010:
                out = 3'b001;
            4'b0011:
                out = 3'b010;
            4'b0100:
                out = 3'b001;
            4'b0101:
                out = 3'b010;
            4'b0110:
                out = 3'b010;
            4'b0111:
                out = 3'b011;
            4'b1000:
                out = 3'b001;
            4'b1001:
                out = 3'b010;
            4'b1010:
                out = 3'b010;
            4'b1011:
                out = 3'b011;
            4'b1100:
                out = 3'b010;
            4'b1101:
                out = 3'b011;
            4'b1110:
                out = 3'b011;
            4'b1111:
                out = 3'b100;
        endcase
    end
endmodule 