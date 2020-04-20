SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMRFICCSentToFirmGet]
/************************************************************
* CREATED:     7/6/06  CHS
* MODIFIED		9/28/06 chs
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the PM RFI
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, RFIType, RFI, VendorGroup, FirmNumber, Contact
*
************************************************************/
(
	@JCCo bCompany, 
	@Job bJob, 
	@RFIType bDocType, 
	@RFI bDocument, 
	@VendorGroup bGroup, 
	@FirmNumber bFirm, 
	@Contact bEmployee,
	@KeyID int = Null
)

AS
SET NOCOUNT ON;


select d.KeyID, 
	d.PMCo, d.Project, d.RFIType, t.Description as 'RFITypeDescription',
	d.RFI, d.RFISeq, d.VendorGroup, d.SentToFirm, f.FirmName as 'SentToFirmName', 
	d.SentToContact, p.FirstName + ' ' + p.LastName as 'SentToContactName', 
	d.DateSent, d.InformationReq, d.DateReqd, d.Response, d.DateRecd, d.Send, 
	d.PrefMethod, d.CC, d.UniqueAttchID,
	
	substring(d.InformationReq, 1, 90) as 'InformationReqTrunc',
	substring(d.Response, 1, 90) as 'ResponseTrunc'

from PMRD d with (nolock)
	Left Join PMDT t with (nolock) on d.RFIType = t.DocType
	Left Join PMPM p with (nolock) on d.VendorGroup = p.VendorGroup AND d.SentToContact = p.ContactCode AND d.SentToFirm = p.FirmNumber
	Left Join PMFM f with (nolock) on d.VendorGroup = f.VendorGroup AND d.SentToFirm = f.FirmNumber

where PMCo = @JCCo 
	and Project = @Job 
	and RFIType = @RFIType 
	and RFI = @RFI
	and d.VendorGroup=@VendorGroup 
	and d.SentToFirm=@FirmNumber 
	and d.SentToContact=@Contact
	and d.KeyID = IsNull(@KeyID, d.KeyID)



GO
GRANT EXECUTE ON  [dbo].[vpspPMRFICCSentToFirmGet] TO [VCSPortal]
GO
