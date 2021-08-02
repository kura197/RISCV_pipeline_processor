#ifndef READ_ELF_H_
#define READ_ELF_H_

#include <vector>

int load_elf(const char* filename, unsigned int& init_pc, std::vector<unsigned char>& mem);

#endif
