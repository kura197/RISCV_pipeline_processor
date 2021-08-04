`include "lib_pkg.sv";

module decoder 
import lib_pkg::*;
#(parameter WIDTH=32)
(
    input logic [WIDTH-1:0] instr,
    output op_type_t op_type,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic [31:0] imm
);

logic [6:0] opcode;
assign opcode = instr[6:0];

always_comb
    case(opcode)
        7'b0110111: begin
            op_type = LUI;
            imm = {instr[31:12], 12'b0};
            rd = instr[11:7];
            funct3 = 0;
            rs1 = 0;
            rs2 = 0;
            funct7 = 0;
        end
        7'b0010111: begin
            op_type = AUIPC;
            imm = {instr[31:12], 12'b0};
            rd = instr[11:7];
            funct3 = 0;
            rs1 = 0;
            rs2 = 0;
            funct7 = 0;
        end
        7'b1101111: begin
            op_type = JAL;
            imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            rd = instr[11:7];
            funct3 = 0;
            rs1 = 0;
            rs2 = 0;
            funct7 = 0;
        end
        7'b1100111: begin
            op_type = JALR;
            imm = {{20{instr[31]}}, instr[31:20]};
            rd = instr[11:7];
            funct3 = instr[14:12];
            rs1 = instr[19:15];
            rs2 = 0;
            funct7 = 0;
        end
        7'b1100011: begin
            op_type = BRANCH;
            imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            rd = 0;
            funct3 = instr[14:12];
            rs1 = instr[19:15];
            rs2 = instr[24:20];
            funct7 = 0;
        end
        7'b0000011: begin
            op_type = LOAD;
            imm = {{20{instr[31]}}, instr[31:20]};
            rd = instr[11:7];
            funct3 = instr[14:12];
            rs1 = instr[19:15];
            rs2 = 0;
            funct7 = 0;
        end
        7'b0100011: begin
            op_type = STORE;
            imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            rd = 0;
            funct3 = instr[14:12];
            rs1 = instr[19:15];
            rs2 = instr[24:20];
            funct7 = 0;
        end
        7'b0010011: begin
            op_type = OPIMM;
            imm = {{20{instr[31]}}, instr[31:20]};
            rd = instr[11:7];
            funct3 = instr[14:12];
            rs1 = instr[19:15];
            rs2 = 0;
            funct7 = instr[31:25];
        end
        7'b0110011: begin
            op_type = OP;
            imm = 32'dx;
            rd = instr[11:7];
            funct3 = instr[14:12];
            rs1 = instr[19:15];
            rs2 = instr[24:20];
            funct7 = instr[31:25];
        end
        7'b0001111: begin
            op_type = MISCMEM;
            imm = 32'dx;
            rd = 0;
            funct3 = 0;
            rs1 = 0;
            rs2 = 0;
            funct7 = 0;
        end
        7'b1110011: begin
            op_type = SYSTEM;
            imm = 32'dx;
            rd = 0;
            funct3 = instr[14:12];
            rs1 = 0;
            rs2 = 0;
            funct7 = instr[31:25];
        end
        default: begin
            op_type = 4'dx;
            imm = 32'dx;
            rd = 'x;
            funct3 = 'x;
            rs1 = 'x;
            rs2 = 'x;
            funct7 = 'x;
        end
    endcase

endmodule