SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMProjectNoteGet]
/***********************************************************
* Created:     8/27/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	Get project note(s).
************************************************************/
(
	@JCCo bCompany, @Job bJob, @UserID INT, @KeyID INT = Null
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @EmptyBoxValue VARCHAR(8000)
	SET @EmptyBoxValue = ''

	SELECT n.KeyID
		, n.PMCo
		, n.Project
		, CAST(n.NoteSeq AS VARCHAR(10)) AS'NoteSeq'
		, n.Issue
		, i.Description AS 'Issue Description'
		, n.VendorGroup, n.Firm
		, f.FirmName AS 'FirmName'
		, n.FirmContact
		, p.FirstName + ' ' + p.LastName AS 'ContactName'
		, RTRIM(n.PMStatus) AS 'PMStatus'
		, s.Description AS 'Status Description'
		, n.AddedBy
		, n.AddedDate
		, n.ChangedBy
		, n.ChangedDate
		, n.Summary
		, n.Notes
		, @UserID AS 'UserID'
		, @EmptyBoxValue AS 'EmptyBox'
		, n.UniqueAttchID

	FROM PMPN n WITH (NOLOCK)
		LEFT JOIN PMSC s WITH (NOLOCK) ON n.PMStatus = s.Status
		LEFT JOIN PMIM i WITH (NOLOCK) ON n.Issue = i.Issue AND n.Project = i.Project AND n.PMCo = i.PMCo 
		LEFT JOIN PMFM f WITH (NOLOCK) ON n.VendorGroup = f.VendorGroup AND n.Firm = f.FirmNumber
		LEFT JOIN PMPM p WITH (NOLOCK) ON n.VendorGroup = p.VendorGroup AND n.Firm = p.FirmNumber AND n.FirmContact = p.ContactCode

	WHERE n.PMCo=@JCCo 
		AND n.Project=@Job 
		AND n.KeyID = ISNULL(@KeyID, n.KeyID)

END


GO
GRANT EXECUTE ON  [dbo].[vpspPMProjectNoteGet] TO [VCSPortal]
GO
