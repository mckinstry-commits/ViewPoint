SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMOtherDocsDistributedToGet]
/************************************************************
* CREATED:     2/1/07  CHS
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns PM Other Documents
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup, FirmNumber, Contact
*
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @FirmNumber bFirm, 
@Contact bEmployee,
	@KeyID int = Null)

AS
SET NOCOUNT ON;

select distinct o.KeyID, o.PMCo, o.Project, o.DocType,  
t.Description as 'DocTypeDescription',
o.Document, o.Description,
o.Location, 
l.Description as 'LocationDescription', 
o.VendorGroup, 
o.RelatedFirm, 
f1.FirmName as 'RelatedFirmName',
o.ResponsibleFirm,
f2.FirmName as 'ResponsibleFirmName',
o.ResponsiblePerson,
p.FirstName+' '+p.LastName as 'ResponsiblePersonName',
--d.SentToFirm, d.SentToContact,
o.Issue, 
i.Description as 'IssueDescription',
o.Status, 
s.Description as 'StatusDescription',
o.DateDue, o.DateRecd, o.DateSent, o.DateDueBack, o.DateRecdBack,
o.DateRetd, convert(varchar, o.Notes) as 'Notes', 
o.UniqueAttchID


from PMOD o with (nolock)
	Left Join PMDT t with (nolock) on o.DocType = t.DocType
	Left Join PMFM f1 with (nolock) on o.VendorGroup=f1.VendorGroup and o.RelatedFirm=f1.FirmNumber
	Left Join PMFM f2 with (nolock) on o.VendorGroup=f2.VendorGroup and o.ResponsibleFirm=f2.FirmNumber
	Left Join PMIM i with (nolock) on o.PMCo=i.PMCo and o.Project=i.Project and o.Issue = i.Issue
	Left join PMSC s with (nolock) on o.Status = s.Status
	Left Join PMPL l with (nolock) on o.PMCo=l.PMCo and o.Project=l.Project and o.Location=l.Location
	left join PMPM p with (nolock) on o.ResponsiblePerson=p.ContactCode and o.VendorGroup=p.VendorGroup and o.ResponsibleFirm=p.FirmNumber
	left join PMOC d with (nolock) on d.PMCo=o.PMCo and d.Project=o.Project and d.VendorGroup=o.VendorGroup and d.DocType = o.DocType and d.Document = o.Document

where (o.PMCo = @JCCo and o.Project = @Job and o.VendorGroup = @VendorGroup) and
	((o.ResponsibleFirm = @FirmNumber and o.ResponsiblePerson = @Contact) or (d.SentToFirm = @FirmNumber and d.SentToContact = @Contact))
	and o.KeyID = IsNull(@KeyID, o.KeyID) 





GO
GRANT EXECUTE ON  [dbo].[vpspPMOtherDocsDistributedToGet] TO [VCSPortal]
GO
