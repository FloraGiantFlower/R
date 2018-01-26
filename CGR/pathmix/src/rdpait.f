      SUBROUTINE RDPAIT(NALL,PAR,XINIT,XALL,ITP,
     +   LFNJOB,LFNTER,H,TOL,TRUPB,INLC,IVAR,IVERB,ISTAT)
C
C READS PA() AND IT() CARDS FROM JOBFILE, SPECIFYING STARTING
C VALUES, ITERATED, AND EQUAL PARAMETERS.
C
C SAMPLE CC, PA AND IT CARDS:
C     CC CARDS MAY BE INCLUDED AS COMMENTS
C     PA ( H=.3, Z=2, C=.5, FF=.5 )
C     IT ( H, C, Y, FF=FM )
C
C "IT (ALL)" MAY BE VALID IN CERTAIN APPLICATIONS
C
C OUTPUT: INITIAL VALUES OF XALL() AND ITP(); AS WELL AS
C         H, TRUPB, TOL, AND INLC (FOR ALMINI)
C
C STATUS FLAG ISTAT IS SET AS FOLLOWS:  0=OK, -1=EOF, +1=IT(,ALL,)
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)

      CHARACTER   PAR(*)*(*)
      DIMENSION   XINIT(NALL),XALL(NALL),ITP(NALL)
      CHARACTER   CARD*80

C READ FIRST CARD

      CALL GETREC( LFNJOB,LFNTER, .TRUE., CARD,ICOL,NCHARS,ISTAT)

C CHECK FOR END OF JOB FILE

      IF ( ISTAT .NE. 0 ) GO TO 910

C SKIP FORWARD PAST "CC" CARDS (IF ANY)

100   IF ( CARD(ICOL:ICOL+1 ) .EQ. 'CC ') THEN
         CALL GETREC( LFNJOB,LFNTER, .FALSE., CARD,ICOL,NCHARS,ISTAT)
         IF ( ISTAT .NE. 0 ) GO TO 830
         GO TO 100
      END IF

C HANDLE "PA" CARD

      IF ( CARD(ICOL:ICOL+1 ) .EQ. 'PA') THEN
         CALL PACARD( CARD,ICOL,NCHARS,
     +      NALL,PAR,XINIT,XALL, LFNJOB,LFNTER, ISTAT)
         IF ( ISTAT .NE. 0 ) GO TO 200

         CALL GETREC( LFNJOB,LFNTER, .FALSE., CARD,ICOL,NCHARS,ISTAT)
         IF ( ISTAT .NE. 0 ) GO TO 830

C        SKIP FORWARD PAST "CC" CARDS (IF ANY)

110      IF ( CARD(ICOL:ICOL+1 ) .EQ. 'CC ') THEN
            CALL GETREC( LFNJOB,LFNTER, .FALSE., CARD,ICOL,NCHARS,ISTAT)
            IF ( ISTAT .NE. 0 ) GO TO 830
            GO TO 110
         END IF

      END IF

      IF ( CARD(ICOL:ICOL+1 ) .EQ. 'PA') THEN
         WRITE (LFNTER,*) 'MULTIPLE "PA" CARDS BEFORE "IT" CARD'
         GO TO 810
      END IF

C HANDLE "IT" CARD

      IF ( CARD(ICOL:ICOL+1 ) .NE. 'IT ') THEN
         WRITE (LFNTER,*) 'EXPECTED "CC" "PA" OR "IT"'
         GO TO 810
      END IF

      CALL ITCARD( CARD,ICOL,NCHARS, NALL,PAR,XALL,ITP,
     +   LFNJOB,LFNTER, H,TOL,TRUPB,INLC,IVAR,IVERB, ISTAT)

C DECIDE WHAT TO DO BASED ON THE THE STATUS CODE RETURNED

200   IF ( ISTAT .EQ. 0 ) GO TO 900
      IF ( ISTAT .EQ. 1 ) GO TO 901
      IF ( ISTAT .EQ. -1 ) GO TO 810
      IF ( ISTAT .EQ. -2 ) GO TO 820
      IF ( ISTAT .EQ. -3 ) GO TO 830

      WRITE (LFNTER,*) 'UNKNOWN STATUS CODE=', ISTAT
      call intpr('INTERNAL ERROR IN RDPAIT',-1,0,0)
      STOP

C ERROR HANDLER

C     SYNTAX ERROR

