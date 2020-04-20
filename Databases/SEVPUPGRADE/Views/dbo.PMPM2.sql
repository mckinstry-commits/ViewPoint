SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:
* Modfied By:	GF 05/21/2008 - issue #128319 added PMPMOvrdAddr view
*
* Provides a view of PM Firm Contacts for
* firms other than responsible firms in 
* PM Document Tracking.
*
*****************************************/
/**** used for firm contacts other than responsible firms in PM Document Tracking ****/
   
CREATE  view [dbo].[PMPM2] as
select top 100 percent a.*, 
		'FullContactName' = isnull(ltrim(rtrim(a.FirstName)),'') + ' ' + isnull(ltrim(rtrim(a.MiddleInit)),'') + ' ' + isnull(ltrim(rtrim(a.LastName)),''),
		b.OvrdMailAddress, b.OvrdMailAddress2, b.OvrdMailCity, b.OvrdMailState, b.OvrdMailZip, b.OvrdMailCountry
From dbo.PMPM a
join dbo.PMPMOvrdAddr b on b.VendorGroup=a.VendorGroup and b.FirmNumber=a.FirmNumber and b.ContactCode=a.ContactCode

GO
GRANT SELECT ON  [dbo].[PMPM2] TO [public]
GRANT INSERT ON  [dbo].[PMPM2] TO [public]
GRANT DELETE ON  [dbo].[PMPM2] TO [public]
GRANT UPDATE ON  [dbo].[PMPM2] TO [public]
GO
