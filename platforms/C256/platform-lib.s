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

PLATFORM_INCLUDE "platform-include.inc"

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
        sep   #SHORT_A
        .a8

        ; init text-mode lut table
        ldx #$0000
:       lda .LOWORD(text_color_lut),x
            sta $AF1F40,x       ; FG_CHAR_LUT_PTR
        sta $AF1F80,x       ; BG_CHAR_LUT_PTR
        inx
        cpx #$40
        bne :-

        ; set new default color
        lda #$78
        sta f:$00001E       ; CURCOLOR

        ; update screen color
        ldx #$0000
:       sta $AFC000,x       ; CS_COLOR_MEM_PTR
        inx
        cpx #$2000
        bne :-

        rep   #SHORT_A
        .a16
        plx
        jmp   _sf_success     ; assume WDC monitor already did it

;                       B    G    R  alpha
text_color_lut: .byte   0,   0,   0, 255  ; black
                .byte   0,   0, 120, 255  ; red
                .byte   0, 120,   0, 255  ; green
                .byte   0, 120, 120, 255  ; yellow
                .byte 180,   0,   0, 255  ; blue
                .byte 120,   0, 120, 255  ; magenta
                .byte 110, 110,   0, 255  ; cyan
                .byte  64,  64,  64, 255  ; white

                .byte  16,  16,  16, 255  ; bright black
                .byte   0,   0, 255, 255  ; bright red
                .byte   0, 255,   0, 255  ; bright green
                .byte   0, 255, 255, 255  ; bright yellow
                .byte 255,  92,  92, 255  ; bright blye
                .byte 255,   0, 255, 255  ; bright magenta
                .byte 255, 255,   0, 255  ; bright cyan
                .byte 170, 170, 170, 255  ; bright white


.endproc


.proc     _sf_post_init
          plx
          jmp   _sf_success
.endproc

.proc     _sf_emit_old
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



.proc       _con_write
            sep   #SHORT_A|SHORT_I
            .a8
            .i8
            tya
            jsl $001018       ; PUTCH kernel function, XXX - change to symbolic name
            rep   #SHORT_A|SHORT_I
            .a16
            .i16
            rts
.endproc

.proc       _sf_emit
            plx
            jsr   _popay
            phx
            php                     ; really required?
            cpy   #$0000
            beq   do_null           ; ignore nulls
            lda   ESCMODE
            asl
            tax
            jmp   (.LOWORD(table),x)
