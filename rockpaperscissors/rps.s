*************************************************************************
*
* This is a simple Rock, Paper, Scissors game implemented in 68000
* assembler code to run on the TS2 single board computer with the
* TUTOR ROM monitor.
*
* It is written for the VASM cross-assembler.
*
* Copyright (C) 2017 Jeff Tranter <tranter@pobox.com>
*
* To Do:
*
* Add alternative version for "rock-paper-scissors-Spock-lizard".
*
*************************************************************************

*************************************************************************
*
* Constants
*
*************************************************************************

CR      equ     $0D                     Carriage return
LF      equ     $0A                     Line feed

* TUTOR TRAP 14 functions
GETNUMD equ     225                     Convert ASCII encoded decimal to hex.
TUTOR   equ     228                     Go to TUTOR; print prompt.
HEX2DEC equ     236                     Convert hex value to ASCII encoded decimal.
PORTIN1 equ     241                     Input string from port 1.
OUTPUT  equ     243                     Output string to port 1.
OUTCH   equ     248                     Output single character to port 1.
FIXDATA equ     250                     Initialize A6 to BUFFER and append string.
FIXBUF  equ     251                     Initialize A5 and A6 to BUFFER.

* Items:
ROCK     equ    1
PAPER    equ    2
SCISSORS equ    3

* Players/Winner:
TIE      equ    0
HUMAN    equ    1
COMPUTER equ    2

*************************************************************************
*
* Main Program Start
*
*************************************************************************

* Start address
        ORG     $1000                   Locate in RAM.

* Initialize variables
* TODO: Make random seed more random (e.g based on user input).

        move.l  #1,SEED                 Random number seed

start
        move.b  #1,TOTALGAMES           Total number of games.
        move.b  #1,GAMENO               Current game number.
        move.b  #0,COMPUTERWON          Games won by computer.
        move.b  #0,HUMANWON             Games won by human player.

        lea.l   (S_WELCOME,pc),a0       Get startup message.
        bsr     PrintString             Display it.
enter
        lea.l   (S_HOWMANY,pc),a0       "How many games do you want to play?"
        bsr     PrintString             Display it.

        bsr     GetString               Get response.
        bsr     ValidDec                Make sure it is a valid number.
        bvs     invalid                 Complain if invalid.
        bsr     Dec2Bin                 Convert it to number.

        cmp.l   #1,d0                   Make sure it is in range from 1 to 10.
        blt     invalid                 Too small.
        cmp.l   #10,d0
        ble     okay                    It is valid.

invalid
        lea.l   (S_INVALID1,pc),a0      "Please enter a number from 1 to 10."
        bsr     PrintString             Display it.
        bra     enter                   Try again.

okay
        move.b  d0,TOTALGAMES           Set total games to play.

gameloop

* Display "Game number: 1 of 10"

        lea.l   (S_GAMENUMBER,pc),a0    "Game number: "
        bsr     PrintString             Display it.
        move.b  GAMENO,d0               Get game number
        bsr     PrintDec                Display it.
        lea.l   (S_OF,pc),a0            " of "
        bsr     PrintString             Display it.
        move.b  TOTALGAMES,d0           Get total games.
        bsr     PrintDec                Display it.
        bsr     CrLf                    Newline.

* Get computer's play. Do this before the human enters their play so
* there can be no accusations of cheating!

        move.l  #1,d0                   Want random number between 1...
        move.l  #3,d1                   and 3.
        bsr     Random                  Generate number.
        move.b  d2,COMPUTERPLAY         Save computer's move.

* Get user's play.

enter1
        lea.l   (S_PLAY,pc),a0          "What do you play?"
        bsr     PrintString             Display it.

        bsr     GetString               Get response.
        bsr     ValidDec                Make sure it is a valid number.
        bvs     invalid1                Complain if invalid.
        bsr     Dec2Bin                 Convert it to number.

        cmp.l   #1,d0                   Make sure it is in range from 1 to 3.
        blt     invalid1                Too small.
        cmp.l   #3,d0
        ble     okay1                   It is valid.

invalid1
        lea.l   (S_INVALID2,pc),a0      "Please enter a number from 1 to 3."
        bsr     PrintString             Display it.
        bra     enter1                  Try again.

