#!/bin/bash
set -e -x
ca65 -I ../../inc go65c816.s -l go65c816.lst
sh ../../build.sh go65c816
ld65 -v -C go65c816.l -S 0x1000 go65c816.o ../../forth.o -m forth.map -o forth
srec_cat forth -binary -offset 0x1000 -o forth.hex -intel
ls -l forth forth.hex
