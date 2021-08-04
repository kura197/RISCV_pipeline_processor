#include <iostream>
#include <fstream>
#include <vector>
#include <verilated.h>
#include <verilated_vcd_c.h> 
#include "read_elf.h"
#include "Vriscv.h"

void print_rf(Vriscv* dut){
    unsigned int pc = dut->v__DOT__datapath__DOT__pc;
    vector<unsigned int> x(32);
    for(int i = 0; i < 32; i++)
        x[i] = dut->v__DOT__datapath__DOT__regfile__DOT__data[i];
    fprintf(stderr, "\rpc: %08x, x0: %08x, ra: %08x, sp: %08x,\n \
            \rgp: %08x, tp: %08x, t0: %08x, s0: %08x,\n \
            \ra0: %08x, a1: %08x, a2: %08x, a3: %08x,\n \
            \ra4: %08x, a5: %08x, a6: %08x, a7: %08x\n\n", \
            pc, x[0], x[1], x[2], \
            x[3], x[4], x[5], x[8], \
            x[10], x[11], x[12], x[13], \
            x[14], x[15], x[16], x[17]);
}

unsigned int read_mem(vector<unsigned char>& mem, int addr){
    int ret = 0;
    for(int i = 0; i < 4; i++){
        ret |= static_cast<unsigned int>(mem[addr+i]) << (8*i);
    }

    //static int last;
    //if(addr > 0x100 && last != addr){
    //    fprintf(stderr, "read. addr=%x, val=%x\n", addr, ret);
    //    last = addr;
    //}
    return ret;
}

void write_mem(vector<unsigned char>& mem, int addr, unsigned int val, int wr_en){
    for(int i = 0; i < 4; i++){
        if((wr_en >> i) & 1){
            mem[addr+i] = (val >> (8*i)) & 0xFF;
        }
    }
    //if(wr_en)
    //    fprintf(stderr, "write. addr=%x, val=%x\n", addr, val);
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    if(argc != 2){
        fprintf(stderr, "Usage: %s binary\n", argv[0]);
        return -1;
    }

    //// initialize memory
    const int IADDR = 20;
    const int DADDR = IADDR;
    vector<unsigned char> mem(1 << DADDR);
    unsigned int init_pc;
    load_elf(argv[1], init_pc, mem);
    fprintf(stderr, "Initial PC: %d\n", init_pc);

    Vriscv *dut = new Vriscv();

    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    dut->trace(tfp, 100); // Trace 100 levels of hierarchy
    tfp->open("wave.vcd");

    //// toggle reset_n
    dut->reset_n = 1;
    dut->clk = 0;
    dut->init_pc = init_pc - 4;
    int time_counter = 0;
    while(time_counter < 100){
        if(time_counter % 5 == 0){
            dut->clk = !dut->clk;

            if(time_counter == 20)
                dut->reset_n = 0;
        }
        dut->eval();
        tfp->dump(time_counter);
        time_counter++;
    }

    //// start simulation
    dut->reset_n = 1;
    int cycle = 0;
    while(time_counter < 6000 && !Verilated::gotFinish()){
        if(time_counter % 5 == 0){
            dut->clk = !dut->clk;

            if(time_counter % 10 == 0){
                cycle++;
                print_rf(dut);
            }

        }

        dut->eval();
        tfp->dump(time_counter);

        dut->dmem_rdata = read_mem(mem, dut->dmem_addr);
        dut->imem_rdata = read_mem(mem, dut->imem_addr);
        if(time_counter % 5 == 0){
            if(dut->clk == 1){
                write_mem(mem, dut->dmem_addr, dut->dmem_wdata, dut->dmem_wr_en);
            }
        }

        if(dut->fin == 1){
            fprintf(stderr, "ECALL is issued.\n");
            printf("a0 : %08x, a7 : %08x\n", dut->v__DOT__datapath__DOT__regfile__DOT__data[10], dut->v__DOT__datapath__DOT__regfile__DOT__data[17]);
            break;
        }

        time_counter++;
    }

    fprintf(stderr, "Final cycle count = %d\n", cycle);
    print_rf(dut);

    dut->final();
    delete dut;
    tfp->close();
    delete tfp;
}