okay1
        move.b  d0,HUMANPLAY            Save player's move.

* Report computer's play.

        lea.l   (S_MYCHOICE,pc),a0      "This is my choice..."
        bsr     PrintString             Display it.
        move.b  COMPUTERPLAY,d0         Get computer's move.
        bsr     PrintPlay               Print name of play.
        bsr     CrLf                    Then newline.

* Report human's play.

        lea.l   (S_YOUPLAYED,pc),a0     "You played "
        bsr     PrintString             Display it.
        move.b  HUMANPLAY,d0            Get computer's move.
        bsr     PrintPlay               Print name of play.
        bsr     CrLf                    Then newline.

* Determine who won.

        move.b  HUMANPLAY,d0            Get human player's move
        move.b  COMPUTERPLAY,d1         Get computer's move
        bsr     DetermineWinner         Determine who won
        move.b  d2,WINNER               Save value.

* Report who won and update score.

        cmp.b   #TIE,WINNER             Was it a tie?
        bne     next1                   Branch if not
        lea.l   (S_TIE,pc),a0           "It's a tie."
        bsr     PrintString             Display it.
        bra     nextgame

next1   cmp.b  #COMPUTER,WINNER         Did computer win?
        bne     next2                   Branch if not
        move.b  COMPUTERPLAY,d0         Get computer's move.
        bsr     PrintPlay               Print name of play.
        lea.l   (S_BEATS,pc),a0         " beats "
        bsr     PrintString             Display it.
        move.b  HUMANPLAY,d0            Get human's move.
        bsr     PrintPlay               Print name of play.
        lea.l   (S_IWIN,pc),a0          ", I win."
        bsr     PrintString             Display it.
        add.b   #1,COMPUTERWON          Update won games.
        bra     nextgame

next2                                   * Human won (rare, but it happens).
        move.b  HUMANPLAY,d0            Get human's move.
        bsr     PrintPlay               Print name of play.
        lea.l   (S_BEATS,pc),a0         " beats "
        bsr     PrintString             Display it.
        move.b  COMPUTERPLAY,d0         Get computer's move.
        bsr     PrintPlay               Print name of play.
        lea.l   (S_YOUWIN,pc),a0        ", You win."
        bsr     PrintString             Display it.
        add.b   #1,HUMANWON             Update won games.

nextgame
        add.b   #1,GAMENO               Increment game number.

        move.b  GAMENO,d0               Get game number.
        cmp.b   TOTALGAMES,d0           Last game played?
        ble     gameloop                If not, play next game.

* Report final game scores.

        lea.l   (S_FINALSCORE,pc),a0    "Final game score:"
        bsr     PrintString             Display it.
        lea.l   (S_IWON,pc),a0          "I have won "
        bsr     PrintString             Display it.
        move.b  COMPUTERWON,d0          Get computer won games.
        bsr     PrintDec                Print it.
        cmp     #1,d0                   Handle "game" versus "games".
        beq     one1
        lea.l   (S_GAMES,pc),a0         " games."
        bra     disp1
one1    lea.l   (S_GAME,pc),a0         " game."
disp1   bsr     PrintString             Display it.
        lea.l   (S_YOUWON,pc),a0        "You have won "
        bsr     PrintString             Display it.
        move.b  HUMANWON,d0             Get human won games.
        bsr     PrintDec                Print it.
        cmp     #1,d0                   Handle "game" versus "games".
        beq     one2
        lea.l   (S_GAMES,pc),a0         " games."
        bra     disp2
one2    lea.l   (S_GAME,pc),a0         " game."
disp2   bsr     PrintString             Display it.

* Print the winner

        move.b  HUMANWON,d0
        cmp.b   COMPUTERWON,d0          Compare scores.
        blt     computerwon             Computer won.
        bgt     humanwon                Human won.

        lea.l   (S_TIE1,pc),a0          "It's a tie!"
        bsr     PrintString             Display it.
        bra     playagain

computerwon
        lea.l   (S_IWIN1,pc),a0         "I win!"
        bsr     PrintString             Display it.
        bra     playagain

humanwon
        lea.l   (S_YOUWIN1,pc),a0       "You win!"
        bsr     PrintString             Display it.

* Ask if user wants to play again.

