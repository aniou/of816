.p816
.a16
.i16
.include  "macros.inc"
.import   _Forth_initialize
.import   _Forth_ui
.import   _system_interface

.pushseg
.segment  "FStartup"
.proc     startup
          clc
          xce

          setaxl
          lda   #$9000
          tcd                       ; direct page for forth

          lda   #.hiword($020000)   ; top of dictionary memory
          pha
          lda   #.loword($020000)
          pha
          lda   #.hiword($010000)   ; bottom of dictionary
          pha
          lda   #.loword($010000)
          pha

          lda   #$1000            ; relative to direct page, top is the address immediately after the first usable cell.
          pha
          lda   #$0104            ; relative to direct page, The Bottom value is the address of the last usable cell
          pha
          lda   #$afff            ; return stack first usable byte - NOT relative do DP
          pha
          lda   #.hiword(_system_interface)
          pha
          lda   #.loword(_system_interface)
          pha
          jsl   _Forth_initialize
          jsl   _Forth_ui
          brk
          .byte $00
.endproc
.popseg
