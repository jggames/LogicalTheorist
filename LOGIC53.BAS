DEFINT A-Z
DIM lines$(1000), proof$(1000)
DIM part$(41), pt$(41), variable$(20)
DIM keys(1, 256), varpos(64, 2), numbers(2000), ww(4)
DIM prf(1000, 2), var(11), jumps(16)
DIM lin$(1), comp$(42), wff$(11), poption$(2)
DIM dd$(100)
DIM neg(6), v1(5, 5, 3), firstlineofRCP(20), corner(16)
DIM vector(50), Table(18, 256), sy(6), dr(4)
DIM symbol$(6), theorem$(2), drule$(2)

SCREEN 0
WIDTH 80
CLS
LOCATE 1, 1, 0, 0, 7

version$ = "Logical Theorist 5.3"
progname$ = "logic53"

ON ERROR GOTO NoInit
OPEN progname$ + ".pin" FOR INPUT AS #1
INPUT #1, lmargin, margin1, margin2, linesperpage, co1, co2, value, pstring$, filename$
FOR t = 0 TO 5
  FOR c = 0 TO 5
    FOR nc = 0 TO 3
      INPUT #1, v1(t, c, nc)
    NEXT nc
  NEXT c
NEXT t
FOR t = 0 TO 5
  INPUT #1, neg(t)
NEXT t
GOTO InitOk

NoInit:
lmargin = 5
margin1 = 45
margin2 = 25
linesperpage = 54
co1 = 0
co2 = 7
pstring$ = ""
filename$ = "23-AXIOM"
value = 2
v1(0, 0, 0) = 1
v1(1, 0, 0) = 0
v1(0, 1, 0) = 1
v1(1, 1, 0) = 1
v1(0, 0, 1) = 0
v1(1, 0, 1) = 1
v1(0, 1, 1) = 1
v1(1, 1, 1) = 1
v1(0, 0, 2) = 0
v1(1, 0, 2) = 0
v1(0, 1, 2) = 0
v1(1, 1, 2) = 1
v1(0, 0, 3) = 1
v1(1, 0, 3) = 0
v1(0, 1, 3) = 0
v1(1, 1, 3) = 1
neg(0) = 1
neg(1) = 0
RESUME InitOk

InitOk:
CLOSE #1
ON ERROR GOTO 0
dbox$ = CHR$(205) + CHR$(201) + CHR$(187) + CHR$(186) + CHR$(200) + CHR$(188)
cmd$ = COMMAND$
title2$ = "PROOFS"
currentpath$ = ""
dead = -99
pcode$ = ""
action = 0
windo = 3
REM *** Get the commands issued at run-time ***
IF cmd$ <> "" THEN
  in = INSTR(cmd$, " ")
  IF ASC(LEFT$(cmd$, 1)) > 64 THEN
    IF in = 0 THEN
      filename$ = cmd$
    ELSE
      filename$ = LEFT$(cmd$, in - 1)
    END IF
    in2 = INSTR(in + 1, cmd$, " ")
    IF in <> 0 THEN co1 = VAL(MID$(cmd$, in + 1, 2))
    IF in2 <> 0 THEN co2 = VAL(MID$(cmd$, in2 + 1, 2))
  ELSE
    IF in = 0 THEN
      co1 = VAL(cmd$)
    ELSE
      co1 = VAL(LEFT$(cmd$, in - 1))
    END IF
    IF in <> 0 THEN co2 = VAL(MID$(cmd$, in + 1, 2))
  END IF
END IF
CALL DrawBox(10, 3, 60, 11, co1, co2, dbox$)
CALL Centre(4, version$)
CALL Centre(5, "Copyright (c) 12 February 2003")
CALL Centre(7, "James B. Gerrie")
CALL Centre(8, "30 Tuckett St.")
CALL Centre(9, "Hamilton, ON")
CALL Centre(10, "Canada, L8P 2A7")
CALL Centre(11, "905-524-1995")
CALL Centre(12, "jgerrie@hwcn.org")
DELAY 3
poption$(1) = "save"
poption$(2) = "print"
load$ = "load: "
save$ = "save: "
message$ = "Error"
linemax = 1000
helpscreen = 0
windowsize = 59
proveline = 0
predtot = 0
axioms = 0
cursor = 1

REM *** Logical symbols
sy(0) = 26
sy(1) = 118
sy(2) = 43
sy(3) = 61
sy(4) = 40
sy(5) = 41
sy(6) = 126

FOR t = 0 TO 6
  symbol$(t) = CHR$(sy(t))
NEXT t

REM Derived Rules
theorem$(1) = "((p" + symbol$(0) + "q)" + symbol$(0) + "((r" + symbol$(0) + "p)" + symbol$(0) + "(r" + symbol$(0) + "q)))"
theorem$(2) = "((p" + symbol$(0) + "q)" + symbol$(0) + "((q" + symbol$(0) + "r)" + symbol$(0) + "(p" + symbol$(0) + "r)))"
theorem$(0) = "(p" + symbol$(0) + "(q" + symbol$(0) + "(p" + symbol$(2) + "q)))"

REM *** Initialize Screen and program variables to zero ***
GOSUB Getkeys
GOSUB ClearLines
GOSUB CreateScreen

Start:
GOSUB Init
GOSUB UpdateScreen

REM *** Main Program Loop ***
Main:
DO WHILE last < linemax
  CALL Getcharacter(POS(0), CSRLIN, cursor)
  SELECT CASE fv
  CASE 1
    GOSUB Flow1
  CASE 2
    GOSUB Flow2
  END SELECT
  IF FRE("S") > 1256 THEN
    GOSUB ContinueFlow
  ELSE
    EXIT LOOP
  END IF
LOOP
CALL ErrorMessage("You have reached the maximum number of lines.", 0)
GOSUB SaveLines
GOTO Main:
REM *** End of main program loop ***

Flow1:
linenumber = row + (b - 2)
location = column + (a - 6)
SELECT CASE wv
CASE 27
  GOSUB Esc
CASE 14
  GOSUB Init
CASE 15
  GOSUB CheckMem
CASE 2
  GOSUB Block
CASE 4
  GOSUB Del
CASE 5
  GOSUB Enter
CASE 19
  GOSUB Find
CASE 10
  GOSUB Jump
CASE 13
  GOSUB Chr13
CASE 16
  GOSUB PrintOut
CASE 26
  GOSUB Zoom
CASE 22
  GOSUB Vroom
CASE 97 TO 117
  min = 97
  max = 117
  GOSUB Switch
CASE 119 TO 122
  min = 119
  max = 122
  GOSUB Switch
CASE 18
  ON ERROR GOTO ErrorHandler
  GOSUB LoadLines
  ON ERROR GOTO 0
CASE 23
  ON ERROR GOTO ErrorHandler
  GOSUB SaveLines
  ON ERROR GOTO 0
CASE 6
  ON ERROR GOTO ErrorHandler
  GOSUB dir
  ON ERROR GOTO 0
CASE 3
  ON ERROR GOTO ErrorHandler
  GOSUB GetDir
  ON ERROR GOTO 0
END SELECT
RETURN

Flow2:
linenumber = row + (b - 2)
location = column + (a - 6)
SELECT CASE wv
CASE 59 TO 68
  GOSUB FunctionKeys
CASE 115
  GOSUB SkipBackward
CASE 116
  GOSUB SkipForward
END SELECT
RETURN

FunctionKeys:
IF R2 = 0 THEN
  SELECT CASE helpscreen
  CASE 0
    GOSUB Mainfunctions
  CASE 2
    GOSUB Otherfunctions
  CASE 3
    GOSUB Editfunctions
  CASE 4
    GOSUB FileFunctions
  END SELECT
END IF
RETURN

Mainfunctions:
SELECT CASE wv
CASE 59
  GOSUB F1
CASE 60
  GOSUB F2
CASE 61
  GOSUB F3
CASE 62
  GOSUB F4
CASE 63
  GOSUB F5
CASE 64
  GOSUB F6
CASE 65
  GOSUB F7
CASE 66
  GOSUB F8
CASE 67
  GOSUB F9
CASE 68
  GOSUB F10
END SELECT
RETURN

ContinueFlow:
x = keys(0, wv)
y = keys(1, wv)
ON fv - 1 GOSUB ScreenCheck
ON blk GOSUB Highlight
ON R2 GOSUB Rule2
a = tmp1
b = tmp2
RETURN

ScreenCheck:
tmp1 = a + x
tmp2 = b + y
IF tmp2 - 2 >= last THEN tmp2 = last + 2
IF tmp1 < 6 OR tmp1 > windowsize OR tmp2 < 2 OR tmp2 > 11 THEN
  IF tmp1 > 5 THEN blkpos = blkpos - x
  column = column + x
  IF y < 0 AND blk = 0 THEN
    IF b = 2 THEN
      row = row + y
    ELSE
      b = 2
    END IF
  ELSEIF y > 0 AND blk = 0 THEN
    IF b = 11 THEN
       row = row + y
     ELSE
       b = 11
    END IF
  END IF
  IF row < 1 THEN row = 1
  IF row > last - 9 AND last > 9 THEN
    row = last - 9
  END IF
  IF column < 1 THEN column = 1
  IF column > 196 THEN column = 196
  IF tmp1 < 6 THEN
    tmp1 = 6
  ELSEIF tmp1 > windowsize THEN
    tmp1 = a
  END IF
  tmp2 = b
  GOSUB ScrollScreen
END IF
RETURN

ScrollScreen:
SELECT CASE windo
CASE 1
  FOR t = 0 TO 9
    LOCATE t + 2, 2, 0
    PRINT USING "### "; row + t;
    PRINT MID$(lines$(row + t) + SPACE$(254), column, 74);
  NEXT t
CASE 2
  FOR t = 0 TO 9
    prf$ = STR$(prf(row + t, 0))
    IF prf(row + t, 1) > 0 THEN prf$ = prf$ + "," + STR$(prf(row + t, 1))
    prf$ = prf$ + proof$(row + t) + SPACE$(74)
    LOCATE t + 2, 2, 0
    PRINT USING "### "; row + t;
    PRINT LEFT$(prf$, 74);
  NEXT t
CASE 3
  FOR t = 0 TO 9
    prf$ = STR$(prf(row + t, 0))
    IF prf(row + t, 1) > 0 THEN
      prf$ = prf$ + "," + STR$(prf(row + t, 1))
    END IF
    prf$ = LEFT$(prf$ + proof$(row + t) + SPACE$(19), 19)
    lin$ = MID$(lines$(row + t) + SPACE$(254), column, 54) + "º" + prf$
    LOCATE t + 2, 2, 0
    PRINT USING "### "; row + t;
    PRINT lin$;
  NEXT t
END SELECT
RETURN

Highlight:
tmp2 = b
IF blklen + x + blkstart - 1 > linlen OR blklen + x < 1 THEN
  x = 0
  tmp1 = a
END IF
blklen = blklen + x
IF blkpos < 6 THEN blkpos = 6
COLOR 7, 0
LOCATE b, blkpos, 0
blk$ = MID$(lines$(blklin), blkstart, blklen)
part$(41) = RIGHT$(lines$(blklin), linlen - (blkstart + blklen) + 1)
PRINT RIGHT$(blk$, tmp1 - 5);
IF blklen + blkstart - 1 <> linlen AND tmp1 < windowsize THEN
  COLOR co1, co2
  PRINT MID$(lines$(blklin), blkstart + blklen, windowsize - tmp1)
