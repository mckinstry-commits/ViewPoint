SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMDailyDeliveriesLogGet]
/************************************************************
* CREATED:		6/01/06	chs
* MODIFIED		6/6/07	chs
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the PM Daily Deliveries Log
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, DailyLog, LogDate, VendorGroup
*   
************************************************************/
(@JCCo bCompany, @Job bJob, @DailyLog smallint, @LogDate bDate, @VendorGroup bGroup,
	@KeyID int = Null)

AS
	SET NOCOUNT ON;

declare @logtype tinyint

/*
	Note: LogType

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

set @logtype = 6

	
SELECT 
d.KeyID, d.PMCo, d.Project, d.LogDate, d.DailyLog, d.LogType,

cast(d.Seq as varchar(3)) as 'Seq', 

d.PRCo, d.Crew, 
d.VendorGroup, d.FirmNumber, f.FirmName, d.ContactCode, 
isnull(p.FirstName+' '+p.LastName,' ') as FirstLastName,
d.Equipment, d.Visitor, 
d.Description, d.ArriveTime, d.DepartTime, d.CatStatus, d.Supervisor, 
d.Foreman, d.Journeymen, d.Apprentices, d.PhaseGroup, d.Phase, d.PO, 
po.Description as 'PODescription',
d.Material, 
m.Description as 'Material Description', 
d.Quantity, d.Location, 
l.Description as 'Location Description', 
d.Issue, 
i.Description as 'Issue Description', d.DelTicket, 
d.CreatedChangedBy, d.MatlGroup, d.UM, d.UniqueAttchID, d.EMCo 

FROM PMDD d with (nolock)
	Left Join PMFM f with (nolock) on d.VendorGroup=f.VendorGroup and d.FirmNumber=f.FirmNumber
	Left Join PMPM p with (nolock) on d.VendorGroup=p.VendorGroup and d.FirmNumber=p.FirmNumber and d.ContactCode=p.ContactCode
	Left Join PMIM i with (nolock) on d.PMCo=i.PMCo and d.Project=i.Project and d.Issue=i.Issue
	Left Join PMPL l with (nolock) on d.PMCo=l.PMCo and d.Project=l.Project and d.Location=l.Location
	Left Join HQMT m with (nolock) on d.Material=m.Material and d.MatlGroup=m.MatlGroup
	Left Join POHD po with (nolock) on d.PO = po.PO

Where d.PMCo=@JCCo and d.Project=@Job and d.LogDate=@LogDate and 
d.LogType=@logtype and d.DailyLog = @DailyLog
and d.KeyID = IsNull(@KeyID, d.KeyID)

GO
GRANT EXECUTE ON  [dbo].[vpspPMDailyDeliveriesLogGet] TO [VCSPortal]
GO