playagain
        lea.l   (S_PLAYAGAIN,pc),a0     "Play again (y/n)? "
        bsr     PrintString             Display it.
        bsr     GetString               Get response.
        cmp.b   #'y',(a0)               Did user enter 'y'?
        beq     start                   If so, go to start
        cmp.b   #'Y',(a0)               Did user enter 'Y'?
        beq     start                   If so, go to start
        cmp.b   #'n',(a0)               Did user enter 'n'?
        beq     exit                    If so, exit
        cmp.b   #'N',(a0)               Did user enter 'N'?
        beq     exit                    If so, exit
        bra     playagain               Otherwise invalid input, try again.

exit
        bra     Tutor                   Return to TUTOR

*************************************************************************
*
* Utility Functions
*
*************************************************************************

************************************************************************
*
* Print a string to the console.
*
* Outputs null-terminated string pointed to by A0 to the console.
*
* Inputs: A0 - pointer to start of string.
* Outputs: none
* Registers changed: none
*
*************************************************************************
PrintString
        movem.l d7/a5/a6,-(sp)          Preserve registers that are changed here or by TUTOR.
        move.l  a0,a5                   TUTOR routine wants start of string in A5.
        move.l  a0,a6                   This will be a pointer to the end of string + 1.
loop1   cmp.b   #0,(a6)+                Find terminating null.
        bne.s   loop1                   Loop until found.
        subq.l  #1,a6                   Undo last increment.

* A5 now points to start of string and A6 points to one past end of string.

        move.b  #OUTPUT,d7              Output string function.
        trap    #14                     Call TRAP14 handler.
        movem.l (sp)+,d7/a5/a6          Restore registers.
        rts

************************************************************************
*
* Get a string from the console, terminated in newline.
*
* Input a string from the console until the user enters newline
* (Enter) and return pointer in A0. String does not include the
* newline character. The same internal buffer is used on each call, so
* copy the string if you need to to be persistent before calling the
* routine again.
*
* Inputs: none
* Outputs: A0 - pointer to start of null-terminated string.
* Registers changed: A0
*
************************************************************************
GetString
        movem.l d7/a5/a6,-(sp)          Preserve registers that are changed here or by TUTOR.

        move.B  #FIXBUF,d7              Initialize A5 and A6 to point to BUFFER.
        trap    #14                     Call TRAP14 handler.

        move.b  #PORTIN1,d7             Input string function.
        trap    #14                     Call TRAP14 handler.

        clr.b   (a6)                    Write null to end of string (A5 points to end+1).
        move.l  a5,a0                   Point pointer to start of string in A0.

        movem.l (sp)+,d7/a5/a6          Restore registers.
        rts

************************************************************************
*
* Print a number to the console in decimal.
*
* Prints decimal value of a 32-bit number on the console.
*
* Inputs: DO - the number to display (longword)
* Outputs: none
* Registers changed: none
*
************************************************************************
PrintDec
        movem.l d0/d7/a5/a6,-(sp)       Preserve registers that are changed here or by TUTOR.

        move.b  #FIXBUF,d7              Initialize A5 and A6 to point to BUFFER.
        trap    #14                     Call TRAP14 handler.

        move.b  #HEX2DEC,d7             Hex to decimal conversion function.
        trap    #14                     Call TRAP14 handler.

        move.b  #OUTPUT,d7              String output function.
        trap    #14                     Call TRAP14 handler.

        movem.l (sp)+,d0/d7/a5/a6       Restore registers.
        rts

************************************************************************
*
* Print a character to the console.
*
* Output the character in D0 to the console.
*
* Inputs: D0 - character to output (in low byte).
* Outputs: none
* Registers changed: none
*
*************************************************************************
PrintChar
        movem.l a0/d0/d1/d7,-(sp)       Preserve registers that are changed here or by TUTOR.
        move.b  #OUTCH,d7               Output character function.
        trap    #14                     Call TRAP14 handler.
        movem.l (sp)+,a0/d0/d1/d7       Restore registers.
        rts