END IF
blkoff = tmp1 + column - 5
GOSUB DisplayBlock
RETURN

DisplayBlock:
COLOR 7, 0
LOCATE 13, 6, 0
FOR t = 1 TO LEN(lines$(blklin))
  IF t = blkstart THEN
    COLOR co1, co2
  ELSEIF t = blkoff THEN
    COLOR 7, 0
  END IF
  PRINT MID$(lines$(blklin), t, 1);
NEXT t
COLOR co1, co2
RETURN

REM *** Regular keystrokes ***

Block:
IF blk = 0 AND windo <> 2 THEN
  blkoff = 0
  blklin = linenumber
  part$(0) = LEFT$(lines$(blklin), location - 1)
  blkstart = location
  blklen = 1
  blkpos = a
  linlen = LEN(lines$(blklin))
  blk = 1
  blk$ = ""
  GOSUB BlockNum
  LOCATE 23, 74, 0
  COLOR 23, 0
  PRINT "Block";
  COLOR co1, co2
  IF location > linlen THEN GOSUB BlockOff
ELSE
  GOSUB BlockOff
END IF
RETURN

BlockNum:
CALL Blankline(13, 16)
IF blklin > 0 AND blklin < 1000 THEN
  PRINT USING " ### "; blklin;
END IF
RETURN

BlockOff:
blk = 0
in$ = blk$
CALL Functions(helpscreen, 0)
GOSUB UpdateScreen
RETURN

SkipForward:
in = INSTR(location + 1, lines$(linenumber), symbol$(5))
IF in <> 0 THEN
  wv = 0
  keys(0, wv) = in - location
END IF
RETURN

SkipBackward:
FOR t = location - 1 TO 1 STEP -1
  IF MID$(lines$(linenumber), t, 1) = symbol$(4) THEN
    wv = 0
    keys(0, wv) = t - location
    t = -1
  END IF
NEXT t
RETURN

Vroom:
Start = location
linlen = LEN(lines$(linenumber))
a$ = MID$(lines$(linenumber), location, 2)
IF LEFT$(a$, 1) = symbol$(4) OR a$ = symbol$(6) + symbol$(4) THEN
  count = 0
  IF a$ = symbol$(6) + symbol$(4) THEN Start = Start + 1
  FOR t = Start TO linlen
    w = ASC(MID$(lines$(linenumber), t, 1))
    IF w = 40 THEN count = count + 1
    IF w = 41 THEN count = count - 1
    IF count = 0 THEN
      wv = 0
      fv = 2
      keys(0, wv) = t - location
      t = linlen
    END IF
  NEXT t
END IF
RETURN

Chr13:
GOSUB BlockOff
fv = 2
RETURN

Switch:
nv = wv
sv = SCREEN(b, a)
test1 = INSTR(lines$(linenumber), CHR$(nv))
test2 = INSTR(proof$(linenumber), CHR$(nv))
IF sv >= min AND sv <= max AND test1 = 0 AND test2 = 0 THEN
  CALL Blankline(15, 16)
  PRINT "Change all "; CHR$(sv); "'s to "; CHR$(nv); "'s (y/n)?";
  CALL Getcharacter(POS(0), CSRLIN, 3)
  IF wv = 89 OR wv = 121 OR wv = 13 THEN
    lines$(linenumber) = FNReplace$(lines$(linenumber), sv, nv)
    proof$(linenumber) = FNReplace$(proof$(linenumber), sv, nv)
  END IF
END IF
GOSUB UpdateScreen
RETURN

REM *** Function Keys ***
F1:
IF blk$ = "" THEN
  GOSUB NoBlock
ELSE
  GOSUB Definition1
END IF
RETURN

F2:
IF blk$ = "" THEN
  GOSUB NoBlock
ELSE
  GOSUB Definition2
END IF
RETURN

F3:
IF blk$ = "" THEN
  GOSUB NoBlock
ELSE
  GOSUB Definition3
END IF
RETURN

NoBlock:
CALL Blankline(15, 16)
PRINT "Please specify block on which to perform definitional transformation."
REM BEEP
CALL Functions(1, 3)
CALL Getcharacter(POS(0), CSRLIN, 1)
CALL Functions(helpscreen, 0)
GOSUB UpdateScreen
RETURN

F4:
in$ = lines$(linenumber)
GOSUB Separator
IF FNLinePart$(1, 9, 1) = "" AND FNCheckRCP(linenumber) <> 1 AND part$(25) = symbol$(0) THEN
  lin$ = FNLinePart$(11, 24, 1)
  CALL Blankline(15, 17)
  PRINT "Searching..."
  searchloop = 1
  DO WHILE searchloop <= last
    IF lines$(searchloop) = lin$ AND FNCheckRCP(searchloop) <> 1 THEN
      CALL Newline(FNLinePart$(26, 39, 1), " R1", linenumber, searchloop, action)
      EXIT LOOP
    END IF
    searchloop = searchloop + 1
  LOOP
  IF searchloop = last + 1 THEN
    CALL ErrorMessage(lin$, 1)
  END IF
ELSE
  CALL ErrorMessage("Cannot perform Rule 1.", 0)
END IF
GOSUB UpdateScreen
RETURN

F5:
IF windo <> 2 AND FNCheckRCP(linenumber) <> 1 THEN
  CALL Blankline(17, 22)
  helpscreen = 5
  CALL Functions(helpscreen, 0)
  cursor = 3
  FOR t = 1 TO 11
    wff$(t) = ""
    variable$(t) = ""
    var(t) = 0
  NEXT t
  blk$ = ""
  newlin$ = ""
  varcount = 1
  R2lin = linenumber
  CALL Blankline(17, 18)
  PRINT USING " ### "; linenumber;
  PRINT LEFT$(lines$(R2lin), 75)
  COLOR co1, co2
  in$ = lines$(R2lin)
  R2 = 1
  keys(0, 0) = 0
  wv = 0
  GOSUB FindVariables
  IF vartot < 1 THEN
    CALL ErrorMessage("Cannot perform Rule 2.", 0)
    GOSUB R2off
  ELSE
    GOSUB DisplayWFF
  END IF
END IF
RETURN

F6:
topline = linenumber
GOSUB FirstLine
IF FNCheckRCP(topline) + FNCheckRCP(blklin) <> 2 THEN
  IF FNLinePart$(11, 24, 1) = FNOtherLine$(26, 39, 1) AND part$(25) + pt$(25) = STRING$(2, 26) AND FNOtherLine$(1, 9, 1) + FNLinePart$(1, 9, 1) = "" THEN
    IF dr(1) = 0 THEN
      theorem = 1
      GOSUB FindTheorem
    END IF
    IF dr(1) > 0 THEN
      wff$(1) = FNLinePart$(11, 24, 1)
      wff$(2) = FNLinePart$(26, 39, 1)
      wff$(3) = FNOtherLine$(11, 24, 1)
      in$ = lines$(dr(1))
      linenumber = dr(1)
      GOSUB DRMacro
    END IF
  ELSEIF FNLinePart$(26, 39, 1) = FNOtherLine$(11, 24, 1) AND part$(25) + pt$(25) = STRING$(2, 26) AND FNOtherLine$(1, 9, 1) + FNLinePart$(1, 9, 1) = "" THEN
    IF dr(2) = 0 THEN
      theorem = 2
      GOSUB FindTheorem
    END IF
    IF dr(2) > 0 THEN
      wff$(1) = FNLinePart$(11, 24, 1)
      wff$(2) = FNOtherLine$(11, 24, 1)
      wff$(3) = FNOtherLine$(26, 39, 1)
      in$ = lines$(dr(2))
      linenumber = dr(2)
      GOSUB DRMacro
    END IF
  ELSE
    CALL ErrorMessage("Selected lines do not satisfy conditions of DR 1.", 0)
  END IF
ELSE
  CALL ErrorMessage("RCP Conflict.  Cannot perform Derived Rule 1.", 0)
END IF
CALL Functions(helpscreen, 0)
GOSUB UpdateScreen
RETURN

FindTheorem:
CALL PleaseWait
linecount = 1
DO WHILE linecount <= last
  in$ = lines$(linecount)
  GOSUB Wildcard
  IF in$ = theorem$(theorem) AND prf(linecount, 2) <= 0 THEN
    dr(theorem) = linecount
    drule$(theorem) = lines$(linecount)
    EXIT LOOP
  END IF
linecount = linecount + 1
LOOP
IF linecount% = last + 1 THEN CALL ErrorMessage(theorem$(theorem), 1)
RETURN

FirstLine:
in$ = lines$(blklin)
GOSUB Separator
FOR t = 1 TO 40
  pt$(t) = part$(t)
NEXT t
in$ = lines$(topline)
GOSUB Separator
RETURN

DRMacro:
action = last + 1
GOSUB FindVariables
R2lin = linenumber
GOSUB SubWFF
linenumber = last
action = linenumber + 1
GOSUB F4
linenumber = last
action = linenumber + 1
GOSUB F4
RETURN

F7:
topline = linenumber
IF dr(0) = 0 THEN
  theorem = 0
  GOSUB FindTheorem
END IF
IF dr(0) > 0 AND FNCheckRCP(topline) <> 1 AND FNCheckRCP(blklin) <> 1 THEN
  wff$(1) = lines$(topline)
  wff$(2) = lines$(blklin)
  in$ = lines$(dr(0))
  linenumber = dr(0)
  GOSUB DRMacro
ELSE
  CALL ErrorMessage("Cannot perform Derived Rule 2.", 0)
END IF
CALL Functions(helpscreen, 0)
GOSUB UpdateScreen
RETURN

F8:
helpscreen = 2
CALL Instructions(helpscreen)
CALL Functions(helpscreen, 0)
RETURN

Otherfunctions:
SELECT CASE wv
CASE 59
  GOSUB Definition4
CASE 60
  GOSUB Rule3
CASE 61
  GOSUB Values
CASE 62
  GOSUB Table
CASE 63
  GOSUB Replace
CASE 64
  GOSUB RCPon
CASE 65
  GOSUB RCPoff
CASE 66
  GOSUB Enter
CASE 67
  GOSUB F9
CASE 68
  GOSUB F10
END SELECT
RETURN

F9:
helpscreen = 3
CALL Instructions(helpscreen)
CALL Functions(helpscreen, 0)
RETURN

Editfunctions:
SELECT CASE wv
CASE 59
  GOSUB Block
CASE 60
  GOSUB Vroom
CASE 61
  GOSUB Find
CASE 62
  GOSUB Del
CASE 63
  GOSUB Prove
CASE 64
  GOSUB CheckMem
CASE 65
  GOSUB Store
CASE 66
  GOSUB F8
CASE 67
  GOSUB Parms
CASE 68
  GOSUB F10
END SELECT
RETURN

Store:
CALL Functions(1, 3)
CALL Blankline(15, 17)
PRINT "Press [ENTER] to save current settings, or [ESC] to abort."
CALL Getcharacter(POS(0), CSRLIN, 1)
IF wv = 13 THEN
  ON ERROR GOTO Problem
  OPEN progname$ + ".pin" FOR OUTPUT AS #1
  WRITE #1, lmargin, margin1, margin2, linesperpage, co1, co2, value, pstring$, filename$
  FOR t = 0 TO 5
    FOR c = 0 TO 5
      FOR nc = 0 TO 3
	WRITE #1, v1(t, c, nc)
      NEXT nc
    NEXT c
  NEXT t
  FOR t = 0 TO 5
    WRITE #1, neg(t)
  NEXT t
