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

          rep   #SHORT_A|SHORT_I
          lda   #$8000
          tcd                       ; direct page for forth

          lda   #.hiword($030000)   ; top of dictionary memory
          pha
          lda   #.loword($030000)
          pha
          lda   #.hiword($020000)   ; bottom of dictionary
          pha
          lda   #.loword($020000)
          pha

          lda   #$1000            ; relative to direct page, top is the address immediately after the first usable cell.
          pha
          lda   #$0104            ; relative to direct page, The Bottom value is the address of the last usable cell
          pha
          lda   #$9fff            ; return stack first usable byte - NOT relative do DP
          pha
          lda   #.hiword(_system_interface)
          pha
          lda   #.loword(_system_interface)
          pha
          jsl   _Forth_initialize
          jsl   _Forth_ui

                                  ; after BYE we return here
          lda   #$00              ; set default DP, assume 0
          tcd
          rtl                     ; return to caller (BASIC)
          .byte $00
.endproc
.popseg
