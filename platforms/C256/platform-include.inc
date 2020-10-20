;
; ESC mode for OF terminal emu
; Zero Page
;
                                 ; addr  size
ESCMODE   = DP_END               ; $34   2 bytes
ESCACC    = ESCMODE+2            ; $36   2 bytes accumulator for OF terminal emu
MNUM2     = ESCACC+2             ; $38   2 bytes factor for converting numbers
DEF_COLOR = MNUM2+2              ; $3a   1 byte  default fore color
                                 ; $3b           first free

;ESCNUM   = MNUM2+2            ; parameter number (0-15) doubled by factor 2 XXX: to one byte?
;NUMCOUNT = ESCNUM+2           ; digit number in Pn
;ESCPn    = NUMCOUNT+2         ; 32 bytes for 16 P parameter numbers, see notes.md
;ESCDIAG  = ESCPn+32           ; 2 bytes for diagnostic
;ESCEND   = ESCDIAG+2

ESCNUM   = $B0                  ; $b0   2 bytes parameters count, doubled by 2 - aligned for better debug
NUMCOUNT = ESCNUM+2             ; $b2   2 bytes digit number in Pn
ESCPn    = $C0                  ; $c0  32 bytes for 16 P parameter numbers
ESCDIAG  = $E0                  ; $e0   2 bytes, aligned for better visibility

; C256 addresses and vectors
C256_COLS_VISIBLE     = $0F
C256_LINES_VISIBLE    = $13
C256_CURSORX          = $1A
C256_CURSORY          = $1C
C256_CURCOLOR         = $1E

; memory areas
C256_KEY_BUFFER_RPOS  = $0f8b
C256_KEY_BUFFER_WPOS  = $0f8d

; vector tables
C256_BOOT             = $1000
C256_PUTCH            = $1018
C256_GETCHW           = $104c
C256_LOCATE           = $1084

; memory regions
C256_FG_CHAR_LUT_PTR  = $AF1F40
C256_BG_CHAR_LUT_PTR  = $AF1F80
C256_CS_TEXT_MEM_PTR  = $AFA000
C256_CS_COLOR_MEM_PTR = $AFC000

; eof
