SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [dbo].[vpspPMDailyLogGet]
/************************************************************
* CREATED:		1/9/06		RWH
* MODIFIED:		6/6/06		chs
* Modified:		6/5/07		chs
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the PM Daily Log
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo and Job 
*
************************************************************/

(@JCCo bCompany, @Job bJob,
	@KeyID int = Null)
as
SET NOCOUNT ON;


declare @OurFirm int
set @OurFirm = (select JCJM.OurFirm from JCJM with (nolock) where JCJM.JCCo = @JCCo and JCJM.Job = @Job)
if @OurFirm is null
	begin
		set @OurFirm = (select PMCO.OurFirm from PMCO with (nolock) where PMCO.PMCo = 1)
	end


SELECT l.KeyID, l.PMCo, l.Project, l.LogDate, 

--l.DailyLog, 
cast(l.DailyLog as varchar(10)) as 'DailyLog',

l.Description, 
l.Weather, l.Wind, l.TempHigh, l.TempLow, l.EmployeeYN, l.CrewYN,
l.SubcontractYN, l.EquipmentYN, l.ActivityYN, l.ConversationsYN,
l.DeliveriesYN, l.AccidentsYN, l.VisitorsYN, l.Notes, 
l.UniqueAttchID, @OurFirm as 'OurFirm', h.MatlGroup

FROM PMDL l with (nolock)
	Left Join HQCO h with (nolock) on l.PMCo=h.HQCo

Where PMCo=@JCCo and Project=@Job
and l.KeyID = IsNull(@KeyID, l.KeyID)

GO
GRANT EXECUTE ON  [dbo].[vpspPMDailyLogGet] TO [VCSPortal]
GO
