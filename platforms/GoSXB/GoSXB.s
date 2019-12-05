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
          lda   #$0000            ; direct page for Forth
          tcd
          lda   #.hiword($820000)   ; top of dictionary memory
          pha
          lda   #.loword($820000)
          pha
          lda   #.hiword($810000)   ; bottom of dictionary
          pha
          lda   #.loword($810000)
          pha
          lda   #$0280            ; first usable stack cell (relative to direct page)
          pha
          lda   #$0100            ; last usable stack cell+1 (relative to direct page)
          pha
          lda   #$03FF            ; return stack first usable byte
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
