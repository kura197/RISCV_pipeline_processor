
TOP := riscv.sv
INCLUDE := ./src

SRC := ./src/$(TOP)

TB_SRC := testbench/tb_riscv.cpp testbench/read_elf.cpp

OBJ_DIR := obj_dir

OBJ := vtest

MKFILE := V${TOP:.sv=.mk}

CFLAGS := -std=c++14
#VFLAGS := --trace-fst --trace-params --trace-structs --trace-underscore
VFLAGS := --trace --trace-params --trace-structs --trace-underscore

# need to set TEST_BIN for simulation
.PHONY:test
test: $(OBJ_DIR)/$(OBJ)
	#./$(OBJ_DIR)/$(OBJ) $(TEST_BIN)
	TEST_DIR=$(TEST_DIR) ./test.sh

$(OBJ_DIR)/$(OBJ): $(OBJ_DIR)
	make -C $(OBJ_DIR) -f $(MKFILE)

$(OBJ_DIR): src/* testbench/*
	if [ -d "$(OBJ_DIR)" ]; then rm -r $(OBJ_DIR); fi
	verilator -cc $(SRC) $(VFLAGS) -CFLAGS $(CFLAGS) -exe $(TB_SRC) -I$(INCLUDE) -o $(OBJ)

.PHONY:clean
clean:
	rm -r $(OBJ_DIR) wave.vcd
