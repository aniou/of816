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

          lda   #.hiword($040000)   ; top of dictionary memory
          pha
          lda   #.loword($040000)
          pha
          lda   #.hiword($030000)   ; bottom of dictionary
          pha
          lda   #.loword($030000)
          pha

          lda   #$0300            ; first usable stack cell (relative to direct page)
          pha
          lda   #$0100            ; last usable stack cell+1 (relative to direct page)
          pha
          lda   #$09FF            ; return stack first usable byte
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
