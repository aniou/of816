#!/bin/bash
set -e -x
export PATH="$HOME/bin:$PATH"

toke fcode/xmodem.fs
toke fcode/ansi.fs
toke fcode/editor.fs
ca65 -I ../../inc C256.s -l C256.lst
../../build.sh C256
ld65 -v -C C256.l C256.o ../../forth.o -m forth.map -o forth

# build hex file for emulators or direct upload
srec_cat forth -binary -offset 0x010000 -o forth.hex -intel

# build prg file (program format recognized by Foenix Kernel)
echo -n "PGX" | srec_cat \
                        - -binary -offset 0x00 \
                        forth -binary -offset 0x07 \
                        -generate 0x0003 0x0007 -constant-l-e 0x010000 4 \
                        -o forth.prg -binary

ls -l forth *.hex *.prg