************************************************************************
*
* Send CRLF to the console.
*
* Send carriage return, line feed to the console.
*
* Inputs: none
* Outputs: none
* Registers changed: none
*
************************************************************************
CrLf
        movem.l d0,-(sp)                Preserve registers that are changed here or by TUTOR.
        move.b  #CR,d0                  Print CR
        bsr     PrintChar
        move.b  #LF,d0                  Print LF
        bsr     PrintChar
        movem.l (sp)+,d0                Restore registers.
        rts


************************************************************************
*
* Convert decimal string to 32-bit value.
*
* Inputs: A0 points to string, which must be terminated in a null.
* Outputs: D0 contains the binary value
* Registers changed: D0
*
************************************************************************
Dec2Bin
        movem.l d7/a1/a5/a6,-(sp)       Preserve registers that are changed here or by TUTOR.

* Change null (0) indicating end of string to EOT (4), as required by TUTOR GETNUMD function.

        move.l  a0,a1                   Initialize index to start of string.
find1   cmp.b   #0,(a1)+                Is it a null?
        bne.s   find1
        subq.l  #1,a1                   Go back to position of null.
        move.b  #4,(a1)                 Change it to EOT.

        move.l  a0,a5                   Put string start in A5.
        move.b  #FIXDATA,d7             Copy string to buffer function.
        trap    #14                     Call TRAP14 handler.

        move.b  #GETNUMD,d7             Decimal to binary function.
        trap    #14                     Call TRAP14 handler.

        movem.l (sp)+,d7/a1/a5/a6       Restore registers.
        rts

************************************************************************
*
* validdec
*
* Check for string being a valid decimal number, i.e. only the
* characters 0-9.
*
* Inputs: A0 points to string, which must be terminated in a null.
* Outputs: Sets overflow bit if invalid, clears if valid.
* Registers changed: none
*
************************************************************************
ValidDec
        movem.l a0,-(sp)                Preserve registers.

scan    tst.b   (a0)                    Have we reached end of string?
        beq.s   good                    If so, we're done and string is valid.
        cmp.b   #'0',(a0)               Does it start with '0' ?
        blt.s   bad                     Invalid character if lower.
        cmp.b   #'9',(a0)+              Does it start with '9' ?
        bgt.s   bad                     Invalid character if higher.
        bra.s   scan                    go back and continue.

bad     or      #$02,CCR                Set overflow bit to indicate error.
        bra.s   ret

good    and     #$02,CCR                Clear overflow bit to indicate good.
ret     movem.l (sp)+,a0                Restore registers.
        rts

************************************************************************
*
* Go to TUTOR monitor.
*
* Go to the TUTOR monitor and display prompt. Does not do full
* initialization but does set stack pointer and status register. Does
* not return.
*
* Inputs: none
* Outputs: none
* Registers used: n/a
*
************************************************************************
Tutor
        move.b  #TUTOR,d7               Go to TUTOR function.
        trap    #14                     Call TRAP14 handler.

************************************************************************
*
* Random
*
* Generate a random 32-bit number between two values.
*
* Inputs: D0.l: minimum value, D1.l: maximum value
* Outputs: D2.l: returned random number
* Registers used: D2
*
************************************************************************
Random
        movem.l d7,-(sp)                Save registers.
        move.l  SEED,d7                 Random seed.
again   movem.l d0-d6,-(sp)             Save registers.
        bsr     RANDOM                  Calculate random number.
        movem.l (sp)+,d0-d6             Restore registers
        move.l  d7,SEED                 Save as next seed.
        move.l  d7,d2                   Get random result.

* TODO: Limit value to selected range.

        and.l   #$000003,d2             Only allow 2 bits (0-3)
        cmp.b   #0,d2                   If zero, try again.
        beq     again
        movem.l (sp)+,d7                Restore registers
        rts

