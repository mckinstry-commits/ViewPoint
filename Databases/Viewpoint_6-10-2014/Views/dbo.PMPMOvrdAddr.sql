SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
 * Created By:	GF 05/19/2008 6.1.0 issue #128319
 * Modfied By:  AW 2/6/2013 TFS 29966 Default blank City,State,Country,Zip from Firm master if null
 *
 * Provides a view of PM Firm Contacts (PMPM) with
 * the override address being either the PM Firm Contact
 * mail address info or the PM Firm Master address info
 * depending on the PMPM.UseAddressOvr flag.
 * This view will be used initially in the document template
 * setup for any merge fields that used the PMPM view for contact info.
 *
 *****************************************/

CREATE view [dbo].[PMPMOvrdAddr] as select a.*,
	'OvrdMailAddress' = case a.UseAddressOvr when 'Y' then a.MailAddress else b.MailAddress end,
	'OvrdMailAddress2' = case a.UseAddressOvr when 'Y' then a.MailAddress2 else b.MailAddress2 end,
	'OvrdMailCity' = case a.UseAddressOvr when 'Y' then isnull(a.MailCity,b.MailCity) else b.MailCity end,
	'OvrdMailState' = case a.UseAddressOvr when 'Y' then isnull(a.MailState,b.MailState) else b.MailState end,
	'OvrdMailZip' = case a.UseAddressOvr when 'Y' then isnull(a.MailZip,b.MailZip) else b.MailZip end,
	'OvrdMailCountry' = case a.UseAddressOvr when 'Y' then isnull(a.MailCountry,b.MailCountry) else b.MailCountry end

from dbo.PMPM a
left join dbo.PMFM b on b.VendorGroup=a.VendorGroup and b.FirmNumber=a.FirmNumber


GO
GRANT SELECT ON  [dbo].[PMPMOvrdAddr] TO [public]
GRANT INSERT ON  [dbo].[PMPMOvrdAddr] TO [public]
GRANT DELETE ON  [dbo].[PMPMOvrdAddr] TO [public]
GRANT UPDATE ON  [dbo].[PMPMOvrdAddr] TO [public]
GRANT SELECT ON  [dbo].[PMPMOvrdAddr] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMPMOvrdAddr] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMPMOvrdAddr] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMPMOvrdAddr] TO [Viewpoint]
GO
