
\ 2020, Piotr Meyer <aniou+forth@smutek.pl>

start1 decimal

." load ANSI words" cr

s" get-current vocabulary ANSI also ANSI definitions" evaluate

\ internal words here, do not need to be exposed -----------------------

\ 0-7  - normal FG colors, mapped to 30-37
\ 8-15 - bright FG colors, mapped to 90-97
: id_to_ansi_fg  ( color_index -- ansi_fg_index )
  dup 8 <
  if 30 + else 82 + then ;

: id_to_ansi_bg  ( color_index -- ansi_bg_index )
  dup 8 <
  if 40 + else 92 + then ;

: fbar ( n -- | draws bar of length n by char 0xdb|219 - polygon )
  0 do 219 emit loop ;

: bbar ( n -- | draws bar of length n by char 0x20|32 - space )
  0 do 32  emit loop ;

: color_name ( n -- | prints color name )
  case
     0  of s" Black         " endof
     1  of s" Red           " endof
     2  of s" Green         " endof
     3  of s" Yellow        " endof
     4  of s" Blue          " endof
     5  of s" Magenta       " endof
     6  of s" Cyan          " endof
     7  of s" White         " endof
     8  of s" Bright-Black  " endof
     9  of s" Bright-Red    " endof
    10  of s" Bright-Green  " endof
    11  of s" Bright-Yellow " endof
    12  of s" Bright-Blue   " endof
    13  of s" Bright-Magenta" endof
    14  of s" Bright-Cyan   " endof
    15  of s" Bright-White  " endof
  endcase
  type
;

: space 
  32 emit ;

\ ---------------------------------------------------------------------

external

0 constant BLACK
1 constant RED
2 constant GREEN
3 constant YELLOW
4 constant BLUE
5 constant MAGENTA
6 constant CYAN
7 constant WHITE

8 constant BRIGHT-BLACK
9 constant BRIGHT-RED
10 constant BRIGHT-GREEN
11 constant BRIGHT-YELLOW
12 constant BRIGHT-BLUE
13 constant BRIGHT-MAGENTA
14 constant BRIGHT-CYAN
15 constant BRIGHT-WHITE

: ansi_escape ( -- | output escape code )
  base @ decimal
  27 emit [char] [ emit
  base !
;

: foreground ( n -- | set foreground color to n )
  base @ >r decimal
  ansi_escape id_to_ansi_fg (u.) type [char] m emit 
  r> base !
;

: background ( n -- | set background color to n )
  base @ >r decimal
  ansi_escape id_to_ansi_bg (u.) type [char] m emit
  r> base !
;

: color-reset ( -- | reset bg/fg colors to defaults )
  ansi_escape s" 0" type [char] m emit ;

: .colors
  base @ decimal
  cr
  s"      Color name        foreground       background " type cr 
  16 0 do 
        I 2 u.r                 \ number 
        space 
        I .h
        I color_name
        I id_to_ansi_fg 3 u.r   \ ansi color code 
	    space
        I foreground 12 fbar    \ set color and display bar
        space
        color-reset
        I id_to_ansi_bg 3 u.r   \ ansi color code 
        space
        I background 12 bbar  \ set color and display bar
        color-reset 
        cr 
       loop 
  base !
;

." ANSI words loaded" cr

fcode-end