END IF
GoOn:
CLOSE #1
ON ERROR GOTO 0
GOSUB UpdateScreen
CALL Functions(helpscreen, 0)
RETURN

Problem:
RESUME GoOn

F10:
helpscreen = 4
CALL Instructions(helpscreen)
CALL Functions(helpscreen, 0)
RETURN

FileFunctions:
ON ERROR GOTO ErrorHandler
SELECT CASE wv
CASE 59
  GOSUB LoadLines
CASE 60
  GOSUB SaveLines
CASE 61
  GOSUB Init
CASE 62
  GOSUB dir
CASE 63
  GOSUB GetDir
CASE 64
  GOSUB DelFile
CASE 65
  GOSUB MakeDir
CASE 66
  GOSUB F8
CASE 67
  GOSUB F9
CASE 68
  GOSUB PrintOut
END SELECT
ON ERROR GOTO 0
RETURN

CheckMem:
CALL Blankline(15, 17)
PRINT "Free Memory = "; FRE("S")
CALL Functions(1, 3)
CALL Getcharacter(POS(0), CSRLIN, 1)
CALL Blankline(15, 17)
CALL Functions(helpscreen, 0)
RETURN

REM *** Edit Functions ***

FindVariables:
vartot = 0
predtot = 0
GOSUB SingleVariables
FOR t = 224 TO 238
  GOSUB PredVariables
NEXT t
IF R2 <> 1 THEN
  FOR t = 65 TO 90
    IF t = 69 THEN t = t + 1
    GOSUB PredVariables
  NEXT t
END IF
GOSUB OrderVariables
RETURN

SingleVariables:
n = 1
FOR t = 97 TO 117
  IF t = sy(0) OR t = sy(1) OR t = sy(2) OR t = sy(3) THEN t = t + 1
  i = INSTR(n, in$, CHR$(t))
  IF i <> 0 THEN
    lft = ASC(MID$(SPACE$(1) + in$, i, 1))
    IF (lft > 223 AND lft < 238) OR (lft > 118 AND lft < 123) OR (lft > 64 AND lft < 91) THEN
      t = t - 1
      n = i + 1
    ELSE
      vartot = vartot + 1
      variable$(vartot) = MID$(in$, i, 1)
      varpos(vartot, 1) = i
      varpos(vartot, 2) = 1
      n = 1
    END IF
  ELSE
     n = 1
  END IF
NEXT t
RETURN

PredVariables:
Start = 1
i = 1
DO WHILE i <> 0
  i = INSTR(i, in$, CHR$(t))
  IF i <> 0 THEN
    vartot = vartot + 1
    predtot = predtot + 1
    variable$(vartot) = MID$(in$, i, 1)
    varpos(vartot, 1) = i
    varpos(vartot, 2) = 1
    FOR c = i + 1 TO i + 5
      w$ = MID$(in$, c, 1)
      IF w$ <> "" THEN
	d = ASC(w$)
      ELSE
	d = 0
      END IF
      IF d > 118 AND d < 123 THEN
	variable$(vartot) = variable$(vartot) + w$
	varpos(vartot, 2) = varpos(vartot, 2) + 1
      ELSE
	EXIT FOR
      END IF
    NEXT c
    FOR c = 1 TO vartot - 1
      IF variable$(c) = variable$(vartot) THEN
	vartot = vartot - 1
	predtot = predtot - 1
      END IF
    NEXT c
    i = i + 1
  END IF
LOOP
RETURN

OrderVariables:
FOR t = 1 TO vartot
  FOR variablecount = 1 TO vartot - 1
    IF varpos(variablecount, 1) > varpos(variablecount + 1, 1) THEN
      SWAP varpos(variablecount, 1), varpos(variablecount + 1, 1)
      SWAP varpos(variablecount, 2), varpos(variablecount + 1, 2)
      SWAP variable$(variablecount), variable$(variablecount + 1)
    END IF
  NEXT variablecount
NEXT t
RETURN

Wildcard:
GOSUB FindVariables
FOR t = 1 TO vartot
  wff$(t) = CHR$(t + 111)
NEXT t
GOSUB Substitute
in$ = newlin$
RETURN

Find:
CALL Functions(5, 0)
CALL Blankline(15, 17)
PRINT "Search String: ";
CALL InputLine(65, 0, searchlin$)
searchlin$ = in$
searchtype = 0
DO WHILE searchtype < 1 OR searchtype > 3
  CALL Blankline(15, 17)
  searchtype = 1
  PRINT "Search for [1]=Line match, [2]=Where used or [3]=Form? ";
  CALL InputLine(1, 0, STR$(searchtype))
  searchtype = VAL(in$)
LOOP
GOSUB Search
CALL Blankline(14, 17)
IF numjumps > 0 THEN PRINT "Found: ";
FOR t = 1 TO numjumps
  PRINT jumps(t);
NEXT t
wv = 0
GOSUB UpdateScreen
CALL Functions(helpscreen, 0)
RETURN

REM *** Pass searchlin$, and searchtype ***
Search:
CALL Functions(1, 3)
numjumps = 0
jumpnum = 0
CALL PleaseWait
SELECT CASE searchtype
CASE 1, 2
  FOR linecount = linenumber TO last
    found = 0
    IF searchtype = 1 THEN
      IF lines$(linecount) = searchlin$ THEN found = 1
    ELSE
      IF INSTR(lines$(linecount), searchlin$) <> 0 THEN found = 1
    END IF
    IF found = 1 THEN
      numjumps = numjumps + 1
      jumps(numjumps) = linecount
      IF numjumps > 15 THEN linecount = last
    END IF
    IF INKEY$ = CHR$(27) THEN EXIT FOR
  NEXT linecount
CASE 3
  in$ = searchlin$
  GOSUB Wildcard
  searchlin$ = in$
  FOR linecount = linenumber TO last
    in$ = lines$(linecount)
    GOSUB Wildcard
    IF INSTR(in$, searchlin$) <> 0 THEN
      numjumps = numjumps + 1
      jumps(numjumps) = linecount
      IF numjumps > 15 THEN linecount = last
    END IF
    IF INKEY$ = CHR$(27) THEN EXIT FOR
  NEXT linecount
END SELECT
RETURN

Jump:
CALL Blankline(15, 16)
PRINT "Jump to line number: ";
CALL InputLine(3, 1, "")
nv = VAL(in$)
IF in$ = "" AND wv <> 27 THEN
  jumpnum = jumpnum + 1
  IF jumpnum > numjumps THEN jumpnum = 1
  nv = jumps(jumpnum)
END IF
IF (nv > 0 AND nv <= last - 9) OR (last - 9 < 0 AND nv > 0 AND nv < last) THEN
  row = nv
  b = 2
ELSEIF nv > 0 AND nv <= last AND last > 9 THEN
  row = last - 9
  b = 2 + (nv - (last - 9))
END IF
GOSUB UpdateScreen
CALL Functions(helpscreen, 0)
keys(0, 0) = 0
wv = 0
fv = 2
RETURN

Del:
IF (FNCheckRCP(linenumber) <> 1 OR prf(linenumber, 2) = 1) AND (prf(linenumber, 2) <> -2 AND prf(linenumber, 0) <> 0) THEN
  GOSUB Delete
  GOSUB KillDeadLines
  x = -254
  y = 0
  fv = 2
  GOSUB ScreenCheck
ELSE
  CALL ErrorMessage("Cannot delete this line.", 0)
END IF
CALL Functions(helpscreen, 0)
RETURN

Delete:
IF prf(linenumber, 2) = -1 THEN axioms = axioms - 1
FOR t = 1 TO rcpcount
  IF firstlineofRCP(t) > linenumber THEN
    firstlineofRCP(t) = firstlineofRCP(t) - 1
  ELSEIF firstlineofRCP(t) = linenumber THEN
    FOR c = t TO rcpcount
      firstlineofRCP(c) = firstlineofRCP(c + 1)
    NEXT c
    rcpcount = rcpcount - 1
    rcp = firstlineofRCP(rcpcount)
  END IF
NEXT t
FOR t = linenumber TO (last - 1)
  FOR c = 0 TO 2
    IF prf(t + 1, c) > linenumber THEN
      prf(t + 1, c) = prf(t + 1, c) - 1
    ELSEIF prf(t + 1, c) = linenumber THEN
      prf(t + 1, 2) = dead
    END IF
  NEXT c
  lines$(t) = lines$(t + 1)
  proof$(t) = proof$(t + 1)
  FOR c = 0 TO 2
    prf(t, c) = prf(t + 1, c)
  NEXT c
NEXT t
FOR t = 0 TO 2
  IF dr(t) > linenumber THEN
    dr(t) = dr(t) - 1
  ELSEIF dr(t) = linenumber THEN
    dr(t) = 0
  END IF
NEXT t
IF blklin > linenumber THEN
  blklin = blklin - 1
  GOSUB DisplayBlock
ELSEIF blklin = linenumber THEN
  blklin = 0
  blk$ = ""
  GOSUB BlockNum
  COLOR co1, co2
END IF
lines$(last) = ""
proof$(last) = ""
FOR c = 0 TO 2
  prf(last, c) = 0
NEXT c
last = last - 1
RETURN

KillDeadLines:
count = linenumber
WHILE count <= last
  IF prf(count, 2) = dead THEN
    linenumber = count
    GOSUB Delete
    count = count - 1
  END IF
  count = count + 1
WEND
RETURN

Enter:
in1$ = ""
wl = 1
DO UNTIL wl = 0
  CALL Functions(5, 0)
  CALL Blankline(15, 17)
  PRINT "Enter axiom: ";
  CALL InputLine(67, 3, in1$)
  in1$ = in$
  GOSUB CheckLogic
  IF badbrack = 0 AND in$ <> "" THEN
    linenumber = axioms + 1
    lines$(0) = lines$(linenumber)
    lines$(linenumber) = in$
    in1$ = in$
    GOSUB CheckTaut
    IF in1$ <> "" THEN
      axioms = axioms + 1
      action = -1
      CALL Newline(in1$, " Axiom", axioms, 0, axioms)
      in1$ = ""
    END IF
  END IF
LOOP
GOSUB UpdateScreen
CALL Functions(helpscreen, 0)
RETURN

Prove:
proveline = linenumber
CALL Functions(1, 3)
CALL Blankline(15, 17)
PRINT "WARNING:  This function deletes all lines which are not used in proving"
PRINT "          the current line."
CALL Getcharacter(POS(0), CSRLIN, 1)
IF wv = 13 THEN
  CALL PleaseWait
  COLOR co1, co2
  FOR linenumber = proveline + 1 TO last
    GOSUB Delete
  NEXT linenumber
  count = 1
  linenumber = proveline
  numbers(count) = prf(linenumber, 0)
  IF prf(linenumber, 1) > 0 THEN
    count = count + 1
    numbers(count) = prf(linenumber, 1)
  END IF
  linenumber = linenumber - 1
  WHILE linenumber > 0
    flag = 0
    FOR t = 1 TO count
      IF linenumber = numbers(t) THEN flag = 1
    NEXT t
    IF flag = 1 THEN
      count = count + 1
      numbers(count) = prf(linenumber, 0)
      IF prf(linenumber, 1) > 0 THEN
	count = count + 1
	numbers(count) = prf(linenumber, 1)
      END IF
    ELSE
      GOSUB Delete
    END IF
    linenumber = linenumber - 1
  WEND
END IF
b = 2
a = 6
fv = 2
row = 1
column = 1
ERASE numbers
GOSUB UpdateScreen
CALL Functions(helpscreen, 0)
RETURN