810   CALL ERRLOC(LFNTER,CARD,ICOL)
      WRITE (LFNTER,*) 'ERROR: SYNTAX ERROR IN CARD'
      call intpr('ERROR IN JOB FILE',-1,0,0)
      STOP

C     INVALID PARAMETER NAME

820   CALL ERRLOC(LFNTER,CARD,ICOL)
      WRITE (LFNTER,*) 'ERROR: ILLEGAL PARAMETER NAME'
      call intpr('ERROR IN JOB FILE',-1,0,0)
      STOP

C     PREMATURE EOF

830   WRITE (LFNTER,*) 'ERROR: PREMATURE EOF IN JOB FILE'
      call intpr('ERROR IN JOB FILE',-1,0,0)
      STOP

C SUCCESSFUL RETURN

900   ISTAT = 0
      RETURN

C     SUCCESSFUL; IT CARD INCLUDED THE KEYWORD "ALL"
901   ISTAT = 1
      RETURN

C     END OF JOB FILE
910   ISTAT = -1
      RETURN
      END

      SUBROUTINE PACARD( CARD,ICOL,NCHARS,
     +   NALL,PAR,XINIT,XALL, LFNJOB,LFNTER, ISTAT)
C
C READ A "PA" CARD FROM THE JOBFILE, WHICH SPECIFIES STARTING VALUES OF
C ESTIMATED PARAMETERS, AND FIXED VALUES OF NON-ESTIMATED PARAMETERS
C
C STATUS FLAG ISTAT IS SET AS FOLLOWS:  0=OK, OTHER=ERROR (SEE BELOW)
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)

      CHARACTER   CARD*(*)
      CHARACTER   PAR(*)*(*)
      DIMENSION   XINIT(NALL), XALL(NALL)

C RESET XALL TO DEFAULT VALUES

      DO 10 I=1,NALL
         XALL(I) = XINIT(I)
10    CONTINUE

C ADVANCE PAST "PA" TO LEADING "("

      ICOL = NSPACE(CARD,ICOL+2,ISTAT)
      IF ( ISTAT .NE. 0 .OR.
     +     CARD(ICOL:ICOL) .NE. '(' ) THEN
         WRITE (LFNTER,*) '"(" EXPECTED AFTER "PA"'
         GO TO 810
      END IF

C CHECK FOR A NULL LIST

      ICOL = NSPACE(CARD,ICOL+1,ISTAT)
      IF ( ISTAT .NE. 0 ) GO TO 200

      IF ( CARD(ICOL:ICOL) .EQ. ')' ) GO TO 700

C STEP THROUGH CARD PARSING OUT PARAMETER NAMES

100   CONTINUE

C     CHECK FOR A VALID LIST ELEMENT

         INDEX = MATCHP(CARD,ICOL,NALL,PAR)
         IF ( INDEX .LE. 0 ) GO TO 820

C     ADVANCE PAST THE EQUAL SIGN

         ICOL = NSPACE(CARD,ICOL,ISTAT)
         IF ( ISTAT .NE. 0 .OR.
     +        CARD(ICOL:ICOL) .NE. '=' ) THEN
            WRITE (LFNTER,*) '"=" EXPECTED AFTER PARAMETER NAME'
            GO TO 810
         END IF

C     READ THE NUMERIC VALUE INTO XALL

         ICOL = ICOL + 1
         XALL(INDEX) = XNO(CARD,ICOL,ISTAT)
         IF ( ISTAT .NE. 0 ) THEN
            WRITE (LFNTER,*) 'NUMERIC VALUE EXPECTED AFTER "="'
            GO TO 810
         END IF

C     ADVANCE TO THE NEXT DELIMITER

         ICOL = NSPACE(CARD,ICOL,ISTAT)
         IF ( ISTAT .NE. 0 .OR.
     +        ( CARD(ICOL:ICOL) .NE. ')' .AND.
     +          CARD(ICOL:ICOL) .NE. ',' ) ) THEN
            WRITE (LFNTER,*) '")" OR "," EXPECTED'
            GO TO 810
         END IF

C     SEE IF WE ARE DONE

         IF ( CARD(ICOL:ICOL) .EQ. ')' ) GO TO 700

C     IF WE HAVE REACHED THE END OF THE LINE WITHOUT FINDING THE
C     CLOSING ")", READ ANOTHER LINE FROM THE JOB FILE

