; Platform support dictionary words for C256 FOENIX FMX
;

; ---------------------------------------------------------------------
; directory support words
; for gforth implementation see
; https://forth-standard.org/proposals/directory-experiemental-proposal
;
;
; check after C256's kernel change!

C256_BIOS_STATUS     = $000320   ; 1 byte, see sdos_bios.asm
C256_DOS_STATUS      = $00032E   ; 1 byte, see sdos_fat.asm for statuses
C256_DOS_DIR_PTR     = $000338   ; 4 byte pointer to a directory entry
C256_DOS_FD_PTR      = $000340   ; 4 byte pointer to FD data
C256_DOS_DST_PTR     = $000354   ; 4 bytes - Pointer for transferring data

; another, simpler approach
dword       DIROPEN,"DIROPEN"
            ENTER
            ONLIT .sizeof(filedesc)    ; ( fdsize )
            .dword DUP                 ; fdsize, fdsize
            .dword ALLOC               ; fdsize, fd
            .dword SWAP                ; fd, fdsize
            .dword TWODUP              ; fd, fdsize,  fd, fdsize
            .dword ERASE               ; fd, fdsize
            .dword DROP                ; fd
            .dword DUP                 ; fd, fd
            CODE
            jsr  _popay                ; fd
            sta  f:C256_DOS_FD_PTR+2
            tya
            sta  f:C256_DOS_FD_PTR
            jsl  c256::F_DIROPEN
            bcc  dirop_fail

            lda #00
            tay
            jsr _pushay                ; fd, 0
            NEXT

dirop_fail:
            lda f:C256_DOS_STATUS
            and #$00ff
            tay
            lda f:C256_BIOS_STATUS
            and #$00ff
            jsr _pushay                ; ( fd, hi:bios_stat|lo:dos_stat             )
            NEXT
eword

; read and prints file names
; doesn't returns file name because
; it is located outside of forth memory
; quick poc of read dir function interface
dword       DIRPRINT,"DIRPRINT"          ; ( fd )
dirp_loop:
            jsl  c256::F_DIRNEXT          ; ( fd )
            bcc  dirp_fail


            lda  f:C256_DOS_DIR_PTR    ; file name is located at beginning of struct
            sta  dos::FD_PTR
            lda  f:C256_DOS_DIR_PTR+2
            sta  dos::FD_PTR+2
            lda  [dos::FD_PTR]  ; first char of short filename
            and  #$00ff                ; we need only low byte and setas/al is sparse here
            bne  dirp_notend           ; 00 means 'last entry'

            lda  #$0000
            tay
            jsr  _pushay               ; ( fd, status=0 )

            lda  #$ffff
            tay
            jsr  _pushay               ; ( fd, status=0, flag=true )

            NEXT

dirp_notend:
            cmp  #$e5                  ; deleted file?
            beq  dirp_loop

            ldy  #direntry::ATTRIBUTE
            lda  [dos::FD_PTR], y
            and  #$ff0f
            cmp  #$0f                  ; it is longname?
            beq  dirp_loop

            ; XXX - bad, SIZE is DWORD, not WORD!
            ldy  #direntry::SIZE
            lda  [dos::FD_PTR], y
            tay
            lda  #$0000
            jsr  _pushay               ; ( fd, filesize )

            lda  f:C256_DOS_DIR_PTR    ; file name is located at beginning of struct
            tay
            lda  f:C256_DOS_DIR_PTR+2
            jsr  _pushay               ; ( fd, filesize, direntry )
            lda  #00
            ldy  #11                   ; short name always has 11 chars
            jsr  _pushay               ; ( fd, filesize, direntry, len )
            ENTER
            .dword TYPE                ; ( fd, filesize                ) XXX - change to name/ext scheme! now prints "12345678ext"
            SLIT " "                   ; ( fd, filesize, string, len   )
            .dword TYPE                ; ( fd, filesize                )
            .dword DOTD                ; ( fd                          )
            ;.dword DOTH
            ONLIT  0                   ; ( fd, status=0                )
            ONLIT  0                   ; ( fd, status=0, flag=false    )
            EXIT