* This is the source for "A Pseudo Random-Number Generator" by Michael
* P. McLaughlin from Dr. Dobb's Toolbook of 68000 Programming.
*
* It has been modified slightly to compile with the VASM assembler.
*
;PSEUDO-RANDOM NUMBER GENERATOR -- (USES D2-D7)
;GIVEN ANY SEED (1 TO 2**31-2) IN D7 (LONGWORDS), THIS GENERATOR YIELDS A
;NON-REPEATING SEQUENCE (RAND(I)) USING ALL INTEGERS IN THE RANGE 1 TO
;2**31-2. THE AVERAGE EXECUTION TIME IS 240 MICROSECONDS (AT 8 MHZ). THIS
;GENERATOR, REFERRED TO IN THE LITERATURE AS "GGUBS", IS KNOWN TO POSSESS
;GOOD STATISTICS. THE ALGORITHM IS:
;
;              RAND(I+1) = (16807*RAND(I)) MOD (2**31)-1)
;
;WHEN PROPERLY CODED, THIS ALGORITHM WILL TRANSFORM RAND (0) = 1 INTO
;RAND(1000) = 522329230. THE FOLLOWING IMPLEMENTATION USES SYNTHETIC
;DIVISION, VIZ.,
;
;              K1 = RAND(I) DIV 127773
;              RAND(I+1) = 16807*RAND(I)-K1*127773)-K1*2836
;              IF RAND(I+1)<0 THEN RAND(I+1) = RAND(I+1)+2147483647
;
;REFERENCE:
;              BRATLEY, P., FOX, B.L. and L.E. SCHRAGE, 1983.
;              A GUIDE TO SIMULATION. SPRINGER-VERLAG.
;

RANDOM         MOVE.L     D7,D6               ;copy RAND(I)
               MOVE.L     #127773,D2          ;synthetic modulus
               BSR.S      DIV                 ;divide D6 by 127773
               MOVE.L     D4,D5               ;copy K1
               MULS       #-2836,D5           ;D5 = -2836*K1
               MULU       #42591,D4           ;multiply D4 by 12773
               MOVE.L     D4,D6
               ADD.L      D4,D4
               ADD.L      D6,D4
               SUB.L      D4,D7               ;D7 = RAND(I)-K1*12773
               MOVEQ      #4,D4               ;counter
RAN1           MOVE.L     D7,D6               ;multiply D7 by 16807
               LSL.L      #3,D7
               SUB.L      D6,D7
               DBRA       D4,RAN1
               ADD.L      D5,D7               ;D7 = RAND(I+1)
               BPL.S      EXIT
               ADD.L      #2147483647,D7      ;normalize negative result
EXIT           RTS                            ;D7 = RAND(I+1)
;RAND(I) (31 BITS) DIV 127773 (17 BITS)
DIV            ADD.L      D6,D6               ;shift out unused bit
               CLR.L      D4                  ;quotient
               MOVEQ      #14,D3              ;counter
               MOVE       D6,D5               ;save low word of RAND(I)
               SWAP       D6
               AND.L      #$0FFFF,D6          ;D6 = RAND(I) DIV 2**15
DIV1           ADD        D4,D4               ;line up quotient
               ADD        D5,D5               ;and dividend
               ADDX.L     D6,D6               ;shift in bit of low word
               CMP.L      D2,D6               ;trial subtraction
               BMI.S      DIV2
               SUB.L      D2,D6               ;real subtraction
               ADDQ       #1,D4               ;put 1 in quotient
DIV2           DBRA       D3,DIV1             ;decrement counter and loop
               RTS

************************************************************************
*
* Print Play
*
* Print "Rock", "Paper", or "Scissors".
*
* Inputs: D0.b: value of ROCK, PAPER, or SCISSORS.
* Outputs: none
* Registers used: none
*
************************************************************************
PrintPlay
        movem.l a0,-(sp)                Preserve registers.
        cmp.b   #ROCK,d0                Is it Rock?
        bne     try1                    Branch if not.
        lea.l   S_ROCK,a0               Get pointer to string.
        bra     printit                 Print it.
try1    cmp.b   #PAPER,d0               Is it Paper?
        bne     try2                    Branch if not.
        lea.l   S_PAPER,a0              Get pointer to string.
        bra     printit                 Print it.
try2    cmp.b   #SCISSORS,d0            Is it Scissors?
        bne     oops                    Branch if not.
        lea.l   S_SCISSORS,a0           Get pointer to string.
printit
        bsr     PrintString             Print the string.
        movem.l (sp)+,a0                Restore registers.
        rts
oops:   
        illegal                         Was not valid, should never happen,
*                                       so cause exception if it does