Parms:
CALL Blankline(13, 22)
CALL DrawBox(10, 15, 60, 6, co1, co2, dbox$)
CALL Title("Change Parameters", 15, 12, 59)
CALL Functions(1, 3)
LOCATE 16, 12, 0: PRINT "Left margin:  "; lmargin;
LOCATE 17, 12, 0: PRINT "Margin 1:     "; margin1;
LOCATE 18, 12, 0: PRINT "Margin 2:     "; margin2;
LOCATE 16, 40, 0: PRINT "Lines per page:"; linesperpage;
LOCATE 17, 40, 0: PRINT "Colour 1:     :"; co1;
LOCATE 18, 40, 0: PRINT "Colour 2:     :"; co2;
LOCATE 19, 19, 0: PRINT "Printer setup string: "; pstring$;
DO WHILE wv <> 13 AND wv <> 27
  lmargin = FNGetInfo(2, 27, 16, 80, 0, lmargin)
  IF wv = 27 THEN EXIT LOOP
  margin1 = FNGetInfo(2, 27, 17, 80 - lmargin, 1, margin1)
  margin2 = FNGetInfo(2, 27, 18, 80 - lmargin - margin1, 1, margin2)
  linesperpage = FNGetInfo(3, 56, 16, 100, 1, linesperpage)
  co1 = FNGetInfo(2, 56, 17, 15, 0, co1)
  co2 = FNGetInfo(2, 56, 18, 15, 0, co2)
  LOCATE 19, 41, 0
  CALL InputLine(20, 3, pstring$)
  pcode$ = ""
  IF in$ <> "" THEN
    FOR t = 1 TO LEN(in$) STEP 2
      FOR dec = 0 TO 255
        chunk$ = UCASE$(MID$(in$ + "0000", t, 2))
        IF RIGHT$("0" + HEX$(dec), 2) = chunk$ THEN pcode$ = pcode$ + CHR$(dec)
      NEXT dec
    NEXT t
  END IF
  pstring$ = in$
LOOP
CALL Blankline(13, 22)
GOSUB CreateScreen
GOSUB UpdateScreen
RETURN

PrintOut:
CALL Functions(1, 3)
linecount = 1
prnchoice = 0
DO WHILE prnchoice < 1 OR prnchoice > 2
  CALL Blankline(15, 16)
  prnchoice = 2
  PRINT "Print lines to [1]=Disk or [2]=Printer? ";
  CALL InputLine(1, 0, STR$(prnchoice))
  IF wv <> 27 THEN
    prnchoice = VAL(in$)
  ELSE
    EXIT LOOP
  END IF
LOOP
IF wv <> 27 THEN
  tmpfilename$ = filename$
  IF prnchoice = 1 THEN
    i = INSTR(filename$, ".")
    IF i = 0 THEN
      filename$ = LEFT$(filename$, 8) + ".DOC"
    ELSE
      filename$ = LEFT$(filename$, i) + "DOC"
    END IF
    io$ = "print to disk: "
    GOSUB GetFileName
    IF in$ <> "" THEN filename$ = in$
  END IF
  CALL Blankline(15, 16)
  PRINT "Start line: ";
  prntloop = FNGetInfo(4, 13, 15, last, 1, 1)
  IF wv = 27 THEN EXIT IF
  CALL Blankline(16, 17)
  PRINT "End line:   ";
  lst = FNGetInfo(4, 13, 16, last, prntloop, last)
  IF wv = 27 THEN EXIT IF
  GOSUB ContPrint
END IF
GOSUB UpdateScreen
CALL Functions(helpscreen, 0)
RETURN

ContPrint:
CALL Blankline(15, 16)
PRINT "Press [ENTER] to " + poption$(prnchoice) + " lines";prntloop;"-";lst;"or [ESC] to abort."
CALL Getcharacter(POS(0), CSRLIN, 1)
IF wv = 13 THEN
  ON ERROR GOTO ErrorHandler
  CALL Blankline(15, 16)
  PRINT "Sending "; filename$
  IF prnchoice = 1 THEN
    OPEN currentpath$ + filename$ FOR OUTPUT AS #1
  ELSE
    OPEN "LPT1:" FOR OUTPUT AS #2
    PRINT #2, pcode$
  END IF
  WHILE prntloop <= lst
    num$ = "   " + STR$(prntloop)
    lin$ = RIGHT$(num$, 3) + "# " + lines$(prntloop)
    IF prnchoice = 1 THEN
      lin$ = RIGHT$(num$, 3) + "# " + lines$(prntloop)
    ELSE
      lin$ = RIGHT$(num$, 3) + ". " + lines$(prntloop)
    END IF
    proof$ = STR$(prf(prntloop, 0))
    IF prf(prntloop, 1) > 0 THEN proof$ = proof$ + "," + STR$(prf(prntloop, 1))
    proof$ = proof$ + proof$(prntloop)
    length1 = LEN(lin$)
    length2 = LEN(proof$)
    flag = 0
    WHILE flag = 0
      IF length1 > margin1 THEN
	GOSUB Columnprint1
      ELSE
	lin$(0) = lin$
	lin$ = ""
      END IF
      IF length2 > margin2 - 1 THEN
	GOSUB Columnprint2
      ELSE
	lin$(1) = proof$
	proof$ = ""
      END IF
      IF lin$ = "" AND proof$ = "" AND prnchoice = 1 THEN
	lin$(1) = lin$(1) + "*"
      END IF
      IF prnchoice = 2 THEN
	 lin$(0) = lin$(0) + STRING$(margin1 + (80 - lmargin - margin1 - margin2) - LEN(lin$(0)), 32)
      END IF
      FOR t = 0 TO 1
	lin$(t) = FNReplace$(lin$(t), sy(0), 62)
      NEXT t
      IF prnchoice = 1 THEN
	WRITE #1, lin$(0), lin$(1)
      ELSE
	PRINT #2, SPC(lmargin); lin$(0); lin$(1)
	linecount = linecount + 1
	IF lin$ = "" AND proof$ = "" THEN
	  PRINT #2, ""
	  linecount = linecount + 1
	END IF
	IF linecount >= linesperpage THEN
	  FOR z = 1 TO INT(66 - linesperpage)
	    PRINT #2, ""
	  NEXT z
	  linecount = 0
	END IF
	END IF
	length1 = LEN(lin$)
	length2 = LEN(proof$)
	IF length1 = 0 AND length2 = 0 THEN flag = 1
     WEND
     prntloop = prntloop + 1
  WEND
  IF prnchoice = 1 THEN
    CLOSE 1
  ELSE
    FOR z = linecount + 1 TO 66
      PRINT #2, ""
    NEXT z
    CLOSE 2
  END IF
  ON ERROR GOTO 0
END IF
filename$ = tmpfilename$
RETURN

Columnprint1:
cut = 0
FOR t = margin1 TO 2 STEP -1
  i$ = MID$(lin$, t - 1, 2)
  IF i$ = ")" + symbol$(0) OR i$ = ")" + symbol$(2) OR i$ = ")v" OR i$ = ")" + symbol$(3) THEN
    cut = t
    t = 0
  END IF
NEXT t
lin$(0) = LEFT$(lin$, cut)
lin$ = "     " + MID$(lin$, cut + 1)
RETURN

Columnprint2:
cut = 0
addone$ = ""
FOR t = margin2 - 1 TO 1 STEP -1
  i$ = MID$(proof$, t, 1)
  IF i$ = ";" THEN
    cut = t
    t = 0
  END IF
NEXT t
IF cut = 0 THEN
  FOR t = margin2 - 1 TO 1 STEP -1
    i$ = MID$(proof$, t, 1)
    IF i$ = symbol$(0) OR i$ = symbol$(1) OR i$ = symbol$(2) OR i$ = symbol$(3) THEN
      cut = t
      t = 0
      addone$ = " "
    END IF
  NEXT t
END IF
lin$(1) = LEFT$(proof$, cut)
proof$ = "    " + addone$ + MID$(proof$, cut + 1)
RETURN

REM *** Logical Functions ***

RCPon:
CALL Functions(5, 0)
CALL Blankline(15, 17)
PRINT USING "### "; last + 1;
CALL InputLine(76, 1, "")
GOSUB CheckLogic
IF in$ <> "" AND rcpcount < 10 AND badbrack = 0 THEN
  linenumber = last + 1
  lines$(0) = ""
  lines$(linenumber) = in$
  in1$ = in$
  GOSUB CheckTaut
  IF in1$ <> "" THEN
    in$ = in1$
    rcpcount = rcpcount + 1
    firstlineofRCP(rcpcount) = last + 1
    Definition$ = "HP"
    blklin = last + 1
    GOSUB Separator
    part$(0) = ""
    part$(41) = ""
    Test = 1
    rcp = 1
    action = last + 1
    GOSUB CheckNewLine
    rcp = firstlineofRCP(rcpcount)
  END IF
END IF
GOSUB UpdateScreen
CALL Functions(helpscreen, 0)
RETURN

RCPoff:
IF rcp > 0 THEN
  Definition$ = "RCP"
  in$ = symbol$(4) + lines$(firstlineofRCP(rcpcount)) + symbol$(0) + lines$(last) + symbol$(5)
  GOSUB Separator
  IF rcpcount < 2 THEN
    rcp = -2
  ELSE
    rcp = 2
  END IF
  part$(0) = ""
  part$(41) = ""
  blklin = firstlineofRCP(rcpcount)
  Test = 1
  action = last + 1
  GOSUB CheckNewLine
  prf(last, 1) = last - 1
  rcpcount = rcpcount - 1
  IF rcp = 2 THEN rcp = firstlineofRCP(rcpcount)
  IF rcp = -2 THEN rcp = 0
  blklin = 0
  GOSUB BlockNum
  COLOR co1, co2
END IF
GOSUB UpdateScreen
CALL Functions(helpscreen, 0)
RETURN

Definition1:
Definition$ = "D1"
in$ = blk$
Test = 0
GOSUB Separator
IF part$(25) = symbol$(0) AND part$(10) = symbol$(4) AND part$(40) = symbol$(5) THEN
  part$(19) = part$(19) + symbol$(6)
  part$(25) = symbol$(1)
  Test = 1
ELSEIF part$(25) = symbol$(1) AND LEFT$(part$(19), 1) = symbol$(6) AND part$(10) = symbol$(4) AND part$(40) = symbol$(5) THEN
  part$(19) = LEFT$(part$(19), LEN(part$(19)) - 1)
  part$(25) = CHR$(sy(0))
  Test = 1
END IF
GOSUB CheckNewLine
RETURN

Definition2:
Definition$ = "D2"
in$ = blk$
Test = 0
GOSUB Separator
IF part$(25) = symbol$(2) AND part$(10) = symbol$(4) AND part$(40) = symbol$(5) THEN
  part$(9) = part$(9) + symbol$(6)
  part$(19) = part$(19) + symbol$(6)
  part$(34) = part$(34) + symbol$(6)
  part$(25) = symbol$(1)
  Test = 1
ELSEIF part$(25) = symbol$(1) AND LEFT$(part$(9), 1) = symbol$(6) AND LEFT$(part$(19), 1) = symbol$(6) THEN
  IF part$(10) = symbol$(4) AND part$(40) = symbol$(5) AND LEFT$(part$(34), 1) = symbol$(6) THEN
    part$(9) = LEFT$(part$(9), LEN(part$(9)) - 1)
    part$(19) = LEFT$(part$(19), LEN(part$(19)) - 1)
    part$(34) = LEFT$(part$(34), LEN(part$(34)) - 1)
    part$(25) = symbol$(2)
    Test = 1
  END IF