dirp_fail:
            lda f:C256_BIOS_STATUS
            and #$00ff
            tay
            lda f:C256_DOS_STATUS
            and #$00ff
            jsr _pushay                ; ( fd, status                  )
            lda  #$0000
            tay
            jsr  _pushay               ; ( fd, status=0, flag=false    )

            NEXT
eword

; user-visible, simple dir word
dword       DOTDIR,".DIR"
            ENTER
            .dword DIROPEN             ; fd, status
            .dword DUP                 ; fd, status, status
            .dword _IFFALSE
            .dword nosuccess
dotdirnext: ;ONLIT 50
            ;.dword TENMS
            .dword DROP                ; fd
            .dword CR
            .dword DIRPRINT            ; fd, status, flag
            .dword _IF
            .dword dotdirnext

nosuccess:
            .dword CR
            SLIT "output status: "
            .dword TYPE
            .dword DOTH
            ONLIT 0
            .dword FREE                ; -  -- and exit
            EXIT

eword

;dword       DIRNEXT,"DIRNEXT"          ; fd
;            jsl  C256_F_DIRNEXT
;            bcc  dirnext_fail
;            lda  f:C256_DOS_DIR_PTR+2  ; file name is located at beginning of struct
;            tay
;            lda  f:C256_DOS_DIR_PTR
;            jsr  _pushay               ; fd direntry
;            lda  #00
;            ldy  #11                   ; short name always has 11 chars
;            jsr  _pushay               ; fd, direntry, len
;
;            lda #00
;            tay
;            jsr _pushay                ; fd, direntry, len, 0
;            NEXT
;
;dirnext_fail:
;            lda f:C256_BIOS_STATUS
;            tay
;            lda f:C256_DOS_STATUS+2
;            jsr _pushay                ; fd, direntry, len, status
;            NEXT
;eword

; ; todo - free path
; ; todo - move asm code to separate words
; ; open-dir ( c-addr u – wdirid wior )
; dword       OPEN_DIR,"OPEN-DIR"
;             ENTER                      ; path, size
;             .dword DUP                 ; path, size, size
;             .dword INCR                ; path, size, size+1
;             .dword DUP                 ; path, size, size+1, size+1
;             .dword ALLOC               ; path, size, size+1, buf
;             .dword SWAP                ; path, size, buf, size+1
;             .dword TWODUP              ; path, size, buf, size2, buf, size2
;             .dword ERASE               ; path, size, buf, size2
;             .dword DROP                ; path, size, buf
;             .dword DUP                 ; path, size, buf,  buf
;             .dword TWOSWAP             ; buf,  buf,  path, size
;             .dword ROT                 ; buf,  path, size, buf
;             .dword SWAP                ; buf,  path, buf, size
;             .dword CMOVE               ; buf
;             ONLIT C256_DOS_FD_SIZE     ; buf,  fdsize
;             .dword DUP                 ; buf,  fdsize, fdsize
;             .dword ALLOC               ; buf,  fdsize, fd
;             .dword SWAP                ; buf,  fd, fdsize
;             .dword TWODUP              ; buf,  fd, fdsize,  fd, fdsize
;             .dword ERASE               ; buf,  fd, fdsize
;             .dword DROP                ; buf,  fd
;             .dword DUP                 ; buf,  fd, fd
;             CODE
;             jsr  _popay                ; buf,  fd
;             sta  f:C256_DOS_FD_PTR+2
;             sta  TMP_PTR+2             ; - scratch, for future use
;             tya
;             sta  f:C256_DOS_FD_PTR
;             sta  TMP_PTR               ; - scratch, for future use
;             ENTER
;             .dword SWAP                ; fd, buf
;             .dword DUP                 ; fd, buf, buf
;             CODE
;             jsr  _popay                ; fd, buf
;             phy
;             ldy  #4                    ; #FILEDESC.PATH in C256 - high byte
;             sta  [TMP_PTR], y
;             dey
;             dey
;             pla
;             sta  [TMP_PTR], y
;             jsl  C256_F_DIROPEN
;             bcc  odir_fail
; 
;             ; ok
;             ENTER                      ; fd, buf
;             ONLIT 0                    ; fd, buf, 0  - free-mem ignores u
;             .dword FREE                ; fd
;             ONLIT 0                    ; fd, 0       - ok
;             EXIT
; 
; odir_fail:  ENTER
;             ONLIT 0                    ; fd, buf, 0
;             .dword FREE                ; fd
;             ONLIT 0                    ; fd, 0
;             .dword FREE                ; -
;             ONLIT 0                    ; 0           - wior=0 - fail
;             CODE
;             lda f:C256_BIOS_STATUS
;             tay
;             lda f:C256_DOS_STATUS
;             jsr _pushay                ; 0, status
;             NEXT
; eword
;
; ; read-dir ( c-addr u1 wdirid – u2 flag wior )
; ; quick poc
; dword       READ_DIR,"READ-DIR"        ; buf, size, fd
;             jsr  _popay                ; buf, size
;             sta  f:C256_DOS_FD_PTR+2
;             tya
;             sta  f:C256_DOS_FD_PTR
;             jsl C256_F_DIRNEXT
;             bcc  ndir_fail
;
;
; ndir_fail   jsr  _stackincr           ; buf   -- drop
;             jsr  _stackincr           ;       -- drop
;
;             CODE
;
;             NEXT
; eword
;