************************************************************************
*
* Determine Winner
*
* Determine who won.
*
* Inputs: D0.b: human's move, D1.b: computer's move
* Outputs: D2.b: Winner (TIE, HUMAN, OR COMPUTER)
* Registers used: D2
*
************************************************************************
DetermineWinner
        movem.l d0/d2,-(sp)             Preserve registers.

* Check that input parameters are within range 1..3

        move.b  d0,d2                   Get input value.
        ext.w   d2                      CHK only supports word size, so need to extend from byte to word.
        sub.w   #1,d2                   Add one so we can use CHK.
        chk.w   #2,d2                   Will trap if outside the range of 0..2

        move.b  d1,d2                   Now do the same for the value in D1.
        ext.w   d2
        sub.w   #1,d2
        chk.w   #2,d2

* Find entry in the rule table corresponding to the two input values.

        lea.l   RuleTable,a0            Get address of start of table.
search
        cmp.b   (a0),d0                 Does entry match human player value?
        bne     next                    Branch if not.
        cmp.b   1(a0),d1                Does entry match computer player value?
        bne     next                    Branch if not.

* If here, then match was found.

        move.b  2(a0),d2                Get result from table
        movem.l (sp)+,d0/d1             Restore registers.
        rts                             And return.

next
        addq.l  #3,a0                   Advance to next entry in table.
        bra     search

************************************************************************
*
* Table of Winning Rules
*
* Player 1      Player 2      Winner
* (human)       (computer)
* ------------  ------------  ------
RuleTable
 dc.b ROCK,      ROCK,      TIE
 dc.b ROCK,      PAPER,     COMPUTER
 dc.b ROCK,      SCISSORS,  HUMAN
 dc.b PAPER,     ROCK,      HUMAN
 dc.b PAPER,     PAPER,     TIE
 dc.b PAPER,     SCISSORS,  COMPUTER
 dc.b SCISSORS,  ROCK,      COMPUTER
 dc.b SCISSORS,  PAPER,     HUMAN
 dc.b SCISSORS,  SCISSORS,  TIE

*************************************************************************
*
* Strings
*
*************************************************************************

S_WELCOME       dc.b    "Welcome to Rock, Paper, Scissors\r\n================================\r\n", 0
S_HOWMANY       dc.b    "How many games do you want to play? ", 0
S_INVALID1      dc.b    "Please enter a number from 1 to 10.\r\n", 0
S_INVALID2      dc.b    "Please enter a number from 1 to 3.\r\n", 0
S_GAMENUMBER    dc.b    "Game number: ", 0
S_OF            dc.b    " of ", 0
S_PLAY          dc.b    "1=Rock 2=Paper 3=Scissors\r\n1... 2... 3... What do you play? ", 0
S_MYCHOICE      dc.b    "This is my choice... ", 0
S_YOUPLAYED     dc.b    "You played ", 0
S_ROCK          dc.b    "Rock", 0
S_PAPER         dc.b    "Paper", 0
S_SCISSORS      dc.b    "Scissors", 0
S_TIE           dc.b    "It's a tie.\r\n", 0
S_BEATS         dc.b    " beats ", 0
S_IWIN          dc.b    ", I win.\r\n", 0
S_YOUWIN        dc.b    ", you win.\r\n", 0
S_FINALSCORE    dc.b    "Final game score:\r\n", 0
S_IWON          dc.b    "I have won ", 0
S_YOUWON        dc.b    "You have won ", 0
S_GAMES         dc.b    " games.\r\n", 0
S_GAME          dc.b    " game.\r\n", 0
S_YOUWIN1       dc.b    "You win!\r\n", 0
S_IWIN1         dc.b    "I win!\r\n", 0
S_TIE1          dc.b    "It's a tie!\r\n", 0
S_PLAYAGAIN     dc.b    "Play again (y/n)? ", 0

*************************************************************************
*
* Variables:
*
*************************************************************************

* Total number of games
TOTALGAMES     ds.b     1

* Current game number
GAMENO         ds.b     1

* Games won by computer
COMPUTERWON    ds.b     1

* Games won by human
HUMANWON       ds.b     1

* Human player's most recent play.
HUMANPLAY      ds.b     1

* Computer's most recent play.
COMPUTERPLAY   ds.b     1

* Most recent winner.
WINNER         ds.b     1

* Random number initial seed
               align    1
SEED           ds.l     1