200      IF ( ICOL .GE. NCHARS ) THEN

            CALL GETREC( LFNJOB,LFNTER, .FALSE., CARD,ICOL,NCHARS,ISTAT)
            IF ( ISTAT .NE. 0 ) THEN
               WRITE (LFNTER,*) 'CLOSING ")" NOT FOUND BEFORE EOF'
               GO TO 830
            END IF

C     ADVANCE TO NEXT ENTRY

         ELSE
            ICOL = NSPACE(CARD,ICOL+1,ISTAT)
            IF ( ISTAT .NE. 0 ) THEN
               WRITE (LFNTER,*) 'PARAMETER NAME EXPECTED AFTER ","'
               GO TO 810
            END IF
         END IF

      GO TO 100

C END OF "PA" CARD

700   CONTINUE

      IF ( ICOL .LT. NCHARS ) THEN
         WRITE (LFNTER,*)
     +      'TEXT AFTER ")" IGNORED: "', CARD(ICOL+1:NCHARS), '"'
      END IF
      RETURN

C ERROR HANDLER

C     SYNTAX ERROR
810   ISTAT = -1
      RETURN

C     INVALID PARAMETER NAME
820   ISTAT = -2
      RETURN

C     PREMATURE EOF
830   ISTAT = -3
      RETURN
      END

      SUBROUTINE ITCARD( CARD,ICOL,NCHARS, NALL,PAR,XALL,ITP,
     +   LFNJOB,LFNTER, H,TOL,TRUPB,INLC,IVAR,IVERB, ISTAT)
C
C READ AN "IT" CARD FROM THE JOBFILE, WHICH IDENTIFIES THE PARAMETERS
C TO BE ESTIMATED
C
C STATUS FLAG ISTAT IS SET AS FOLLOWS:  0,1=OK, OTHER=ERROR (SEE BELOW)
C ISTAT=1 INDICATES THAT PARAMER "ALL" IS AMONG THE ITERATED PARAMETERS
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)

      CHARACTER   CARD*(*)
      CHARACTER   PAR(*)*(*)
      DIMENSION   XALL(NALL), ITP(NALL)
      LOGICAL     ALLFLG
      data iequal /0/
C INITIALIZE

      ALLFLG = .FALSE.

C ADVANCE PAST "IT" TO LEADING "("

      ICOL = NSPACE(CARD,ICOL+2,ISTAT)
      IF ( ISTAT .NE. 0 .OR.
     +     CARD(ICOL:ICOL) .NE. '(' ) THEN
         WRITE (LFNTER,*) '"(" EXPECTED AFTER "IT"'
         GO TO 810
      END IF

C CHECK FOR A NULL LIST

      ICOL = NSPACE(CARD,ICOL+1,ISTAT)
      IF ( ISTAT .NE. 0 ) GO TO 200

      IF ( CARD(ICOL:ICOL) .EQ. ')' ) GO TO 700

C INITIALIZE FLAG FOR PARAMETERS SET EQUAL TO ONE ANOTHER

      IEQUAL = 0

C STEP THROUGH CARD PARSING OUT PARAMETER NAMES

100   CONTINUE

C     CHECK FOR A VALID LIST ELEMENT

         INDEX = MATCHP(CARD,ICOL,NALL,PAR)
         IF ( INDEX .LT. 0 ) GO TO 820

C     MATCHES - DEFINE AS ITERATED OR EQUAL DEPENDING ON FLAG IEQUAL

         IF ( INDEX .EQ. 0 ) THEN
C           PARAMETER NAME "ALL"
            IF ( IEQUAL .NE. 0 ) THEN
               WRITE (LFNTER,*) 'PARAMETER "ALL" CANNOT BE EQUATED'
               GO TO 810
            END IF
            ALLFLG = .TRUE.

         ELSE IF ( IEQUAL .EQ. 0 ) THEN
C           SET ITP TO ITERATE
            ITP(INDEX) = 1

         ELSE
C           EQUATE TWO (OR MORE) PARAMETERS
            ITP(INDEX) = -IEQUAL
            XALL(INDEX) = XALL(IEQUAL)
         END IF

C     ADVANCE TO THE NEXT DELIMITER

         ICOL = NSPACE(CARD,ICOL,ISTAT)
         IF ( ISTAT .NE. 0 .OR.
     +        ( CARD(ICOL:ICOL) .NE. ')' .AND.
     +          CARD(ICOL:ICOL) .NE. ',' .AND.
     +          CARD(ICOL:ICOL) .NE. '=' ) ) THEN
            WRITE (LFNTER,*) '")" "," OR "=" EXPECTED'
            GO TO 810
         END IF