; ---------------------------------------------------------------------
; interface words
; ( c-addr u -- c-addr u ) append \0 to provided buffer, usually string
;                          mostly used for creating 0-terminated strings
;                          needed by FMX Kernel

; note to self - it works, but looks pretty complicated. Although memmove
;      routines also looks pretty complicated

dword       TO_CSTRING,"TO-CSTRING"
            ENTER                      ; ( src, len                                           )
            .dword TWODUP              ; ( src, len,   src, len                               )
            .dword DUP                 ; ( src, len,   src, len,   len                        )
            .dword INCR                ; ( src, len,   src, len,   len+1                      )
            .dword DUP                 ; ( src, len,   src, len,   len+1, len+1               )
            .dword ALLOC               ; ( src, len,   src, len,   len+1, dst                 )
            .dword SWAP                ; ( src, len,   src, len,   dst,   len+1               )
            .dword TWODUP              ; ( src, len,   src, len,   dst,   len+1, dst,   len+1 )
            .dword ERASE               ; ( src, len,   src, len,   dst,   len+1               )
            .dword TWODUP              ; ( src, len,   src, len,   dst,   len+1, dst,   len+1 )
            .dword TWOROT              ; ( src, len,   dst, len+1, dst,   len+1, src,   len   )
            .dword TWOSWAP             ; ( src, len,   dst, len+1, src,   len,   dst,   len+1 )
            .dword ROT                 ; ( src, len,   dst, len+1, src,   dst,   len+1, len   )
            .dword SWAP                ; ( src, len,   dst, len+1, src,   dst,   len,   len+1 )
            .dword DROP                ; ( src, len,   dst, len+1, src,   dst,   len          )
            .dword CMOVE               ; ( src, len,   dst, len+1                             )
            .dword TWOSWAP             ; ( dst, len+1, src, len                               )
            .dword FREE                ; ( dst, len+1                                         )
            EXIT
eword


; ---------------------------------------------------------------------
; file support words

