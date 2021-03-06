;Kernel_INC.asm
;Kernel ROM jump table

; a copy of file Kernel_FMX/src/kernel_inc.asm
; from https://github.com/Trinity-11/Kernel_FMX

.scope c256
BOOT             = $001000 ; Cold boot routine
RESTORE          = $001004 ; Warm boot routine
BREAK            = $001008 ; End program and return to command prompt
READY            = $00100C ; Print prompt and wait for keyboard input
SCINIT           = $001010 ;
IOINIT           = $001014 ;
PUTC             = $001018 ; Print a character to the currently selected channel
PUTS             = $00101C ; Print a string to the currently selected channel
PUTB             = $001020 ; Output a byte to the currently selected channel
PUTBLOCK         = $001024 ; Ouput a binary block to the currently selected channel
SETLFS           = $001028 ; Obsolete (done in OPEN)
SETNAM           = $00102C ; Obsolete (done in OPEN)
OPEN             = $001030 ; Open a channel for reading and/or writing. Use SETLFS and SETNAM to set the channels and filename first.
CLOSE            = $001034 ; Close a channel
SETIN            = $001038 ; Set the current input channel
SETOUT           = $00103C ; Set the current output channel
GETB             = $001040 ; Get a byte from input channel. Return 0 if no input. Carry is set if no input.
GETBLOCK         = $001044 ; Get a X byes from input channel. If Carry is set, wait. If Carry is clear, do not wait.
GETCH            = $001048 ; Get a character from the input channel. A=0 and Carry=1 if no data is wating
GETCHW           = $00104C ; Get a character from the input channel. Waits until data received. A=0 and Carry=1 if no data is wating
GETCHE           = $001050 ; Get a character from the input channel and echo to the screen. Wait if data is not ready.
GETS             = $001054 ; Get a string from the input channel. NULL terminates
GETLINE          = $001058 ; Get a line of text from input channel. CR or NULL terminates.
GETFIELD         = $00105C ; Get a field from the input channel. Value in A, CR, or NULL terminates
TRIM             = $001060 ; Removes spaces at beginning and end of string.
PRINTC           = $001064 ; Print character to screen. Handles terminal commands
PRINTS           = $001068 ; Print string to screen. Handles terminal commands
PRINTCR          = $00106C ; Print Carriage Return
PRINTF           = $001070 ; Print a float value
PRINTI           = $001074 ; Prints integer value in TEMP
PRINTH           = $001078 ; Print Hex value in DP variable
PRINTAI          = $00107C ; Prints integer value in A
PRINTAH          = $001080 ; Prints hex value in A. Printed value is 2 wide if M flag is 1, 4 wide if M=0
LOCATE           = $001084 ;
PUSHKEY          = $001088 ;
PUSHKEYS         = $00108C ;
CSRRIGHT         = $001090 ;
CSRLEFT          = $001094 ;
CSRUP            = $001098 ;
CSRDOWN          = $00109C ;
CSRHOME          = $0010A0 ;
SCROLLUP         = $0010A4 ; Scroll the screen up one line. Creates an empty line at the bottom.
; Undefined label for: SCRGETWORD       = %ADDR% ; Read a current word on the screen. A word ends with a space, punctuation (except _), or any control character (value < 32). Loads the address into CMPTEXT_VAL and length into CMPTEXT_LEN variables.
CLRSCREEN        = $0010A8 ; Clear the screen
INITCHLUT        = $0010AC ; Init character look-up table
INITSUPERIO      = $0010B0 ; Init Super-IO chip
INITKEYBOARD     = $0010B4 ; Init keyboard
; Undefined label for: INITRTC          = %ADDR% ; Init Real-Time Clock
INITCURSOR       = $0010BC ; Init the Cursors registers
INITFONTSET      = $0010C0 ; Init the Internal FONT Memory
INITGAMMATABLE   = $0010C4 ; Init the RGB GAMMA Look Up Table
INITALLLUT       = $0010C8 ; Init the Graphic Engine (Bitmap/Tile/Sprites) LUT
INITVKYTXTMODE   = $0010CC ; Init the Text Mode @ Reset Time
INITVKYGRPMODE   = $0010D0 ; Init the Basic Registers for the Graphic Mode
SETSIZES         = $00112C ; Set the text screen size variables based on the border and screen resolution.
F_OPEN           = $0010F0 ; open a file for reading/writing/creating
F_CREATE         = $0010F4 ; create a new file
F_CLOSE          = $0010F8 ; close a file (make sure last cluster is written)
F_WRITE          = $0010FC ; write the current cluster to the file
F_READ           = $001100 ; read the next cluster from the file
F_DELETE         = $001104 ; delete a file / directory
; Undefined label for: F_RENAME         = %ADDR% ; rename a file
F_DIROPEN        = $001108 ; open a directory and seek the first directory entry
F_DIRNEXT        = $00110C ; seek to the next directory of an open directory
F_DIRREAD        = $001110 ; Read the directory entry for the specified file
F_DIRWRITE       = $001114 ; Write any changes in the current directory cluster back to the drive
F_LOAD           = $001118 ; load a binary file into memory, supports multiple file formats
F_SAVE           = $00111C ; Save memory to a binary file
CMDBLOCK         = $001120 ; Send a command to a block device
F_RUN            = $001124 ; Load and run an executable binary file
F_MOUNT          = $001128 ; Mount the designated block device
F_COPY           = $001130 ; Copy a file
F_ALLOCFD        = $001134 ; Allocate a file descriptor
F_FREEFD         = $001138 ; Free a file descriptor

;
; Interrupt Jump Table
;

VEC_INT00_SOF   = $001700 ; Interrupt routine for Start Of Frame interrupt
VEC_INT01_SOL   = $001704 ; Interrupt routine for Start Of Line interrupt
VEC_INT02_TMR0  = $001708 ; Interrupt routine for Timer0
VEC_INT03_TMR1  = $00170C ; Interrupt routine for Timer1
VEC_INT04_TMR2  = $001710 ; Interrupt routine for Timer2
.endscope
