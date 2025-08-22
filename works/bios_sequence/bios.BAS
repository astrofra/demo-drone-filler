10 ' --- BIOS-like Credits ---
20 MODE 2:INK 0,0:INK 1,15:PAPER 0:PEN 1:BORDER 0:CLS
30 RANDOMIZE TIME
40 PRINT "DRONE FILLER":PRINT
50 REM Groups
60 DIM G$(4)
65 DIM G2$(4)
70 G2$(1)="Fra":G2$(2)="XBarr, Mooz":G2$(3)="MadMarie":G2$(4)="Nicolas Tilly"
75 G$(1)="Code  ":G$(2)="Engine":G$(3)="Photos":G$(4)="Music "
80 R=5:PRINT "by Resistance":PRINT
90 FOR I=1 TO 4
100   LOCATE 2,R:PRINT "> ";G$(I);" ...";
110   SPINCOL=20:SPINROW=R
120   STEPS=8 :' spinner duration (frames)
130   GOSUB 500 :' do spinner
140   LOCATE SPINCOL,SPINROW:PRINT "   ";
150   LOCATE SPINCOL,SPINROW:PRINT G2$(I)
160   R=R+1
170 NEXT I
180 PRINT:PRINT "Reset Drone Sequence.":PRINT "Ready."
185 CALL &BB18
190 END
200 '
210 ' --- spinner subroutine
500 S$=CHR$(124)+CHR$(47)+CHR$(45)+CHR$(92)
510 FOR K=1 TO STEPS
520   C=1+((K-1) MOD 4)
530   LOCATE SPINCOL,SPINROW:PRINT MID$(S$,C,1);
540   FOR D=1 TO 120:NEXT D :' delay, tweak for speed
550 NEXT K
560 RETURN
