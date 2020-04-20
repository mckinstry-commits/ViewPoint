SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[vpspPMMeetingMinutesGet]
/************************************************************
* CREATED:		1/12/06  CHS
* MODIFIED:		2/7/06	chs
* MODIFIED:		6/7/07	CHS
* MODIFIED:		6/12/07		CHS
*
* USAGE:
*   Returns the PM Meeting Minutes
*	
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup
*   
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup,
	@KeyID int = Null)

AS

SET NOCOUNT ON;

SELECT i.KeyID, i.PMCo, i.Project, i.MeetingType, i.MeetingDate, 

cast(i.Meeting as varchar(10)) as 'Meeting',

i.MinutesType, i.MeetingTime, i.Location, 
i.Subject, i.VendorGroup, i.FirmNumber, f.FirmName, i.Preparer, 
i.NextDate, i.NextTime, i.NextLocation, i.Notes, 
i.UniqueAttchID, case i.MinutesType when 0 then 'Agenda' else 'Minutes' end as 'MeetingMinutesDescription',
j.FirstName+' '+j.LastName as 'PreparerName'

FROM PMMM i with (nolock)
left join PMPM j with (nolock) on i.Preparer = j.ContactCode and i.VendorGroup=j.VendorGroup and i.FirmNumber=j.FirmNumber
left join PMFM f with (nolock) on i.VendorGroup=f.VendorGroup and i.FirmNumber=f.FirmNumber

Where i.PMCo=@JCCo and i.Project=@Job and i.VendorGroup=@VendorGroup
and i.KeyID = IsNull(@KeyID, i.KeyID)




GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesGet] TO [VCSPortal]
GO
