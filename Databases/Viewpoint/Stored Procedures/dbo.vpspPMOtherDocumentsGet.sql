SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMOtherDocumentsGet]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	Get the other document(s).
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @OurFirm bFirm, @KeyID BIGINT = NULL)

AS
BEGIN
	SET NOCOUNT ON;

	SELECT o.KeyID,
		o.PMCo,
		o.Project,
		o.DocType,
		t.Description AS 'DocTypeDescription',
		o.Document,
		o.Description AS 'DocumentDescription',
		o.Location, 
		l.Description AS 'LocationDescription', 
		o.VendorGroup, 
		o.RelatedFirm, 
		f1.FirmName AS 'RelatedFirmName',
		o.ResponsibleFirm,
		f2.FirmName AS 'ResponsibleFirmName',
		o.ResponsiblePerson,
		p.FirstName + ' ' + p.LastName AS 'ResponsiblePersonName',
		o.Issue, 
		i.Description AS 'IssueDescription',
		o.Status, 
		s.Description AS 'StatusDescription',
		o.DateDue, 
		o.DateRecd, 
		o.DateSent, 
		o.DateDueBack, 
		o.DateRecdBack,
		o.DateRetd, 
		o.Notes, 
		o.UniqueAttchID

	FROM PMOD o WITH (NOLOCK)
		LEFT JOIN PMDT t WITH (NOLOCK) ON o.DocType = t.DocType
		LEFT JOIN PMFM f1 WITH (NOLOCK) ON o.VendorGroup = f1.VendorGroup AND o.RelatedFirm = f1.FirmNumber
		LEFT JOIN PMFM f2 WITH (NOLOCK) ON o.VendorGroup = f2.VendorGroup AND o.ResponsibleFirm = f2.FirmNumber
		LEFT JOIN PMIM i WITH (NOLOCK) ON o.PMCo = i.PMCo AND o.Project = i.Project AND o.Issue = i.Issue
		LEFT JOIN PMSC s WITH (NOLOCK) ON o.Status = s.Status
		LEFT JOIN PMPL l WITH (NOLOCK) ON o.PMCo = l.PMCo AND o.Project = l.Project AND o.Location = l.Location
		LEFT JOIN PMPM p WITH (NOLOCK) ON o.ResponsiblePerson = p.ContactCode AND o.VendorGroup = p.VendorGroup AND o.ResponsibleFirm = p.FirmNumber

	WHERE o.PMCo = @JCCo 
		AND o.Project = @Job 
		AND o.VendorGroup = @VendorGroup
		AND o.KeyID = ISNULL(@KeyID, o.KeyID)
END


GO
GRANT EXECUTE ON  [dbo].[vpspPMOtherDocumentsGet] TO [VCSPortal]
GO
