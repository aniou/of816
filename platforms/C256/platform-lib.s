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
PLATFORM_INCLUDE "platform-macros.inc"
.include "platform-kernel-vectors.inc"

cpu_clk   = 14318000

; ---------------------------------------------------------------------
;
.proc       _system_interface
            ;wdm 3
            phx
            asl
            tax
            jmp   (.loword(table),x)
table:      .addr _sf_pre_init
            .addr _sf_post_init
            .addr _sf_emit
            .addr _sf_keyq
            .addr _sf_key
            .addr _sf_fcode
            .addr _sf_reset_all
.endproc
.export     _system_interface

; ---------------------------------------------------------------------
;
.proc       _sf_success
            lda   #$0000
            tay
            clc
            rtl
.endproc

; ---------------------------------------------------------------------
;
.proc       _sf_fail
            ldy   #.loword(-21)
            lda   #.hiword(-21)
            sec
            rtl
.endproc

; ---------------------------------------------------------------------
;
.proc       _sf_pre_init
            ; init text-mode lut table
            setas
            ldx   #$0000
:           lda   .loword(text_color_lut),x
            sta   C256_FG_CHAR_LUT_PTR,x
            sta   C256_BG_CHAR_LUT_PTR,x
            inx
            cpx   #$40                                ; 16 colors * 4 (BGRA)
            bne   :-

            ; set new default color
            ;lda   #$00
            ;sta   C256_BORDER_COLOR_B
            ;sta   C256_BORDER_COLOR_G
            ;sta   C256_BORDER_COLOR_R
            lda   #$78                            ; "white" on "bright black"
            ;lda   #$c4                            ; light blue on blue
            sta   DEF_COLOR
            sta   f:C256_CURCOLOR
            sta   C256_CURSOR_COLOR_REG

            ; update screen color
            ldx   #$0000
:           sta   C256_CS_COLOR_MEM_PTR,x             ; color memory area
            inx
            cpx   #$2000
            bne :-

            ; clear parts of ZP, for testing
            setxl
            lda   #$00
            ldx   #$80                              ; ZP page size
:           sta   $90,x
            dex
            bpl   :-

            setal
            plx
            jmp   _sf_success

; xterm-like palette, adjusted for C256 colors and my needs
;
text_color_lut:  ;  B    G    R  alpha (not used for text?)
            .byte   0,   0,   0, 255  ; black
            .byte   0,   0, 120, 255  ; red
            .byte   0, 120,   0, 255  ; green
            .byte   0, 120, 120, 255  ; yellow
;            .byte 180,   0,   0, 255  ; blue
            .byte $ba, $48, $0c, $ff  ; blue, atari
            .byte 120,   0, 120, 255  ; magenta
            .byte 110, 110,   0, 255  ; cyan
            .byte  64,  64,  64, 255  ; white

            .byte  16,  16,  16, 255  ; bright black
            .byte   0,   0, 255, 255  ; bright red
            .byte   0, 255,   0, 255  ; bright green
            .byte   0, 255, 255, 255  ; bright yellow
;            .byte 255,  92,  92, 255  ; bright blue
            .byte $fe, $ae, $72, $ff  ; bright blue, 'atari'
            .byte 255,   0, 255, 255  ; bright magenta
            .byte 255, 255,   0, 255  ; bright cyan
            .byte 170, 170, 170, 255  ; bright white

.endproc


; ---------------------------------------------------------------------
;
.proc       _sf_post_init
            plx
            jmp   _sf_success
.endproc


; ---------------------------------------------------------------------
;
.proc       _sf_emit_old
            plx
            jsr   _popay
            phx
            php
            phd
            setaxs
            tya
            jsl   C256_PUTCH
            lda   #$01            ; XXX: artifical setting data bank
            pha                   ; XXX: just for emu testing purposes
            plb                   ; XXX: check it again
            setal
            pld
            plp
            setaxl
            plx
            jmp   _sf_success
.endproc



; ---------------------------------------------------------------------
;
.proc       _con_write
            setaxs
            phd                   ; test for emu, XXX - probably not required
            tya
            jsl   C256_PUTCH
            pld                   ; test for emu, XXX - probably not required
            setaxl
            rts
.endproc

