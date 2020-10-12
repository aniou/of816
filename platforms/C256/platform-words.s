; Platform support dictionary words for C256 FOENIX FMX
;



; ---------------------------------------------------------------------
; experimental words for ANSI support, as long FoenixIDE has bugs...

.FEATURE STRING_ESCAPES

dword     X1,"X1"
          ENTER
          SLIT "normal:\"(20 1B)[30mblack"
          .dword TYPE
          .dword CR
          EXIT
eword


; ---------------------------------------------------------------------


dword     dCPU_HZ,"$CPU_HZ"
          FCONSTANT cpu_clk
eword

; ---------------------------------------------------------------------
;
;

; (ms --) - range from 1 to 65535 in 1/10 of second
; with more-or-less accuracy

; cycles count:
;
; 43 + 4 +     - init

; (
;     3 +         - ldx
;     (28636 * 5) - x loop
;     -1          - exit form x loop has 4 cycles
;  + 5            - y loop
; ) * Y 
; -1              - exit from y loop has 4 cycles

; ...             - exit from routine
;

; for example 
; 14318000 cycles/s / 5 = 2863600
; 2863600 / 100 = 28636 (x loops per 1/100 of second)

; now 100 10ms lasts  14318752 cycles from wdm to wdm
; 42 + 4 + ((3+((28636 * 5)-1) + 5) * 100)-1 + 7 = 14318752

dword	TENMS,"10MS"
	;wdm 10
	jsr   _popay            ;  42 cyc, pop value to write
	phx			;   4 cyc, (save SP)
	;ldy #ycnt              ;   3 cyc, (from stack)
sleep0:	ldx #28636              ;   3 cyc, should be calc from cpu_clk/5
sleep1:	dex			;   2 cyc                   ; 5 cycles * X
	bne sleep1		;   3 or 2 at end 			;
        dey			;   2 cyc
	bne sleep0		;   3 or 2 at end
	tay			; 2          A was equal to 0
        plx                     ; 5
	;wdm 10
	NEXT
eword


