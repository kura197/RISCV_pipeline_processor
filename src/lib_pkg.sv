
`ifndef LIB_PKG_SV_
`define LIB_PKG_SV_

package lib_pkg;

    typedef enum logic [3:0] {LUI, AUIPC, JAL, JALR, BRANCH, LOAD, STORE, OPIMM, OP, MISCMEM, SYSTEM} op_type_t;

    typedef enum logic [3:0] {ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND} alu_type_t;

    typedef enum logic [3:0] {BEQ, BNE, BLT, BGE, BLTU, BGEU} cmp_type_t;

endpackage

`endif