END IF
GOSUB CheckNewLine
RETURN

Definition3:
Definition$ = "D3"
in$ = blk$
Test = 0
GOSUB Separator
IF part$(25) = symbol$(3) AND part$(10) = symbol$(4) AND part$(40) = symbol$(5) AND part$(9) = "" THEN
  subject$ = FNLinePart$(11, 24, 1)
  predicate$ = FNLinePart$(26, 39, 1)
  FOR t = 11 TO 39
    part$(t) = ""
  NEXT t
  part$(20) = symbol$(4) + subject$ + CHR$(sy(0)) + predicate$ + symbol$(5)
  part$(35) = symbol$(4) + predicate$ + symbol$(0) + subject$ + symbol$(5)
  part$(25) = symbol$(2)
  Test = 1
ELSEIF part$(25) = symbol$(2) AND LEFT$(part$(20), 1) = symbol$(4) AND LEFT$(part$(35), 1) = symbol$(4) THEN
  IF part$(10) = symbol$(4) AND part$(40) = symbol$(5) AND part$(19) = "" AND part$(34) = "" THEN
    part4$ = FNLinePart$(11, 24, 1)
    in$ = FNLinePart$(26, 39, 1)
    GOSUB Separator
    subject$ = FNLinePart$(11, 24, 1)
    predicate$ = FNLinePart$(26, 39, 1)
    in$ = part4$
    GOSUB Separator
    IF FNLinePart$(11, 24, 1) = predicate$ AND FNLinePart$(26, 39, 1) = subject$ THEN
      part$(25) = symbol$(3)
      Test = 1
    END IF
  END IF
END IF
GOSUB CheckNewLine
RETURN

Definition4:
Definition$ = "D4"
Test = 0
IF LEFT$(blk$, 2) = "(E" AND RIGHT$(blk$, 1) = symbol$(5) AND blklen < 6 THEN
  CALL Newline(part$(0) + symbol$(6) + "(" + MID$(blk$, blklen - 1, 1) + ")" + symbol$(6) + part$(41), SPACE$(1) + Definition$, blklin, 0, 0)
ELSEIF LEFT$(blk$, 2) = symbol$(6) + "(" AND RIGHT$(blk$, 2) = ")" + symbol$(6) AND blklen < 6 THEN
  CALL Newline(part$(0) + "(E" + MID$(blk$, blklen - 2, 1) + symbol$(5) + part$(41), SPACE$(1) + Definition$, blklin, 0, 0)
ELSE
  CALL DefinitionError(Definition$)
END IF
CALL Functions(helpscreen, 0)
GOSUB BlockOff
RETURN

CheckNewLine:
IF Test = 1 AND FNCheckRCP(blklin) <> 1 THEN
  CALL Newline(FNLinePart$(0, 41, 1), SPACE$(1) + Definition$, blklin, 0, action)
ELSE
  CALL DefinitionError(Definition$)
END IF
CALL Functions(helpscreen, 0)
GOSUB BlockOff
RETURN

Rule2:
IF fv = 1 THEN
  SELECT CASE wv
  CASE 65 TO 125, 224 TO 237, sy(4), sy(5), sy(6), 8
    GOSUB GetWFF
  END SELECT
ELSE
  SELECT CASE wv
  CASE 58 TO 68
    GOSUB GetWFF
  END SELECT
END IF
IF wv = 13 THEN
  in$ = blk$
  GOSUB CheckLogic
  IF badbrack = 0 THEN
    CALL Blankline(18, 19)
    vt = ASC(variable$(varcount))
    IF blk$ <> "" THEN
      sb = ASC(blk$)
    ELSE
      sb = 0
    END IF
    IF vt > 223 AND (sb <> 0 AND (sb > 90 AND sb < 119)) THEN
      GOSUB DisplayWFF
    ELSEIF (vt > 117 AND vt < 123) AND sb <> 0 AND (((sb < 118 OR sb > 122) OR INSTR(lines$(R2lin), symbol$(4) + CHR$(sb) + symbol$(5)) <> 0)) THEN
      GOSUB DisplayWFF
    ELSE
      wff$(varcount) = blk$
      blk$ = ""
      varcount = varcount + 1
      IF varcount > vartot THEN
	in$ = lines$(R2lin)
	GOSUB SubWFF
      ELSE
	GOSUB DisplayWFF
      END IF
    END IF
  ELSE
    GOSUB DisplayWFF
  END IF
ELSE
   GOSUB DisplayWFF
END IF
RETURN

GetWFF:
COLOR 7, 0
LOCATE 19, position + 2, 1
blk$ = blk$
CALL InputLine(fl, 2, blk$)
blk$ = in$
RETURN

DisplayWFF:
COLOR 7, 0
position = 5 + varpos(varcount, 1)
fl = 80 - (position + 1)
LOCATE 18, position, 0
PRINT "³";
LOCATE 19, position, 0
PRINT "À>"; blk$; STRING$(ABS((80 - (position + 1)) - LEN(blk$)), 254);
PRINT STRING$(ABS((80 - (position + 1)) - LEN(blk$)), 29);
COLOR co1, co2
RETURN

SubWFF:
flag = 0
FOR t = 1 TO vartot
  IF wff$(t) <> "" THEN flag = 1
  IF RIGHT$(wff$(t), 1) = symbol$(6) THEN
     flag = 0
     EXIT FOR
  END IF
NEXT t
IF flag > 0 THEN
  GOSUB Substitute
  in2$ = " "
  FOR t = 1 TO vartot
    IF wff$(t) <> "" THEN
       in2$ = in2$ + variable$(t) + "/" + wff$(t) + "; "
    END IF
  NEXT t
  CALL Newline(newlin$, LEFT$(in2$, LEN(in2$) - 2), R2lin, 0, action)
END IF
GOSUB R2off
GOSUB UpdateScreen
R2 = 0
RETURN

Substitute:
newlin$ = ""
FOR t = 1 TO LEN(in$)
   w$ = MID$(in$, t, 1)
   flag = 0
   FOR varcount = 1 TO vartot
      w$ = MID$(in$, t, varpos(varcount, 2))
      IF w$ = variable$(varcount) AND wff$(varcount) <> "" THEN
	 newlin$ = newlin$ + wff$(varcount)
	 flag = 1
	 IF varpos(varcount, 2) > 1 THEN
	    t = t + varpos(varcount, 2) - 1
	 END IF
      END IF
   NEXT varcount
   IF flag = 0 THEN newlin$ = newlin$ + LEFT$(w$, 1)
NEXT t
RETURN

R2off:
R2 = 0
cursor = 1
helpscreen = 0
CALL Blankline(17, 22)
CALL Instructions(helpscreen)
CALL Functions(helpscreen, 0)
RETURN

Rule3:
part$(0) = ""
part$(41) = ""
in$ = lines$(linenumber)
vars$ = ""
found = 0
GOSUB Separator
GOSUB FindVariables
FOR t = 1 TO vartot
  IF varpos(t, 2) > 1 THEN
    FOR c = 2 TO varpos(t, 2)
      IF INSTR(vars$, MID$(variable$(t), c, 1)) = 0 THEN
	vars$ = vars$ + MID$(variable$(t), c, 1) + "/"
      END IF
    NEXT c
  END IF
NEXT t
IF predtot > 0 AND vars$ <> "" AND windo <> 2 AND FNCheckRCP(linenumber) <> 1 THEN
  CALL Blankline(15, 17)
  PRINT "Which variable do you wish to quantify ("; LEFT$(vars$, LEN(vars$) - 1); ")?";
  CALL Getcharacter(POS(0), CSRLIN, 2)
  IF INSTR(vars$, CHR$(wv)) <> 0 THEN found = 1
  message$ = "Cannot find variable."
  IF prf(linenumber, 2) > 0 THEN
    FOR t = 1 TO rcpcount
      IF INSTR(1, lines$(firstlineofRCP(t)), CHR$(wv)) <> 0 THEN
	IF INSTR(1, lines$(firstlineofRCP(t)), symbol$(4) + CHR$(wv) + symbol$(5)) = 0 THEN
	  message$ = "RCP conflict.  Variable-" + CHR$(wv) + " is hypothesized free in line" + STR$(firstlineofRCP(t))
	  found = 0
	END IF
      END IF
    NEXT t
  END IF
  IF found <> 0 AND part$(8) = "" THEN
    FOR t = 8 TO 4 STEP -2
      part$(t) = part$(t - 2)
      part$(t - 1) = part$(t - 3)
    NEXT t
    part$(2) = symbol$(4) + CHR$(wv) + symbol$(5)
    CALL Newline(FNLinePart$(0, 41, 1), " R3", linenumber, 0, 0)
  ELSEIF part$(8) <> "" THEN
    CALL ErrorMessage("Too many quantifyers.", 0)
  ELSE
    CALL ErrorMessage(message$, 0)
  END IF
ELSE
  CALL ErrorMessage("Cannot perform Rule 3.", 0)
END IF
CALL Functions(helpscreen, 0)
GOSUB BlockOff
RETURN

CheckBrackets:
bracktot = 0
badbrack = 0
opcount = 0
count = 0
a$ = "Line is improperly bracketed or missing logical operator."
l = LEN(in$)
IF FNIsItaWFF(in$, 5) > 0 THEN
  FOR t = 1 TO l
    w1$ = MID$(in$, t, 1)
    w2$ = MID$(in$ + " ", t + 1, 1)
    w1 = ASC(w1$)
    w2 = ASC(w2$)
    SELECT CASE w1
      CASE 65 TO 68, 70 TO 90, 224 TO 237
	GOSUB BadWFF
      CASE 97 TO 117
	GOSUB BadWFF
	IF w2 > 118 AND w2 < 123 THEN count = 99
      CASE sy(0), sy(1), sy(2), sy(3)
	opcount = opcount + 1
      CASE 69
	SELECT CASE w2
	  CASE 119 TO 122
	    opcount = opcount + 1
	  CASE ELSE
	    count = 99
	END SELECT
      CASE sy(4)
	bracktot = bracktot + 1
	count = count + 1
      CASE sy(5)
	count = count - 1
	bracktot = bracktot + 1
      CASE 119 TO 122
	IF w2 = sy(5) AND MID$(" " + in$, t, 1) = symbol$(4) THEN
	  opcount = opcount + 1
	ELSE
	  GOSUB BadWFF
	END IF
    END SELECT
  NEXT t
  IF count <> 0 OR bracktot / 2 <> opcount THEN
    GOSUB BadBracket
  END IF
ELSE
  a$ = "Improper variable."
  t = 1
  WHILE INSTR(t, in$ + " ", symbol$(6)) <> 0
    t = INSTR(t, in$ + " ", symbol$(6)) + 1
  WEND
  w1$ = MID$(in$ + " ", t, 1)
  w2$ = MID$(in$ + "ww", t + 1, 1)
  w1 = ASC(w1$)
  w2 = ASC(w2$)
  SELECT CASE w1
    CASE 97 TO 117
      IF l - (t - 1) > 1 THEN GOSUB BadBracket
    CASE 119 TO 122
      GOSUB BadBracket
    CASE ELSE
      IF l - (t - 1) > 5 OR (w2 < 119 OR w2 > 122) THEN GOSUB BadBracket
  END SELECT
