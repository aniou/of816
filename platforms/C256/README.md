# C256 Foenix (FMX)

This is port to [C256 Foenix](https://c256foenix.com/) system. Currently
[it works](https://www.youtube.com/watch?v=fsYlth-gQSA&feature=youtu.be)
on real hardware, C256 FMX Rev C4A.

The port itself relies on default [FMX Kernel](https://github.com/Trinity-11/Kernel_FMX/)
but replaces included [BASIC](https://github.com/pweingar/BASIC816)

# Compiling

Port requires following utilities to compile:

* srec_cat (from "srecord" package on Ubuntu) to generate *.hex files
* ca65 and ld65 from [CC65 development package](https://cc65.github.io/)

To compile package simply go into of816/platforms/C256/ and run ./build.sh

# Using

Code itself may be uploaded to FMX via debug USB port using
[C256Mgr tool](https://github.com/pweingar/C256Mgr)

Example call on Ubuntu:
```code
# python3.7 C256Mgr/C256Mgr/c256mgr.py --port /dev/ttyXRUSB0 --upload forth.hex
```

# Some notes about memory location

Program itself overwrites BASIC at addr $3A:0000, uses memory range between
$01:0000 and $02:0000 and Bank0 area between $9000 and $AFFFF.

Provided values may be subjects to change in future.



