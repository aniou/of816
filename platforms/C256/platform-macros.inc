
; C256-style macros

.macro setaxs
     sep #$30
    .a8
    .i8
.endmacro

.macro setas
    sep #$20
    .a8
.endmacro

.macro setxs
    sep #$10
    .i8
.endmacro

.macro setaxl
    rep #$30
    .a16
    .i16
.endmacro

.macro setal
    rep #$20
    .a16
.endmacro

.macro setxl
    rep #$10
    .i16
.endmacro

; eof
