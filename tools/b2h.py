#!/usr/bin/env python3
#
# Zwölf Binary to Howl Converter
# Copyright (c) 2025 Lone Dynamics Corporation. All rights reserved.
#
# This converts a binary file into a series of Howl commands
# that can be used to program a Zwölf module over I2C.
#

import sys

class Bin2Howl():

    def __init__(self):
        self.a = 0

    def convert(self, file, addr = 0):
        with open(file, "rb") as f:
            ba = bytearray(f.read())
            size = len(ba)
            self.setaddr(addr + size)
            for b in reversed(ba):
                self.prog(b)
            print(f"w 80 40")   # reset

    def setaddr(self, addr):
        print(f"w 80 80")   # halt

        # addr hi
        self.seta((addr >> 8) & 0xff)

        print(f"w 81 04")   # swap
        print(f"w 80 20")   # exec

        # addr lo
        self.seta(addr & 0xff)

        print(f"w 81 32")   # ssp
        print(f"w 80 20")   # exec

    def prog(self, val):
        # byte value
        self.seta(val)

        print(f"w 81 01")   # push 
        print(f"w 80 20")   # exec

    def seta(self, val):
        op = 0x80 | (val ^ 0x80)    # li
        print(f"w 81 {op:02x}")     # set remote data register
        print(f"w 80 20")           # exec
        if val >= 0x80:
            op = 0x15               # sh
            print(f"w 81 {op:02x}") # set remote data register
            print(f"w 80 20")       # exec


# --
 
b2h = Bin2Howl()
b2h.convert(sys.argv[1])
