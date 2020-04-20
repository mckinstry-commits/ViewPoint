SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMDailyLogDrillDownUpdate]
/************************************************************
* CREATED:		6/12/06		CHS
* MODIFIED:		12/21/07	CHS
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* USAGE:
*   Updates PM Daily Log
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
	@Seq smallint,
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
	@EMCo bCompany,

	@Original_PMCo bCompany,
	@Original_Project bJob,
	@Original_LogDate bDate,
	@Original_DailyLog smallint,
	@Original_LogType tinyint,
	@Original_Seq smallint,
	@Original_PRCo bCompany,
	@Original_Crew varchar(10),
	@Original_VendorGroup bGroup,
	@Original_FirmNumber bFirm,
	@Original_ContactCode bEmployee,
	@Original_Equipment bEquip,
	@Original_Visitor varchar(60),
	@Original_Description VARCHAR(MAX),
	@Original_ArriveTime smalldatetime,
	@Original_DepartTime smalldatetime,
	@Original_CatStatus char(1),
	@Original_Supervisor varchar(30),
	@Original_Foreman tinyint,
	@Original_Journeymen tinyint,
	@Original_Apprentices tinyint,
	@Original_PhaseGroup bGroup,
	@Original_Phase bPhase,
	@Original_PO varchar(30),
	@Original_Material varchar(30),
	@Original_Quantity int,
	@Original_Location varchar(10),
	@Original_Issue bIssue,
	@Original_DelTicket varchar(10),
	@Original_CreatedChangedBy bVPUserName,
	@Original_MatlGroup bGroup,
	@Original_UM nvarchar(50),
	@Original_UniqueAttchID uniqueidentifier,
	@Original_EMCo bCompany,

	@EquipDescription varchar(60) = null

)
AS
	SET NOCOUNT ON;
	
	
if @PhaseGroup is null
	begin
		set @PhaseGroup = (select JCJP.PhaseGroup 
							from JCJP with (nolock) 
							where JCJP.JCCo = @PMCo AND JCJP.Job = @Project AND JCJP.Phase = @Phase)
	end
	
UPDATE PMDD
	set
		--PMCo = @PMCo,
		--Project = @Project,
		--LogDate = @LogDate,
		--DailyLog = @DailyLog,
		--LogType = @LogType,
		--Seq = @Seq,
		PRCo = @PRCo,
		Crew = @Crew,
		VendorGroup = @VendorGroup,
		FirmNumber = @FirmNumber,
		ContactCode = @ContactCode,
		Equipment = @Equipment,
		Visitor = @Visitor,
		Description = @Description,
		ArriveTime = @ArriveTime,
		DepartTime = @DepartTime,
		CatStatus = @CatStatus,
		Supervisor = @Supervisor,
		Foreman = @Foreman,
		Journeymen = @Journeymen,
		Apprentices = @Apprentices,
		PhaseGroup = @PhaseGroup,
		Phase = @Phase,
		PO = @PO,
		Material = @Material,
		Quantity = @Quantity,
		Location = @Location,
		Issue = @Issue,
		DelTicket = @DelTicket,
		CreatedChangedBy = @CreatedChangedBy,
		MatlGroup = @MatlGroup,
		UM = @UM,
		UniqueAttchID = @UniqueAttchID,
		EMCo = @EMCo

	WHERE
			(PMCo = @Original_PMCo)
		AND (Project = @Original_Project)
		AND (LogDate = @Original_LogDate)
		AND (DailyLog = @Original_DailyLog)
		AND (LogType = @Original_LogType)
		AND (Seq = @Original_Seq)

		AND (PRCo = @Original_PRCo OR @Original_PRCo IS NULL AND PRCo IS NULL)
		AND (Crew = @Original_Crew OR @Original_Crew IS NULL AND Crew IS NULL)
		AND (VendorGroup = @Original_VendorGroup OR @Original_VendorGroup IS NULL AND VendorGroup IS NULL)
		AND (FirmNumber = @Original_FirmNumber OR @Original_FirmNumber IS NULL AND FirmNumber IS NULL)
		AND (ContactCode = @Original_ContactCode OR @Original_ContactCode IS NULL AND ContactCode IS NULL)

		AND (Equipment = @Original_Equipment OR @Original_Equipment IS NULL AND Equipment IS NULL)
		AND (Visitor = @Original_Visitor OR @Original_Visitor IS NULL AND Visitor IS NULL)
		AND (ArriveTime = @Original_ArriveTime OR @Original_ArriveTime IS NULL AND ArriveTime IS NULL)
		AND (DepartTime = @Original_DepartTime OR @Original_DepartTime IS NULL AND DepartTime IS NULL)
		AND (CatStatus = @Original_CatStatus OR @Original_CatStatus IS NULL AND CatStatus IS NULL)

		AND (Supervisor = @Original_Supervisor OR @Original_Supervisor IS NULL AND Supervisor IS NULL)
		AND (Foreman = @Original_Foreman OR @Original_Foreman IS NULL AND Foreman IS NULL)
		AND (Journeymen = @Original_Journeymen OR @Original_Journeymen IS NULL AND Journeymen IS NULL)
		AND (Apprentices = @Original_Apprentices OR @Original_Apprentices IS NULL AND Apprentices IS NULL)
		AND (PhaseGroup = @Original_PhaseGroup OR @Original_PhaseGroup IS NULL AND PhaseGroup IS NULL)

		AND (Phase = @Original_Phase OR @Original_Phase IS NULL AND Phase IS NULL)
		AND (PO = @Original_PO OR @Original_PO IS NULL AND PO IS NULL)
		AND (Material = @Original_Material OR @Original_Material IS NULL AND Material IS NULL)
		AND (Quantity = @Original_Quantity OR @Original_Quantity IS NULL AND Quantity IS NULL)
		AND (Location = @Original_Location OR @Original_Location IS NULL AND Location IS NULL)

		AND (Issue = @Original_Issue OR @Original_Issue IS NULL AND Issue IS NULL)
		AND (DelTicket = @Original_DelTicket OR @Original_DelTicket IS NULL AND DelTicket IS NULL)
		AND (CreatedChangedBy = @Original_CreatedChangedBy OR @Original_CreatedChangedBy IS NULL AND CreatedChangedBy IS NULL)
		AND (MatlGroup = @Original_MatlGroup OR @Original_MatlGroup IS NULL AND MatlGroup IS NULL)
		AND (UM = @Original_UM OR @Original_UM IS NULL AND UM IS NULL)

		AND (EMCo = @Original_EMCo OR @Original_EMCo IS NULL AND EMCo IS NULL)





GO
GRANT EXECUTE ON  [dbo].[vpspPMDailyLogDrillDownUpdate] TO [VCSPortal]
GO
