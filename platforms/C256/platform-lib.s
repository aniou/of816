; Platform support library for C256 FOENIX FMX
; https://wiki.c256foenix.com/
; 
; This file should define any equates that are platform specific, and may be used to
; define the system interface functions if it is not supplied elsewhere.
;
; Generally the system interface is used for console I/O
; and other such things.  The function code is given in the A register, the Y register
; has the Forth stack depth, and X is the Forth stack pointer vs the direct page.
; THE X REGISTER MUST REFLECT PROPER FORTH STACK POINTER UPON RETURN!
;
; The interface function is called with the Forth direct page and return stack in effect.
; Function codes $0000-$7FFF are reserved to be defined for use by Forth.  Codes $8000-
; $FFFF may be used by the system implementator for system-specific functions.
;
; The system interface must implement functions marked as mandatory.
; System interface functions shall RTL with the expected stack effects, AY=0, and
; carry clear if successful; or shall RTL with a code for THROW in AY and carry set on
; failure.  A safe throw code for console I/O is -21 (unsupported operation).
;
; Stack cells are 2 words/4 bytes/32 bits, and the stack pointer points to the top of
; the stack.  If the system interface is defined here, the stack manipulation functions
; defined in interpreter.s may be used.  If defined elsewhere, you are on your own for
; ensuring correct operation on the stack.
;
; The system interface functions may use the direct page ZR bytes $00-$03, if they need
; more than that they can use something reserved elsewhere via long addressing or 
; by temporarily changing the direct page.
;
; Here are the function codes, expected stack results, and descriptions
;
; $0000 ( -- ) pre initialize platform - called before Forth initialization, to be used
;       for initialization that must take place before Forth initialization.
; $0001 ( -- ) post initialize platform - called after Forth initialization, to be used
;       for initialization that must take place after Forth initialization.
; $0002 ( char -- ) emit a character to the console output.  This function should
;       implement the control sequences described in IEEE 1275-1994 (a subset of the
;       ANSI terminal standard).  For serial devices, this may be assumed.
; $0003 ( -- f ) f is true if the console input has a character waiting
; $0004 ( -- char ) read a character from the console (blocking)
; $0005 ( -- addr ) return pointer to list of FCode modules to evaluate.  If pointer is
;       0, none are evaluated.  List should be 32-bit pointers ending in 0.
;       this is never called if FCode support is not included.
;       The system will trust that there is FCode there and not look for a signature.
; $0006 ( -- ) perform RESET-ALL, restart the system as if reset button was pushed

cpu_clk   = 14318000

.proc     _system_interface
          ;wdm 3
          phx
          asl
          tax
          ;jmp   (table,x)
          jmp   (.LOWORD(table),x)
table:    .addr _sf_pre_init
          .addr _sf_post_init
          .addr _sf_emit
          .addr _sf_keyq
          .addr _sf_key
          .addr _sf_fcode
          .addr _sf_reset_all
.endproc
.export   _system_interface

.proc     _sf_success
          lda   #$0000
          tay
          clc
          rtl
.endproc

.proc     _sf_fail
          ldy   #.loword(-21)
          lda   #.hiword(-21)
          sec
          rtl
.endproc


.proc     _sf_pre_init
          plx
          jmp   _sf_success     ; assume WDC monitor already did it
.endproc


.proc     _sf_post_init
          plx
          jmp   _sf_success
.endproc

.proc     _sf_emit
          plx
          jsr   _popay
          phx
          php
          sep   #SHORT_A|SHORT_I
          .a8
          .i8
          tya

          jsl $001018       ; PUTCH kernel function, XXX - change to symbolic name

          plp
          .a16
          .i16
          plx
          jmp   _sf_success
.endproc

; crude try - there is no 'wait for key' function so far
;
;.384328   a6 8b       ldx $0f8b   check_buffer    LDX KEY_BUFFER_RPOS     ; Is KEY_BUFFER_RPOS < KEY_BUFFER_WPOS
;.38432a e4 8d       cpx $0f8d                   CPX KEY_BUFFER_WPOS
;.38432c 90 02       bcc $384330                 BCC read_buff           ; Yes: a key is present, read it
;.38432e 80 e4       bra $384314                 BRA get_wait            ; Otherwise, keep waiting
;

.proc     _sf_keyq
          lda   #$00
          tay                     ; anticipate false
          php
          lda $0f8b               ; KEY_BUFFER_RPOS
          cmp $0f8d               ; is KEY_BUFFER_RPOS < KEY_BUFFER_WPOS
          bcs :+                  ; no - it is <=, no key is present
          dey                     ; from $0000 to $FFFF when key is present
:         plp                     ; required or not?
          tya
          plx
          jsr   _pushay
          jmp   _sf_success
.endproc

.proc     _sf_key
          php
          lda #0000
          tay
          jsl $00104C            ; GETCHW kernel function
          and #$00ff             ; only byte lower is needed
          plp
          tay
          lda   #$0000
          plx
          jsr   _pushay
          jmp   _sf_success
.endproc

.proc     _sf_fcode
.if include_fcode
          ldy   #.loword(list)
          lda   #.hiword(list)
.else
          lda   #$0000
          tay
.endif
          plx
          jsr   _pushay
          jmp   _sf_success
.if include_fcode
list:
  .if romloader_at_init
          .dword romldr
  .endif
          .dword 0
  .if romloader_at_init
romldr:   PLATFORM_INCBIN "fcode/romloader.fc"
  .endif
.endif

.endproc

; something doesn't work here (Exception -21)
.proc     _sf_reset_all
          plx
          jmp   _sf_fail
;          jml   $001000     ; BOOT kernel function
.endproc

