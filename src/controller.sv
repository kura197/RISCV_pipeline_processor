`include "lib_pkg.sv";

module controller  
import lib_pkg::*;
#()
(
    input op_type_t op_type,
    input op_type_t reg_op_type,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic cmp_res,
    output logic sel_alu0,
    output logic sel_alu1,
    output alu_type_t alu_type,
    output logic sel_ex,
    output logic [3:0] dmem_wr_en,
    output logic sel_res,
    output logic sel_rf_wr,
    output logic rf_wr_en,
    output logic sel_pc,
    output cmp_type_t cmp_type,
    output logic fin
);

/// for debug
assign fin = (op_type == SYSTEM) && ({funct7, funct3} == 10'd0);

/// typedef enum [`INSTR_BIT-1:0] {NOP, LUI, AUIPC, JAL, JALR, BRANCH, LOAD, STORE, OPIMM, OP, MISCMEM, SYSTEM} instr_kind;
/// typedef enum logic [3:0] {ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND} alu_type_t;
/// typedef enum logic [3:0] {BEQ, BNE, BLT, BGE, BLTU, BGEU} cmp_type_t;

//assign sel_pc = (op_type == BRANCH) && cmp_res || op_type == JAL || op_type == JALR;
assign sel_pc = (reg_op_type == BRANCH) && cmp_res || reg_op_type == JAL || reg_op_type == JALR;

