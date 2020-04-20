SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:
* Modfied By:	GF 05/21/2008 - issue #128319 added PMPMOvrdAddr view
*
*
* Provides a view of PM Firm Contacts for
* responsible firms in PM Document Tracking.
*
*****************************************/
/**** used for responsible firm contacts in PM Document Tracking ****/
   
CREATE  view [dbo].[PMPM1] as
select top 100 percent a.*, 
   		'FullContactName' = ltrim(rtrim(isnull(a.FirstName,''))) + ' ' + ltrim(rtrim(isnull(a.MiddleInit,''))) + ' ' + ltrim(rtrim(isnull(a.LastName,''))),
		b.OvrdMailAddress, b.OvrdMailAddress2, b.OvrdMailCity, b.OvrdMailState, b.OvrdMailZip, b.OvrdMailCountry
From dbo.PMPM a
join dbo.PMPMOvrdAddr b on b.VendorGroup=a.VendorGroup and b.FirmNumber=a.FirmNumber and b.ContactCode=a.ContactCode

GO
GRANT SELECT ON  [dbo].[PMPM1] TO [public]
GRANT INSERT ON  [dbo].[PMPM1] TO [public]
GRANT DELETE ON  [dbo].[PMPM1] TO [public]
GRANT UPDATE ON  [dbo].[PMPM1] TO [public]
GO
