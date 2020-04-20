SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMRFICCGet]
/************************************************************
* CREATED:		6/27/06	CHS
* MODIFIED:		6/7/07	CHS
* MODIFIED:		7/12/07	CHS
* MODIFIED:		8/24/09	JB		Cleaned SP - Added RFIID for RFI response
*
* USAGE:
*   Returns the PM RFI
*
* CALLED FROM:x.KeyID, 
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup, FirmNumber, Contact
*
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @FirmNumber bFirm, @Contact bEmployee, @KeyID int = Null)
AS

SET NOCOUNT ON;

	SELECT  h.KeyID
		,h.KeyID AS RFIID
		,h.PMCo
		,h.Project
		,h.RFIType
		,h.RFI
		,h.Subject
		,h.RFIDate
		,h.Issue
		,h.Status
		,h.Submittal
		,h.Drawing
		,h.Addendum
		,h.SpecSec
		,h.ScheduleNo
		,h.VendorGroup
		,h.ResponsibleFirm
		,h.ResponsiblePerson
		,h.ReqFirm
		,h.ReqContact
		,Convert(varchar(1024), h.Notes) AS Notes
		,h.UniqueAttchID
		,Convert(varchar(1024), h.Response) AS Response
		,h.DateDue
		,t.Description AS 'RFITypeDescription'
		,i.Description AS 'IssueDescription'
		,s.Description AS 'StatusDescription'
		,f.FirmName
		,p.FirstName + ' ' + p.LastName AS RespFirstLastName
		,rf.FirmName AS 'RequestingFirmName'
		,rp.FirstName + ' ' + rp.LastName AS ReqFirstLastName

	FROM PMRI h 
		LEFT JOIN PMDT t WITH (NOLOCK) ON h.RFIType = t.DocType
		LEFT JOIN PMIM i WITH (NOLOCK) ON h.PMCo = i.PMCo AND h.Project= i.Project AND h.Issue = i.Issue
		LEFT JOIN PMSC s WITH (NOLOCK) ON h.Status = s.Status
		LEFT JOIN PMFM f WITH (NOLOCK) ON h.VendorGroup = f.VendorGroup AND h.ResponsibleFirm = f.FirmNumber
		LEFT JOIN PMPM p WITH (NOLOCK) ON h.VendorGroup = p.VendorGroup AND h.ResponsiblePerson = p.ContactCode AND h.ResponsibleFirm = p.FirmNumber
		LEFT JOIN PMFM rf WITH (NOLOCK) ON h.VendorGroup = rf.VendorGroup AND h.ReqFirm = rf.FirmNumber 
		LEFT JOIN PMPM rp WITH (NOLOCK) ON h.VendorGroup = rp.VendorGroup AND h.ReqContact = rp.ContactCode AND h.ReqFirm = rp.FirmNumber

	WHERE h.VendorGroup = @VendorGroup
		AND h.RespondFirm = @FirmNumber 
		AND h.RespondContact = @Contact
		AND h.PMCo = @JCCo
		AND h.Project = @Job
		AND h.KeyID = IsNull(@KeyID, h.KeyID)



GO
GRANT EXECUTE ON  [dbo].[vpspPMRFICCGet] TO [VCSPortal]
GO
