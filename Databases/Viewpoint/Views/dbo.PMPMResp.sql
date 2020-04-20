SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
* Modfied By:	GF 05/21/2008 - issue #128319 added PMPMOvrdAddr view
 *
 * Provides a view of PM Firm Contacts for
 * responsible firm Contacts in PM Document Tracking.
 *
 *****************************************/

CREATE  view [dbo].[PMPMResp] as
		select a.*,
		'FullContactName' = ltrim(rtrim(isnull(a.FirstName,''))) + ' ' + ltrim(rtrim(isnull(a.MiddleInit,''))) + ' ' + ltrim(rtrim(isnull(a.LastName,''))),
		b.OvrdMailAddress, b.OvrdMailAddress2, b.OvrdMailCity, b.OvrdMailState, b.OvrdMailZip, b.OvrdMailCountry
From dbo.PMPM a
join dbo.PMPMOvrdAddr b on b.VendorGroup=a.VendorGroup and b.FirmNumber=a.FirmNumber and b.ContactCode=a.ContactCode

GO
GRANT SELECT ON  [dbo].[PMPMResp] TO [public]
GRANT INSERT ON  [dbo].[PMPMResp] TO [public]
GRANT DELETE ON  [dbo].[PMPMResp] TO [public]
GRANT UPDATE ON  [dbo].[PMPMResp] TO [public]
GO