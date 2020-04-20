SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMOtherDocumentsDistributionGet]
/************************************************************
* CREATED:		11/28/06	CHS
* MODIFIED:		6/7/07		CHS
* MODIFIED:		6/12/07		CHS
*				GF 11/11/2011 TK-09960
*
* USAGE:
*   Returns PM Other Documents Distribution
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup, DocType, & Document
*
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup,
 @DocType bDocType, @Document bDocument, @KeyID BIGINT = Null)

AS
SET NOCOUNT ON;

SELECT
	d.KeyID
	,d.PMCo
	,d.Project
	,d.DocType
	,t.Description as 'DocTypeDescription'
	,d.Document
	,o.Description as 'DocumentDescription'
	,CAST(d.Seq as varchar(10)) as 'Seq' 
	,d.VendorGroup
	,d.SentToFirm
	,f.FirmName as 'SentToFirmName'
	,d.SentToContact
	,p.FirstName + ' ' + p.LastName as 'SentToContactName'
	----TK-09960
	,d.[Send]
	,dbo.vpfYesNo(d.[Send]) AS 'SendYesOrNo'
	,d.[PrefMethod]
	,cp.[DisplayValue] as 'PrefMethodDesc'
	,d.[CC]
	,cc.[DisplayValue] as 'CCYesOrNo'

--d.Send, 

--	case d.Send
--		when 'Y' then 'Yes'
--		when 'N' then 'No'
--		end as 'SendYesOrNo',
		
--d.PrefMethod, 
								
--	case d.PrefMethod
--		when 'M' then 'Print'
--		when 'E' then 'Email'
--		when 'F' then 'Fax'
--		end as 'PrefMethodDesc',
	
--d.CC, 
	
--	case d.CC
--		when 'Y' then 'Yes'
--		when 'N' then 'No'
--		end as 'CCYesOrNo',


	,d.DateSent
	,d.Notes
	,d.UniqueAttchID

FROM dbo.PMOC d
	Left Join dbo.PMDT t with (nolock) on d.DocType = t.DocType
	left join dbo.PMOD o with (nolock) on d.PMCo=o.PMCo and d.Project=o.Project and d.VendorGroup=o.VendorGroup and d.DocType = o.DocType and d.Document = o.Document
	Left Join dbo.PMFM f with (nolock) on d.VendorGroup=f.VendorGroup and d.SentToFirm=f.FirmNumber
	Left Join dbo.PMPM p with (nolock) on d.VendorGroup=p.VendorGroup and d.SentToFirm=p.FirmNumber and d.SentToContact=p.ContactCode
	LEFT JOIN dbo.DDCI cp WITH (NOLOCK) ON cp.ComboType = 'PMPrefMethod' AND d.PrefMethod = cp.DatabaseValue
	LEFT JOIN dbo.DDCI cc WITH (NOLOCK) ON cc.ComboType = 'PMCC' AND d.CC = cc.DatabaseValue
	
WHERE d.PMCo = @JCCo
	AND d.Project = @Job 
	AND d.VendorGroup = @VendorGroup
	AND d.DocType = @DocType
	AND d.Document = @Document
	AND d.KeyID = IsNull(@KeyID, d.KeyID)



GO
GRANT EXECUTE ON  [dbo].[vpspPMOtherDocumentsDistributionGet] TO [VCSPortal]
GO
