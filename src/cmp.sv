`include "lib_pkg.sv";

module cmp 
import lib_pkg::*;
#(parameter WIDTH=32)
(
    input cmp_type_t cmp_type,
    input [WIDTH-1:0] in0,
    input [WIDTH-1:0] in1,
    output logic out
);

///typedef enum logic [3:0] {BEQ, BNE, BLT, BGE, BLTU, BGEU} cmp_type_t;
always_comb
    case(cmp_type)
        BEQ: out = in0 == in1;
        BNE: out = in0 != in1;
        BLT: out = signed'(in0) < signed'(in1);
        BGE: out = signed'(in0) >= signed'(in1);
        BLTU: out = in0 < in1;
        BGEU: out = in0 >= in1;
        default: out = 1'bx;
    endcase

endmodule