
\ 2020, Piotr Meyer <aniou+forth@smutek.pl>

\ ansi testing words

start1

." load ANSI tests" cr

external

: ta00
  " reset by 0m"(20 1B)[0m"
  type
  CR
;

: ta01
  " reset by m"(20 1B)[m"
  type
  CR
;

: tabg1
  " normal bg:"(20 1B)[40mblack"
  type
  " "(20 1B)[41mred"
  type
  " "(20 1B)[42mgreen"
  type
  " "(20 1B)[43myellow"
  type
  " "(20 1B)[44mblue"
  type
  " "(20 1B)[45mmagenta"
  type
  " "(20 1B)[46mcyan"
  type
  " "(20 1B)[47;30mwhite"
  type
  " "(20 1B)[0m"
  type
  CR
;

: tabg2
  " bright bg:"(20 1B)[100mblack"
  type
  " "(20 1B)[101mred"
  type
  " "(20 1B)[102mgreen"
  type
  " "(20 1B)[103myellow"
  type
  " "(20 1B)[104mblue"
  type
  " "(20 1B)[105mmagenta"
  type
  " "(20 1B)[106mcyan"
  type
  " "(20 1B)[107;30mwhite"
  type
  " "(20 1B)[0m"
  type
  CR
;

: tafg1
  " normal fg:"(20 1B)[30mblack"
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
  " "(20 1B)[37mwhite"
  type
  " "(20 1B)[0m"
  type
  CR
;

: tafg2
  " bright fg:"(20 1B)[90;40mblack"(1B)[0m"
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

: ta
  tafg1 tafg2 tabg1 tabg2
;

." ANSI tests loaded" cr

fcode-end
