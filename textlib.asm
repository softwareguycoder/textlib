;  Library name     : textlib
;  Version          : 1.0
;  Created date     : 18 Dec 2018
;  Last update      : 18 Dec 2018
;  Author           : Brian Hart
;  Description      : A linkable library of text-oriented procedures and tables
;
;  Build using these commands:
;    nasm -f elf64 -g -F stabs textlib.asm
;
; This code is from the book "Assembly Language Step by Step: Programming with Linux," 3rd ed.,
; by Jeff Duntemann (John Wiley & Sons, 2009).
;
; The following are equates that define named constants, for enhanced program readability
;
SYS_READ    EQU 3                   ; Syscall number for sys_read
SYS_WRITE   EQU 4                   ; Syscall number for sys_write

OK          EQU 0                   ; Operation completed without errors
ERROR       EQU -1                  ; Operation failed to complete; error flag

STDIN       EQU 0                   ; File Descriptor 0: Standard Input
STDOUT      EQU 1                   ; File Descriptor 1: Standard Output
STDERR      EQU 2                   ; File Descriptor 2: Standard Error

EOF         EQU 0                   ; End-of-file reached

SECTION .bss                            ; Section containing uninitialized data


SECTION .data                           ; Section containing initialized data

; Here we have two parts of a single useful data structure, implementing
; the text line of a hex dump utility.  The first part displays 16 bytes in
; hex separated by spaces.  Immediately following is a 16-character line
; delimited by vertical bar characters.  Because they are adjacent, the two
; parts can be referenced separately or as a single contiguous unit.
; Remember that if DumpLin is to be used separately, you must append an
; EOL before sending it to the Linux console.

    DumpLin: db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"
    DUMPLEN  EQU $-DumpLin
    ASCLin:  db "|................|",10
    ASCLEN:  EQU $-ASCLin
    FULLLEN: EQU $-DumpLin

; The HexDigits table is used to convert numeric values to their hex
; equivalents.  Index by nybble without a scale: [HexDigits+eax]
    HexDigits: db   "0123456789ABCDEF"

; This table allows us to generate text equivalents for binary numbers.
; Index into the table by the nybble using a scale of 4:
    BinDigits: db "0000","0001","0010","0011"
               db "0100","0101","0110","0111"
               db "1000","1001","1010","1011"
               db "1100","1101","1110","1111"
               
; This table is used for ASCII character translation, into the ASCII
; portion of the hex dump line, via XLAT or ordinary memory lookup.
; All printable characters "play through" as themselves.  The high 128 
; characters are transalated into ASCII period (2Eh).  The non-printable
; characters in the low 128 are also translated to ASCII period, as is
; char 127.
DotXlat:
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h, 28h, 29h, 2Ah, 2Bh, 2Ch, 2Dh, 2Eh, 2Fh
    db 30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h, 38h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 3Eh, 3Fh
    db 40h, 41h, 42h, 43h, 44h, 45h, 46h, 47h, 48h, 49h, 4Ah, 4Bh, 4Ch, 4Dh, 4Eh, 4Fh
    db 50h, 51h, 52h, 53h, 54h, 55h, 56h, 57h, 58h, 59h, 5Ah, 5Bh, 5Ch, 5Dh, 5Eh, 5Fh
    db 60h, 61h, 62h, 63h, 64h, 65h, 66h, 67h, 68h, 69h, 6Ah, 6Bh, 6Ch, 6Dh, 6Eh, 6Fh
    db 70h, 71h, 72h, 73h, 74h, 75h, 76h, 77h, 78h, 79h, 7Ah, 7Bh, 7Ch, 7Dh, 7Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh

SECTION .text                           ; Section containing code
    GLOBAL ClearLine, DumpChar, Newlines, PrintLine             ; Procedures
    GLOBAL DumpLin, HexDigits, BinDigits                        ; Data items
    
;-------------------------------------------------------------------------
; ClearLine   : Clear a hex dump line string to 16 zero values
; UPDATED     : 13 Dec 2018
; IN          : Nothing
; RETURNS     : Nothing
; MODIFIES    : Nothing
; CALLS       : DumpChar
; DESCRIPTION : The hex dump line string is cleared to binary 0 by
;               calling DumpChar 16 times, passing it 0 each time.

ClearLine:
    pushad                          ; Save all of the caller's general-purpose (GP) registers to the stack
    mov edx, 15                     ; We're going to go 16 pokes, counting from zero
.poke:
    xor eax, eax                    ; Tell DumpChar to poke a '0' (it looks at the value of EAX for what to poke)
    call DumpChar                   ; Insert the '0' into the hex dump string
    sub edx, 1                      ; DEC doesn't affect CF!
    jae .poke                       ; Loop back if EDX >= 0
    popad                           ; Restore all of the caller's GP registers from the stack
    ret                             ; Go home

