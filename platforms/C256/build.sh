#!/bin/bash
set -e -x
export PATH="$HOME/bin:$PATH"

toke fcode/xmodem.fs
toke fcode/ansi.fs
toke fcode/editor.fs
ca65 -I ../../inc C256.s -l C256.lst
../../build.sh C256
ld65 -v -C C256.l C256.o ../../forth.o -m forth.map -o forth
srec_cat forth -binary -offset 0x010000 -o forth.hex -intel

ls -l forth *.hex
