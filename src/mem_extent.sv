`include "lib_pkg.sv";

module mem_extent
import lib_pkg::*;
#(parameter WIDTH=32)
(
    input logic load,
    input logic [2:0] funct3,
    input logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out
);

/// typedef enum [`INSTR_BIT-1:0] {LUI, AUIPC, JAL, JALR, BRANCH, LOAD, STORE, OPIMM, OP, MISCMEM, SYSTEM} instr_kind;
always_comb
    if(load)
        case(funct3)
            3'b000: out = {{24{in[7]}}, in[7:0]};
            3'b001: out = {{16{in[15]}}, in[15:0]};
            3'b010: out = in;
            3'b100: out = {24'd0, in[7:0]};
            3'b101: out = {16'd0, in[15:0]};
            default: out = 32'dx;
        endcase
    else
        out = in;

endmodule