C     SEE IF WE ARE DONE

         IF ( CARD(ICOL:ICOL) .EQ. ')' ) GO TO 700

C     HANDLE SPECIFICATION OF EQUAL PARAMETERS

         IF ( CARD(ICOL:ICOL) .EQ. ',') THEN
C           CLEAR EQUAL PARAMETERS FLAG IF NOT "="
            IEQUAL = 0
         END IF

         IF ( CARD(ICOL:ICOL) .EQ. '=' ) THEN
            IF ( INDEX .LE. 0 ) THEN
               WRITE (LFNTER,*) 'PARAMETER "ALL" CANNOT BE EQUATED'
               GO TO 810
            END IF
            IF ( IEQUAL .EQ. 0 ) IEQUAL = INDEX
         END IF

C     IF WE HAVE REACHED THE END OF THE LINE WITHOUT FINDING THE
C     CLOSING ")", READ ANOTHER LINE FROM THE JOB FILE

200      IF ( ICOL .GE. NCHARS ) THEN

            CALL GETREC( LFNJOB,LFNTER, .FALSE., CARD,ICOL,NCHARS,ISTAT)
            IF ( ISTAT .NE. 0 ) THEN
               WRITE (LFNTER,*) 'CLOSING ")" NOT FOUND BEFORE EOF'
               GO TO 830
            END IF

C     ADVANCE TO NEXT ENTRY

         ELSE
            ICOL = NSPACE(CARD,ICOL+1,ISTAT)
            IF ( ISTAT .NE. 0 ) THEN
               WRITE (LFNTER,*) 'PARAMETER NAME EXPECTED AFTER ","'
               GO TO 810
            END IF
         END IF

      GO TO 100

C READ SECOND SET OF (...) FOR H,TOL,INLC ETC. SPECIFICATIONS

700   CONTINUE

      CALL IT2CRD( CARD,ICOL,NCHARS,
     +   LFNTER,H,TRUPB,TOL,INLC,IVAR,IVERB, ISTAT )
      IF ( ISTAT .NE. 0 ) RETURN

C END OF "IT" CARD

      IF ( ICOL .LT. NCHARS ) THEN
         WRITE (LFNTER,*)
     +      'TEXT AFTER ")" IGNORED: "', CARD(ICOL+1:NCHARS), '"'
      END IF

      ISTAT = 0
      IF (ALLFLG) ISTAT = 1
      RETURN

C ERROR HANDLER

C     SYNTAX ERROR
810   ISTAT = -1
      RETURN

C     INVALID PARAMETER NAME
820   ISTAT = -2
      RETURN

C     PREMATURE EOF
830   ISTAT = -3
      RETURN
      END

      SUBROUTINE IT2CRD( CARD,ICOL,NCHARS,
     +   LFNTER,H,TRUPB,TOL,INLC,IVAR,IVERB, ISTAT)
C
C READS THE SECOND SET OF SPECIFICATIONS FROM AN "IT" CARD, WHICH
C OVERRIDE THE DEFAULT VALUES FOR "H" "TOL" AND "INLC" (FOR ALMINI).
C (FOR DESCRIPTIONS OF THESE VARIABLES, SEE ALMINI DOCUMENTATION)
C
C ARGUMENTS:
C     CARD   -- "IT" CARD (CHARACTER VARIABLE)
C     ICOL   -- COLUMN TO BEGIN PROCESSING
C     NCHARS -- LENGTH OF CARD (TO LAST NON-BLANK)
C     LFNTER -- LOGICAL UNIT TO PRINT ERROR MESSAGES
C     H      -- NEW DIFFERENTIATION INTERVAL, IF SPECIFIED
C     TRUPB  -- NEW TRUNCATION UPPER BOUND, IF H SPECIFIED
C     TOL    -- NEW TOLERANCE, IF SPECIFIED
C     INLC   -- NEW NON-LINEAR CONSTRAINT MODE, IF SPECIFIED
C
C STATUS FLAG ISTAT IS SET AS FOLLOWS:  0=OK, OTHER=ERROR (SEE BELOW)
C
C SAMPLE CARD:
C     IT (...ITERATED PARAMETERS...) (H=.0001, TOL=.01, INLC=1, IVAR=1)
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      CHARACTER   CARD*(*)