table:      .addr _mode0            ; no ESC sequence in progress
            .addr _mode1            ; ESC but no [ yet
            .addr _mode2            ; ESC[ in progress
do_null:    plp                     ; really reqiured?
            plx
            jmp   _sf_success
.endproc

.proc       _mode0
            cpy   #$1B              ; ESC
            bne   :+
            inc   ESCMODE
            bra   done
:           jsr   _con_write
done:       plp
            plx
            jmp   _sf_success
.endproc

.proc       _mode1
            cpy   #'['              ; second char in sequence?
            beq   :+                ; yes, change modes
            stz   ESCMODE           ; otherwise back to mode 0
            phy
            ldy   #$1B
            jsr   _con_write        ; output the ESC we ate
            ply
            jsr   _con_write        ; and output this char
            bra   done
:           stz   ESCACC
            stz   ESCNUM
            ldx   #0        ; clear all Pn (16)
:           stz   ESCPn, x
            inx
            inx
            ;dec            ; WTF? po co ja to tu?
            cpx   #32
            bcc   :-
            lda   #4        ; four digits, at 0 we set ESCACC to 9999, at -1 we do nothing
            sta   NUMCOUNT      ; max parameter valuer - four digits
            inc   ESCMODE           ; sequence started!
done:       plp
            plx
            jmp   _sf_success
.endproc

.proc     _mode2
        cpy   #' '              ; ignore spaces in codes
        beq   done

        cpy   #';'
        bne   :+

        ldx   ESCNUM        ; how many p1;p2;p3;pn parameters?
        cpx   #32       ; max 16 (16*2)? - ignore following
        bcs   done

        lda   ESCACC            ; move ACC to EXCPn if ;
        sta   ESCPn, x
        inx
        inx
        stx   ESCNUM
        lda   #4        ; reset number of valid
        sta   NUMCOUNT
                stz   ESCACC
        bra   done

:       lda   NUMCOUNT      ; how many digits was processed?
                bmi   done              ; -1? then default max value was already set
        bne   :+
                lda   #9999     ; if there is a fifth number then max should be set
                sta   ESCACC
        dec   NUMCOUNT      ; but only one time, we use -1 to mark this
        bra   done      ;

:       tya
        sec
        sbc   #$30
        bmi   endesc            ; eat it and end ESC mode if invalid
        cmp   #$0a
        bcs   :+                ; try letters if not a digit
        tay                     ; a digit, accumulate it into ESCACC
        lda   #10               ; multiply current ESCACC by 10
        sta   MNUM2
        lda   #$0000            ; initialize result
        beq   elp
do_add:     clc
        adc   ESCACC
lp:         asl   ESCACC
elp:        lsr   MNUM2
        bcs   do_add
        bne   lp
        sta   ESCACC            ; now add the current digit
        tya
        clc
        adc   ESCACC
        sta   ESCACC
        dec   NUMCOUNT
        bra   done

:       nop
        ldx   ESCNUM
                lda   ESCACC
                sta   ESCPn, x          ; save accumulator on parameter list
        tya                     ; not a digit, try letter codes

        sec
        sbc   #'@'
        bmi   endesc
        cmp   #$1B              ; ctrl+Z
        bcc   upper             ; upper case code
        sbc   #$20              ; convert lower case to 00-1A
        bmi   endesc
        cmp   #$1B
        bcc   lower             ; lower case codes
endesc:     nop                     ; zbedne?
        rep   #SHORT_A|SHORT_I
        .a16            ; zbedne?
        .i16                    ; zbedne?
        stz   ESCMODE
        sta ESCDIAG
done:       plp
        plx
        jmp   _sf_success
none:       rts
upper:      asl
        tax
        stx ESCDIAG
        jsr   (.LOWORD(utable),x)
        bra   endesc
utable:   .addr none              ; @ insert char
          .addr none              ; A cursor up
          .addr none              ; B cursor down
          .addr none              ; C cursor forward
          .addr none              ; D cursor backward
          .addr none              ; E cursor next line
          .addr none              ; F cursor previous line
          .addr none              ; G cursor horizontal absolute
          .addr none              ; H cursor position
          .addr none              ; I
          .addr none              ; J erase display
          .addr none              ; K erase line
          .addr none              ; L insert lines
          .addr none              ; M delete lines
          .addr none              ; N
          .addr none              ; O
          .addr none              ; P delete char
          .addr none              ; Q
          .addr none              ; R
          .addr none              ; S scroll up
          .addr none              ; T scroll down
          .addr none              ; U
          .addr none              ; V
          .addr none              ; W
          .addr none              ; X
          .addr none              ; Y
          .addr none              ; Z
lower:    asl
          tax
    stx ESCDIAG
          jsr   (.LOWORD(ltable),x)
          bra   endesc
ltable:   .addr none              ; `
          .addr none              ; a
          .addr none              ; b
          .addr none              ; c
          .addr none              ; d
          .addr none              ; e
          .addr none              ; f cursor position
          .addr none              ; g
          .addr none              ; h
          .addr none              ; i
          .addr none              ; j
          .addr none              ; k
          .addr none              ; l
          .addr sgr               ; m set graphic rendition
          .addr none              ; n device status report (requires input buffer)
          .addr none              ; o
          .addr none              ; p normal screen (optional)
          .addr none              ; q invert screen (optional)
          .addr none              ; r
          .addr none              ; s reset screen (optional)
          .addr none              ; t
          .addr none              ; u
          .addr none              ; v
          .addr none              ; w
          .addr none              ; x
          .addr none              ; y
          .addr none              ; z

.endproc


; set graphic rendition
; very naive test routine
sgr:            nop
                lda #$aa
                sta ESCDIAG
                rep   #SHORT_A
                .a16
                lda ESCPn
                cmp #30
                bcc sgr_exit    ; if less than 30
                cmp #38
                bcc setfgcolor1  ; between 30 and 37, normal fg color

                cmp #90
                bcc sgr_exit    ; if less than 90 and gt than 37
                cmp #98
                bcc setfgcolor2  ; between 90 and 97, bright fg color

                lda #$ff
                sta ESCDIAG
                rts             ; not in rang 30-37 and 90-97, ignore


sgr_exit:       nop
                lda #$fe
                sta ESCDIAG
                rts

setfgcolor1:    nop             ; we assume normal mode
                sep   #SHORT_A
                .a8             ; color in C256 is defined by 1 byte (lo and hi for fg and bg)
                sec
                sbc #30
                sta ESCDIAG
                bra setfgcolor

setfgcolor2:    nop             ; we assume normal mode
                sep   #SHORT_A
                .a8             ; color in C256 is defined by 1 byte (lo and hi for fg and bg)
                sec
                sbc #82             ; because index of bright color starts from 8
                sta ESCDIAG

; very crude
setfgcolor:     nop
                ;rts
                xba             ; preserve low A in high A
                lda f:$00001E   ; CURCOLOR
                and #$0f        ; preserve background bits
                sta f:$00001E
                xba             ; restore low A
                asl             ; move left
                asl
                asl
                asl
                ora f:$00001E
                sta f:$00001E
                sta ESCDIAG
                rep  #SHORT_A
                .a16
                rts




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

