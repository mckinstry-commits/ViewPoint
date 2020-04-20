SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMRFIResponderGet]
/************************************************************
* CREATED:		6/27/06		CHS
* MODIFIED:		6/7/07		CHS
*				7/12/07		CHS
*				1/14/2008	CHS
*				8/24/09		JB	Cleanedup SP, Added RFIID for Response list.
*
* USAGE:
*   Returns PM RFI Responder/list
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup, FirmNumber, Contact, optional KeyID
*
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @FirmNumber bFirm, @Contact bEmployee, @KeyID int = Null)

AS
SET NOCOUNT ON;

	SELECT DISTINCT h.KeyID
		,h.KeyID AS RFIID
		,h.PMCo
		,h.Project
		,h.RFI
		,h.RFIType
		,t.Description AS 'RFITypeDescription'
		,h.Subject
		,h.RFIDate
		,h.Issue
		,i.Description AS 'IssueDescription'
		,h.Status
		,s.Description AS 'StatusDescription'
		,h.Submittal
		,h.Drawing
		,h.Addendum
		,h.SpecSec
		,h.ScheduleNo
		,h.VendorGroup
		,h.ResponsibleFirm
		,f.FirmName
		,h.ResponsiblePerson
		,p.FirstName + ' ' + p.LastName AS 'RespFirstLastName'
		,h.ReqFirm
		,rf.FirmName AS 'RequestingFirmName'
		,h.ReqContact
		,rp.FirstName + ' ' + rp.LastName AS 'ReqFirstLastName'
		,h.Notes
		,h.UniqueAttchID
		,h.Response
		,h.DateDue
		,h.PrefMethod
		,h.ImpactDesc
		,h.ImpactDays
		,h.ImpactCosts
		,h.ImpactPrice
		,h.RespondFirm
		,h.RespondContact
		,h.DateSent
		,h.DateRecd
		,h.InfoRequested
		,h.InfoRequested AS 'InformationReq' 

	FROM PMRI h WITH (NOLOCK)
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
GRANT EXECUTE ON  [dbo].[vpspPMRFIResponderGet] TO [VCSPortal]
GO
