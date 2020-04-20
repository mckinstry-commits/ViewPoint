SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMMeetingAttendedMinutesGet]
/************************************************************
* CREATED:     2/13/07  CHS
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the PM Meeting Attended Minutes
*	
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup, Contact
*   
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @FirmNumber bFirm, @Contact bEmployee,
	@KeyID int = Null)

AS

SET NOCOUNT ON;

SELECT distinct i.KeyID, i.PMCo, i.Project, i.MeetingType, i.MeetingDate, 
	i.Meeting, i.MinutesType, i.MeetingTime, i.Location, 
	i.Subject, i.VendorGroup, i.FirmNumber, f.FirmName, i.Preparer, 
	i.NextDate, i.NextTime, i.NextLocation, convert(varchar(2048), i.Notes) as 'Notes', 
	i.UniqueAttchID, 
		case i.MinutesType 
			when 0 then 'Agenda' 
			else 'Minutes' 
			end as 'MeetingMinutesDescription',
			
	j.FirstName+' '+j.LastName as 'PreparerName'

FROM PMMM i with (nolock)
	left join PMPM j with (nolock) on i.Preparer = j.ContactCode 
				and i.VendorGroup=j.VendorGroup 
				and i.FirmNumber=j.FirmNumber
	left join PMFM f with (nolock) on i.VendorGroup=f.VendorGroup 
				and i.FirmNumber=f.FirmNumber
	left Join PMMD d with (nolock) on i.PMCo = d.PMCo 
				and i.PMCo = d.PMCo 
				and i.MeetingType = d.MeetingType 
				and i.Meeting = d.Meeting 
				and i.MinutesType = d.MinutesType

Where i.PMCo=@JCCo and i.Project=@Job and i.VendorGroup=@VendorGroup 
	and ((d.FirmNumber = @FirmNumber and d.ContactCode = @Contact)
			or (i.FirmNumber = @FirmNumber and i.Preparer = @Contact))
and i.KeyID = IsNull(@KeyID, i.KeyID)


GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingAttendedMinutesGet] TO [VCSPortal]
GO
