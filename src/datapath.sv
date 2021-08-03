`include "lib_pkg.sv";

module datapath 
import lib_pkg::*;
#(parameter WIDTH=32, IADDR=10, DADDR=10)
(
    input logic clk,
    input logic reset_n,
    input logic [WIDTH-1:0] init_pc,
    output op_type_t op_type,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
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
    output logic mem_to_reg,
    input logic stall_f,
    input logic stall_d,
    input logic flush_e,
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

bus_stage0 stage0, reg_stage0;
bus_stage1 stage1, reg_stage1;
bus_stage2 stage2, reg_stage2;
bus_stage3 stage3, reg_stage3;

assign stage0 = '{
                instr: instr,
                pc: pc,
                inc_pc: inc_pc
                };

assign stage1 = '{
                rf_wr_en: rf_wr_en,
                rs1: rs1,
                rs2: rs2,
                rd: rd,
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
                sel_pc: sel_pc,
                pc: reg_stage0.pc,
                inc_pc: inc_pc,
                dmem_wr_en: dmem_wr_en_dec,
                ecall: ecall
                };

assign stage2 = '{
                rf_wr_en: reg_stage1.rf_wr_en,
                rd: reg_stage1.rd,
                //rf_rdata2: reg_stage1.rf_rdata2,
                rf_rdata2: rf_rdata2_f,
                sel_res: reg_stage1.sel_res,
                sel_rf_wr: reg_stage1.sel_rf_wr,
                sel_pc: reg_stage1.sel_pc,
                ex_out: ex_out,
                cmp_out: cmp_out,
                inc_pc: reg_stage1.inc_pc,
                dmem_wr_en: reg_stage1.dmem_wr_en,
                ecall: reg_stage1.ecall
                };

assign stage3 = '{
                rf_wr_en: reg_stage2.rf_wr_en,
                rd: reg_stage2.rd,
                sel_rf_wr: reg_stage2.sel_rf_wr,
                sel_pc: reg_stage2.sel_pc,
                cmp_out: reg_stage2.cmp_out,
                result: result,
                inc_pc: reg_stage2.inc_pc,
                ecall: reg_stage2.ecall
                };

assign inc_pc = pc + 4;
assign imem_addr = pc[IADDR-1:0];
assign instr = imem_rdata;
assign dmem_addr = reg_stage2.ex_out[DADDR-1:0];
assign dmem_wdata = reg_stage2.rf_rdata2;
assign fin = reg_stage3.ecall;

assign rd_ex = reg_stage1.rd;
assign rd_mem = reg_stage2.rd;
assign rd_wb = reg_stage3.rd;
assign rs1_dec = rs1;
assign rs2_dec = rs2;
assign rs1_ex = reg_stage1.rs1;
assign rs2_ex = reg_stage1.rs2;
assign mem_to_reg = reg_stage1.sel_res;
assign dmem_wr_en = reg_stage2.dmem_wr_en;

////////// Fetch //////////

flopenr #(
    .WIDTH(WIDTH)
) reg_pc (
    .clk(clk),
    .reset_n(reset_n),
    .init(init_pc),
    .wr_en(!stall_f),
    .in(next_pc),
    .out(pc)
);


////////// Decode //////////

flopenr #(
    .WIDTH($bits(stage0))
) reg_decode (
    .clk(clk),
    .reset_n(reset_n),
    .init('d0),
    .wr_en(!stall_d),
    .in(stage0),
    .out(reg_stage0)
);

decoder #(
    .WIDTH(WIDTH)
) decoder (
    .instr(reg_stage0.instr),
    .op_type(op_type),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .funct3(funct3),
    .funct7(funct7),
    .imm(imm)
);

regfile #(
    .WIDTH(WIDTH),
    .ADDR(RFADDR)
) regfile (
    .clk(clk),
    .reset_n(reset_n),
    .wr_en(reg_stage3.rf_wr_en),
    .rs1(rs1),
    .rs2(rs2),
    .rd(reg_stage3.rd),
    .rdata1(rf_rdata1),
    .rdata2(rf_rdata2),
    .wdata(rf_wdata)
);

////////// Execute //////////

flopenr #(
    .WIDTH($bits(stage1))
) reg_execute (
    .clk(clk),
    .reset_n(reset_n & ~flush_e),
    //.reset_n(reset_n),
    .init('d0),
    .wr_en(1'b1),
    .in(stage1),
    .out(reg_stage1)
);

mux4 #(
    .WIDTH(WIDTH)
) mux4_rf_rdata1_forwarding (
    .sel(sel_rdata1_f),
    .in0(reg_stage1.rf_rdata1),
    .in1(reg_stage2.ex_out),
    .in2(reg_stage3.result),
    .in3(),
    .out(rf_rdata1_f)
);

mux4 #(
    .WIDTH(WIDTH)
) mux4_rf_rdata2_forwarding (
    .sel(sel_rdata2_f),
    .in0(reg_stage1.rf_rdata2),
    .in1(reg_stage2.ex_out),
    .in2(reg_stage3.result),
    .in3(),
    .out(rf_rdata2_f)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_alu0 (
    .sel(reg_stage1.sel_alu0),
    .in0(rf_rdata1_f),
    .in1(reg_stage1.pc),
    .out(alu_in0)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_alu1 (
    .sel(reg_stage1.sel_alu1),
    .in0(rf_rdata2_f),
    .in1(reg_stage1.imm),
    .out(alu_in1)
);

alu #(
    .WIDTH(WIDTH)
) alu (
    .alu_type(reg_stage1.alu_type),
    .in0(alu_in0),
    .in1(alu_in1),
    .out(alu_out)
);

cmp #(
    .WIDTH(WIDTH)
) cmp (
    .cmp_type(reg_stage1.cmp_type),
    .in0(reg_stage1.rf_rdata1),
    .in1(reg_stage1.rf_rdata2),
    .out(cmp_out)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_ex (
    .sel(reg_stage1.sel_ex),
    .in0(alu_out),
    .in1(reg_stage1.imm),
    .out(ex_out)
);

////////// Memory //////////

flopenr #(
    .WIDTH($bits(stage2))
) reg_memory (
    .clk(clk),
    .reset_n(reset_n),
    .init('d0),
    .wr_en(1'b1),
    .in(stage2),
    .out(reg_stage2)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_res (
    .sel(reg_stage2.sel_res),
    .in0(reg_stage2.ex_out),
    .in1(dmem_rdata),
    .out(result)
);

////////// Write Back //////////

flopenr #(
    .WIDTH($bits(stage3))
) reg_wback (
    .clk(clk),
    .reset_n(reset_n),
    .init('d0),
    .wr_en(1'b1),
    .in(stage3),
    .out(reg_stage3)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_rf_wr (
    .sel(reg_stage3.sel_rf_wr),
    .in0(reg_stage3.result),
    .in1(reg_stage3.inc_pc),
    .out(rf_wdata)
);

/// TODO: support jump
mux2 #(
    .WIDTH(WIDTH)
) mux2_pc (
    .sel(reg_stage3.sel_pc),
    .in0(inc_pc),
    .in1(reg_stage3.result),
    .out(next_pc)
);

endmodule