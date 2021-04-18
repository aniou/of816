# C256 Foenix (FMX)

This is port to [C256 Foenix](https://c256foenix.com/) system. [It works](https://www.youtube.com/watch?v=fsYlth-gQSA&feature=youtu.be)
on:
* C256 FMX Rev C4
* FoenixU/U+
* emulators (see below)

The port itself relies on default [FMX Kernel](https://github.com/Trinity-11/Kernel_FMX/).

It works in [Foenix IDE](https://github.com/Trinity-11/FoenixIDE) from
sersion [0.5.3.1](https://github.com/Trinity-11/FoenixIDE/releases), 
see [below](#on-foenixide) for instructions. 

It is possible to run current, unmodified version of this port on 
[go65c816 emulator](https://github.com/aniou/go65c816), see README.md
in go65c816 repository for [instructions](https://github.com/aniou/go65c816#running-forth).

## Latest changes

* 2021-04-14: Better integration with Foenix systems: of816 now is located
  at lower memory addresses and can be run by issuing ``brun "forth.pgx"``
  from BASIC.

  After ``BYE`` a reset routine is called.

* 2020-10-13: CUP/ED sequences support - now words AT-XY and PAGE works!

  From now print routines silently skip over LF character - this is an
  workaround for default C256 kernel that treats CR like original Commodore 
  (line down and go to column 0) and LF as "one line down" that leads 
  to redundant empty lines. 
  
  OF816 forth contains sample editor that may be tested in following way:
  
 ![running editor](doc/editor-ide-1.png)  
  
 ![running editor](doc/editor-ide-2.png)  

* 2020-10-11: foundations for ANSI codes support and working 3/4 bit SGR code.

  See [fcode/ansi.fs](fcode/ansi.fs) for working examples and syntax for 
  OpenFirmware hex code support in strings.

![ANSI SGR support](doc/ansi-colors-ide-1.png)


## Compiling

Port requires following utilities to be in `$PATH` to compile:

* `srec_cat` (from `srecord` package on Ubuntu) to generate `*.hex` files
* `ca65` and `ld65` from [CC65 development package](https://cc65.github.io/)

To compile package simply go into `of816/platforms/C256/` and run `./build.sh`,
after that You should see three files:

* `forth` - raw binary code
* `forth.hex` - 32bit Intel Hex format
* `forth.pgx` - a costom C256 program format, that can be put on SD card/floppy/HDD

## Using

### On real hardware

Code itself may be uploaded to FMX via debug USB port using
[C256Mgr tool](https://github.com/pweingar/C256Mgr)

Example call on Ubuntu:
```code
# python3.7 C256Mgr/C256Mgr/c256mgr.py --port /dev/ttyXRUSB0 --upload forth.hex
```

Originally forth code was loaded at ``$3a:0000`` (in place of BASIC) and
was started automatically after upload. Now is required to call it directly
by issuing ``call 65536`` or ``call &H10000`` commands.

### On FoenixIDE 

FoenixIDE works on Windows and Linux, under Wine (tested on Kubuntu 20.04).

1. Run emulator (default kernel should be loaded into memory automatically),
   and load ```forth.hex``` using *File->Load Hex File w/o Zeroing*
   
   ![loading forth.exe](doc/foenixide-1.png)
   
2. Run emulation (by F5, for example), there should be a starting screen:

   ![starting screen](doc/foenixide-2.png)

3. Call forth by issuing command ``call 65536``

## Current memory map

```
$00:8000 - $00:80FF   - ZP of forth system 
$00:8100 - $00:8FFF   - FORTH stack
$00:9000 - $00:9FFF   - FORTH return stack
$01:0000 - $01:FFFF   - FORTH routines
$02:0000 - $02:FFFF     FORTH dictionary
```

