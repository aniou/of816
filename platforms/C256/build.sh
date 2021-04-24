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
echo -n -e "PGX\x01" | srec_cat \
                        - -binary -offset 0x00 \
                        forth -binary -offset 0x08 \
                        -generate 0x0004 0x0008 -constant-l-e 0x010000 4 \
                        -o forth.pgx -binary

if [ "${1}x" = "debugx" ]; then
  # make a debug hook for quick startup on hw
  cat debug-hook.hex >> forth.hex
fi

ls -l forth *.hex *.pgx
