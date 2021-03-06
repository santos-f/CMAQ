      MODULE TIME_STEP

C*************************************************************************
C
C  FUNCTION:  To define a time class
C             
C  PRECONDITIONS: None
C 
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Prototype created by Jerry Gipson, July, 1999
C                   
C*************************************************************************

      INTEGER :: NFLSTEPS

      INTEGER , ALLOCATABLE  :: STEP_DATE( : )
      INTEGER , ALLOCATABLE  :: STEP_TIME( : )
      INTEGER , ALLOCATABLE  :: STEP_FILE( : )


      CONTAINS

         SUBROUTINE GET_TSTEPS
C*************************************************************************
C
C  FUNCTION: Set-up time step sequence for reading files and writing
C            output records
C             
C  PRECONDITIONS: None
C 
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Prototype created by Jerry Gipson, July, 1999
C                   
C*************************************************************************
         USE M3UTILIO
         USE ENV_VARS
         USE M3FILES

         IMPLICIT NONE     

C..ARGUMENTS: None

C..PARAMETERS: None

C..SAVED LOCAL VARIABLES: None

C..SCRATCH LOCAL VARIABLES:
         CHARACTER*80  MSG         ! Log message
         CHARACTER*16  PNAME       ! Program Name

         INTEGER D0, D1            ! Differences betwwen two times, seconds
         INTEGER INDX              ! Array location to insert new index
         INTEGER MXSTEPS           ! max possible no. of time steps
         INTEGER N, NFL, NS, N2    ! Loop indices
         INTEGER JDATE             ! Current date
         INTEGER JTIME             ! Current time

   
C**********************************************************************
         DATA PNAME / 'GET_TSTEPS' /

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Get the maximum number of time steps
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
         MXSTEPS = 0
         DO N = 1, N_M3FILES

            IF( .NOT. DESC3( M3_FLNAME( N ) ) ) THEN
               CALL M3EXIT( PNAME, 0, 0, 'Could not get ' //
     &                      M3_FLNAME( N ) // ' file description',
     &                      XSTAT1 )
            ENDIF

            MXSTEPS = MXSTEPS + MXREC3D
         ENDDO

         ALLOCATE( STEP_DATE( MXSTEPS ), STEP_TIME( MXSTEPS ), 
     &             STEP_FILE( MXSTEPS ) )


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Load all steps from first file
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
         IF( .NOT. DESC3( M3_FLNAME( 1 ) ) ) THEN
            CALL M3EXIT( PNAME, 0, 0, 'Could not get ' // 
     &                   M3_FLNAME( 1 ) // ' file description',
     &                   XSTAT1 )
         ENDIF

         JDATE = SDATE3D
         JTIME = STIME3D

         NFLSTEPS = MXREC3D

         DO NS = 1, NFLSTEPS
            STEP_DATE( NS ) = JDATE
            STEP_TIME( NS ) = JTIME
            STEP_FILE( NS ) = 1
            CALL NEXTIME( JDATE, JTIME, TSTEP3D )
         ENDDO

         IF( N_M3FILES .EQ. 1 ) RETURN
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Insert non-duplicative time steps from remaining files in the array
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
         MSG = 'Multiple CTM Concentration files being used' 
         CALL M3MESG( MSG )
         MSG = 'Duplicate time steps will be eliminated' 
         CALL M3MESG( MSG )

         DO NFL = 2, N_M3FILES

            IF ( .NOT. DESC3( M3_FLNAME( NFL ) ) ) THEN
               CALL M3EXIT( PNAME, 0, 0,
     &                     'Could not get ' // M3_FLNAME( NFL ) //
     &                     ' file description', XSTAT1 )
            ENDIF

            JDATE = SDATE3D
            JTIME = STIME3D

            DO NS = 1, MXREC3D

               DO N = 1, NFLSTEPS

                  INDX = 0
                  D1 = SECSDIFF( STEP_DATE( N ), STEP_TIME( N ),
     &                           JDATE, JTIME )

                  IF( N .EQ. 1 .AND. D1 .LT. 0 ) THEN
                     INDX = 1
                  ELSEIF( N .EQ. NFLSTEPS .AND. D1 .GT. 0 ) THEN
                     INDX = NFLSTEPS + 1
                  ELSEIF( N .GT. 1 ) THEN
                     D0 = SECSDIFF( STEP_DATE( N - 1 ), STEP_TIME( N - 1 ),
     &                              JDATE, JTIME )
                     IF( D0 .GT. 0 .AND. D1 .LT. 0 ) INDX = N
                  ENDIF
          
                  IF( INDX .GT. 0 ) THEN
                     DO N2 = NFLSTEPS, INDX, -1
                        STEP_DATE( N2 + 1 ) =  STEP_DATE( N2 )
                        STEP_TIME( N2 + 1 ) =  STEP_TIME( N2 )
                     ENDDO
                  
                     STEP_DATE( INDX ) = JDATE
                     STEP_TIME( INDX ) = JTIME
                     STEP_FILE( INDX ) = NFL
                     NFLSTEPS = NFLSTEPS + 1
                  ENDIF

               ENDDO

               IF( INDX .EQ. 0 ) WRITE( LOGUNIT, 93000) JDATE, JTIME,
     &                                  M3_FLNAME( NFL )
               CALL NEXTIME( JDATE, JTIME, TSTEP3D )

            ENDDO

         ENDDO

         RETURN


93000    FORMAT( 10X, 'Duplicate time step ignored: ', I7, 1X, I6, 1X, A )

         END SUBROUTINE GET_TSTEPS

      END MODULE TIME_STEP