C ADVANCE TO LEADING "("

      ICOL = NSPACE(CARD,ICOL+1,ISTAT)
      IF ( ISTAT .NE. 0 ) GO TO 900

      IF ( CARD(ICOL:ICOL) .NE. '(' ) THEN
         WRITE (LFNTER,*) 'OPTION LIST MUST BEGIN WITH "("'
         GO TO 810
      END IF

C STEP THROUGH OPTION SPECIFICATIONS

100   CONTINUE

C     ADVANCE TO NEXT ENTRY

         ICOL = NSPACE(CARD,ICOL+1,ISTAT)
         IF ( ISTAT .NE. 0 ) THEN
            WRITE (LFNTER,*) 'OPTION NAME EXPECTED'
            GO TO 810
         END IF

C     CHECK FOR A VALID OPTION NAME

         L = 0
         IF      ( CARD(ICOL:ICOL)   .EQ. 'H' ) THEN
            L = 1
            ICOL = ICOL + 1
         ELSE IF ( CARD(ICOL:ICOL+2) .EQ. 'TOL' ) THEN
            L = 2
            ICOL = ICOL + 3
         ELSE IF ( CARD(ICOL:ICOL+3) .EQ. 'INLC' ) THEN
            L = 3
            ICOL = ICOL + 4
         ELSE IF ( CARD(ICOL:ICOL+3) .EQ. 'IVAR' ) THEN
            L = 4
            ICOL = ICOL + 4
         ELSE IF ( CARD(ICOL:ICOL+4) .EQ. 'IVERB' ) THEN
            L = 5
            ICOL = ICOL + 5
         ELSE
            WRITE (LFNTER,*) 'INVALID OPTION NAME'
            WRITE (LFNTER,*)
            WRITE (LFNTER,*) 'OPTION        CONTROLS'
            WRITE (LFNTER,*) '------        --------'
            WRITE (LFNTER,*) ' H       DIFFERENTIATION INTERVAL'
            WRITE (LFNTER,*) ' TOL     TOLERANCE ON PTG'
            WRITE (LFNTER,*) ' INLC    NON-LINEAR CONSTRAINTS'
            WRITE (LFNTER,*) ' IVAR    COVARIANCES AND STANDARD ERRORS'
            WRITE (LFNTER,*) ' IVERB   VERBOSITY OF PROLIX'
            GO TO 810
         END IF

C     ADVANCE PAST THE EQUAL SIGN

         ICOL = NSPACE(CARD,ICOL,ISTAT)
         IF ( ISTAT .NE. 0 .OR.
     +        CARD(ICOL:ICOL) .NE. '=' ) THEN
            WRITE (LFNTER,*) '"=" EXPECTED AFTER OPTION NAME'
            GO TO 810
         END IF

C     READ THE NUMERIC VALUE INTO X

         ICOL = ICOL + 1
         X = XNO(CARD,ICOL,ISTAT)
         IF ( ISTAT .NE. 0 ) THEN
            WRITE (LFNTER,*) 'NUMERIC VALUE EXPECTED AFTER "="'
            GO TO 810
         END IF

C     SET THE APPROPRATE OPTION

         IF      ( L .EQ. 1 ) THEN
            H = X
            TRUPB = MAX( .1D0, SQRT(H) )
         ELSE IF ( L .EQ. 2 ) THEN
            TOL = X
         ELSE IF ( L .EQ. 3 ) THEN
            INLC = X
         ELSE IF ( L .EQ. 4 ) THEN
            IVAR = X
         ELSE IF ( L .EQ. 5 ) THEN
            IVERB = X
         END IF

C     ADVANCE TO THE NEXT DELIMITER

         ICOL = NSPACE(CARD,ICOL,ISTAT)
         IF ( ISTAT .NE. 0 .OR.
     +        ( CARD(ICOL:ICOL) .NE. ')' .AND.
     +          CARD(ICOL:ICOL) .NE. ',' ) ) THEN
            WRITE (LFNTER,*) '")" OR "," EXPECTED'
            GO TO 810
         END IF

C     SEE IF WE ARE DONE

         IF ( CARD(ICOL:ICOL) .EQ. ')' ) GO TO 900

      GO TO 100

C ERROR HANDLER

C     SYNTAX ERROR
810   ISTAT = -1
      RETURN

C SUCCESSFUL COMPLETION

