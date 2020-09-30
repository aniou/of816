
# VT ANSI support

## about parameters

; VT510 Video Terminal Programmer Information
; 4.3.3 Control Sequences
;
; P...P are parameter characters received after CSI. These
; characters are in the 3/0 to 3/15 range in the code table.
; Parameter characters modify the action or interpretation of the
; sequence. You can use up to 16 parameters per sequence.  You must
; use the ; (3/11) character to separate parameters.
;
; All parameters are unsigned, positive decimal integers, with the
; most significant digit sent first. Any parameter greater than 9999
; (decimal) is set to 9999 (decimal). If you do not specify a value,
; a 0 value is assumed.  A 0 value or omitted parameter indicates
; a default value for the sequence. For most sequences, the default
; value is 1.