END IF
count = 0
FOR t = l TO 1 STEP -1
  w1$ = MID$(in$, t, 1)
  wv = ASC(w1$)
  IF FNIsItaWFF(w1$, 3) <= 0 THEN
    SELECT CASE wv
      CASE 0 TO 25
	count = t
      CASE 27 TO 39
	count = t
      CASE 42 TO 64
	count = t
      CASE 91 TO 96
	count = t
      CASE 127 TO 223
	count = t
      CASE 123 TO 125
	count = t
      CASE 238 TO 255
	count = t
    END SELECT
  END IF
NEXT t
IF count <> 0 THEN
  a$ = SPACE$(count - 1) + "^ Illegal character."
  GOSUB BadBracket
END IF
RETURN

BadWFF:
SELECT CASE w2
  CASE sy(0), sy(1), sy(2), sy(3), sy(5), 32, 119 TO 122
    count = count
  CASE ELSE
    count = 99
END SELECT
RETURN

BadBracket:
CALL Blankline(15, 16)
badbrack = 1
PRINT in$
PRINT a$
REM BEEP
CALL Functions(1, 3)
CALL Getcharacter(POS(0), CSRLIN, 1)
CALL Functions(helpscreen, 0)
CALL Blankline(15, 16)
RETURN

CheckTaut:
tableok = 0
GOSUB Components
GOSUB Independence
IF tautology = 1 THEN
  CALL Functions(1, 3)
  CALL Blankline(16, 17)
  PRINT "WARNING: Not a tautology.  Do wish to add this line?";
  CALL Getcharacter(POS(0), CSRLIN, 2)
  SELECT CASE wv
  CASE 89, 121, 13
    in1$ = lines$(linenumber)
  CASE ELSE
    in1$ = ""
  END SELECT
  CALL Blankline(15, 17)
END IF
lines$(linenumber) = lines$(0)
RETURN

CheckLogic:
IF FNIsItaWFF(in$, 3) > 0 THEN
  GOSUB Separator
  IF FNIsItaWFF(part$(25), 3) <= 0 AND badbrack <> 1 THEN
    a$ = "Line contains misplaced logical operator."
    GOSUB BadBracket
  END IF
  IF badbrack <> 0 THEN
    in$ = ""
    badbrack = 1
  END IF
ELSEIF FNIsItaWFF(in$, 5) >= 0 THEN
  GOSUB CheckBrackets
END IF
RETURN

Separator:
FOR t = 1 TO 40
  part$(t) = ""
NEXT t
nthcharacter = 1
length = LEN(in$)
count = 0
part = 1
GOSUB CheckBrackets
IF badbrack = 0 THEN
  DO WHILE part < 41
    ON vector(part) GOSUB FindPredNeg, FindQuantifyer, FindNeg, SingleCharacter, SubjectPredicate, WXYZ
    IF nthcharacter > length THEN EXIT LOOP
  LOOP
END IF
RETURN

Getcharacter:
FOR t = 0 TO 3
  w$ = MID$(in$, nthcharacter + t, 1)
  IF w$ <> "" THEN
    ww(t + 1) = ASC(w$)
  ELSE
    ww(t + 1) = 0
  END IF
NEXT t
RETURN

FindPredNeg:
GOSUB Getcharacter
IF ww(1) = sy(6) THEN
  part$(part) = part$(part) + CHR$(ww(1))
  nthcharacter = nthcharacter + 1
ELSE
  part = part + 1
END IF
RETURN

FindQuantifyer:
GOSUB Getcharacter
IF ww(1) = 40 AND (ww(2) = 69 AND (ww(3) > 96 AND ww(3) < 123)) THEN
  part$(part) = MID$(in$, nthcharacter, 4)
  nthcharacter = nthcharacter + 4
END IF
IF ww(1) = 40 AND ((ww(2) > 96 AND ww(2) < 123) AND ww(3) = 41) THEN
  part$(part) = MID$(in$, nthcharacter, 3)
  nthcharacter = nthcharacter + 3
END IF
part = part + 1
RETURN

FindNeg:
GOSUB Getcharacter
IF ww(1) = sy(6) THEN
  part$(part) = part$(part) + CHR$(ww(1))
  nthcharacter = nthcharacter + 1
ELSE
  FOR t = part - 8 TO part - 2 STEP 2
    IF part$(t) <> "" AND part$(t + 1) = "" THEN
      part$(part) = part$(t)
      part$(t) = ""
    END IF
  NEXT t
  part = part + 1
END IF
RETURN

SubjectPredicate:
GOSUB Getcharacter
IF ww(1) = 40 THEN count = count + 1
IF ww(1) = 41 THEN count = count - 1
part$(part) = part$(part) + CHR$(ww(1))
IF count = 0 THEN
  part = part + 1
  nthcharacter = nthcharacter + 1
ELSE
  nthcharacter = nthcharacter + 1
END IF
RETURN

WXYZ:
GOSUB Getcharacter
IF ww(1) > 118 AND ww(1) < 123 THEN
  part$(part) = CHR$(ww(1))
  part = part + 1
  nthcharacter = nthcharacter + 1
ELSE
  part = part + 1
END IF
RETURN

SingleCharacter:
GOSUB Getcharacter
part$(part) = CHR$(ww(1))
part = part + 1
nthcharacter = nthcharacter + 1
RETURN

Zoom:
windo = windo + 1
IF windo > 3 THEN windo = 1
keys(0, 71) = -74
keys(0, 79) = 74
SELECT CASE windo
CASE 1
  windowsize = 79
CASE 2
  windowsize = 79
CASE 3
  keys(0, 71) = -54
  keys(0, 79) = 54
  windowsize = 59
END SELECT
GOSUB CreateScreen
GOSUB UpdateScreen
wv = 71
fv = 2
RETURN

CreateScreen:
CALL DrawBox(1, 1, 80, 12, co1, co2, dbox$)
IF windo = 3 THEN
  CALL DrawBox(60, 1, 21, 12, co1, co2, "ÍË»ºÊ¼")
  CALL Title(filename$, 1, 3, windowsize)
  CALL Title(title2$, 1, 62, 19)
ELSEIF windo = 2 THEN
  CALL Title(title2$, 1, 3, windowsize)
ELSE
  CALL Title(filename$, 1, 3, windowsize)
END IF
GOSUB BlockNum
GOSUB DisplayBlock
CALL Instructions(helpscreen)
CALL Functions(helpscreen, 0)
RETURN

Table:
in$ = lines$(linenumber)
GOSUB GetPrefforOutput
CALL PleaseWait
tableok = 0
GOSUB Components
GOSUB Independence
SELECT CASE prnchoice
  CASE 3
    GOSUB DisplayOutPut
  CASE 1, 2
    GOSUB PrintTable
END SELECT
CALL Blankline(15, 17)
CALL Instructions(helpscreen)
CALL Functions(helpscreen, 0)
RETURN

Values:
CALL Functions(1, 3)
v = 0
DO WHILE v < 1 OR v > 6
  CALL Blankline(15, 22)
  PRINT "How many truth values (1-6) ";
  CALL InputLine(1, 0, STR$(value))
  IF wv <> 27 THEN
    v = VAL(in$)
    value = v
  ELSE
    EXIT LOOP
  END IF
LOOP
IF wv <> 27 THEN
FOR t = 0 TO 3
  CALL Blankline(15, 17)
  COLOR 0, 7
  PRINT SPACE$(1); symbol$(t); SPACE$(1);
  FOR tr = 0 TO value - 1
    PRINT tr;
  NEXT tr
  PRINT
  FOR tr = 0 TO value - 1
    COLOR 0, 7
    PRINT tr;
    FOR tc = 0 TO value - 1
      COLOR 7, 0
      PRINT v1(tr, tc, t);
    NEXT tc
    PRINT
  NEXT tr
  FOR tr = 0 TO value - 1
    tc = 0
    DO WHILE tc < value
      v = -1
      DO WHILE v < 0 OR v >= value
	LOCATE tr + 16, tc + 5 + (2 * tc)
	CALL InputLine(1, 0, STR$(v1(tr, tc, t)))
	IF wv = 27 THEN EXIT IF
	v = VAL(in$)
	v1(tr, tc, t) = v
      LOOP
      tc = tc + 1
    LOOP
  NEXT tr
NEXT t
COLOR 0, 7
LOCATE 15, 40, 0
PRINT SPACE$(4); symbol$(6); SPACE$(1);
FOR tr = 0 TO value - 1
  COLOR 0, 7
  LOCATE 16 + tr, 40, 0
  PRINT tr;
  COLOR 7, 0
  PRINT neg(tr);
NEXT tr
FOR tr = 0 TO value - 1
  v = -1
  DO WHILE v < 0 OR v >= value
    LOCATE tr + 16, 44, 0
    CALL InputLine(1, 0, STR$(neg(tr)))
    IF wv = 27 THEN EXIT FOR
    v = VAL(in$)
    neg(tr) = v
  LOOP
NEXT tr
END IF
CALL Blankline(15, 22)
CALL Instructions(helpscreen)
CALL Functions(helpscreen, 0)
RETURN

Components:
FOR t = 1 TO 42
  comp$(t) = ""
NEXT t
comp$(0) = lines$(linenumber)
compc = 0
ccount = 1
DO WHILE ccount <> compc
  in$ = comp$(compc)
  IF FNIsItaWFF(in$, 3) > 0 THEN
    GOSUB Separator
    comp$(ccount) = FNLinePart$(11, 24, 1)
    comp$(ccount + 1) = FNLinePart$(26, 39, 1)
    ccount = ccount + 2
  END IF
  compc = compc + 1
  IF compc > 40 OR ccount > 40 THEN ccount = compc
LOOP
compc = compc - 1
in$ = lines$(linenumber)
GOSUB FindVariables
IF compc + vartot < 43 THEN
  FOR t = 1 TO vartot
    compc = compc + 1
    comp$(compc) = variable$(t)
  NEXT t
  FOR c = 1 TO compc
    Test = 0
    FOR t = c + 1 TO compc
      IF comp$(c) = comp$(t) THEN
	Test = 1
      END IF
    NEXT t
    IF Test = 1 THEN
      FOR t = c TO compc
	IF t < 42 THEN comp$(t) = comp$(t + 1)
      NEXT t
      comp$(compc) = ""
      c = c - 1
      compc = compc - 1
    END IF
  NEXT c
ELSE
  tableok = 1
END IF
  IF compc > 18 THEN tableok = 1
RETURN

Independence:
tautology = 0
IF value ^ vartot <= 256 AND compc < 19 THEN
  stepv = 1
  varcount = 0
  FOR c = (compc - vartot) + 1 TO compc
    t = 1
    DO WHILE t <= value ^ vartot
      FOR vc = 0 TO value - 1
	FOR stepc = 1 TO stepv
          Table(c, t) = vc
	  t = t + 1
	NEXT stepc
      NEXT vc
    LOOP
    varcount = varcount + 1
    stepv = value ^ varcount
  NEXT c
  FOR t = 0 TO compc + vartot
    IF FNIsItaWFF(comp$(t), 3) <= 0 THEN
      FOR c = 0 TO compc
	IF INSTR(comp$(t) + " ", comp$(c) + " ") <> 0 THEN
	  FOR cn = 1 TO value ^ vartot
	    Table(t, cn) = Table(c, cn)
          NEXT cn
	END IF
      NEXT c
    END IF
  NEXT t
  FOR ccount = compc - vartot TO 0 STEP -1
    in$ = comp$(ccount)
    GOSUB Separator
    IF FNIsItaWFF(comp$(ccount), 3) > 0 THEN
      compv1 = FNWhichComponent(FNLinePart$(11, 24, 1))
      compv2 = FNWhichComponent(FNLinePart$(26, 39, 1))
      stype = 0
      DO UNTIL part$(25) = symbol$(stype) OR stype = 3
	 stype = stype + 1
      LOOP
      FOR cn = 1 TO value ^ vartot