; ---------------------------------------------------------------------
; "In the standard ECMA-48, which can be considered X3.64’s successor,
; there is; a distinction between a parameter with an empty value
; (representing the default ; value), and one that has the value zero.
; There used to be a mode, ZDM (Zero Default Mode), in which the two
; cases were treated identically, but that is now deprecated in the
; fifth edition (1991)"
;
; In following code there is a ZDM used - '0' means 'default', for
; example '1', but it is depended from particular function
; 'None' (for example 'CSI [m' ) also means 'default' and is achieved
; by putting 0 into all P0..P15 words at start - and when nothing is
; parsed then Pn variables still holds initial zeroes.

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
            jmp   (.loword(table),x)
table:      .addr _mode0            ; no ESC sequence in progress
            .addr _mode1            ; ESC but no [ yet
            .addr _mode2            ; ESC[ in progress
do_null:    plp                     ; really reqiured?
            plx
            jmp   _sf_success
.endproc

.proc       _mode0
            cpy   #$1B                ; ESC
            bne   :+
            inc   ESCMODE
            bra   done
:           lda   f:C256F_MODEL_MAJOR
            cmp   #$01            ; another crude hack, go65c816 has 1 here, IDE has 0, hw has 43
            beq   :+
            cpy   #$0a            ; crude hack - c256 mimic c65 and uses cr only
            beq   done            ; LF is interpreted as extra line down. XXX - make 'cr_mode'
:           jsr   _con_write
done:       plp
            plx
            jmp   _sf_success
.endproc

.proc       _mode1
            cpy   #'['                ; second char in sequence?
            beq   :+                  ; yes, change modes
            stz   ESCMODE             ; otherwise back to mode 0
            phy
            ldy   #$1B
            jsr   _con_write          ; output the ESC we ate
            ply
            jsr   _con_write          ; and output this char
            bra   done
:           stz   ESCACC
            stz   ESCNUM              ; clear number of parameters
            ldx   #0                  ; clear all Pn (16)
:           stz   ESCPn, x
            inx
            inx
            cpx   #32
            bcc   :-
            lda   #4                  ; four digits, at 0 we set ESCACC to 9999, at -1 we do nothing
            sta   NUMCOUNT            ; max parameter value - four digits
            inc   ESCMODE             ; sequence started!
done:       plp
            plx
            jmp   _sf_success
.endproc

.proc     _mode2
            ;wdm   10
            cpy   #' '                ; ignore spaces in codes
            beq   done

            cpy   #';'
            bne   :+

            jsr   store_pn            ; save acc to parameter and reset vars
            bra   done

:           lda   NUMCOUNT            ; how many digits was processed?
            bmi   done                ; -1? then default max value was already set
            bne   :+
            lda   #9999               ; if there is a fifth number then max should be set
            sta   ESCACC
            dec   NUMCOUNT            ; but only one time, we use -1 to mark this
            bra   done

:           tya
            sec
            sbc   #$30
            bmi   endesc              ; eat it and end ESC mode if invalid
            cmp   #$0a
            bcs   :+                  ; try letters if not a digit
            tay                       ; a digit, accumulate it into ESCACC
            lda   #10                 ; multiply current ESCACC by 10
            sta   MNUM2
            lda   #$0000              ; initialize result
            beq   elp
do_add:     clc
            adc   ESCACC
lp:         asl   ESCACC
elp:        lsr   MNUM2
            bcs   do_add
            bne   lp
            sta   ESCACC              ; now add the current digit
            tya
            clc
            adc   ESCACC
            sta   ESCACC
            dec   NUMCOUNT
            bra   done

:           nop
            jsr   store_pn            ; not a digit, store ACC in Pn and...
            tya                       ;              try letter codes

            sec
            sbc   #'@'
            bmi   endesc
            cmp   #$1B                ; ctrl+Z
            bcc   upper               ; upper case code
            sbc   #$20                ; convert lower case to 00-1A
            bmi   endesc
            cmp   #$1B
            bcc   lower               ; lower case codes
endesc:     nop                       ; zbedne?
            setaxl
            stz   ESCMODE
done:       plp
            plx
            jmp   _sf_success
none:       rts
upper:      asl
            tax
            jsr   (.loword(utable),x)
            bra   endesc

utable:     .addr none              ; @ insert char
            .addr none              ; A cursor up
            .addr none              ; B cursor down
            .addr none              ; C cursor forward
            .addr none              ; D cursor backward
            .addr none              ; E cursor next line
            .addr none              ; F cursor previous line
            .addr none              ; G cursor horizontal absolute
            .addr cup               ; H cursor position
            .addr none              ; I
            .addr ed                ; J erase display
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
lower:      asl
            tax
            jsr   (.LOWORD(ltable),x)
            bra   endesc
ltable:     .addr none              ; `
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


store_pn:   nop                     ; store parameter

            ldx   ESCNUM            ; how many p1;p2;p3;pn parameters?
            cpx   #32               ; max 16 (16*2)? - ignore following
            bcs   store1

            lda   ESCACC            ; move ACC to EXCPn if
            sta   ESCPn, x
            inx
            inx
            stx   ESCNUM

store1:     stz   ESCACC
            lda   #4                ; reset number of valid
            sta   NUMCOUNT
            rts

.endproc

; ---------------------------------------------------------------------
; 8.3.21 CUP - CURSOR POSITION
;
;   Pn1 - row    from 1
;   Pn2 - column from 1

.proc       cup                        ; CSI n ; m H (n - row from 1, m column from 1)
            setaxl
            lda   ESCPn                ; row, 0=default, default=1, 1=1 - but '1' means '0' in FMX Kernel
            beq   :+
            dec                        ; because LOCATE uses indexes from 0
            cmp   f:C256_LINES_VISIBLE ; comparing with number of columns is convinient because C may be used >=
            bcc   :+
            lda   f:C256_LINES_VISIBLE
            dec                        ; because number of visible cols = Y position + 1
:           tay

            lda   ESCPn+2
            beq   :+
            dec
            cmp   f:C256_COLS_VISIBLE
            bcc   :+
            lda   f:C256_COLS_VISIBLE
            dec
:           tax

            jsl   C256_LOCATE          ; ILOCATE preserves all register, I hope...
            rts

.endproc

; ---------------------------------------------------------------------
; 8.3.39 ED - ERASE IN PAGE
;
;   Ps
;   0 - default, from cursor to end of screen
;   1 -          from cursor to beginning of screen
;   2 -          entire screen
;   3 -          entire screen and scrollback buffer
;
; note: there is no support for ERASURE MODE (ERM)

.proc       ed
            setaxl
            lda   ESCPn
            beq   ed_0
            dec
            beq   ed_1
            dec
            beq   ed_2
            dec
            beq   ed_2            ; we do not have a scrollback
            rts                   ; greater than 3? do nothing

ed_0:       nop
            lda   f:C256_CURSORY
            asl
            asl
            asl
            asl
            asl
            asl
            asl
            adc   f:C256_CURSORX
            pha                   ; save copy for later use
            tax
            setas
            lda   #$20
:           sta   C256_CS_TEXT_MEM_PTR, x
            inx
            cpx   #$2000
            bne   :-

            plx                   ; restore saved position
            lda   DEF_COLOR
:           sta   C256_CS_COLOR_MEM_PTR, x
            inx
            bne   :-
            rts

ed_1:       nop
            lda   f:C256_CURSORY
            asl
            asl
            asl
            asl
            asl
            asl
            asl
            adc   f:C256_CURSORX
            pha                   ; save copy for later use
            tax
            setas
            lda   #$20
:           sta   C256_CS_TEXT_MEM_PTR, x
            dex
            bpl   :-

            plx                   ; restore saved position
            lda   DEF_COLOR
:           sta   C256_CS_COLOR_MEM_PTR, x
            dex
            bpl   :-
            rts


ed_2:       setas
            ldx   #$2000
            lda   #$20            ; space
:           sta   C256_CS_TEXT_MEM_PTR, x
            dex
            bpl   :-

            ldx   #$2000
            lda   DEF_COLOR
:           sta   C256_CS_COLOR_MEM_PTR, x
            dex
            bpl   :-
            rts

.endproc

; set graphic rendition
; supported codes
;
;   0       - reset attributes
;   7       - reverse video            XXX - make special attribute for that
;   8       - hide                     XXX - make special attr. for that too
;  28       - reveal
;  30 -  37 - foreground color
;  39       - default foreground
;  40 -  47 - background color
;  49       - default background
;  90 -  97 - bright foreground color
; 100 - 107 - bright background color

.proc       sgr
            ;wdm   10
            ;rts
            setal
            ; at this moment cases like CSI 0 m and CSI m are treated in the same way
            ; - ESCACC is zeroed at beginning and move to ESCPn when letter code is
            ; found, thus 0m has the same effect that już m
            ; only side-effect comes when there is difference betwen single parameter
            ; '0' and 'no parameters', but it is not a case for SGR support
            ldx   #$00            ; we go through params up to ESCNUM, 02 means 'first parameter'
sgr0:       lda   ESCPn, x
            beq   reset           ; CSI 0 m - also reset

            cmp   #30
            bcc   next_parm       ; if less than 30
            cmp   #38
            bcs   :+              ; if >= 38
            sec
            sbc   #30             ; color index (0-7)
            bra   set_fg

:           cmp   #39             ; default foreground?
            bne   :+
            lda   DEF_COLOR       ; set_fg is universal and uses values 0-f
            rol
            rol
            rol
            rol
            bra   set_fg

:           cmp   #40
            bcc   next_parm
            cmp   #48
            bcs   :+              ; if >= 48
            sec
            sbc   #40             ; color index (0-7)
            bra   set_bg

:           cmp   #49             ; default bacground?
            bne   :+
            lda   DEF_COLOR
            and   #$0f
            bra   set_bg

:           cmp   #90
            bcc   next_parm       ; if less than 90
            cmp   #98
            bcs   :+              ; if >= 98
            sec
            sbc   #82             ; color index (8-15)
            bra   set_fg

:           cmp   #100
            bcc   next_parm       ; if less than 100
            cmp   #108
            bcs   next_parm       ; if >= 108
            sec
            sbc   #92             ; color index (8-15)
            bra   set_bg

next_parm:  inx
            inx                   ; jesli zaczynamy od braku parametrof (feff to tu jest zero i idzie w krzaki !!!)
            cpx   ESCNUM          ; ESCNUM - to jest dokladnie liczba parametrow * 2 wiec musi byc wiecej
            bcc   sgr0
            rts                   ; END

reset:      setas
            ;wdm   10
            lda   DEF_COLOR
            sta   f:C256_CURCOLOR
            setal
            bra   next_parm       ; end or return to params

; A - color index to be set
set_fg:     setas
            xba                   ; preserve low A in high A
            lda   f:C256_CURCOLOR
            and   #$0f            ; preserve background bits
            sta   f:C256_CURCOLOR
            xba                   ; restore low A (color index)
            asl                   ; move left
            asl
            asl
            asl
            ora   f:C256_CURCOLOR
            sta   f:C256_CURCOLOR
            setal
            bra   next_parm

; A - color index to be set
set_bg:     setas
            xba                   ; preserve low A in high A
            lda   f:C256_CURCOLOR
            and   #$f0            ; preserve forground bits
            sta   f:C256_CURCOLOR
            xba                   ; restore low A (color index)
            ora   f:C256_CURCOLOR
            sta   f:C256_CURCOLOR
            setal
            bra   next_parm
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
	tay                         ; anticipate false
	lda   f:C256_KEY_BUFFER_RPOS
	cmp   f:C256_KEY_BUFFER_WPOS  ; is KEY_BUFFER_RPOS < KEY_BUFFER_WPOS
	bcs   :+                    ; no - it is <=, no key is present
	dey                         ; from $0000 to $FFFF when key is present
:	tya
	plx
	jsr   _pushay
	jmp   _sf_success
.endproc

.proc     _sf_key
	php
            ;phb
            phd                         ; XXX: for emu testing
	lda   #0000
	tay
	jsl   C256_GETCHW
	and   #$00ff                ; only byte lower is needed
	tay
            pld                         ; XXX: for emu testing
            ;plb
            setas
            lda #$3a
            pha
            plb
            setal
	plp
	lda   #$0000
	plx
	jsr   _pushay
	jmp   _sf_success
.endproc



.proc       _sf_fcode
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
.proc       _sf_reset_all
            plx
            rtl                  ; return to BASIC816
.endproc

