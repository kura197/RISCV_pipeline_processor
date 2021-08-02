#  RISCV_pipeline_processor
RISC-V 5-stage pipeline processor supporting rv32i instructions.  
 

# Test
All instructions are tested by [riscv-tests](https://github.com/riscv/riscv-tests.git).   
Hardware modules are compiled by Verilator.
```
make
TEST_DIR=/path/to/riscv-tests ./test.sh
```
