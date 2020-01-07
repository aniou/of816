testing 7.3.8.1 Conditional branches - interpretation state

T{ 0 IF 123 THEN -> }T
T{ 1 IF 123 THEN -> 123 }T
T{ -1 IF 123 THEN -> 123 }T
T{ 0 IF 123 ELSE 234 THEN -> 234 }T
T{ 1 IF 123 ELSE 234 THEN -> 123 }T
T{ -1 IF 123 THEN -> 123 }T

testing 7.3.8.2 Case statement - interpretation state

\ abbreviated test, not checking nested

T{ 1 CASE 1 OF 111 ENDOF 2 OF 222 ENDOF 3 OF 333 ENDOF >R 999 R> ENDCASE -> 111 }T
T{ 2 CASE 1 OF 111 ENDOF 2 OF 222 ENDOF 3 OF 333 ENDOF >R 999 R> ENDCASE -> 222 }T
T{ 3 CASE 1 OF 111 ENDOF 2 OF 222 ENDOF 3 OF 333 ENDOF >R 999 R> ENDCASE -> 333 }T
T{ 4 CASE 1 OF 111 ENDOF 2 OF 222 ENDOF 3 OF 333 ENDOF >R 999 R> ENDCASE -> 999 }T

T{ 1 CASE 1- FALSE OF 11 ENDOF 1- FALSE OF 22 ENDOF 1- FALSE OF 33 ENDOF 44 SWAP ENDCASE -> 11 }T
T{ 2 CASE 1- FALSE OF 11 ENDOF 1- FALSE OF 22 ENDOF 1- FALSE OF 33 ENDOF 44 SWAP ENDCASE -> 22 }T
T{ 3 CASE 1- FALSE OF 11 ENDOF 1- FALSE OF 22 ENDOF 1- FALSE OF 33 ENDOF 44 SWAP ENDCASE -> 33 }T
T{ 9 CASE 1- FALSE OF 11 ENDOF 1- FALSE OF 22 ENDOF 1- FALSE OF 33 ENDOF 44 SWAP ENDCASE -> 44 }T

T{ 1 CASE ENDCASE -> }T
T{ 1 CASE 2 SWAP ENDCASE -> 2 }T
T{ 1 CASE 1 OF ENDOF 2 ENDCASE -> }T
T{ 1 CASE 3 OF ENDOF 2 ENDCASE -> 1 }T


testing 7.3.8.3 Conditional loops - interpretation state

T{ 0 BEGIN DUP 5 < WHILE DUP 1+ REPEAT -> 0 1 2 3 4 5 }T
T{ 4 BEGIN DUP 5 < WHILE DUP 1+ REPEAT -> 4 5 }T
T{ 5 BEGIN DUP 5 < WHILE DUP 1+ REPEAT -> 5 }T
T{ 6 BEGIN DUP 5 < WHILE DUP 1+ REPEAT -> 6 }T

T{ 3 BEGIN DUP 1+ DUP 5 > UNTIL -> 3 4 5 6 }T
T{ 5 BEGIN DUP 1+ DUP 5 > UNTIL -> 5 6 }T
T{ 6 BEGIN DUP 1+ DUP 5 > UNTIL -> 6 7 }T

T{ 1 BEGIN DUP 2 > WHILE DUP 5 < WHILE DUP 1+ REPEAT 123 ELSE 345 THEN -> 1 345 }T
T{ 2 BEGIN DUP 2 > WHILE DUP 5 < WHILE DUP 1+ REPEAT 123 ELSE 345 THEN -> 2 345 }T
T{ 3 BEGIN DUP 2 > WHILE DUP 5 < WHILE DUP 1+ REPEAT 123 ELSE 345 THEN -> 3 4 5 123 }T
T{ 4 BEGIN DUP 2 > WHILE DUP 5 < WHILE DUP 1+ REPEAT 123 ELSE 345 THEN -> 4 5 123 }T
T{ 5 BEGIN DUP 2 > WHILE DUP 5 < WHILE DUP 1+ REPEAT 123 ELSE 345 THEN -> 5 123 }T

testing 7.3.8.4 Counted loops - interpretation state

T{ 4 1 DO I LOOP -> 1 2 3 }T
T{ 2 -1 DO I LOOP -> -1 0 1 }T
T{ MID-UINT+1 MID-UINT DO I LOOP -> MID-UINT }T

T{ 1 4 DO I -1 +LOOP -> 4 3 2 1 }T
T{ -1 2 DO I -1 +LOOP -> 2 1 0 -1 }T
T{ MID-UINT MID-UINT+1 DO I -1 +LOOP -> MID-UINT+1 MID-UINT }T

T{ 4 1 DO 1 0 DO J LOOP LOOP -> 1 2 3 }T
T{ 2 -1 DO 1 0 DO J LOOP LOOP -> -1 0 1 }T
T{ MID-UINT+1 MID-UINT DO 1 0 DO J LOOP LOOP -> MID-UINT }T

T{ 1 4 DO 1 0 DO J LOOP -1 +LOOP -> 4 3 2 1 }T
T{ -1 2 DO 1 0 DO J LOOP -1 +LOOP -> 2 1 0 -1 }T
T{ MID-UINT MID-UINT+1 DO 1 0 DO J LOOP -1 +LOOP -> MID-UINT+1 MID-UINT }T

T{ 1 123 SWAP 0 DO I 4 > IF DROP 234 LEAVE THEN LOOP -> 123 }T
T{ 5 123 SWAP 0 DO I 4 > IF DROP 234 LEAVE THEN LOOP -> 123 }T
T{ 6 123 SWAP 0 DO I 4 > IF DROP 234 LEAVE THEN LOOP -> 234 }T

t{ 3 0 do unloop exit loop -> }t
t{ 3 0 do 3 0 do unloop unloop exit loop loop -> }t

t{ 1 0 do true ?leave false loop -> }t

testing 7.3.8.6 Error handling - interpretation state

t{ ' noop catch -> 0 }t
t{ clear ' drop catch -> -4 }t
t{ 123 ' throw catch nip -> 123 }t
