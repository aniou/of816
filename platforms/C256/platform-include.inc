;
; Zero Page
;
                                ; addr  size
ESCMODE   = DP_END              ; $34   2 bytes
ESCACC    = ESCMODE+2           ; $36   2 bytes accumulator for OF terminal emu
MNUM2     = ESCACC+2            ; $38   2 bytes factor for converting numbers
DEF_COLOR = MNUM2+2             ; $3a   1 byte  default fore color
                                ; $3b           first free

ESCNUM   = $B0                  ; $b0   2 bytes parameters count, doubled by 2 - aligned for better debug
NUMCOUNT = ESCNUM+2             ; $b2   2 bytes digit number in Pn
CR_SEQ   = NUMCOUNT+2           ; $b4   2 bytes - flag != 0 when CR was emitted...
ESCPn    = $C0                  ; $c0  32 bytes for 16 P parameter numbers
                                ; ...

; everlapping temporary vars
;
.struct dos
    .org    $E0
    FD_PTR       .dword         ; $e0 shadow of FD_DOS_PTR
    BUFFER_PTR   .dword         ; $e4 cluster data (512 bytes or cluster size)
    DST_PTR      .dword         ; $e8 where data should me moved
    SIZE_COUNTER .dword         ; $eb how many data we need
.endstruct

; FD structure
; must be keept in sync with Kernel_FMX/src/sdos_fat.asm
;
.struct filedesc
    STATUS              .byte   ; The status flags of the file descriptor (open, closed, error, EOF, etc.)
    DEV                 .byte   ; The ID of the device holding the file
    PATH                .dword  ; Pointer to a NULL terminated path string
    CLUSTER             .dword  ; The current cluster of the file.
    FIRST_CLUSTER       .dword  ; The ID of the first cluster in the file
    BUFFER              .dword  ; Pointer to a cluster-sized buffer
    SIZE                .dword  ; The size of the file
    CREATE_DATE         .word   ; The creation date of the file
    CREATE_TIME         .word   ; The creation time of the file
    MODIFIED_DATE       .word   ; The modification date of the file
    MODIFIED_TIME       .word   ; The modification time of the file
    RESERVED            .word   ; Two reserved bytes to bring the descriptor up to 32 bytes
.endstruct

; Directory entry
; must be keept in sync with Kernel_FMX/src/sdos_fat.asm
.struct direntry
    SHORTNAME           .byte 11        ; $00 - The short name of the file (8 name, 3 extension)
    ATTRIBUTE           .byte           ; $0B - The attribute bits
    IGNORED1            .word           ; $0C - Unused (by us) bytes
    CREATE_TIME         .word           ; $0E - Creation time
    CREATE_DATE         .word           ; $10 - Creation date
    ACCESS_DATE         .word           ; $12 - Last access date
    CLUSTER_H           .word           ; $14 - High word of the first cluster #
    MODIFIED_TIME       .word           ; $16 - Last modified time
    MODIFIED_DATE       .word           ; $18 - Last modified date
    CLUSTER_L           .word           ; $1A - Low word of the first cluster #
    SIZE                .dword          ; $1C - The size of the file (in bytes)
.endstruct


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
C256_BORDER_COLOR_B   = $AF0005
C256_BORDER_COLOR_G   = $AF0006
C256_BORDER_COLOR_R   = $AF0007
C256_CURSOR_COLOR_REG = $AF0013
C256F_MODEL_MAJOR     = $AF070B

; eof
