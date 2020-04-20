SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMRequestForQuoteDistributedToGet]
/************************************************************
* CREATED:     1/08/07  CHS
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns PM RFQ
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup
*
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @OurFirm bFirm, 
@FirmNumber bFirm, @Contact bEmployee,
	@KeyID int = Null)
AS
SET NOCOUNT ON;

SELECT r.KeyID, 
	r.PMCo, r.Project, r.PCOType, r.PCO, r.RFQ, r.Description, 
	r.RFQDate, r.VendorGroup, 
	
	r.FirmNumber, 
	f.FirmName,
	
	r.ResponsiblePerson, 
	p.FirstName + ' ' + p.LastName as 'ResponsiblePersonName',
	
	r.Status, 
	c.Description as 'StatusDescription', 
	
	r.Notes, r.UniqueAttchID

FROM PMRQ r with (nolock)
	Left Join PMFM f with (nolock) on r.VendorGroup = f.VendorGroup 
				AND r.FirmNumber = f.FirmNumber
	Left Join PMPM p with (nolock) on r.VendorGroup = p.VendorGroup 
				AND r.ResponsiblePerson = p.ContactCode 
				AND r.FirmNumber = p.FirmNumber
	left Join PMSC c with (nolock) on r.Status = c.Status
	left join PMQD d with (nolock) on r.PMCo = d.PMCo and r.Project = d.Project
				AND r.PCOType = d.PCOType and r.PCO = d.PCO and r.RFQ = d.RFQ

WHERE r.PMCo=@JCCo and r.Project=@Job and d.SentToFirm = @FirmNumber 
and d.SentToContact = @Contact
and r.KeyID = IsNull(@KeyID, r.KeyID)


GO
GRANT EXECUTE ON  [dbo].[vpspPMRequestForQuoteDistributedToGet] TO [VCSPortal]
GO