REM *** The following is the lookup table for the symbols ***
	Table(ccount, cn) = v1(Table(compv1, cn), Table(compv2, cn), stype)
      NEXT cn
    END IF
    GOSUB Negit
  NEXT ccount
  FOR cn = 1 TO value ^ vartot
    IF Table(0, cn) = v1(0, 1, 2) THEN tautology = 1
  NEXT cn
ELSE
  tableok = 1
END IF
RETURN

Negit:
FOR nc = 1 TO LEN(FNLinePart$(1, 9, 2))
  FOR cn = 1 TO value ^ vartot
    Table(ccount, cn) = neg(Table(ccount, cn))
  NEXT cn
NEXT nc
RETURN

DisplayOutPut:
IF tableok = 0 THEN
  CALL Blankline(1, 22)
  FOR t = 0 TO compc
    LOCATE t + 1, 1, 0
    PRINT USING "##"; t;
    PRINT SPACE$(6); LEFT$(comp$(t), 68);
    IF LEN(comp$(t)) > 68 THEN PRINT "..."
  NEXT t
  LOCATE t + 1, 1, 0
  PRINT " ÀÄÄÄ>";
  FOR t = compc TO 0 STEP -1
    PRINT USING "###"; t;
  NEXT t
  wt = 22 - (compc + 3)
  dv = 0
  FOR c = 1 TO value ^ vartot
    COLOR 7, 0
    LOCATE compc + 4 + dv, 1, 0
    PRINT USING "####: "; c;
    FOR t = compc TO 0 STEP -1
      PRINT USING "###"; Table(t, c);
    NEXT t
    dv = dv + 1
    IF dv >= wt AND c <> value ^ vartot THEN
      CALL Functions(1, 3)
      CALL Getcharacter(1, 1, 0)
      IF wv = 27 THEN c = value ^ vartot
      dv = 0
    END IF
  NEXT c
  CALL Blankline(compc + 4 + dv, compc + 3 + wt)
  CALL Functions(1, 1)
  CALL Getcharacter(1, 1, 0)
  GOSUB CreateScreen
  GOSUB UpdateScreen
END IF
RETURN

GetPrefforOutput:
prnchoice = 0
DO WHILE prnchoice < 1 OR prnchoice > 3
  prnchoice = 3
  CALL Blankline(15, 16)
  PRINT "Print truth table to [1]=Disk, [2]=Printer or [3]=Screen? ";
  CALL InputLine(1, 0, STR$(prnchoice))
  prnchoice = VAL(in$)
LOOP
IF prnchoice = 1 THEN
  tmpfilename$ = filename$
  i = INSTR(filename$, ".")
  IF i = 0 THEN
    filename$ = LEFT$(filename$, 8) + ".TBL"
  ELSE
    filename$ = LEFT$(filename$, i) + "TBL"
  END IF
  io$ = "print to disk: "
  GOSUB GetFileName
  IF in$ <> "" THEN filename$ = in$
END IF
RETURN

PrintTable:
CALL Blankline(15, 16)
PRINT "Press [ENTER] to " + poption$(prnchoice) + " truth table, or [ESC] to abort."
CALL Functions(1, 3)
CALL Getcharacter(POS(0), CSRLIN, 1)
IF wv <> 27 THEN
  ON ERROR GOTO PrintProblem
  IF prnchoice = 1 THEN
    OPEN currentpath$ + filename$ FOR OUTPUT AS #1
  ELSE
    OPEN "LPT1:" FOR OUTPUT AS #2
    PRINT #2, pcode$
  END IF
  CALL Blankline(15, 17)
  PRINT "Sending "; filename$
  FOR t = 0 TO compc
    CALL PrintSave(RIGHT$(SPACE$(4) + STR$(t), 4) + SPACE$(4) + comp$(t), prnchoice)
  NEXT t
  CALL PrintSave(CHR$(13), prnchoice)
  lin$ = SPACE$(4)
  FOR t = compc TO 0 STEP -1
    lin$ = lin$ + RIGHT$(SPACE$(3) + STR$(t), 3)
  NEXT t
  CALL PrintSave(lin$, prnchoice)
  FOR c = 1 TO value ^ vartot
    lin$ = RIGHT$(SPACE$(4) + STR$(c), 4)
    FOR t = compc TO 0 STEP -1
      lin$ = lin$ + RIGHT$(SPACE$(3) + STR$(Table(t, c)), 3)
    NEXT t
    CALL PrintSave(lin$, prnchoice)
  NEXT c
  FOR cn = 0 TO 3
    CALL PrintSave(CHR$(13), prnchoice)
    lin$ = SPACE$(1) + symbol$(cn)
    FOR tr = 0 TO value - 1
      lin$ = lin$ + STR$(tr)
    NEXT tr
    CALL PrintSave(lin$, prnchoice)
    FOR tr = 0 TO value - 1
      lin$ = STR$(tr)
      FOR tc = 0 TO value - 1
	lin$ = lin$ + STR$(v1(tr, tc, cn))
      NEXT tc
      CALL PrintSave(lin$, prnchoice)
    NEXT tr
  NEXT cn
  CALL PrintSave(CHR$(13), prnchoice)
  CALL PrintSave(SPACE$(3) + symbol$(6), prnchoice)
  FOR tr = 0 TO value - 1
    lin$ = STR$(tr) + STR$(neg(tr))
    CALL PrintSave(lin$, prnchoice)
  NEXT tr
  ON ERROR GOTO 0
END IF
IF prnchoice = 1 THEN
  CLOSE 1
  filename$ = tmpfilename$
END IF
GOSUB UpdateScreen
CALL Functions(helpscreen, 0)
RETURN

Replace:
in$ = blk$
GOSUB CheckLogic
IF badbrack = 0 AND FNCheckRCP(linenumber) <> 1 THEN
  in$ = lines$(linenumber)
  GOSUB Separator
  Test = 0
  IF blk$ = FNLinePart$(11, 24, 1) AND part$(25) = symbol$(3) THEN
    in1$ = part$(0) + FNLinePart$(26, 39, 1) + part$(41)
    Test = 1
  END IF
  IF blk$ = FNLinePart$(26, 39, 1) AND part$(25) = symbol$(3) THEN
    in1$ = part$(0) + FNLinePart$(11, 24, 1) + part$(41)
    Test = 1
  END IF
  IF Test = 1 THEN
    CALL Newline(in1$, " RR", linenumber, blklin, 0)
  END IF
ELSE
  Test = 0
END IF
IF badbrack <> 0 OR Test = 0 THEN
  CALL ErrorMessage("Cannot perform Rule of Replacement.", 0)
END IF
GOSUB UpdateScreen
CALL Blankline(15, 16)
CALL Instructions(helpscreen)
CALL Functions(helpscreen, 0)
RETURN

$INCLUDE "LOGICIO.BAS"
REM *** Read in data for keys array used in program flow ***

Getkeys:
ERASE keys
a = 1
DO WHILE a <> 256
  READ a, b, c
  PRINT a
  keys(1, a) = b
  keys(0, a) = c
LOOP
FOR t = 1 TO 40
  READ a
  vector(t) = a
NEXT t
RETURN

DATA 13,0,-254
DATA 72,-1,0
DATA 80,1,0
DATA 75,0,-1
DATA 77,0,1
DATA 73,-10,0
DATA 81,10,0
DATA 71,0,-54
DATA 79,0,54
DATA 132,-100,0
DATA 118,100,0
DATA 119,-1000,0
DATA 117,1000,0
DATA 256,256,256

DATA 1,2,1,2,1,2,1,2,3,4,1,2,1,2,1,2,1,2,3,5,6,6,6,6,4,1,2,1,2,1,2
DATA 1,2,3,5,6,6,6,6,4

SUB Blankline (startline, endline)
LOCAL t
COLOR 7, 0
FOR t = startline TO endline
  LOCATE t, 1, 0
  PRINT STRING$(80, 32);
NEXT t
LOCATE startline, 1, 0
END SUB

SUB Centre (y, a$)
LOCAL x
x = INT((80 - LEN(a$)) / 2)
LOCATE y, x, 0
PRINT a$;
END SUB

DEF FNCheckRCP (Q)
SHARED prf(), rcp, firstlineofRCP(), rcpcount
LOCAL v, t
v = 0
IF rcp = 0 AND prf(Q, 2) > 0 THEN v = 1
IF rcp > 0 AND prf(Q, 2) > 0 THEN
  v = 1
  FOR t = 1 TO rcpcount
    IF firstlineofRCP(t) = prf(Q, 2) THEN v = 0
    IF firstlineofRCP(t) = Q THEN v = 0
    IF ABS(prf(Q, 2)) = 2 THEN v = 0
  NEXT t
END IF
FNCheckRCP = v
END DEF

SUB DefinitionError (Definition$)
SHARED in$, blk$
in$ = blk$
CALL ErrorMessage("Cannot perform Definition " + RIGHT$(Definition$, 1) + ".", 0)
END SUB

SUB DisplayPath (aa$)
CALL Blankline(15, 17)
PRINT "Current path: "; aa$
END SUB

SUB DrawBox (tcol, trow, wide, high, textcolor, backcolor, box$)
LOCAL side$, t
COLOR textcolor, backcolor
side$ = MID$(box$, 4, 1)
LOCATE trow, tcol, 0
PRINT MID$(box$, 2, 1); STRING$(wide - 2, LEFT$(box$, 1)); MID$(box$, 3, 1);
FOR t = trow + 1 TO trow + high - 2
  LOCATE t, tcol, 0
  PRINT side$; STRING$(wide - 2, 32); side$;
NEXT t
LOCATE trow + high - 1, tcol, 0
PRINT MID$(box$, 5, 1); STRING$(wide - 2, LEFT$(box$, 1)); MID$(box$, 6, 1);
END SUB

SUB ErrorMessage (a$, t)
SHARED helpscreen
CALL Blankline(15, 16)
REM BEEP
SELECT CASE t
CASE 0
  PRINT a$
CASE 1
  PRINT "Cannot find: "; a$
END SELECT
CALL Functions(1, 3)
CALL Getcharacter(POS(0), CSRLIN, 1)
CALL Blankline(15, 16)
CALL Functions(helpscreen, 0)
END SUB

SUB Functions (menu, funkeys)
SHARED co1, co2, last, symbol$()
COLOR co1, co2
LOCATE 23, 1, 0
SELECT CASE funkeys
CASE 0
  PRINT "[F1]   [F2]   [F3]   [F4]   [F5]    [F6]  [F7]  [F8]  [F9]  [F10]  [ESC]       "
CASE 1
  PRINT "End of truth table." + SPACE$(48) + "[ESC]       "
CASE 2
  PRINT "Use up and down arrow keys to select file.                        "
CASE 3
  PRINT SPACE$(66)
END SELECT
LOCATE 24, 1, 0
SELECT CASE menu
CASE 0
  PRINT "Def 1  Def 2  Def 3  Rule 1 Rule 2  DR 1  DR 2  Other Edit  File   Quit    ";
  PRINT USING "####"; last;
CASE 1
  PRINT "Press [ENTER] to continue.                                         Return      ";