900   ISTAT = 0
      RETURN
      END

      FUNCTION MATCHP(CARD,ICOL,NPAR,PAR)
C
C DETERMINES WHETHER THE INPUT STRING 'CARD' CONTAINS A VALID
C PARAMETER NAME BEGINNING AT 'ICOL'
C
C FUNCTION VALUE RETURNED IS:
C     .GT. 0  --  AN INDEX INTO PAR() CONTAINING THE PARAMETER NAME
C     .EQ. 0  --  THE KEYWORD "ALL" WAS FOUND
C     .LT. 0  --  UNRECOGNIZED
C
C ICOL IS INCREMENTED TO THE NEXT COLUMN FOLLOWING A VALID SUBSTRING
C
      CHARACTER   PAR(*)*(*), CARD*(*)
      CHARACTER   C*1

      NCHARS = LEN(CARD)
      IF ( ICOL .GT. NCHARS ) GO TO 800

C READ TEXT UP TO THE NEXT DELIMITER

      JCOL = ICOL
      I2 = 0

100   CONTINUE
         C = CARD(JCOL:JCOL)
         IF ( C.LT.'0' .OR. (C.GT.'9' .AND. C.LT.'A') ) GO TO 110
         I2 = JCOL
         IF ( JCOL .GE. NCHARS ) GO TO 800
         JCOL = JCOL + 1
      GO TO 100

110   IF ( I2 .LT. ICOL ) GO TO 800

C COMPARE IT WITH THE LIST OF PARAMETERS

      IF ( ISTRC(CARD(ICOL:I2),'ALL') .EQ. 0 ) THEN
         INDEX = 0
         GO TO 900
      END IF

      DO 200 INDEX=1,NPAR
         IF ( ISTRC(CARD(ICOL:I2),PAR(INDEX)) .EQ. 0 ) GO TO 900
200   CONTINUE
      GO TO 800

C UNRECOGNIZED NAME

800   MATCHP = -1
      GO TO 999

C SUCCESSFUL MATCH

900   MATCHP = INDEX
      ICOL = JCOL

999   RETURN
      END

      SUBROUTINE GETREC( LFNJOB,LFNTER, HEADER, CARD,ICOL,NCHARS,ISTAT)
C
C SUBROUTINE TO READ A RECORD FROM THE JOB FILE
C
C INPUT:
C     LFNJOB -- LOGICAL UNIT FOR INPUT JOB FILE
C     LFNTER -- LOGICAL UNIT FOR TERSE OUTPUT FILE
C     HEADER -- WHETHER OR NOT TO WRITE HEADER TO TERSE FILE
C
C OUTPUT:
C     CARD   -- RECORD FROM JOB FILE
C     ICOL   -- FIRST NON-BLANK IN CARD
C     NCHARS -- NUMBER OF CHARACTERS IN CARD
C     ISTAT  -- NON-ZERO IF END OF FILE
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      CHARACTER CARD*(*)
      LOGICAL  HEADER

C INITIALIZE

      ICOL = 1
      NCHARS = 0

C READ RECORD, CHECKING FOR PHYSICAL END OF FILE

100   READ (LFNJOB,'(A)',IOSTAT=ISTAT,END=101) CARD
101   IF ( ISTAT .NE. 0 ) THEN
         ISTAT = -1
         RETURN
      END IF

C SKIP PAST LEADING SPACES TO FIRST NON-BLANK CHARACTER

      ICOL = NSPACE(CARD,1,ISTAT)

C IF LINE IS EMPTY, IGNORE IT AND GET ANOTHER

      IF ( ISTAT .NE. 0 ) THEN
C        ECHO BLANK LINE UNLESS IT IMMEDIATELY FOLLOWS HEADER
         IF ( .NOT. HEADER ) WRITE (LFNTER,*)
         GO TO 100
      END IF

C REMOVE TRAILING SPACES

      NCHARS = LENSTR( CARD )

C CHECK FOR LOGICAL END OF SUB-FILE

      IF ( CARD(ICOL:NCHARS) .EQ. '<EOF>' ) THEN
         ISTAT = 1
         RETURN
      END IF

C WRITE PAGE HEADING IF INDICATED

      IF ( HEADER ) CALL EJECT(LFNTER)

C ECHO CARD TO TERSE OUTPUT FILE

      WRITE (LFNTER,*) CARD(1:NCHARS)

C SUCCESSFUL RETURN

      ISTAT = 0
      END
