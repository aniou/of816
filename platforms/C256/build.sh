#!/bin/bash
export PATH="$HOME/bin:$PATH"

echo "Checking for required commands..."
miss=0
for cmd in ca65 ld65 srec_cat toke
do
  which $cmd > /dev/null
  if [[ $? -gt 0 ]]; then
    echo "  tool ${cmd} not found in PATH"
    miss=1
  fi
done
if [[ $miss -gt 0 ]]; then
    echo "some requied tools missing, aborting"
    exit 1
else
    echo "ok."
fi

set -e -x
toke fcode/xmodem.fs
toke fcode/ansi.fs
toke fcode/editor.fs
ca65 -I inc -I ../../inc C256.s -l C256.lst
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
  # make a debug hook for quick startup on hw with 4M of RAM
  ( cat forth.hex debug-hook.hex ) > forth-debug.hex
fi

ls -l forth *.hex *.pgx
