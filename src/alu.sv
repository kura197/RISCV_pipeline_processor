
`include "lib_pkg.sv";

module alu 
import lib_pkg::*;
#(parameter WIDTH=32)
(
    input alu_type_t alu_type,
    input logic [WIDTH-1:0] in0,
    input logic [WIDTH-1:0] in1,
    output logic [WIDTH-1:0] out
);

///enum [`OP_BIT-1:0] {ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND} op_kind;
always_comb
    case(alu_type)
        ADD: out = in0 + in1;
        SUB: out = in0 - in1;
        SLL: out = in0 << (in1 & 32'b11111);
        SLT: out = {31'd0, signed'(in0) < signed'(in1)};
        SLTU: out = {31'd0, in0 < in1};
        XOR: out = in0 ^ in1;
        SRL: out = in0 >> (in1 & 32'b11111);
        SRA: out = signed'(in0) >>> (in1 & 32'b11111);
        OR: out = in0 | in1;
        AND: out = in0 & in1;
        default: out = 32'dx;
    endcase

endmodule