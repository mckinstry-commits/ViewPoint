SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMRequestForInfoGet]
/************************************************************
* CREATED:     5/25/06  CHS
* MODIFIED:		6/7/07	CHS
* MODIFIED:		7/12/07	CHS
* MODIFIED:		11/15/07	CHS
* MODIFIED:		8/19/09		JB	Cleaned up SP, added RFIID for RFI Response
* MODIFIED:		12/11/09	MCP #136783 Removed the last line (SELECT * FROM PMSM). Need to check
*								with George to see if it needs to be put back
* MODIFIED:		1/7/10	JVH #136989 Removed the join to get the submittal description since
*							we don't store all the data needed to join to the actual submittal and multiple rows were being joined. 
*							We also weren't using the submittal description.
*				4/7/2011 GP Added Reference and Suggestion column
*
* USAGE:
*   Returns the PM RFI
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo and Job 
*
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @KeyID BIGINT = NULL)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT DISTINCT 
		fi.KeyID
		,fi.KeyID as RFIID
		,fi.PMCo
		,fi.Project
		,fi.RFI
		,fi.RFIType
		,t.Description AS 'RFITypeDescription'
		,fi.Subject
		,fi.RFIDate
		,fi.Issue 
		,i.Description AS 'IssueDescription'
		,fi.Status
		,s.Description AS 'StatusDescription'
		,fi.Submittal
		,fi.Drawing
		,fi.Addendum
		,fi.SpecSec
		,fi.ScheduleNo
		,fi.VendorGroup
		,fi.ResponsibleFirm
		,f.FirmName
		,fi.ResponsiblePerson
		,p.FirstName + ' ' + p.LastName AS 'RespFirstLastName'
		,fi.ReqFirm
		,rf.FirmName AS 'RequestingFirmName'
		,fi.ReqContact
		,rp.FirstName + ' ' + rp.LastName AS 'ReqFirstLastName'
		,fi.Notes
		,fi.UniqueAttchID
		,fi.Response
		,fi.DateDue
		,fi.ImpactDesc
		,fi.ImpactDays
		,fi.ImpactCosts
		,fi.ImpactPrice
		,fi.RespondFirm
		,rsf.FirmName AS 'RespondingFirmName'
		,fi.RespondContact
		,ISNULL(rsp.FirstName + ' ', '') + rsp.LastName AS 'RespondingContactName'
		,fi.DateSent
		,fi.DateRecd
		,fi.PrefMethod
		,fi.InfoRequested
		,fi.Reference
		,fi.Suggestion

	FROM PMRI fi WITH (NOLOCK)
		LEFT JOIN PMDT t WITH (NOLOCK) ON fi.RFIType = t.DocType
		LEFT JOIN PMIM i WITH (NOLOCK) ON fi.PMCo = i.PMCo AND fi.Project= i.Project AND fi.Issue = i.Issue
		LEFT JOIN PMSC s WITH (NOLOCK) ON fi.Status = s.Status
		LEFT JOIN PMPM p WITH (NOLOCK) ON fi.VendorGroup = p.VendorGroup AND fi.ResponsiblePerson = p.ContactCode AND fi.ResponsibleFirm = p.FirmNumber
		LEFT JOIN PMFM f WITH (NOLOCK) ON fi.VendorGroup = f.VendorGroup AND fi.ResponsibleFirm = f.FirmNumber
		LEFT JOIN PMFM rf WITH (NOLOCK) ON fi.VendorGroup = rf.VendorGroup AND fi.ReqFirm = rf.FirmNumber 
		LEFT JOIN PMPM rp WITH (NOLOCK)ON fi.VendorGroup = rp.VendorGroup AND fi.ReqContact = rp.ContactCode AND fi.ReqFirm = rp.FirmNumber
		LEFT JOIN PMFM rsf WITH (NOLOCK) ON fi.VendorGroup = rsf.VendorGroup AND fi.RespondFirm = rsf.FirmNumber 
		LEFT JOIN PMPM rsp WITH (NOLOCK)ON fi.VendorGroup = rsp.VendorGroup AND RespondContact = rsp.ContactCode AND fi.RespondFirm = rsp.FirmNumber
		LEFT JOIN JCJM j WITH (NOLOCK) ON fi.PMCo = j.JCCo AND fi.Project = j.Job

	WHERE fi.PMCo = @JCCo AND fi.Project = @Job AND fi.KeyID = IsNull(@KeyID, fi.KeyID)
	
END







GO
GRANT EXECUTE ON  [dbo].[vpspPMRequestForInfoGet] TO [VCSPortal]
GO
