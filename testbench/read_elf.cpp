#include <iostream>
#include <string>
#include <map>
#include <vector>
#include <cstring>
#include <stdio.h>
#include <stdint.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>
#include <elf.h>
#include "read_elf.h"

std::map<int, std::string> get_sh_table(unsigned char *str, Elf32_Shdr *shdr){
    std::map<int, std::string> sh_table;
    unsigned char *tbl_head = &str[shdr->sh_offset];
    unsigned long total_len = 0;

    while(total_len < shdr->sh_size){
        std::string name(reinterpret_cast<char*>(&tbl_head[total_len]));
        sh_table[&tbl_head[total_len] - tbl_head] = name;
        if(name.substr(0, 5) == ".rela"){
            total_len += 5;
        } else {
            total_len += strlen((char *)&tbl_head[total_len]) + 1;
        }
    }

    return sh_table;
}

int init_memory(unsigned char* buf, Elf32_Shdr *shdr, int e_shnum, std::map<int, std::string> sh_table, std::vector<unsigned char>& mem){
    int init_pc = 0;
    for (int i = 0; i < e_shnum; i++, shdr++) {
        std::string& name = sh_table[shdr->sh_name];
        if (name == ".text.init" || name == ".text") {
            init_pc = shdr->sh_offset;
        }

        if (name == ".data" || name == ".text.init" || name == ".text") {
            for(unsigned int k = 0; k < shdr->sh_size; k++){
                unsigned int offset = shdr->sh_offset + k;
                mem[offset] = buf[offset];
            }
        }
    }

    return init_pc;
}

int load_elf(const char* filename, unsigned int& init_pc, std::vector<unsigned char>& mem){
    int fd = open(filename, O_RDONLY);
    if(fd < 0) {
        printf("cannot open %s\n", filename);
        return -1;
    }
    FILE* fp = fdopen(fd, "rb");
    if(fp == NULL){
        printf("cannot open %s\n", filename);
        return -1;
    }

    struct stat stbuf;
    fstat(fd, &stbuf);
    unsigned char buf[stbuf.st_size];
    if(fread(buf, 1, sizeof(buf), fp) != (unsigned long)stbuf.st_size){
        printf("fread failed.");
        return -1;
    }
    fclose(fp);

    Elf32_Ehdr* ehdr = (Elf32_Ehdr *)buf;
    Elf32_Shdr* shdr = (Elf32_Shdr *)(&buf[ehdr->e_shoff]);
    auto sh_table = get_sh_table(buf, &shdr[ehdr->e_shstrndx]);

    init_pc = init_memory(buf, shdr, ehdr->e_shnum, sh_table, mem);

    return 0;
}

//int main(int argc, char* argv[]){
//    if(argc != 2)
//        return -1;
//    
//    unsigned int init_pc;
//    std::vector<unsigned char> imem(65536), dmem(65536);
//    load_elf(argv[1], init_pc, imem, dmem);
//
//    return 0;
//}
