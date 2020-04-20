SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMTransmittalDistributedToGet]
/************************************************************
* CREATED:     12/13/06  CHS
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns PM Transmittal Distributed To
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup, Ourfirm, FirmNumber, and Contact
*
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @FirmNumber bFirm, 
@Contact bEmployee,
	@KeyID int = Null)

AS
SET NOCOUNT ON;

SELECT t.KeyID, 
t.PMCo, t.Project, t.Transmittal, t.Subject, t.TransDate, t.DateSent,
t.DateDue, 

t.Issue,
i.Description as 'IssueDescription',

t.CreatedBy, t.Notes, t.UniqueAttchID, t.VendorGroup, 

t.ResponsibleFirm,
f.FirmName as 'ResponsibleFirmName',

t.ResponsiblePerson,
p.FirstName + ' ' + LastName as 'ResponsiblePersonName',

t.DateResponded,

substring(t.Subject, 1, 90) as 'SubjectTrunc'

FROM PMTM t with (nolock)
	Left Join PMTC d with (nolock) on t.PMCo = d.PMCo and t.Project = d.Project and t.VendorGroup = d.VendorGroup and t.Transmittal = d.Transmittal
	Left Join PMFM f with (nolock) on t.VendorGroup = f.VendorGroup and t.ResponsibleFirm = f.FirmNumber
	Left Join PMPM p with (nolock) on t.VendorGroup = p.VendorGroup and t.ResponsibleFirm = p.FirmNumber and t.ResponsiblePerson = p.ContactCode
	Left Join PMIM i with (nolock) on t.PMCo = i.PMCo and t.Project=i.Project and t.Issue=i.Issue

WHERE
	t.PMCo=@JCCo and t.Project=@Job and t.VendorGroup = @VendorGroup 
	and d.SentToFirm = @FirmNumber and d.SentToContact = @Contact
	and t.KeyID = IsNull(@KeyID, t.KeyID)



GO
GRANT EXECUTE ON  [dbo].[vpspPMTransmittalDistributedToGet] TO [VCSPortal]
GO
