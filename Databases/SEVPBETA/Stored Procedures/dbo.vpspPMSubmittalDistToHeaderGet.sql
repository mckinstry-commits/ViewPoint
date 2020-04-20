SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMSubmittalDistToHeaderGet]
/************************************************************
* CREATED:     2/5/07  CHS
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the PM Submittal Header	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job
*
************************************************************/

(@JCCo bCompany, @Job bJob, @FirmNumber bFirm, @Contact bEmployee,
	@KeyID int = Null)

as
SET NOCOUNT ON;


select s.KeyID, 
s.PMCo, 
s.Project, j.Description as 'ProjectDescription', 
s.Submittal, 
s.Description as 'SubmittalDescription', 
s.SubmittalType, 
t.Description as 'SubmittalTypeDescription',
s.Rev, 
s.PhaseGroup, s.Phase, pd.Description as 'PhaseDescription', 
s.Issue, 
i.Description as 'IssueDescription',
s.Status, 
c.Description as 'StatusDescription', 
s.VendorGroup, 
s.ResponsibleFirm, 
rf.FirmName as 'ResFirmName', 
s.ResponsiblePerson,
rp.FirstName+' '+rp.LastName as 'ResPersonName',
s.SubFirm, 
sf.FirmName as 'SubFirmName', 
s.SubContact, 
sp.FirstName+' '+sp.LastName as 'SubPersonName',
s.ArchEngFirm, 
af.FirmName as 'ArcFirmName', 
s.ArchEngContact,
ap.FirstName+' '+ap.LastName as 'ArcPersonName',
s.DateReqd, s.DateRecd, s.ToArchEng, s.DueBackArch,
s.DateRetd, s.ActivityDate, s.CopiesRecd, s.CopiesSent,
s.Notes, s.CopiesReqd, s.CopiesRecdArch, s.CopiesSentArch,
s.UniqueAttchID, s.SpecNumber, s.RecdBackArch

from PMSM s with (nolock)
	left join JCJM j with (nolock) on s.PMCo = j.JCCo and s.Project = j.Job
	left join PMDT t with (nolock) on s.SubmittalType = t.DocType and t.DocCategory = 'SUBMIT'
	left Join PMSC c with (nolock) on s.Status=c.Status
	left Join PMIM i with (nolock) on i.PMCo=s.PMCo and i.Project=s.Project and i.Issue=s.Issue
	Left Join PMFM rf with (nolock) on s.VendorGroup=rf.VendorGroup and s.ResponsibleFirm=rf.FirmNumber
	Left Join PMFM sf with (nolock) on s.VendorGroup=sf.VendorGroup and s.SubFirm=sf.FirmNumber
	Left Join PMFM af with (nolock) on s.VendorGroup=af.VendorGroup and s.ArchEngFirm=af.FirmNumber
	Left Join PMPM rp with (nolock) on s.VendorGroup=rp.VendorGroup and s.ResponsibleFirm=rp.FirmNumber and s.ResponsiblePerson=rp.ContactCode
	Left Join PMPM sp with (nolock) on s.VendorGroup=sp.VendorGroup and s.SubFirm=sp.FirmNumber and s.SubContact=sp.ContactCode
	Left Join PMPM ap with (nolock) on s.VendorGroup=ap.VendorGroup and s.ArchEngFirm=ap.FirmNumber and s.ArchEngContact=ap.ContactCode
	left Join JCJP pd with (nolock) on s.PhaseGroup=pd.PhaseGroup and s.Phase=pd.Phase

where (@JCCo = s.PMCo) and (@Job = s.Project) and
		((s.ResponsibleFirm = @FirmNumber and s.ResponsiblePerson = @Contact) or 
		 (s.SubFirm = @FirmNumber and s.SubContact = @Contact) or
		 (s.ArchEngFirm = @FirmNumber and s.ArchEngContact = @Contact)) 
		and s.KeyID = IsNull(@KeyID, s.KeyID)

	


GO
GRANT EXECUTE ON  [dbo].[vpspPMSubmittalDistToHeaderGet] TO [VCSPortal]
GO
