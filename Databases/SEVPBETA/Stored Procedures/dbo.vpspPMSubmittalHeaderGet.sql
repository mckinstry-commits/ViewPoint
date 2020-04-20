SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vpspPMSubmittalHeaderGet]
/***********************************************************
* Created:     8/31/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	Get submittal header(s).
************************************************************/

(@JCCo bCompany, @Job bJob, @KeyID BIGINT = Null)
AS
BEGIN
	SET NOCOUNT ON;


	SELECT s.KeyID, 
		s.PMCo, 
		s.Project,
		j.Description AS 'ProjectDescription', 
		s.Submittal, 
		s.Description AS 'SubmittalDescription', 
		s.SubmittalType, 
		t.Description AS 'SubmittalTypeDescription',
		cast(s.Rev AS VARCHAR(3)) AS 'Rev', 
		s.PhaseGroup,
		s.Phase, 
		pd.Description AS 'PhaseDescription', 
		s.Issue, 
		i.Description AS 'IssueDescription',
		s.Status, 
		c.Description AS 'StatusDescription', 
		s.VendorGroup, 
		s.ResponsibleFirm, 
		rf.FirmName AS 'ResFirmName', 
		s.ResponsiblePerson,
		s.ResponsiblePerson AS 'ResponsiblePersonAliased',
		rp.FirstName + ' ' + rp.LastName AS 'ResPersonName',
		s.SubFirm, 
		sf.FirmName AS 'SubFirmName', 
		s.SubContact, 
		sp.FirstName + ' ' + sp.LastName AS 'SubPersonName',
		s.ArchEngFirm, 
		af.FirmName AS 'ArcFirmName', 
		s.ArchEngContact,
		ap.FirstName + ' ' + ap.LastName AS 'ArcPersonName',
		s.DateReqd,
		s.DateRecd,
		s.ToArchEng,
		s.DueBackArch,
		s.DateRetd,
		s.ActivityDate, 
		s.CopiesRecd, 
		s.CopiesSent,
		s.Notes, 
		s.CopiesReqd, 
		s.CopiesRecdArch, 
		s.CopiesSentArch,
		s.UniqueAttchID, 
		s.SpecNumber, 
		s.RecdBackArch

	FROM PMSM s WITH (NOLOCK)
		LEFT JOIN JCJM j WITH (NOLOCK) ON s.PMCo = j.JCCo AND s.Project = j.Job
		LEFT JOIN PMDT t WITH (NOLOCK) ON s.SubmittalType = t.DocType AND t.DocCategory = 'SUBMIT'
		LEFT JOIN PMSC c WITH (NOLOCK) ON s.Status = c.Status
		LEFT JOIN PMIM i WITH (NOLOCK) ON i.PMCo = s.PMCo AND i.Project=s.Project AND i.Issue = s.Issue
		LEFT JOIN PMFM rf WITH (NOLOCK) ON s.VendorGroup = rf.VendorGroup AND s.ResponsibleFirm = rf.FirmNumber
		LEFT JOIN PMFM sf WITH (NOLOCK) ON s.VendorGroup = sf.VendorGroup AND s.SubFirm = sf.FirmNumber
		LEFT JOIN PMFM af WITH (NOLOCK) ON s.VendorGroup = af.VendorGroup AND s.ArchEngFirm = af.FirmNumber
		LEFT JOIN PMPM rp WITH (NOLOCK) ON s.VendorGroup = rp.VendorGroup AND s.ResponsibleFirm = rp.FirmNumber AND s.ResponsiblePerson = rp.ContactCode
		LEFT JOIN PMPM sp WITH (NOLOCK) ON s.VendorGroup = sp.VendorGroup AND s.SubFirm = sp.FirmNumber AND s.SubContact = sp.ContactCode
		LEFT JOIN PMPM ap WITH (NOLOCK) ON s.VendorGroup = ap.VendorGroup AND s.ArchEngFirm = ap.FirmNumber AND s.ArchEngContact = ap.ContactCode
		LEFT JOIN JCJP pd WITH (NOLOCK) ON s.PMCo = pd.JCCo AND s.Project = pd.Job AND s.PhaseGroup = pd.PhaseGroup AND s.Phase = pd.Phase

	WHERE (@JCCo = s.PMCo) 
	AND (@Job = s.Project)
	AND s.KeyID = ISNULL(@KeyID, s.KeyID)

END
GO
GRANT EXECUTE ON  [dbo].[vpspPMSubmittalHeaderGet] TO [VCSPortal]
GO
