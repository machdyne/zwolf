#!/usr/bin/env python3
#
# Zwölf CPU Assembler
# Copyright (c) 2024 Lone Dynamics Corporation. All rights reserved.
#
# TODO: support single-instruction LI for labels; requires more passes
#

import sys
import struct

opcodes = {
    'nop': 0x00,
    'push': 0x01,
    'pop': 0x02,
    'cp': 0x03,
    'swap': 0x04,
    'add': 0x10,
    'sub': 0x11,
    'and': 0x12,
    'or': 0x13,
    'xor': 0x14,
    'sh': 0x15,
    'jp': 0x20,
    'jz': 0x21,
    'jf': 0x22,
    'lpc': 0x30,
    'lio': 0x40,
    'sio': 0x41,
    'li': 0x80,
}

class Assembler():

    def __init__(self):
        self.output = None
        self.labels = {}
        self.genpass = False

    def assemble(self, infile, outfile):
        self.output_bin = open(outfile, "wb")
        self.output_hex = open(outfile + ".hex", "w")
        self.parse(infile, genpass=False)
        self.parse(infile, genpass=True)

    def gen(self, data):
        if self.genpass:
            print("  [{0:04x}] {1:02x}".format(self.pc, data))
            self.output_bin.write(struct.pack('>B', data))
            self.output_hex.write("{0:02x}\n".format(data))
        self.pc = self.pc + 1

    def parse(self, filename, genpass):
        self.pc = 0
        self.genpass = genpass
        with open(filename) as f:
            for l in f.readlines():

                waslabel = False

                l = l.strip()

                la = l.partition(';')[0]
                ll = la.split()

                if len(ll) == 0: continue

                lb = ll[0].split(':')

                if len(lb) > 1:
                    hi = (self.pc >> 8) & 0xff
                    lo = self.pc & 0xff
                    self.labels[lb[0] + '_hi'] = hi
                    self.labels[lb[0] + '_lo'] = lo
                    print(" " + lb[0] + "_hi @ {0:02x}".format(hi))
                    print(" " + lb[0] + "_lo @ {0:02x}".format(lo))
                    continue

                print(l)

                if ll[0] == 'li':

                    if ll[1][0].isnumeric():
                        v = int(ll[1], 0)
                    else:
                        waslabel = True
                        if ll[1] in self.labels:
                            v = self.labels[ll[1]]
                        else:
                            if self.genpass:
                                print("missing label: ", ll[1])
                            v = 0

                    if v < 0x80:
                        self.gen(opcodes['li'] | v)
                        if waslabel:
                            self.gen(opcodes['nop'])
                    else:
                        self.gen(opcodes['li'] | (v ^ 0x80))
                        self.gen(opcodes['sh'])

                elif ll[0] in opcodes:
                    self.gen(opcodes[ll[0]])

            if not self.genpass:
                print(self.labels)

# --
 
asm = Assembler()
asm.assemble(sys.argv[1], sys.argv[2])
