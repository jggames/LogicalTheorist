REM *** File Functions ***

Dir:
ERASE dd$
aa = 1
bb = 2
path$ = currentpath$
GOSUB GetDir
IF wv <> 27 THEN
 CALL Blankline(1, 22)
 COLOR co1, co2
 PRINT currentpath$; SPACE$(80 - LEN(currentpath$));
 COLOR 7, 0
 SHELL "DIR " + currentpath$ + " /b /a-d >" + progname$ + ".dir"
 OPEN progname$ + ".dir" FOR INPUT AS #1
 t = 1
 DO WHILE NOT EOF(1) AND t < 100
   INPUT #1, dd$(t)
   t = t + 1
 LOOP
 CLOSE #1
 dtot = t
 dcount = 1
 GOSUB PrintFiles
 wv = 0
 DO WHILE wv <> 27 AND wv <> 13
   newfile$ = dd$(dcount + (bb - 2))
   COLOR co1, co2
   LOCATE bb, aa, 0
   PRINT newfile$;
   CALL Getcharacter(aa, bb, 0)
   SELECT CASE wv
   CASE 72, 73
     GOSUB PutItBack
     IF bb > (wv - 71) + 1 THEN
       bb = bb - (wv - 71)
     ELSEIF dcount - 21 >= 1 THEN
       dcount = dcount - 21
       GOSUB PrintFiles
       bb = 22
     END IF
   CASE 80, 81
     GOSUB PutItBack
     IF bb < 23 - (wv - 79) AND dcount + bb <= dtot - (wv - 80) THEN
       bb = bb + (wv - 79)
     ELSEIF dcount + 21 <= dtot THEN
       dcount = dcount + 21
       GOSUB PrintFiles
     END IF
   END SELECT
 LOOP
 GOSUB CreateScreen
 IF wv = 13 THEN
     filename$ = newfile$
     currentpath$ = path$
     GOSUB LoadLines
 END IF
END IF
currentpath$ = path$
CALL Functions(helpscreen, 0)
CALL Blankline(16, 17)
GOSUB UpdateScreen
RETURN

PrintFiles:
CALL Blankline(2, 22)
FOR t = dcount TO dcount + 20
  IF t = dtot THEN EXIT FOR
  PRINT dd$(t)
NEXT t
bb = 2
CALL Functions(1, 2)
RETURN

PutItBack:
COLOR 7, 0
LOCATE bb, aa, 0
PRINT newfile$;
RETURN

GetDir:
CALL DisplayPath(currentpath$)
PRINT "Enter new path or press [ENTER]: ";
CALL InputLine(47, 3, currentpath$)
IF in$ = "" THEN in$ = currentpath$
IF LEN(in$) = 1 THEN in$ = ""
currentpath$ = in$
CALL Blankline(15, 17)
CALL Functions(helpscreen, 0)
RETURN

DelFile:
CALL Functions(1, 3)
CALL Blankline(15, 17)
CALL DisplayPath(currentpath$)
PRINT "Enter filename of file to be erased: ";
CALL InputLine(12, 1, "")
IF in$ <> "" THEN
  CALL Blankline(16, 17)
  PRINT "WARNING: Are you sure you want to erase "; in$; "?";
  CALL Getcharacter(POS(0), CSRLIN, 2)
  IF wv = 13 OR wv = 89 OR wv = 121 THEN
    CALL Blankline(15, 17)
    path$ = filename$
    filename$ = in$
    GOSUB MakePath
    filename$ = path$
    PRINT "Erasing "; wholepath$;
    KILL wholepath$
  END IF
END IF
CALL Blankline(15, 17)
CALL Functions(helpscreen, 0)
RETURN

MakeDir:
CALL DisplayPath(currentpath$)
PRINT "Enter name of directory to create: ";
path$ = filename$
in$ = ""
CALL InputLine(45, 3, in$)
IF in$ <> "" THEN
  filename$ = in$
  GOSUB MakePath
  CALL Blankline(15, 17)
  PRINT "Creating "; wholepath$
  MKDIR wholepath$
END IF
filename$ = path$
CALL Blankline(15, 17)
CALL Functions(helpscreen, 0)
RETURN

SaveLines:
ERASE dd$
io$ = save$
GOSUB GetFileName
IF wv <> 27 THEN
  IF in$ = "" THEN
    in$ = filename$
  END IF
  filename$ = in$
  GOSUB MakePath
  OPEN wholepath$ FOR OUTPUT AS #1
  CALL Blankline(15, 17)
  PRINT "Saving "; wholepath$;
  t = 1
  DO WHILE t <= last
    lin$ = lines$(t)
    prf$ = proof$(t)
    lin$ = FNReplace$(lin$, sy(0), 62)
    prf$ = FNReplace$(prf$, sy(0), 62)
    WRITE #1, lin$, prf(t, 0), prf(t, 1), prf(t, 2), prf$
    t = t + 1
  LOOP
  CLOSE 1
  CALL Title(filename$, 1, 3, 59)
END IF
CALL Functions(helpscreen, 0)
GOSUB UpdateScreen
RETURN

MakePath:
IF RIGHT$(currentpath$, 1) = "\" THEN
  wholepath$ = currentpath$ + filename$
ELSEIF currentpath$ = "" THEN
  wholepath$ = filename$
ELSE
  wholepath$ = currentpath$ + "\" + filename$
END IF
RETURN

