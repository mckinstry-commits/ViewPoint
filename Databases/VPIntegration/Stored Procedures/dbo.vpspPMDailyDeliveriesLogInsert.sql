SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMDailyDeliveriesLogInsert]
/************************************************************
* CREATED:		6/13/06	CHS
* MODIFIED		6/6/07	chs
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* USAGE:
*   Inserts PM Daily Deliveries Log
*
* CALLED FROM:
*	ViewpointCS Portal  
*   
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @LogDate bDate,
      @DailyLog SMALLINT,
      @LogType TINYINT,
	--@Seq smallint,
      @Seq VARCHAR(3),
      @PRCo bCompany,
      @Crew VARCHAR(10),
      @VendorGroup bGroup,
      @FirmNumber bFirm,
      @ContactCode bEmployee,
      @Equipment bEquip,
      @Visitor VARCHAR(60),
      @Description VARCHAR(MAX),
      @ArriveTime SMALLDATETIME,
      @DepartTime SMALLDATETIME,
      @CatStatus CHAR(1),
      @Supervisor VARCHAR(30),
      @Foreman TINYINT,
      @Journeymen TINYINT,
      @Apprentices TINYINT,
      @PhaseGroup bGroup,
      @Phase bPhase,
      @PO VARCHAR(30),
      @Material VARCHAR(30),
      @Quantity INT,
      @Location VARCHAR(10),
      @Issue bIssue,
      @DelTicket VARCHAR(10),
      @CreatedChangedBy bVPUserName,
      @MatlGroup bGroup,
      @UM NVARCHAR(50),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @EMCo bCompany
    )
AS 
    SET NOCOUNT ON ;

/*
	LogType:
		0=Employee
		1=Crew
		2=Subcontractors
		3=Equpiment
		4=Activity
		5=Conversations
		6=Deliveries
		7=Accidents
		8=Visitors
*/

    SET @LogType = 6

    IF @Issue = -1 
        SET @Issue = NULL 
    IF @Quantity = -1 
        SET @Quantity = NULL
    IF @FirmNumber = -1 
        SET @FirmNumber = NULL
    IF @ContactCode = -1 
        SET @ContactCode = NULL

    SET @Seq = ( SELECT ISNULL(( MAX(Seq) + 1 ), 1)
                 FROM   PMDD
                 WHERE  ( PMCo = @PMCo )
                        AND ( Project = @Project )
                        AND ( LogDate = @LogDate )
                        AND ( LogType = @LogType )
               )

    INSERT  INTO PMDD
            ( PMCo,
              Project,
              LogDate,
              DailyLog,
              LogType,
              Seq,
              PRCo,
              Crew,
              VendorGroup,
              FirmNumber,
              ContactCode,
              Equipment,
              Visitor,
              Description,
              ArriveTime,
              DepartTime,
              CatStatus,
              Supervisor,
              Foreman,
              Journeymen,
              Apprentices,
              PhaseGroup,
              Phase,
              PO,
              Material,
              Quantity,
              Location,
              Issue,
              DelTicket,
              CreatedChangedBy,
              MatlGroup,
              UM,
              UniqueAttchID,
              EMCo
            )
    VALUES  ( @PMCo,
              @Project,
              @LogDate,
              @DailyLog,
              @LogType,
              @Seq,
              @PRCo,
              @Crew,
              @VendorGroup,
              @FirmNumber,
              @ContactCode,
              @Equipment,
              @Visitor,
              @Description,
              @ArriveTime,
              @DepartTime,
              @CatStatus,
              @Supervisor,
              @Foreman,
              @Journeymen,
              @Apprentices,
              @PhaseGroup,
              @Phase,
              @PO,
              @Material,
              @Quantity,
              @Location,
              @Issue,
              @DelTicket,
              @CreatedChangedBy,
              @MatlGroup,
              @UM,
              @UniqueAttchID,
              @EMCo
            ) ;

    DECLARE @KeyID INT
    SET @KeyID = SCOPE_IDENTITY()
    EXECUTE vpspPMDailyDeliveriesLogGet @PMCo, @Project, @DailyLog, @LogDate,
        @VendorGroup, @KeyID
GO
GRANT EXECUTE ON  [dbo].[vpspPMDailyDeliveriesLogInsert] TO [VCSPortal]
GO
