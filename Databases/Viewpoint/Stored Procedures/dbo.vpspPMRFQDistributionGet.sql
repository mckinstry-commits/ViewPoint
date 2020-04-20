SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vpspPMRFQDistributionGet]
/************************************************************
* CREATED:		1/08/07		CHS
* Modified:		6/05/07		chs
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
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @PCOType bDocType,
 @PCO bPCO, @RFQ bDocument,
	@KeyID int = Null)
AS
SET NOCOUNT ON;

SELECT r.KeyID, 
	r.PMCo, r.Project, r.PCOType, r.PCO, r.RFQ, 
			
	cast(r.RFQSeq as varchar(3)) as 'RFQSeq', 
			
	r.VendorGroup, 
	
	r.SentToFirm, 
	f.FirmName as 'SentToFirmName',

	r.SentToContact, 
	p.FirstName + ' ' + p.LastName as 'SentToContactName',

	r.DateSent, r.DateReqd, r.Response, 
	r.DateRecd, 
	r.Send,

	case r.Send
		when 'Y' then 'Yes'
		when 'N' then 'No'
		end as 'SendYesOrNo',
		
	r.PrefMethod, 
								
	case r.PrefMethod
		when 'M' then 'Print'
		when 'E' then 'Email'
		when 'T' then 'Email - Text Only'
		when 'F' then 'Fax'
		end as 'PrefMethodDesc',
	
	r.CC, 
	
	case r.CC
		when 'Y' then 'Yes'
		when 'N' then 'No'
		end as 'CCYesOrNo',
	
	r.UniqueAttchID,
	
	substring(r.Response, 1, 90) as 'ResponseTrunc'

FROM PMQD r with (nolock)
	Left Join PMFM f with (nolock) on r.VendorGroup = f.VendorGroup AND r.SentToFirm = f.FirmNumber
	Left Join PMPM p with (nolock) on r.VendorGroup = p.VendorGroup AND r.SentToContact = p.ContactCode AND r.SentToFirm = p.FirmNumber

WHERE r.PMCo=@JCCo and r.Project=@Job and r.VendorGroup = @VendorGroup 
and r.PCOType = @PCOType and r.PCO = @PCO and r.RFQ = @RFQ
and r.KeyID = IsNull(@KeyID, r.KeyID)

GO
GRANT EXECUTE ON  [dbo].[vpspPMRFQDistributionGet] TO [VCSPortal]
GO