///TODO: support don't care signal
always_comb
    case(op_type)
        NOP: begin
            sel_alu0 = 1'b0;
            sel_alu1 = 1'b0;
            sel_ex = 1'b0;
            dmem_wr_en = 4'd0;
            sel_res = 1'b0;
            sel_rf_wr = 1'b0;
            rf_wr_en = 1'b0;
            alu_type = ADD;
            cmp_type = BEQ;
        end
        LUI: begin
            sel_alu0 = 1'b0;
            sel_alu1 = 1'b0;
            sel_ex = 1'b1;  //imm
            dmem_wr_en = 4'd0;
            sel_res = 1'b0;
            sel_rf_wr = 1'b0;
            rf_wr_en = 1'b1;
            //sel_pc = 1'b0;
            alu_type = ADD;
            cmp_type = BEQ;
        end
        AUIPC: begin
            sel_alu0 = 1'b1;
            sel_alu1 = 1'b1;
            sel_ex = 1'b0;
            dmem_wr_en = 4'd0;
            sel_res = 1'b0;
            sel_rf_wr = 1'b0;
            rf_wr_en = 1'b1;
            //sel_pc = 1'b0;
            alu_type = ADD;
            cmp_type = BEQ;
        end
        JAL: begin
            sel_alu0 = 1'b1;    //pc
            sel_alu1 = 1'b1;    //imm
            sel_ex = 1'b0;
            dmem_wr_en = 4'd0;
            sel_res = 1'b0;
            sel_rf_wr = 1'b1;
            rf_wr_en = 1'b1;
            //sel_pc = 1'b1;
            alu_type = ADD;
            cmp_type = BEQ;
        end
        JALR: begin
            sel_alu0 = 1'b0;    //rs1
            sel_alu1 = 1'b1;    //imm
            sel_ex = 1'b0;
            dmem_wr_en = 4'd0;
            sel_res = 1'b0;
            sel_rf_wr = 1'b1;
            rf_wr_en = 1'b1;
            //sel_pc = 1'b1;
            alu_type = ADD;
            cmp_type = BEQ;
        end
        BRANCH: begin
            sel_alu0 = 1'b1;
            sel_alu1 = 1'b1;
            sel_ex = 1'b0;
            dmem_wr_en = 4'd0;
            sel_res = 1'b0;
            sel_rf_wr = 1'b0;
            rf_wr_en = 1'b0;
            //sel_pc = cmp_res;
            alu_type = ADD;
            cmp_type = BEQ;
            case(funct3)
                3'b000: cmp_type = BEQ;
                3'b001: cmp_type = BNE;
                3'b100: cmp_type = BLT;
                3'b101: cmp_type = BGE;
                3'b110: cmp_type = BLTU;
                3'b111: cmp_type = BGEU;
                default: cmp_type = 'x;
            endcase
        end
        LOAD: begin
            sel_alu0 = 1'b0;
            sel_alu1 = 1'b1;
            sel_ex = 1'b0;
            dmem_wr_en = 4'd0;
            sel_res = 1'b1;
            sel_rf_wr = 1'b0;
            rf_wr_en = 1'b1;
            //sel_pc = 1'b0;
            alu_type = ADD;
            cmp_type = BEQ;
        end
        STORE: begin
            sel_alu0 = 1'b0;
            sel_alu1 = 1'b1;
            sel_ex = 1'b0;
            sel_res = 1'b0;
            sel_rf_wr = 1'b0;
            rf_wr_en = 1'b0;
            //sel_pc = 1'b0;
            alu_type = ADD;
            cmp_type = BEQ;
            dmem_wr_en = 4'b1111;
            case(funct3)
                3'b000: dmem_wr_en = 4'b0001;
                3'b001: dmem_wr_en = 4'b0011;
                3'b010: dmem_wr_en = 4'b1111;
                default: dmem_wr_en = 4'x;
            endcase
        end
        OPIMM: begin
            sel_alu0 = 1'b0;
            sel_alu1 = 1'b1;
            sel_ex = 1'b0;
            dmem_wr_en = 4'd0;
            sel_res = 1'b0;
            sel_rf_wr = 1'b0;
            rf_wr_en = 1'b1;
            //sel_pc = 1'b0;
            cmp_type = BEQ;
            case(funct3)
                3'b000: alu_type = ADD;
                3'b010: alu_type = SLT;
                3'b011: alu_type = SLTU;
                3'b100: alu_type = XOR;
                3'b110: alu_type = OR;
                3'b111: alu_type = AND;
                3'b001: alu_type = SLL;
                3'b101: begin
                    if (funct7 == 7'b0000000) alu_type = SRL;
                    else if (funct7 == 7'b0100000) alu_type = SRA;
                    else alu_type = 'x;
                end
                default: alu_type = 'x;
            endcase
        end
        OP: begin
            sel_alu0 = 1'b0;
            sel_alu1 = 1'b0;
            sel_ex = 1'b0;
            dmem_wr_en = 4'd0;
            sel_res = 1'b0;
            sel_rf_wr = 1'b0;
            rf_wr_en = 1'b1;
            //sel_pc = 1'b0;
            alu_type = ADD;
            cmp_type = BEQ;
            case(funct3)
                3'b000: begin
                    if (funct7 == 7'b0000000) alu_type = ADD;
                    else if (funct7 == 7'b0100000) alu_type = SUB;
                    else alu_type = 'x;
                end
                3'b010: alu_type = SLT;
                3'b011: alu_type = SLTU;
                3'b100: alu_type = XOR;
                3'b110: alu_type = OR;
                3'b111: alu_type = AND;
                3'b001: alu_type = SLL;
                3'b101: begin
                    if (funct7 == 7'b0000000) alu_type = SRL;
                    else if (funct7 == 7'b0100000) alu_type = SRA;
                    else alu_type = 'x;
                end
                default: alu_type = 'x;
            endcase
        end
        MISCMEM: begin
            sel_alu0 = 1'b0;
            sel_alu1 = 1'b0;
            sel_ex = 1'b0;
            dmem_wr_en = 4'd0;
            sel_res = 1'b0;
            sel_rf_wr = 1'b0;
            rf_wr_en = 1'b0;
            //sel_pc = 1'b0;
            alu_type = ADD;
            cmp_type = BEQ;
        end
        SYSTEM: begin
            sel_alu0 = 1'b0;
            sel_alu1 = 1'b0;
            sel_ex = 1'b0;
            dmem_wr_en = 4'd0;
            sel_res = 1'b0;
            sel_rf_wr = 1'b0;
            rf_wr_en = 1'b0;
            //sel_pc = 1'b0;
            alu_type = ADD;
            cmp_type = BEQ;
        end
        default: begin
            sel_alu0 = 1'bx;
            sel_alu1 = 1'bx;
            sel_ex = 1'bx;
            dmem_wr_en = 4'dx;
            sel_res = 1'bx;
            sel_rf_wr = 1'bx;
            rf_wr_en = 1'b1;
            //sel_pc = 1'bx;
            alu_type = 'x;
            cmp_type = 'x;
        end
    endcase
    
endmodule