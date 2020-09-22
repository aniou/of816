
\ 2020, Piotr Meyer <aniou+forth@smutek.pl>

\ ansi testing words

start1

." load ANSI tests" cr

external

: tafg1
  " normal:"(20 1B)[30mblack"
  type
  " "(20 1B)[31mred"
  type
  " "(20 1B)[32mgreen"
  type
  " "(20 1B)[33myellow"
  type
  " "(20 1B)[34mblue"
  type
  " "(20 1B)[35mmagenta"
  type
  " "(20 1B)[36mcyan"
  type
  " "(20 1B)[37mwhite"(1B)[0m"
  type
  CR
;

: tafg2
  " bright:"(20 1B)[90;30mblack"
  type
  " "(20 1B)[91mred"
  type
  " "(20 1B)[92mgreen"
  type
  " "(20 1B)[93myellow"
  type
  " "(20 1B)[94mblue"
  type
  " "(20 1B)[95mmagenta"
  type
  " "(20 1B)[96mcyan"
  type
  " "(20 1B)[97mwhite"(1B)[0m"
  type
  CR
;

: tafg
  tafg1 tafg2
;

." end of ANSI code" cr

fcode-end
