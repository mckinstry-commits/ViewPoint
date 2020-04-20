SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMDailyLogInsert]
/************************************************************
* CREATED:		2/15/06		CHS
* MODIFIED:		4/11/06		chs
* Modified:		6/5/07		chs
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 12/06/2011 TK-10599
*
* USAGE:
*   Inserts PM Daily Logs
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @LogDate bDate,
	--@DailyLog smallint,
      @DailyLog VARCHAR(10),
      @Description VARCHAR(255),
      @Weather VARCHAR(60),
      @Wind VARCHAR(30),
      @TempHigh SMALLINT,
      @TempLow SMALLINT,
      @EmployeeYN bYN,
      @CrewYN bYN,
      @SubcontractYN bYN,
      @EquipmentYN bYN,
      @ActivityYN bYN,
      @ConversationsYN bYN,
      @DeliveriesYN bYN,
      @AccidentsYN bYN,
      @VisitorsYN bYN,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    SET NOCOUNT ON ;
	
    DECLARE @rcode INT,
        @message VARCHAR(255)
    SELECT  @rcode = 0,
            @message = ''
	
    IF EXISTS ( SELECT  PMDL.DailyLog
                FROM    PMDL
                WHERE   PMDL.PMCo = @PMCo
                        AND PMDL.Project = @Project
                        AND PMDL.LogDate = @LogDate
                        AND PMDL.DailyLog = @DailyLog ) 
        BEGIN
            SELECT  @rcode = 1,
                    @message = 'Log ID has already been used. Please use another ID.'
            GOTO bspmessage
        END
		
			
    IF ( ISNULL(@DailyLog, '') = '' )
        OR @DailyLog = '+'
        OR @DailyLog = 'n'
        OR @DailyLog = 'N' 
        BEGIN
            SET @DailyLog = ( SELECT    ISNULL(( MAX(DailyLog) + 1 ), 1)
                              FROM      PMDL WITH ( NOLOCK )
                              WHERE     PMCo = @PMCo
                                        AND Project = @Project
                                        AND LogDate = @LogDate
                            ) 
        END			
			
    SET @EmployeeYN = 'Y'
    SET @CrewYN = 'Y'
    SET @SubcontractYN = 'Y'
    SET @EquipmentYN = 'Y'
    SET @ActivityYN = 'Y'
    SET @ConversationsYN = 'Y'
    SET @DeliveriesYN = 'Y'
    SET @AccidentsYN = 'Y'
    SET @VisitorsYN = 'Y'

    INSERT  INTO PMDL
            ( PMCo,
              Project,
              LogDate,
              DailyLog,
              Description,
              Weather,
              Wind,
              TempHigh,
              TempLow,
              EmployeeYN,
              CrewYN,
              SubcontractYN,
              EquipmentYN,
              ActivityYN,
              ConversationsYN,
              DeliveriesYN,
              AccidentsYN,
              VisitorsYN,
              Notes,
              UniqueAttchID
            )
    VALUES  ( @PMCo,
              @Project,
              @LogDate,
              @DailyLog,
              @Description,
              @Weather,
              @Wind,
              @TempHigh,
              @TempLow,
              @EmployeeYN,
              @CrewYN,
              @SubcontractYN,
              @EquipmentYN,
              @ActivityYN,
              @ConversationsYN,
              @DeliveriesYN,
              @AccidentsYN,
              @VisitorsYN,
              @Notes,
              @UniqueAttchID
            ) ;

    DECLARE @KeyID INT
    SET @KeyID = SCOPE_IDENTITY()
    EXECUTE vpspPMDailyLogGet @PMCo, @Project, @KeyID

	
    bspexit:
    RETURN @rcode

    bspmessage:
    RAISERROR(@message, 11, -1);
    RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vpspPMDailyLogInsert] TO [VCSPortal]
GO
