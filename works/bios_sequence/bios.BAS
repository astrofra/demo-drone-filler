10 ' --- BIOS-like Greets (Amstrad CPC, Locomotive BASIC, GOSUB only) ---
20 MODE 2:INK 0,0:INK 1,15:PAPER 0:PEN 1:BORDER 0:CLS
30 RANDOMIZE TIME
40 PRINT "DRONE LOCOMOTIVE CONSOLE v1.0":PRINT
50 REM Groups
60 DIM G$(4)
70 G$(1)="Cocoon":G$(2)="Conspiracy":G$(3)="Bomb":G$(4)="Condense"
80 R=5:PRINT "Booting...":PRINT
90 FOR I=1 TO 4
100   LOCATE 2,R:PRINT "Searching ";G$(I);"...";
110   SPINCOL=32:SPINROW=R
120   STEPS=60+INT(RND*40)        :' spinner duration (frames)
130   GOSUB 500                   :' do spinner
140   LOCATE SPINCOL,SPINROW:PRINT "   ";
150   LOCATE SPINCOL,SPINROW:PRINT "Found."
160   R=R+1
170 NEXT I
180 PRINT:PRINT "All targets acknowledged.":PRINT "Ready."
185 CALL &BB18
190 END
200 '
210 ' -------------------- spinner subroutine --------------------
220 ' Uses | / - \ cycling at fixed cursor position with crude delay
230 ' S$ = sequence of glyphs built from ASCII codes
240 '
500 S$=CHR$(124)+CHR$(47)+CHR$(45)+CHR$(92)
510 FOR K=1 TO STEPS
520   C=1+((K-1) MOD 4)
530   LOCATE SPINCOL,SPINROW:PRINT MID$(S$,C,1);
540   FOR D=1 TO 120:NEXT D      :' delay, tweak for speed
550 NEXT K
560 RETURN
