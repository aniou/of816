;
; ESC mode for OF terminal emu
; Zero Page
;
ESCMODE  = DP_END
ESCACC   = ESCMODE+2          ; accumulator for OF terminal emu
MNUM2    = ESCACC+2           ; factor for converting numbers
;ESCNUM   = MNUM2+2            ; parameter number (0-15) doubled by factor 2 XXX: to one byte?
;NUMCOUNT = ESCNUM+2           ; digit number in Pn
;ESCPn    = NUMCOUNT+2         ; 32 bytes for 16 P parameter numbers, see notes.md
;ESCDIAG  = ESCPn+32           ; 2 bytes for diagnostic
;ESCEND   = ESCDIAG+2

ESCNUM   = $B0                ; parameters count, doubled by 2 - aligned for better debug
NUMCOUNT = ESCNUM+2           ; digit number in Pn
ESCPn    = $C0                ; 32 bytes for 16 P parameter numbers
ESCDIAG  = $E0                ; 2 bytes, aligned for better visibility

; Constants
DEF_FG     = $07
DEF_BG     = $08
DEF_COLORS = $78              ; "white" on "bright black", $78

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