; ( c-addr u -- c-addr u ior )  load file passed as string, returns memory addr,
;                               data length and combined operation status
;
dword       FILE_LOAD,"FILE-LOAD"
            ENTER                      ; ( fname,  len                                   )
            .dword TO_CSTRING          ; ( fname0, len                                   )
            .dword TWODUP              ; ( fname0, len, fname0, len                      )
            .dword DROP                ; ( fname0, len, fname0                           )
            ONLIT .sizeof(filedesc)    ; ( fname0, len, fname0, fdsize                   )
            .dword DUP                 ; ( fname0, len, fname0, fdsize, fdsize           )
            .dword ALLOC               ; ( fname0, len, fname0, fdsize, fd               )
            .dword SWAP                ; ( fname0, len, fname0, fd,     fdsize            )
            .dword TWODUP              ; ( fname0, len, fname0, fd,     fdsize, fd, fdsize  )
            .dword ERASE               ; ( fname0, len, fname0, fd,     fdsize           )
            .dword DROP                ; ( fname0, len, fname0, fd                       )
            .dword SWAP                ; ( fname0, len, fd,     fname0                   )
            .dword OVER                ; ( fname0, len, fd,     fname0, fd               )
            ONLIT 512                  ; supported cluster size
            .dword ALLOC
            .dword DUP                 ; ( fname0, len, fd,     fname0, fd, buf, buf     )
            .dword TWOSWAP             ; ( fname0, len, fd,     buf, buf, fname0, fd     )

            CODE
            ; put memory addr into ptr
            jsr  _popay                ; ( fname0, len, fd,     buf, buf, fname0         )
            sta  f:C256_DOS_FD_PTR+2
            sta  dos::FD_PTR+2
            tya
            sta  f:C256_DOS_FD_PTR
            sta  dos::FD_PTR

            ; update pointer to filename
            jsr  _popay                ; ( fname0, len, fd,     buf, buf                 )
            phy                        ; preserve lower word of filename addr
            ldy  #filedesc::PATH+2
            sta  [dos::FD_PTR], y
            dey
            dey
            pla
            sta  [dos::FD_PTR], y

            ; set pointer to 512-bytes buffer for cluster size
            jsr  _popay                ; ( fname0, len, fd,     buf                      )
            phy
            ldy  #filedesc::BUFFER+2
            sta  [dos::FD_PTR], y
            sta  dos::BUFFER_PTR+2     ; ZP pointer for data copy
            dey
            dey
            pla
            sta  [dos::FD_PTR], y
            sta  dos::BUFFER_PTR       ; ZP pointer for data copy

            ; open and read first 512-bytes
            jsl  c256::F_OPEN
            bcs  :+                    ; C=0 in C256 == failure

	; set fileaddr=0 when something has failed
            lda  #0
            tay
            jsr  _pushay	      ; ; ( name0, len, fd,  buf, fileaddr=0            )
	bra  fopen_finish

:
            ; allocate area for file
            ldy  #filedesc::SIZE+2
            lda  [dos::FD_PTR], y
            sta  dos::SIZE_COUNTER+2   ; save for future use
            pha
            ldy  #filedesc::SIZE
            lda  [dos::FD_PTR], y
            sta  dos::SIZE_COUNTER     ; save for future use
            tay
            pla
            jsr  _pushay               ; ( name0, len, fd,  buf, filelen                 )

            ENTER
            .dword DUP                 ; ( name0, len, fd,  buf, filelen, filelen            )
            .dword ALLOC               ; ( name0, len, fd,  buf, filelen, fileaddr           )
            .dword DUP                 ; ( name0, len, fd,  buf, filelen, fileaddr, fileaddr )

            CODE
            jsr  _popay                ; ( name0, len, fd,  buf, filelen, fileaddr           )
            sta  dos::DST_PTR+2
            sty  dos::DST_PTR

fopen_read:
            ldy  #0
fopen_loop:
	setas	      ; optimize it to words? source buffer already is in power of 2
            lda  [dos::BUFFER_PTR], y  ; relax, '[dir], y' does not wrap at bank boundary
            sta  [dos::DST_PTR], y     ; same as above
	setal

	lda  dos::SIZE_COUNTER
	bne  :+
	dec  dos::SIZE_COUNTER+2
:	dec  dos::SIZE_COUNTER
	beq  fopen_finish

            iny
            cpy  #512
            bne  fopen_loop

            clc
            lda  dos::DST_PTR
            adc  #512
            sta  dos::DST_PTR
            bcc  :+
            inc  dos::DST_PTR+2

            ; read next 512-bytes
:           jsl  c256::F_READ
            bcs  fopen_read            ; C=0 in C256 == failure

