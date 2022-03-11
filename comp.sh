#!/bin/bash

nasm -g -f elf64 -o print.o -l print.list  print.asm
ld -o print print.o
