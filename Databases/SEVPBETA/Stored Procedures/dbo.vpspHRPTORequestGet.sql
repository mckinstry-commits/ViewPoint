SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspHRPTORequestGet]
/************************************************************
* CREATED:		03/20/08  CHS
*
* USAGE:
*   Returns the HR PTO Rquests
*	
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job
*   
************************************************************/	
(@HRCo bCompany, @HRRef bHRRef, @KeyID int = Null)

AS

SET NOCOUNT ON;

Select
h.HRCo, h.HRRef, h.Date, h.Description, h.ScheduleCode, 

c.Description as 'ScheduleCodeDescription',

h.Notes, h.UniqueAttchID, h.KeyID, h.Seq, h.Hours, h.Status, 

case h.Status
	when 'N' then 'New'
	when 'A' then 'Approved'
	when 'D' then 'Denied'
	when 'C' then 'Canceled'

end as 'StatusText',

case h.Status
	when 'N' then 'New'
	when 'A' then 'Approved by ' + isnull(n.FullName, '')
	when 'D' then 'Denied'
	when 'C' then 'Canceled'

end as 'StatusTextDetails',

h.Source, h.RequesterComment, h.ApproverComment, h.Approver,

n.FullName as 'ApproverName'


from HRES h with (nolock)
	left join HRCM c on h.HRCo = c.HRCo and c.Type = 'C' and h.ScheduleCode = c.Code
	left join DDUP n on h.Approver = n.VPUserName

where h.HRCo = @HRCo and h.HRRef = @HRRef and h.KeyID = IsNull(@KeyID, h.KeyID)


GO
GRANT EXECUTE ON  [dbo].[vpspHRPTORequestGet] TO [VCSPortal]
GO