fopen_finish:
            ENTER                      ; ( name0, len, fd,  buf, filelen, fileaddr       )
            .dword SWAP                ; ( name0, len, fd,  buf, fileaddr, filelen       )
	.dword TWOPtoR             ; ( name0, len, fd,  buf ) ( R: fileaddr, filelen )
                                       ; ( fname0, len, fd, buf ) ( R: fileaddr, filelen )
            .dword TWOSWAP             ; ( fd, buf, fname0, len ) ( R: fileaddr, filelen )
            .dword FREE                ; ( fd, buf              ) ( R: fileaddr, filelen )
            ONLIT 0
            .dword FREE                ; ( fd                   ) ( R: fileaddr, filelen )
            ONLIT 0
            .dword FREE                ; ( --                   ) ( R: fileaddr, filelen )
	.dword TWORtoP             ; ( fileaddr, filelen    )
            CODE

            lda f:C256_DOS_STATUS
            and #$00ff
            tay
            lda f:C256_BIOS_STATUS
            and #$00ff
            jsr _pushay                ; ( fileaddr, filelen, hi:bios_stat|lo:dos_stat   )
            NEXT

eword

; ( c-addr u -- )  load file passed as string and calls BYTE-LOAD
dword       BYTE_RUN,"BYTE-RUN"
            ENTER                      ; ( filename len          )
            .dword FILE_LOAD           ; ( data len ior          )
            .dword DUP                 ; ( data len ior ior      )
            .dword ZEROQ               ; ( data len ior bool     )
            .dword _IF                 ; 0 is false in of816 but success in kernel
            .dword fload_fail
            ; file_load was ok
            .dword DROP                ; ( data len              )
            .dword TWODUP              ; ( data len data len     )
            .dword DROP                ; ( data len data         )
            ONLIT 1                    ; ( data len data 1       )
            .dword BYTE_LOAD           ; ( data len              )
            .dword FREE                ; ( --                    )
            EXIT

fload_fail:
            .dword CR                  ; ( c-addr u ior          )
            SLIT "ERR: DOS status: "
            .dword TYPE
            .dword DOTH                ; ( c-addr u              )
            .dword FREE                ; ( --                    )
            EXIT
eword

; ( c-addr u -- )  load file passed as string and calls EVAL
dword       CODE_RUN,"CODE-RUN"
            ENTER                      ; ( filename len          )
            .dword FILE_LOAD           ; ( data len ior          )
            .dword DUP                 ; ( data len ior ior      )
            .dword ZEROQ               ; ( data len ior bool     )
            .dword _IF                 ; 0 is false in of816 but success in kernel
            .dword fload_fail
            ; file_load was ok
            .dword DROP                ; ( data len              )
            .dword TWODUP              ; ( data len data len     )
            .dword EVAL                ; ( data len              )
            .dword FREE                ; ( --                    )
            EXIT

fload_fail:
            .dword CR                  ; ( c-addr u ior          )
            SLIT "ERR: DOS status: "
            .dword TYPE
            .dword DOTH                ; ( c-addr u              )
            .dword FREE                ; ( --                    )
            EXIT
eword

; ---------------------------------------------------------------------
; experimental words for ANSI support testing

.FEATURE STRING_ESCAPES

dword     X1,"X1"
          ENTER
          SLIT "normal:\"(20 1B)[30mblack"
          .dword TYPE
          .dword CR
          EXIT
eword

dword     X2,"X2"
          ENTER
          .dword DOTDIR
          SLIT " ansi.fc"
          .dword FILE_LOAD
          .dword DOTS
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

dword       TENMS,"10MS"
            ;wdm 10
            jsr   _popay            ;  42 cyc, pop value to write
            phx                     ;   4 cyc, (save SP)
            ;ldy #ycnt              ;   3 cyc, (from stack)
sleep0:     ldx #28636              ;   3 cyc, should be calc from cpu_clk/5
sleep1:     dex                     ;   2 cyc                   ; 5 cycles * X
            bne sleep1              ;   3 or 2 at end
            dey                     ;   2 cyc
            bne sleep0              ;   3 or 2 at end
            tay                     ;   2 cyc           A was equal to 0
            plx                     ;   5 cyc
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
UART_LSR    = $05                                ; Line Status Register index
LSR_DATA_AVAIL   = $01                           ; Data is ready in the receive buffer, bitmask
LSR_XMIT_EMPTY  = $20                            ; Empty transmit holding register
CURRUART    = $000700            ; 3-bytes: the base address of the current UART

