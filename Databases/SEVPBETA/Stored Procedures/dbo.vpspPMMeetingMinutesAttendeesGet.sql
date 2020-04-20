SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMMeetingMinutesAttendeesGet]
/************************************************************
* CREATED:		2/5/07  CHS
* MODIFIED:		6/7/07	CHS
* MODIFIED:		6/12/07	CHS 
*
* USAGE:
*   Returns the PM Meeting Minutes Attendees
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, MeetinType, Meeting, MinutesType, VendorGroup
*
************************************************************/
(
	@JCCo bCompany, 
	@Job bJob, 
	@MeetingType bDocType, 
	@Meeting int, 
	@MinutesType tinyint, 
	@VendorGroup bGroup, 
	@FirmNumber	bFirm, 
	@Contact bEmployee,
	@KeyID int = Null
	
)

AS
SET NOCOUNT ON;

select 
a.KeyID, a.PMCo, a.Project, a.MeetingType, a.Meeting, a.MinutesType, 

case a.MinutesType 
	when 0 then 'Agenda' 
	else 'Minutes' 
	end as 'MinutesTypeDescription',
	
cast(a.Seq as varchar(10)) as 'Seq', 

a.VendorGroup,
a.FirmNumber,
f.FirmName,

a.ContactCode,
p.FirstName + ' ' + p.LastName as 'ContactName',

a.PresentYN,

case a.PresentYN 
	When 'Y' then 'Yes' 
	When 'N' then 'No'
	end as 'PresentYesOrNo',

a.UniqueAttchID

from PMMD a with (nolock)
	Left Join PMFM f with (nolock) on a.VendorGroup=f.VendorGroup and a.FirmNumber=f.FirmNumber
	Left Join PMPM p with (nolock) on a.VendorGroup=p.VendorGroup and a.FirmNumber=p.FirmNumber and a.ContactCode=p.ContactCode


Where a.PMCo=@JCCo 
	and a.Project=@Job 
	and a.VendorGroup=@VendorGroup
	and a.MeetingType =@MeetingType 
	and a.Meeting = @Meeting 
	and a.MinutesType=@MinutesType
	and a.KeyID = IsNull(@KeyID, a.KeyID)



GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesAttendeesGet] TO [VCSPortal]
GO