; delay calculations
; test_uart_and_ldy# = 18 cycles
; inner_loop         = 5  cycles
; outer_loop         = 5  cycles
; no_branch          = 1  loop is shorter when no branch is taken
; (((test_uart_and_ldy# + (28631 * inner-loop) - no_branch) + outer_loop) * 100) - no_branch = ~14317699
; when 14318000 is required
;
UART_LSR	= $05		; Line Status Register index
LSR_DATA_AVAIL	= $01		; Data is ready in the receive buffer, bitmask
LSR_XMIT_EMPTY  = $20		; Empty transmit holding register
CURRUART	= $000700	; 3-bytes: the base address of the current UART

dword		UART_GETCQ,"UART-GETC?"
		jsr  _popay		;  42   - pop value to write
		phx			;   4   - save forth SP
		phd			;   4   - save Direct Page
		tyx			;   2   - delay counter to X
		lda  #CURRUART		;   3   - set DP to CURRUART (0700) and later use lda [0],x
		tcd			;   2
		lda  #$0000             ;   3   - clear A, for later use
		sep  #SHORT_A		;   3   - later we will use short
		.a8

test_uart:	ldy #UART_LSR		;   3   - begin UART test
		lda [0], y		;   7   - A is short but DP is set to 0700
		and #LSR_DATA_AVAIL	;   2   -
		bne finish_test		;   3/2 - quit if 1 or fall to ~1/100 sec delay

		ldy #28631              ;   3   - see calculations at top
sleep1:		dey			;   2
		bne sleep1		;   3/2 - small loop, delay between tests
		dex			;   2
		bne test_uart		;   3/2 - larger loop, go to next test

finish_test:	rep #SHORT_A		;         A has now 1 if there is byte or 0 if timeout
		.a16
		tay			;       - A,Y=0 when false or A,Y=1 when true
		pld			;	- restore DP
		plx			;	- restore forth SP
		jsr _pushay
		NEXT
eword

; XXX - porawic true na 'all one bits'

dword		UART_PUTCQ,"UART-PUTC?"
		jsr  _popay		;  42   - pop value to write
		phx			;   4   - save forth SP
		phd			;   4   - save Direct Page
		tyx			;   2   - delay counter to X
		lda  #CURRUART		;   3   - set DP to CURRUART (0700) and later use lda [0],x
		tcd			;   2
		lda  #$0000             ;   3   - clear A, for later use
		sep  #SHORT_A		;   3   - later we will use short
		.a8

test_uart:	ldy #UART_LSR		;   3   - begin UART test
		lda [0], y		;   7   - A is short but DP is set to 0700
		and #LSR_XMIT_EMPTY	;   2   -
		bne finish_test		;   3/2 - quit if 1 or fall to ~1/100 sec delay

		ldy #28631              ;   3   - see calculations at top
sleep1:		dey			;   2
		bne sleep1		;   3/2 - small loop, delay between tests
		dex			;   2
		bne test_uart		;   3/2 - larger loop, go to next test

finish_test:	rep #SHORT_A		;         A has now 1 if THR is empty or 0 if timeout
		.a16
		tay			;       - A,Y=0 when false or A,Y=0x20 when true
		pld			;	- restore DP
		plx			;	- restore forth SP
		jsr _pushay
		NEXT
eword



; ---------------------------------------------------------------------

; XXX : so terrible and non-portable between kernels, but there is no
;       vector for this
C256_UART_PUTC   = $38441a
C256_UART_SELECT = $384345
C256_UART_HASBYT = $3843d8
C256_UART_GETC   = $3843f9


; default UART is set by UART_SELECT, but at this moment we rely on
; C256 init and UART being set to port 0

; UART-SELECT (u -- ) select COM to user (1 or 2)
; XXX - check input
dword     UART_SELECT ,"UART-SELECT"
          jsr   _popay            ; pop value to write
          phx                     ; save sp
          tya                     ; value to a
          jsl C256_UART_SELECT
; xxx - temporary
          rep   #SHORT_A
          .A16
          lda #96		  ; UART_1200
          jsl $384367	          ; JSL UART_SETBPS
          plx                     ; restore sp
          NEXT
eword


; UART-PUTC (u -- ) send value by serial
;
dword     UART_PUT ,"UART-PUTC"
          jsr   _popay            ; pop value to write
          phx                     ; save sp
          tya                     ; value to a
          jsl C256_UART_PUTC
          rep   #SHORT_A
          .A16
          plx                     ; restore sp
          NEXT
eword

; UART-PUTS (addr u --) address and length, send string via serial
;
dword   UART_PUTS,"UART-PUTS"
        jsr _popay   			; pop offset
	    sta XR+2				; effective 0
        sty XR                	; save low word
        jsr _popay				; pop addr of string write
		sta YR+2
		sty YR
		phx						; save sp

		ldy #0					; clear counter
        sep #SHORT_A
		.a8
puts1:	lda [YR],Y
		phy						; i'm not happy with that but
        jsl C256_UART_PUTC
		ply						; so far it must be enough
        iny
		cpy XR
		bcc puts1
		rep #SHORT_A
		.a16
		plx						; restore sp
        NEXT
eword

; ; 
; ;
; dword	UART_HASBYT,"UART-HASBYT?"
; 		jsl C256_UART_HASBYT
; 		rep #SHORT_A
; 		.a16
; 		ldy #$0000
; 		bcc :+
; 		dey
; :		tay
; 		jsr _pushay
; 		NEXT
; eword
; 

dword	UART_GETC,"UART-GETC"
		jsl C256_UART_GETC
		rep #SHORT_A
		.a16
		and #$00ff
		tay
		lda #$0000
		jsr _pushay
		NEXT
eword

; XXX - horrible and ugly, copy fcode scanne from original impl.

.if include_fcode && romloader_as_word ; SXB stuff, should do different
dword     LW,"LW"
          ENTER
          ONLIT :+
          .dword ONE
          .dword BYTE_LOAD
          EXIT
:         PLATFORM_INCBIN "fcode/xmodem.fc"
eword
dword     LA,"LA"
          ENTER
          ONLIT :+
          .dword ONE
          .dword BYTE_LOAD
          EXIT
:         PLATFORM_INCBIN "fcode/ansi.fc"
eword
dword     LE,"LE"
          ENTER
          ONLIT :+
          .dword ONE
          .dword BYTE_LOAD
          EXIT
:         PLATFORM_INCBIN "fcode/editor.fc"
eword
.endif