dword            UART_GETCQ,"UART-GETC?"
                 jsr  _popay                     ;  42   - pop value to write
                 phx                                             ;   4   - save forth SP
                 phd                                             ;   4   - save Direct Page
                 tyx                                             ;   2   - delay counter to X
                 lda  #CURRUART                  ;   3   - set DP to CURRUART (0700) and later use lda [0],x
                 tcd                                             ;   2
                 lda  #$0000             ;   3   - clear A, for later use
                 sep  #SHORT_A                   ;   3   - later we will use short
                 .a8

test_uart:  ldy #UART_LSR                        ;   3   - begin UART test
                 lda [0], y                      ;   7   - A is short but DP is set to 0700
                 and #LSR_DATA_AVAIL             ;   2   -
                 bne finish_test                 ;   3/2 - quit if 1 or fall to ~1/100 sec delay

                 ldy #28631              ;   3   - see calculations at top
sleep1:          dey                                             ;   2
                 bne sleep1                      ;   3/2 - small loop, delay between tests
                 dex                                             ;   2
                 bne test_uart                   ;   3/2 - larger loop, go to next test

finish_test:     rep #SHORT_A                    ;         A has now 1 if there is byte or 0 if timeout
                 .a16
                 tay                                             ;       - A,Y=0 when false or A,Y=1 when true
                 pld                                             ;               - restore DP
                 plx                                             ;               - restore forth SP
                 jsr _pushay
                 NEXT
eword

; XXX - porawic true na 'all one bits'

dword            UART_PUTCQ,"UART-PUTC?"
                 jsr  _popay                     ;  42   - pop value to write
                 phx                                             ;   4   - save forth SP
                 phd                                             ;   4   - save Direct Page
                 tyx                                             ;   2   - delay counter to X
                 lda  #CURRUART                  ;   3   - set DP to CURRUART (0700) and later use lda [0],x
                 tcd                                             ;   2
                 lda  #$0000             ;   3   - clear A, for later use
                 sep  #SHORT_A                   ;   3   - later we will use short
                 .a8

test_uart:  ldy #UART_LSR                        ;   3   - begin UART test
                 lda [0], y                      ;   7   - A is short but DP is set to 0700
                 and #LSR_XMIT_EMPTY             ;   2   -
                 bne finish_test                 ;   3/2 - quit if 1 or fall to ~1/100 sec delay

                 ldy #28631              ;   3   - see calculations at top
sleep1:          dey                                             ;   2
                 bne sleep1                      ;   3/2 - small loop, delay between tests
                 dex                                             ;   2
                 bne test_uart                   ;   3/2 - larger loop, go to next test

finish_test:     rep #SHORT_A                    ;         A has now 1 if THR is empty or 0 if timeout
                 .a16
                 tay                                             ;       - A,Y=0 when false or A,Y=0x20 when true
                 pld                                             ;               - restore DP
                 plx                                             ;               - restore forth SP
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
          lda #96                                  ; UART_1200
          jsl $384367                      ; JSL UART_SETBPS
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
dword       UART_PUTS,"UART-PUTS"
            jsr _popay            ; pop offset
            sta XR+2              ; effective 0
            sty XR                ; save low word
            jsr _popay            ; pop addr of string write
            sta YR+2
            sty YR
            phx                   ; save sp

            ldy #0                ; clear counter
            sep #SHORT_A
            .a8
puts1:      lda [YR],Y
            phy                   ; i'm not happy with that but
            jsl C256_UART_PUTC
            ply                   ; so far it must be enough
            iny
            cpy XR
            bcc puts1
            rep #SHORT_A
            .a16
            plx                   ; restore sp
            NEXT
eword

;
;
; dword     UART_HASBYT,"UART-HASBYT?"
;                jsl C256_UART_HASBYT
;                rep #SHORT_A
;                .a16
;                ldy #$0000
;                bcc :+
;                dey
; :              tay
;                jsr _pushay
;                NEXT
; eword


dword       UART_GETC,"UART-GETC"
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