;-------------------------------------------------------------------------
; DumpChar    : "Poke" a value into the hex dump line string.
; UPDATED     : 13 Dec 2018
; IN          : Pass the 8-bit value to be poked in EAX.
; RETURNS     : Pass the value's position in the line (0-15) in EDX
; MODIFIES    : EAX, ASCLin, DumpLin
; CALLS       : Nothing
; DESCRIPTION : The value passed in EAX will be put in both the hex dump
;               portion and in the ASCII portion, at the position passed
;               in EDX, represented by a space where it is not a
;               printable character.

DumpChar:
; Push the values that are in the registers EBX and EDI onto the stack.  This is 
; because we will need these registers within this subroutine; however, once we're
; done executing, the caller of this subroutine might have been using EBX and EDI for
; something else.  Therefore, we want to temporarily save the values in these registers
; to the stack (kind of like our "scratch pad") to restore when we're done.
    push ebx                        ; Save caller's EBX
    push edi                        ; Save caller's EDI
; First, we insert the input char into the ASCII portion of the dump line
    mov  bl, BYTE [DotXlat+eax]     ; Translate nonprintables to '.'
    mov  BYTE [ASCLin+edx+1], bl    ; Write to ASCII portion
; Now we insert the hex equivalent of the input char into the hex portion
; of the hex dump line:
    mov  ebx, eax                   ; Save a second copy of the input char
    lea  edi, [edx*2+edx]           ; Calc offset into the hex dump line string (EDX times 3)
; Look up low nybble character and insert it into the hex dump string:
    and  eax, 0000000Fh             ; Mask out all but the low nybble
    mov  al, BYTE [HexDigits+eax]   ; Look up the char equiv. of nybble
    mov  BYTE [DumpLin+edi+2], al   ; Write the char equiv. to the line string
; Look up high nybble character and insert it into the string:
    and  ebx, 000000F0h             ; Mask out all but second-lowest nybble
    shr  ebx, 4                     ; Shift high 4 bits of byte into low 4 bits
    mov  bl, BYTE [HexDigits+ebx]   ; Look up char equiv. of nybble
    mov  BYTE [DumpLin+edi+1], bl   ; Write the char equiv. to the line string
; Done! Let's go home:
    pop  edi                        ; Restore caller's EDI
    pop  ebx                        ; Restore caller's EBX
    ret                             ; Return to caller

;-------------------------------------------------------------------------
; Newlines      : Sends between 1 and 15 newlines to the Linux console
; UPDATED       : 18 Dec 2018
; IN            : # of newlines to send, from 1 to 15, in EDX
; RETURNS       : Nothing
; MODIFIES      : Nothing
; CALLS         : Kernel sys_write
; DESCRIPTION   : The number of newline characters (0Ah) specified in EDX
;                 is sent to STDOUT using INT 80h sys_write. This
;                 procedure demonstrates placing constant data in the
;                 procedure definition itself, rather than in the .data or
;                 .bss sections
Newlines:   
    pushad                          ; Save all the caller's GP registers
    cmp edx,15                      ; Make sure the caller didn't ask for more than 15
    ja  .exit                       ; If so, exit without doing anything
    mov ecx, EOLs                   ; Put address of EOLs table into ECX
    mov eax, SYS_WRITE              ; Specify sys_write call
    mov ebx, STDOUT                 ; Specify File Descriptor 1: Standard Output
    ; Address of data is already in ECX
    ; Number of bytes to write is specified by the EDX value passed in
    int 80h                         ; Make the kernel call
.exit:
    popad           ; Restore all the caller's GP registers
    ret             ; Go home!
EOLs:   db 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10

;-------------------------------------------------------------------------
; PrintLine   : Displays the hex dump line stirng via INT 80h sys_write
; UPDATED     : 13 Dec 2018
; IN          : Nothing
; RETURNS     : Nothing
; MODIFIES    : Nothing
; CALLS       : Kernel sys_write
; DESCRIPTION : The hex dump line string DumpLin is displayed to STDOUT
;               using INT 80h sys_write.  All GP registers are preserved.

PrintLine:
    pushad                          ; Save all of the GP registers of the caller to the stack
    mov  eax, SYS_WRITE             ; Specify sys_write syscall
    mov  ebx, STDOUT                ; Specify File Descriptor 1: Standard output
    mov  ecx, DumpLin               ; Pass offset of line string
    mov  edx, FULLLEN               ; Pass size of the line string
    int  80h                        ; Make kernel call to display line string
    popad                           ; Restore all of the GP registers of the caller back from the stack
    ret                             ; Go home!
    
