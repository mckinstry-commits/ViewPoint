SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMRFISentToFirmGet]
/************************************************************
* CREATED:		7/6/06		CHS
* Modified		10/19/06	chs
* MODIFIED:		6/7/07		CHS
* MODIFIED:		6/12/07		CHS
*
* USAGE:
*   Returns the PM RFI
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, RFIType, RFI
*
* OUTPUT PARAMETESR
*   
* RETURN VALUE
*   
************************************************************/
(@JCCo bCompany, @Job bJob, @RFIType bDocType, @RFI bDocument,
	@KeyID int = Null)
AS
SET NOCOUNT ON;

select 
	d.KeyID, d.PMCo, d.Project, d.RFIType, t.Description as 'RFITypeDescription',
	d.RFI, 
	
	cast(d.RFISeq as varchar(10)) as 'RFISeq', 
	
	d.VendorGroup, d.SentToFirm, f.FirmName as 'SentToFirmName', 
	d.SentToContact, p.FirstName + ' ' + p.LastName as 'SentToContactName', 
	d.DateSent, d.InformationReq, d.DateReqd, d.Response, d.DateRecd, d.Send, 
	'' as msg,
	
	case d.Send
		when 'Y' then 'Yes'
		when 'N' then 'No'
		end as 'SendYesOrNo',
		
	d.PrefMethod, 
								
	case d.PrefMethod
		when 'M' then 'Print'
		when 'E' then 'Email'
		when 'T' then 'Email - Text Only'
		when 'F' then 'Fax'
		end as 'PrefMethodDesc',
	
	d.CC, 
	
	case d.CC
		when 'N' then 'None'
		when 'B' then 'Bcc'
		when 'C' then 'Cc'
		end as 'CCDescription',
		
	d.UniqueAttchID,
	
	substring(d.InformationReq, 1, 90) as 'InformationReqTrunc',
	substring(d.Response, 1, 90) as 'ResponseTruncated'
	

from PMRD d
	Left Join PMDT t with (nolock) on d.RFIType = t.DocType
	Left Join PMPM p with (nolock) on d.VendorGroup = p.VendorGroup AND d.SentToContact = p.ContactCode AND d.SentToFirm = p.FirmNumber
	Left Join PMFM f with (nolock) on d.VendorGroup = f.VendorGroup AND d.SentToFirm = f.FirmNumber

where PMCo = @JCCo and Project = @Job and RFIType = @RFIType and RFI = @RFI
and d.KeyID = IsNull(@KeyID, d.KeyID)



GO
GRANT EXECUTE ON  [dbo].[vpspPMRFISentToFirmGet] TO [VCSPortal]
GO
