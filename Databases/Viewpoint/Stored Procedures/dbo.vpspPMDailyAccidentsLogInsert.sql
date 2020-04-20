SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMDailyAccidentsLogInsert]
/************************************************************
* CREATED:		6/13/06	CHS
* MODIFIED		6/6/07	chs
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* USAGE:
*   Inserts PM Daily Accident Log
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@PMCo bCompany,
	@Project bJob,
	@LogDate bDate,
	@DailyLog smallint,
	@LogType tinyint,
	--@Seq smallint,
	@Seq varchar(3),
	@PRCo bCompany,
	@Crew varchar(10),
	@VendorGroup bGroup,
	@FirmNumber bFirm,
	@ContactCode bEmployee,
	@Equipment bEquip,
	@Visitor varchar(60),
	@Description VARCHAR(MAX),
	@ArriveTime smalldatetime,
	@DepartTime smalldatetime,
	@CatStatus char(1),
	@Supervisor varchar(30),
	@Foreman tinyint,
	@Journeymen tinyint,
	@Apprentices tinyint,
	@PhaseGroup bGroup,
	@Phase bPhase,
	@PO varchar(30),
	@Material varchar(30),
	@Quantity int,
	@Location varchar(10),
	@Issue bIssue,
	@DelTicket varchar(10),
	@CreatedChangedBy bVPUserName,
	@MatlGroup bGroup,
	@UM nvarchar(50),
	@UniqueAttchID uniqueidentifier,
	@EMCo bCompany
)
AS
	SET NOCOUNT ON;

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

set @LogType = 7

if @Issue = -1 set @Issue = null 
if @Quantity = -1 set @Quantity = null
if @FirmNumber = -1 set @FirmNumber = null
if @ContactCode = -1 set @ContactCode = null

set @Seq = (Select IsNull((Max(Seq)+1),1) FROM PMDD WHERE (PMCo = @PMCo) and (Project = @Project) and (LogDate = @LogDate) and (LogType = @LogType))

INSERT INTO 
	PMDD(PMCo, Project, LogDate, DailyLog, LogType, Seq, 
	PRCo, Crew, VendorGroup, FirmNumber, ContactCode, 
	Equipment, Visitor, Description, ArriveTime, DepartTime, 
	CatStatus, Supervisor, Foreman, Journeymen, Apprentices, 
	PhaseGroup, Phase, PO, Material, Quantity, Location, Issue, 
	DelTicket, CreatedChangedBy, MatlGroup, UM, UniqueAttchID, EMCo) 
	
VALUES (@PMCo, @Project, @LogDate, @DailyLog, @LogType, @Seq, 
	@PRCo, @Crew, @VendorGroup, @FirmNumber, @ContactCode, @Equipment, 
	@Visitor, @Description, @ArriveTime, @DepartTime, @CatStatus, 
	@Supervisor, @Foreman, @Journeymen, @Apprentices, @PhaseGroup, 
	@Phase, @PO, @Material, @Quantity, @Location, @Issue, @DelTicket, 
	@CreatedChangedBy, @MatlGroup, @UM, @UniqueAttchID, @EMCo);

DECLARE @KeyID int
SET @KeyID = SCOPE_IDENTITY()
execute vpspPMDailyAccidentsLogGet @PMCo, @Project, @DailyLog, @LogDate, @VendorGroup, @KeyID
GO
GRANT EXECUTE ON  [dbo].[vpspPMDailyAccidentsLogInsert] TO [VCSPortal]
GO
