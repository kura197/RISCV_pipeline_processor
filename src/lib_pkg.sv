
`ifndef LIB_PKG_SV_
`define LIB_PKG_SV_

package lib_pkg;

    typedef enum logic [3:0] {NOP, LUI, AUIPC, JAL, JALR, BRANCH, LOAD, STORE, OPIMM, OP, MISCMEM, SYSTEM} op_type_t;
    typedef enum logic [3:0] {ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND} alu_type_t;
    typedef enum logic [3:0] {BEQ, BNE, BLT, BGE, BLTU, BGEU} cmp_type_t;

    typedef struct packed {
        logic [31:0] instr;
        logic [31:0] pc;
    } bus_stage_f;

    typedef struct packed {
        op_type_t op_type;
        logic [0:0] rf_wr_en;
        logic [4:0] rd;
        logic [4:0] rs1;
        logic [4:0] rs2;
        logic [31:0] rf_rdata1;
        logic [31:0] rf_rdata2;
        logic [2:0] funct3;
        logic [31:0] imm;
        logic [0:0] sel_alu0;
        logic [0:0] sel_alu1;
        alu_type_t alu_type;
        cmp_type_t cmp_type;
        logic [0:0] sel_ex;
        logic [0:0] sel_res;
        logic [0:0] sel_rf_wr;
        logic [31:0] pc;
        logic [31:0] inc_pc;
        logic [3:0] dmem_wr_en;
        logic [0:0] ecall;
    } bus_stage_d;

    typedef struct packed {
        logic [0:0] rf_wr_en;
        logic [4:0] rd;
        logic [31:0] rf_rdata2;
        logic [2:0] funct3;
        logic [0:0] sel_res;
        logic [0:0] sel_rf_wr;
        logic [31:0] ex_out;
        logic [31:0] inc_pc;
        logic [3:0] dmem_wr_en;
        logic [0:0] ecall;
    } bus_stage_e;

    typedef struct packed {
        logic [0:0] rf_wr_en;
        logic [4:0] rd;
        logic [0:0] sel_rf_wr;
        logic [31:0] result;
        logic [31:0] inc_pc;
        logic [0:0] ecall;
    } bus_stage_m;

endpackage

`endif