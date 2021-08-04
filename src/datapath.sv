`include "lib_pkg.sv";

module datapath 
import lib_pkg::*;
#(parameter WIDTH=32, IADDR=10, DADDR=10)
(
    input logic clk,
    input logic reset_n,
    input logic [WIDTH-1:0] init_pc,
    output op_type_t op_type,
    output op_type_t reg_op_type,
    output logic [2:0] funct3_d,
    output logic [2:0] funct3_m,
    output logic [6:0] funct7_d,
    output logic [IADDR-1:0] imem_addr,
    input logic [WIDTH-1:0] imem_rdata,
    output logic [DADDR-1:0] dmem_addr,
    output logic [WIDTH-1:0] dmem_wdata,
    input logic [WIDTH-1:0] dmem_rdata,
    input logic sel_alu0,
    input logic sel_alu1,
    input alu_type_t alu_type,
    input logic sel_ex,
    input logic sel_res,
    input logic sel_rf_wr,
    input logic rf_wr_en,
    input logic sel_pc,
    input cmp_type_t cmp_type,
    output logic cmp_out,
    input logic [1:0] sel_rdata1_f,
    input logic [1:0] sel_rdata2_f,
    output logic [4:0] rd_ex, 
    output logic [4:0] rd_mem, 
    output logic [4:0] rd_wb, 
    output logic [4:0] rs1_dec, 
    output logic [4:0] rs2_dec, 
    output logic [4:0] rs1_ex, 
    output logic [4:0] rs2_ex, 
    output logic mem_to_reg_ex,
    output logic mem_to_reg_m,
    input logic load_hazard,
    input logic [3:0] dmem_wr_en_dec,
    output logic [3:0] dmem_wr_en,
    input logic ecall,
    output logic fin
);

localparam RFADDR = 5;

logic [WIDTH-1:0] pc, next_pc, inc_pc;
logic [WIDTH-1:0] instr;
logic [WIDTH-1:0] imm;
logic [RFADDR-1:0] rs1, rs2, rd;
logic [WIDTH-1:0] rf_rdata1, rf_rdata2, rf_wdata;
logic [WIDTH-1:0] rf_rdata1_f, rf_rdata2_f;
logic [WIDTH-1:0] alu_in0, alu_in1, alu_out;
logic [WIDTH-1:0] ex_out;
logic [WIDTH-1:0] result;
logic flush_f, flush_d, flush_e;
logic stall_f, stall_d;

bus_stage_f stage_f, reg_stage_f;
bus_stage_d stage_d, reg_stage_d;
bus_stage_e stage_e, reg_stage_e;
bus_stage_m stage_m, reg_stage_m;

assign stage_f = '{
                instr: instr,
                pc: pc
                };

assign stage_d = '{
                op_type: op_type,
                rf_wr_en: rf_wr_en,
                rs1: rs1,
                rs2: rs2,
                rd: rd,
                funct3: funct3_d,
                rf_rdata1: rf_rdata1,
                rf_rdata2: rf_rdata2,
                imm: imm,
                sel_alu0: sel_alu0,
                sel_alu1: sel_alu1,
                alu_type: alu_type,
                cmp_type: cmp_type,
                sel_ex: sel_ex,
                sel_res: sel_res,
                sel_rf_wr: sel_rf_wr,
                pc: reg_stage_f.pc,
                inc_pc: pc, /// reg_stage_f.pc + 4
                dmem_wr_en: dmem_wr_en_dec,
                ecall: ecall
                };

assign stage_e = '{
                rf_wr_en: reg_stage_d.rf_wr_en,
                rd: reg_stage_d.rd,
                rf_rdata2: rf_rdata2_f,
                funct3: reg_stage_d.funct3,
                sel_res: reg_stage_d.sel_res,
                sel_rf_wr: reg_stage_d.sel_rf_wr,
                ex_out: ex_out,
                inc_pc: reg_stage_d.inc_pc,
                dmem_wr_en: reg_stage_d.dmem_wr_en,
                ecall: reg_stage_d.ecall
                };

assign stage_m = '{
                rf_wr_en: reg_stage_e.rf_wr_en,
                rd: reg_stage_e.rd,
                sel_rf_wr: reg_stage_e.sel_rf_wr,
                result: result,
                inc_pc: reg_stage_e.inc_pc,
                ecall: reg_stage_e.ecall
                };

assign inc_pc = pc + 4;
assign imem_addr = pc[IADDR-1:0];
assign instr = imem_rdata;
assign dmem_addr = reg_stage_e.ex_out[DADDR-1:0];
assign dmem_wdata = reg_stage_e.rf_rdata2;
assign funct3_m = reg_stage_e.funct3;
assign fin = reg_stage_m.ecall;

assign rd_ex = reg_stage_d.rd;
assign rd_mem = reg_stage_e.rd;
assign rd_wb = reg_stage_m.rd;
assign rs1_dec = rs1;
assign rs2_dec = rs2;
assign rs1_ex = reg_stage_d.rs1;
assign rs2_ex = reg_stage_d.rs2;
assign mem_to_reg_ex = reg_stage_d.sel_res;
assign mem_to_reg_m = reg_stage_e.sel_res;
assign dmem_wr_en = reg_stage_e.dmem_wr_en;
assign reg_op_type = reg_stage_d.op_type;

assign stall_f = load_hazard;
assign stall_d = load_hazard;
assign flush_d = sel_pc;
assign flush_e = load_hazard | sel_pc;

////////// Fetch //////////

flopencr #(
    .WIDTH(WIDTH)
) reg_pc (
    .clk(clk),
    .reset_n(reset_n),
    .init(init_pc),
    .wr_en(!stall_f),
    .clr(1'b0),
    .in(next_pc),
    .out(pc)
);


////////// Decode //////////

flopencr #(
    .WIDTH($bits(stage_f))
) reg_decode (
    .clk(clk),
    .reset_n(reset_n),
    .init('d0),
    .wr_en(!stall_d),
    .clr(flush_d),
    .in(stage_f),
    .out(reg_stage_f)
);

decoder #(
    .WIDTH(WIDTH)
) decoder (
    .instr(reg_stage_f.instr),
    .op_type(op_type),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .funct3(funct3_d),
    .funct7(funct7_d),
    .imm(imm)
);

regfile #(
    .WIDTH(WIDTH),
    .ADDR(RFADDR),
    .SP_INIT('h8000)
) regfile (
    .clk(clk),
    .reset_n(reset_n),
    .wr_en(reg_stage_m.rf_wr_en),
    .rs1(rs1),
    .rs2(rs2),
    .rd(reg_stage_m.rd),
    .rdata1(rf_rdata1),
    .rdata2(rf_rdata2),
    .wdata(rf_wdata)
);

////////// Execute //////////

flopencr #(
    .WIDTH($bits(stage_d))
) reg_execute (
    .clk(clk),
    .reset_n(reset_n),
    .init('d0),
    .wr_en(1'b1),
    .clr(flush_e),
    .in(stage_d),
    .out(reg_stage_d)
);

mux4 #(
    .WIDTH(WIDTH)
) mux4_rf_rdata1_forwarding (
    .sel(sel_rdata1_f),
    .in0(reg_stage_d.rf_rdata1),
    .in1(reg_stage_e.ex_out),
    .in2(reg_stage_m.result),
    .in3(),
    .out(rf_rdata1_f)
);

mux4 #(
    .WIDTH(WIDTH)
) mux4_rf_rdata2_forwarding (
    .sel(sel_rdata2_f),
    .in0(reg_stage_d.rf_rdata2),
    .in1(reg_stage_e.ex_out),
    .in2(reg_stage_m.result),
    .in3(),
    .out(rf_rdata2_f)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_alu0 (
    .sel(reg_stage_d.sel_alu0),
    .in0(rf_rdata1_f),
    .in1(reg_stage_d.pc),
    .out(alu_in0)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_alu1 (
    .sel(reg_stage_d.sel_alu1),
    .in0(rf_rdata2_f),
    .in1(reg_stage_d.imm),
    .out(alu_in1)
);

alu #(
    .WIDTH(WIDTH)
) alu (
    .alu_type(reg_stage_d.alu_type),
    .in0(alu_in0),
    .in1(alu_in1),
    .out(alu_out)
);

cmp #(
    .WIDTH(WIDTH)
) cmp (
    .cmp_type(reg_stage_d.cmp_type),
    .in0(rf_rdata1_f),
    .in1(rf_rdata2_f),
    .out(cmp_out)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_ex (
    .sel(reg_stage_d.sel_ex),
    .in0(alu_out),
    .in1(reg_stage_d.imm),
    .out(ex_out)
);

////////// Memory //////////

flopencr #(
    .WIDTH($bits(stage_e))
) reg_memory (
    .clk(clk),
    .reset_n(reset_n),
    .init('d0),
    .wr_en(1'b1),
    .clr(1'b0),
    .in(stage_e),
    .out(reg_stage_e)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_res (
    .sel(reg_stage_e.sel_res),
    .in0(reg_stage_e.ex_out),
    .in1(dmem_rdata),
    .out(result)
);

////////// Write Back //////////

flopencr #(
    .WIDTH($bits(stage_m))
) reg_wback (
    .clk(clk),
    .reset_n(reset_n),
    .init('d0),
    .wr_en(1'b1),
    .clr(1'b0),
    .in(stage_m),
    .out(reg_stage_m)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_rf_wr (
    .sel(reg_stage_m.sel_rf_wr),
    .in0(reg_stage_m.result),
    .in1(reg_stage_m.inc_pc),
    .out(rf_wdata)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_pc (
    .sel(sel_pc),
    .in0(inc_pc),
    .in1(ex_out),
    .out(next_pc)
);

endmodule