LoadLines:
io$ = load$
GOSUB GetFileName
IF wv <> 27 THEN
  IF in$ = "" THEN
    in$ = filename$
  END IF
  filename$ = in$
  GOSUB ClearLines
  GOSUB MakePath
  OPEN wholepath$ FOR INPUT AS #1
  CALL Blankline(15, 17)
  PRINT "Loading "; wholepath$
  t = 1
  DO WHILE NOT EOF(1) AND FRE("S") > 6000
    INPUT #1, lines$(t), prf(t, 0), prf(t, 1), prf(t, 2), proof$(t)
    t = t + 1
  LOOP
  last = t - 1
  CLOSE 1
  FOR t = 1 TO last
    lines$(t) = FNReplace$(lines$(t), 62, sy(0))
    proof$(t) = FNReplace$(proof$(t), 62, sy(0))
    lines$(t) = FNReplace$(lines$(t), 118, sy(1))
    proof$(t) = FNReplace$(proof$(t), 118, sy(1))
    lines$(t) = FNReplace$(lines$(t), 250, sy(2))
    proof$(t) = FNReplace$(proof$(t), 250, sy(2))
    lines$(t) = FNReplace$(lines$(t), 240, sy(3))
    proof$(t) = FNReplace$(proof$(t), 240, sy(3))
    IF LEFT$(proof$(t), 2) = " A" THEN prf(t, 2) = -1
    SELECT CASE prf(t, 2)
    CASE 1
      rcpcount = rcpcount + 1
      firstlineofRCP(rcpcount) = t
      rcp = t
    CASE -2
      rcpcount = rcpcount - 1
      rcp = 0
    CASE 2
      rcpcount = rcpcount - 1
      rcp = firstlineofRCP(rcpcount)
    CASE -1
      axioms = axioms + 1
    END SELECT
  NEXT t
  CALL Title(filename$, 1, 3, windowsize)
END IF
CALL Functions(helpscreen, 0)
GOSUB UpdateScreen
RETURN

ErrorHandler:
CLOSE
CALL Blankline(15, 17)
er = ERR
SELECT CASE er
CASE 53
  PRINT "File not found."
CASE 71
  PRINT "Disk not ready."
CASE 76
  PRINT "Path not found."
CASE 61
  PRINT "Disk full."
CASE 64
  PRINT "Bad file name."
CASE 5
  PRINT "Illegal function call.  Contact Programmer and give him heck!"
CASE 57, 24, 25, 27, 68
  PRINT "Device I/O error.  Check Printer."
CASE 62, 63
  PRINT "Bad file format."
  ERASE lines$, proof$
  ERASE prf, jumps
CASE ELSE
  PRINT "Error number"; er
END SELECT
CALL Functions(1, 3)
CALL GetCharacter(POS(0), CSRLIN, 1)
GOSUB CreateScreen
GOSUB UpdateScreen
RESUME ContinueFlow

PrintProblem:
CLOSE
CALL Blankline(15, 17)
PRINT "Device I/O error.  Check Printer."
CALL Functions(1, 3)
CALL GetCharacter(POS(0), CSRLIN, 1)
GOSUB CreateScreen
GOSUB UpdateScreen
RESUME Main

GetFileName:
CALL DisplayPath(currentpath$)
PRINT "Enter filename to "; io$;
CALL InputLine(12, 0, filename$)
RETURN

ClearLines:
a = 6
b = 2
tmp1 = a
tmp2 = b
row = 1
column = 1
axioms = 0
jumpnum = 0
last = 0
rcp = 0
rcpcount = 0
dr(0) = 0
dr(1) = 0
dr(2) = 0
drule$(1) = ""
drule$(2) = ""
drule$(0) = ""
jumps(1) = 1
blklin = 0
blkstart = 0
blkend = 0
blk$ = ""
ERASE lines$, proof$
ERASE prf, jumps
RETURN

UpdateScreen:
CALL Blankline(15, 16)
COLOR co1, co2
GOSUB ScrollScreen
RETURN

OutOfMemory:
CALL ErrorMessage("Out of memory.", 0)
lines$(last) = ""
proof$(last) = ""
FOR c = 0 TO 2
   prf(last, c) = 0
NEXT c
last = last - 1
GOSUB UpdateScreen
RESUME ContinueFlow

Esc:
CALL Blankline(15, 17)
IF blk = 1 OR R2 = 1 THEN
  GOSUB R2off
  GOSUB BlockOff
ELSE
  SELECT CASE helpscreen
  CASE 0
    PRINT "Exit " + version$ + " (y/n)?";
    CALL Getcharacter(POS(0), CSRLIN, 2)
    IF w$ = "y" OR w$ = "Y" THEN
      CLS
    END
    END IF
  CASE ELSE
    helpscreen = 0
    CALL Instructions(helpscreen)
    CALL Functions(0, 0)
  END SELECT
END IF
GOSUB UpdateScreen
RETURN

Init:
ON ERROR GOTO ErrorHandler
wv = 32
DO WHILE wv <> 27
  CALL Blankline(15, 17)
  PRINT "Create a new system (y/n)?";
  CALL Getcharacter(POS(0), CSRLIN, 2)
  SELECT CASE wv
  CASE 78, 110
    GOSUB LoadLines
    wv = 27
  CASE 89, 121
    GOSUB ClearLines
    GOSUB UpdateScreen
    GOSUB Enter
    wv = 27
  CASE 27
    CALL Blankline(15, 16)
  END SELECT
LOOP
ON ERROR GOTO 0
RETURN