CASE 2
  PRINT "Def 4  Rule 3 Values Table  Replace CPon  CPoff Axiom Edit  File   Return      ";
CASE 3
  PRINT "Block  Vroom  Search Delete Occamize Mem  Store Other Param File   Return      ";
CASE 4
  PRINT "Load   Save   New    Files  ChgDir  Erase Mkdir Other Edit  Print  Return      ";
CASE 5
  PRINT " " + symbol$(0) + SPACE$(6) + symbol$(1) + SPACE$(6) + symbol$(2) + SPACE$(6) + symbol$(3) + "      " + symbol$(6) + "       ë     á     å     ç     í     Return      ";
END SELECT
END SUB

SUB Getcharacter (oldx, oldy, cursor)
SHARED w$, fv, wv, b, a
LOCAL curcount
curcount = 0
SELECT CASE cursor
CASE 1
  LOCATE b, a, 1
  PRINT "";
CASE 2
  LOCATE oldy, oldx, 1
  PRINT "";
CASE 3
  curcount = 0
END SELECT
fv = 0
DO WHILE fv = 0
  w$ = INKEY$
  fv = LEN(w$)
  SELECT CASE cursor
  CASE 3
    curcount = curcount + 1
    IF curcount = 100 THEN LOCATE b, a, 1: PRINT "";
    IF curcount = 200 THEN LOCATE oldy, oldx, 1: PRINT "";
    IF curcount > 300 THEN curcount = 0
  END SELECT
LOOP
wv = ASC(RIGHT$(w$, 1))
END SUB

DEF FNGetInfo (b, x, y, max, min, default)
LOCAL a, a$
a = -99
DO UNTIL a >= min AND a <= max
  LOCATE y, x, 0
  CALL InputLine(b, 0, "")
  a = INT(VAL(in$))
  IF in$ = "" THEN
     a = default
  END IF
  IF max <= min OR wv = 27 THEN EXIT LOOP
LOOP
LOCATE y, x - 1, 0
PRINT a; SPACE$(b);
FNGetInfo = a
END DEF

SUB InputLine (fl, special, a$)
SHARED in$, wv, wl, fv, sy(), symbol$()
SELECT CASE special
CASE 0
  IF LEFT$(a$, 1) = SPACE$(1) THEN a$ = RIGHT$(a$, LEN(a$) - 1)
  in$ = ""
  wl = 0
  PRINT a$; STRING$(LEN(a$), 29);
  CALL Getcharacter(POS(0), CSRLIN, 2)
  IF wv = 13 THEN in$ = a$
CASE 1
  in$ = ""
  wv = 32
  wl = 0
  fv = 0
CASE 2
  in$ = a$
  wl = LEN(in$)
  PRINT in$;
CASE 3
  in$ = a$
  wl = LEN(in$)
  PRINT in$;
  wv = 32
  fv = 0
END SELECT
IF wv > 31 THEN
  PRINT STRING$(ABS(fl - wl), 254);
  PRINT STRING$(ABS(fl - wl), 29);
END IF
DO WHILE wv <> 27 AND wv <> 13
  IF fl = wl AND (wv <> 8 AND wv <> 13) THEN
REM    BEEP
    wv = 32
  END IF
  IF fv = 2 THEN wv = wv + 69
  SELECT CASE wv
  CASE 153
    wv = 27
    GOSUB Accept
  CASE 128
    wv = sy(0)
    GOSUB Accept
  CASE 129
    wv = sy(1)
    GOSUB Accept
  CASE 130
    wv = sy(2)
    GOSUB Accept
  CASE 131
    wv = sy(3)
    GOSUB Accept
  CASE 132
    wv = sy(6)
    GOSUB Accept
  CASE 133
    wv = 235
    GOSUB Accept
  CASE 134
    wv = 225
    GOSUB Accept
  CASE 135
    wv = 229
    GOSUB Accept
  CASE 136
    wv = 231
    GOSUB Accept
  CASE 137
    wv = 237
    GOSUB Accept
  CASE 8
    IF wl <> 0 THEN
      PRINT CHR$(29); CHR$(254); CHR$(29);
      in$ = LEFT$(in$, LEN(in$) - 1)
      wl = wl - 1
    END IF
    wv = 32
  CASE 33 TO 126
    GOSUB Accept
  END SELECT
  CALL Getcharacter(POS(0), CSRLIN, 2)
LOOP
IF wv = 27 THEN
  in$ = ""
  wl = 0
ELSEIF special <> 0 THEN
  PRINT STRING$(fl - wl, 32);
END IF
EXIT SUB
Accept:
PRINT CHR$(wv);
in$ = in$ + CHR$(wv)
wl = wl + 1
wv = 32
RETURN
END SUB

SUB Instructions (c)
SHARED symbol$()
LOCATE 18, 1, 0
COLOR 7, 0
SELECT CASE c
CASE 0
PRINT "Def 1: (P"; symbol$(0); "Q)"; symbol$(3); "("; symbol$(6); "P"; symbol$(1); "Q)     Def 2: (P"; symbol$(2); "Q)"; symbol$(3); symbol$(6); "("; symbol$(6); "P"; symbol$(1); symbol$(6); "Q)     Def 3: (P"; symbol$(3); "Q)";
PRINT  symbol$(3); "((P";symbol$(0); "Q)"; symbol$(2); "(Q"; symbol$(0); "P))  ";
PRINT SPACE$(80);
PRINT "Rule 1:   (P"; symbol$(0); "Q)        Rule 2:  Any WFF may be substituted for any variable    ";
PRINT "          (P)            DR 1:  Hypothetical Syllogism derived rule            ";
PRINT "therefore (Q)            DR 2:  Conjunction derived rule                       ";
CASE 2
PRINT "                          *** OTHER FUNCTIONS MENU ***                         ";
PRINT "Def 4:    (Ex)"; symbol$(3); symbol$(6); "(x)"; symbol$(6); "            Table:    Create truth table for current line ";
PRINT "Rule 3:   íx                    Replace:  Rule of replacement                  ";
PRINT "therefore (x)íx                 CPon/off: Open/close a conditional proof       ";
PRINT "Values:   Enter truth values    Axiom:    Add a new axiom to your system       ";
CASE 3
PRINT "                                *** EDIT MENU ***                              ";
PRINT "[F1]-[F5]  Move cursor to desired line before selecting function               ";
PRINT "Occamize:  Prune unnecessary lines       Mem:   Display available memory       ";
PRINT "Store:     Save new default parameters   Other: Switch to Other Functions Menu ";
PRINT "Param:     Change program parameters     Edit:  Switch to Edit Menu            ";
CASE 4
PRINT "                                *** FILE MENU ***                              ";
PRINT "Load:   Load a system from disk     Save:  Save system currently in memory     ";
PRINT "New:    Create a new system         Files: List files in current directory     ";
PRINT "ChgDir: Change current directory    Erase: Delete a file from the disk         ";
PRINT "Mkdir:  Create a new directory      Print: Output lines to printer or disk     ";
END SELECT
END SUB

DEF FNIsItaWFF (in$, u)
SHARED symbol$()
LOCAL t, v
v = 0
IF in$ = "" THEN
  v = -1
ELSE
  FOR t = 0 TO u
    v = v + INSTR(in$, symbol$(t))
  NEXT t
END IF
FNIsItaWFF = v
END DEF

DEF FNLinePart$ (aa, bb, cc)
SHARED part$()
LOCAL aa$, i
aa$ = ""
FOR i = aa TO bb STEP cc
  aa$ = aa$ + part$(i)
NEXT i
FNLinePart$ = aa$
END DEF

SUB Newline (in1$, in2$, in3, in4, ln)
SHARED lines$(), proof$(), in$
SHARED blklin, wv, action, rcpcount, axioms, numjumps, rcp, last, helpscreen
SHARED firstlineofRCP(), dr(), jumps(), prf()
STATIC l
LOCAL t, c
ON ERROR GOTO OutOfMemory
IF ln <> last + 1 THEN
  DO UNTIL (ln > axioms AND ln > in3 AND ln > in4 AND ln <= last + 1 AND ln > firstlineofRCP(rcpcount)) OR action = -1
    CALL Functions(1, 3)
    CALL Blankline(15, 16)
    PRINT "Create line ";
    CALL InputLine(3, 0, STR$(last + 1))
    ln = VAL(in$)
    IF wv = 27 THEN EXIT SUB
  LOOP
  FOR t = last + 1 TO (ln + 1) STEP -1
    FOR c = 0 TO 2
      IF prf(t - 1, c) >= ln THEN
	prf(t - 1, c) = prf(t - 1, c) + 1
      END IF
    NEXT c
    lines$(t) = lines$(t - 1)
    proof$(t) = proof$(t - 1)
    FOR c = 0 TO 2
      prf(t, c) = prf(t - 1, c)
    NEXT c
  NEXT t
  FOR c = 1 TO rcpcount
    IF firstlineofRCP(c) >= ln THEN
      firstlineofRCP(c) = firstlineofRCP(c) + 1
    END IF
  NEXT c
  FOR c = 0 TO 2
    IF dr(c) >= ln THEN
      dr(c) = dr(c) + 1
    END IF
  NEXT c
  IF blklin >= ln THEN
    blklin = blklin + 1
  END IF
END IF
l = LEN(in1$)
IF l < 255 AND FRE("S") > 1500 THEN
  last = last + 1
  lines$(ln) = in1$
  proof$(ln) = in2$
  prf(ln, 0) = in3
  prf(ln, 1) = in4
  prf(ln, 2) = rcp
  IF action = -1 THEN prf(ln, 2) = -1
  COLOR 7, 0
  LOCATE 24, 76, 0
  PRINT USING "####"; last;
  DELAY 1
  jumps(1) = ln
  numjumps = 1
ELSE
  IF FRE("S") <= 1500 THEN
    CALL ErrorMessage("Cannot add line to system.  Out of memory.", 0)
  ELSE
    CALL ErrorMessage("New line is too large.  Cannot create.", 0)
  END IF
END IF
ON ERROR GOTO 0
action = 0
CALL Functions(helpscreen, 0)
END SUB

DEF FNOtherLine$ (aa, bb, cc)
SHARED pt$()
LOCAL aa$
aa$ = ""
FOR i = aa TO bb STEP cc
  aa$ = aa$ + pt$(i)
NEXT i
FNOtherLine$ = aa$
END DEF

SUB PleaseWait
CALL Blankline(15, 16)
PRINT "Please wait..."
END SUB

SUB PrintSave (lin$, prnchoice)
SHARED sy(), symbol$()
lin$ = FNReplace$(lin$, sy(0), 62)
IF prnchoice = 1 THEN
  WRITE #1, lin$
ELSE
  PRINT #2, lin$
END IF
END SUB

DEF FNReplace$ (aa$, bb, cc)
LOCAL i
i = 1
DO WHILE i > 0
  i = INSTR(i, aa$, CHR$(bb))
  IF i > 0 THEN
    MID$(aa$, i, 1) = CHR$(cc)
    i = i + 1
  END IF
LOOP
FNReplace$ = aa$
END DEF

SUB Title (n$, r, c, l)
SHARED co1, co2
COLOR co1, co2
LOCATE r, c, 0
PRINT SPACE$(1) + n$ + SPACE$(1); STRING$(l - LEN(n$) - 5, 205)
END SUB

DEF FNWhichComponent (in$)
SHARED compc, comp$()
LOCAL t
t = 0
FOR t = 1 TO compc
  IF in$ = comp$(t) THEN
    FNWhichComponent = t
  END IF
NEXT t
END DEF


