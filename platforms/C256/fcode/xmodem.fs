
\ 2020, Piotr Meyer <aniou+forth@smutek.pl>

\ code based on:

\ XMODEM PROTOCOL ON FORTH-83
\ Wilson M. Federici
\ 1208 NW Grant
\ Corvallis OR 97330  (503) 753-6744
\ Version 1.01  9/85

\ xxx - ." should be converted to something like 'status' word
\          that show progress in statusline or does nothing

\ simplest XMODEM session

\ 
\ SENDER                                      RECEIVER
\ 
\                                         <-- NAK
\ SOH 01 FE Data[128] CSUM                -->
\                                         <-- ACK
\ SOH 02 FD Data[128] CSUM                -->
\                                         <-- ACK
\ SOH 03 FC Data[128] CSUM                -->
\                                         <-- ACK
\ SOH 04 FB Data[128] CSUM                -->
\                                         <-- ACK
\ SOH 05 FA Data[100] CPMEOF[28] CSUM     -->
\                                         <-- ACK
\ EOT                                     -->
\                                         <-- ACK

\ steps: 
\ receive (main loop)
\  - set first response (NAK)
\  - waitrec    
\      - clean-line (drop all from line)
\      - send response
\      - receive first byte
\      - if SOH
\          - rxrec (validate here)
\      - else return first byte or timeout (-1)
\  - handle ACK/NAK/EOT and retries (3)
\    and set next response based on them

start1 decimal

." load XMODEM code" cr

headerless
defer uart-getc?
s" uart-getc?" $find drop to uart-getc?
defer uart-putc?
s" uart-putc?" $find drop to uart-putc?
defer uart-getc
s" uart-getc" $find drop to uart-getc
defer uart-putc
s" uart-putc" $find drop to uart-putc
defer uart-select
s" uart-select" $find drop to uart-select


external

\ : uart-getc? true ;
\ : uart-putc? true ;
\ : uart-getc  true ;
\ : uart-putc  true ;

1  CONSTANT SOH
4  CONSTANT EOT
6  CONSTANT ACK
21 CONSTANT NAK
24 CONSTANT CAN

10 constant txtime \ 1 sec
20 constant stime  \ 2 sec
50 constant ltime  \ 5 sec

variable rec#      \ current record number 
variable tries     \ current attempt number
variable response  \ response for other side

create rec-buf 128 allot

: error-exit
  exit
;

: ?cancel ( char -- char )			\ abort if CAN
  dup can = if 
   cr ." cancelled" error-exit
  then
;


: swait ( u -- char / -1 )          \ -1 means timeout
  uart-getc? if                     \ 0 on timeout
    uart-getc
  else
    -1 
  then
;


: clean-line
  begin stime swait -1 = until      \ timeout for 2 seconds
;


: tx ( char -- )					
  txtime uart-putc? if				\ 0 on timeout
    uart-putc
  else
    cr ." timeout in uart-putc?" error-exit
  then
;

  
: handle-nak ( rec -- response) 
  drop
  ." NAK, tries: " ?
  NAK
;

: handle-tmout ( rec -- response)
  drop
  ." timeout, tries: " tries @ .
  NAK
;

: handle-eot ( rec -- response)
  drop
  ." EOT" cr
  ACK tx
  EOT
;

\ cksum is calculated in rxrec now
\ so this word does almost nothing
: handle-ack ( rec -- response)
  drop
  true
  if 
    1 rec# +!
    ." record ok"  
    cr rec-buf 128 type cr \ debug
    ACK
  else
    ." bad cksum, tries: " ?
    NAK
  then
;

: handle-unk ( rec -- response )
  drop
  ." unknown data, tries: " ?
  NAK
;

\ simplest checksum at rec-buf
: run-sum  ( -- cksum ) 
  0 rec-buf 128                        ( 0, addr,     128 )
  over                                 ( 0, addr,     128,  addr)
  + swap                               ( 0, addr+128, addr )
  do i c@ + loop 255 and               ( cksum )
; 

\ draw some bars, more-or-less every 8
: draw-progress ( addr -- )
  15 and
   8 =
  0<> if
    ." #"
  then
;


\ receive single record calculate sum (crc not yet)
\ exit when error - line is cleaned at begginning of next record
\ xxx - maybe move calculations to handle-ack?
: rxrec ( rec# -- rec#, ACK/NAK)
  stime swait                           ( rec#, rec#/-1 )
  dup -1 = if ." !" else ." #" then
  dup                                   ( rec#, rec#/-1, rec#/-1 )
  255 xor                               ( rec#, rec#/-1, comp1 )
  stime swait                           ( rec#, rec#/-1, comp1, comp2/-1 )
  dup -1 = if ." !" else ." #" then
  <> if 
    ."  rec not math complementary! "
    2drop                               \ drop both rec# - not needed
    nak                                       
    exit						
  then
  \ we probably doesn't need 
  \ a rec# floating around?
  over                                   ( rec#, rec#/-1, rec# )
  <> if			
    ."  bad record no! "
    nak
    exit
  then

  ."  "
  rec-buf 128 over + swap do
    stime swait 
    dup -1 = if ." !" else i draw-progress then
    i c! 
  loop
  ."  "

  stime swait  							( rec#, chksum1 )
  dup -1 = if ." !" else ." #" then
  run-sum                               ( rec#, chksum1, chksum2 )
  = if 
    ."  cksum ok "
    ack
  else
    ."  bad cksum "
    nak
  then
;

\ send response and wait for information from other side
\ SOH means that a new record is on the way  
\ otherwhise return status
: waitrec ( resp, rec# -- rec#, ack/nak/eot/-1 )
  clean-line   
  swap                                 ( rec#, resp )
  tx                                   ( rec# )
  ltime swait                          ( rec#, status   - from swait )
  dup SOH = IF drop rxrec THEN         ( rec#, status   - from rxrec )
;


\ main loop
: receive ( -- resp   - resp eq EOT is considered success)
  1 rec# !
  4 tries !
  NAK 
  begin 
    cr ." rec# " rec# @ dup .				  ( resp, rec# )
    waitrec                             	  ( rec#, status )
    case                                	  
      ACK of handle-ack     3  tries  ! endof    \ reset tries
      EOT of handle-eot     0  tries  ! endof    \ force exit here
      NAK of handle-nak    -1  tries +! endof 
       -1 of handle-tmout  -1  tries +! endof
             handle-unk    -1  tries +! 
    endcase
    tries @                                   ( resp, tries )
    0=
  until
;

\ word used for testing
: txm 
  cr ." test start" cr
  1 uart-select
  begin
    receive
    case
     NAK of cr ." abort, too many attempts " cr exit endof
     EOT of cr ." success"                   cr exit endof
    endcase
  again
;




." end of XMODEM code" cr

fcode-end
