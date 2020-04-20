SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMDailyLogDelete]
/************************************************************
* CREATED:     2/15/06  CHS
*
* USAGE:
*   Deletes PM Daily Log
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@Original_DailyLog smallint,
	@Original_LogDate bDate,
	@Original_PMCo nvarchar(50),
	@Original_Project nvarchar(50),
	@Original_AccidentsYN nvarchar(50),
	@Original_ActivityYN nvarchar(50),
	@Original_ConversationsYN nvarchar(50),
	@Original_CrewYN nvarchar(50),
	@Original_DeliveriesYN nvarchar(50),
	@Original_Description char(255),
	@Original_EmployeeYN nvarchar(50),
	@Original_EquipmentYN nvarchar(50),
	@Original_SubcontractYN nvarchar(50),
	@Original_TempHigh smallint,
	@Original_TempLow smallint,
	@Original_UniqueAttchID uniqueidentifier,
	@Original_VisitorsYN nvarchar(50),
	@Original_Weather varchar(60),
	@Original_Wind varchar(30)
)
AS
	SET NOCOUNT ON;
DELETE FROM PMDL 
WHERE (DailyLog = @Original_DailyLog) 
AND (LogDate = @Original_LogDate) 
AND (PMCo = @Original_PMCo) 
AND (Project = @Original_Project) 
AND (AccidentsYN = @Original_AccidentsYN) 
AND (ActivityYN = @Original_ActivityYN) 
AND (ConversationsYN = @Original_ConversationsYN) 
AND (CrewYN = @Original_CrewYN) 
AND (DeliveriesYN = @Original_DeliveriesYN) 
AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL) 
AND (EmployeeYN = @Original_EmployeeYN) 
AND (EquipmentYN = @Original_EquipmentYN) 
AND (SubcontractYN = @Original_SubcontractYN) 
AND (TempHigh = @Original_TempHigh OR @Original_TempHigh IS NULL AND TempHigh IS NULL) 
AND (TempLow = @Original_TempLow OR @Original_TempLow IS NULL AND TempLow IS NULL) 
AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL) 
AND (VisitorsYN = @Original_VisitorsYN) 
AND (Weather = @Original_Weather OR @Original_Weather IS NULL AND Weather IS NULL) 
AND (Wind = @Original_Wind OR @Original_Wind IS NULL AND Wind IS NULL)

GO
GRANT EXECUTE ON  [dbo].[vpspPMDailyLogDelete] TO [VCSPortal]
GO
