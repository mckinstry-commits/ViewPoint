SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[pvPortalParameters]
AS

	SELECT '%UserID%' AS KeyField, 'UserID' AS 'Description'
	UNION
	SELECT '%RoleID%' AS KeyField, 'RoleID' AS 'Description'
	UNION
	SELECT '%PRCo%' As KeyField, 'PRCo' AS 'Description'
	UNION
    SELECT '%PREmployee%' As KeyField, 'PR Employee' AS 'Description'
	UNION
    SELECT '%HRCo%' As KeyField, 'HRCo' AS 'Description'
	UNION
    SELECT '%HRRef%' As KeyField, 'HRRef' AS 'Description'
	UNION
    SELECT '%VendorGroup%' As KeyField, 'User Vendor Group' AS 'Description'
	UNION
    SELECT '%Vendor%' As KeyField, 'User Vendor' AS 'Description'
	UNION
    SELECT '%CustGroup%' As KeyField, 'Customer Group' AS 'Description'
	UNION
    SELECT '%Customer%' As KeyField, 'Customer' AS 'Description'
	UNION
    SELECT '%Contact%' As KeyField, 'Contact' AS 'Description'
	UNION
	SELECT '%ContactName%' As KeyField, 'Contact Name' AS 'Description'
	UNION
    SELECT '%FirmNumber%' As KeyField, 'Firm Number' AS 'Description'
	UNION
    SELECT '%FirmName%' As KeyField, 'Firm Name' AS 'Description'
	UNION
    SELECT '%JCCo%' As KeyField, 'JCCo' AS 'Description'
	UNION
	SELECT '%PMCo%' As KeyField, 'PMCo' AS 'Description'
	UNION
    SELECT '%Job%' as KeyField, 'Job' AS 'Description'
	UNION
	SELECT '%Project%' As KeyField, 'Project' AS 'Description'
	UNION
	SELECT '$OurFirm$' As KeyField, 'Our Firm' AS 'Description'
	UNION 
	SELECT '$VendorGroup$' As KeyField, 'Site Vendor Group' AS 'Description'
	UNION
	SELECT '$JCCo$' AS Keyfield, 'JCCo' As 'Description'
	UNION
	SELECT '$PMCo$' As KeyField, 'PMCo' AS 'Description'
	UNION
	SELECT '$Job$' AS KeyField , 'Job' As 'Description'
	UNION
	SELECT '$Project$' AS KeyField, 'Project' AS 'Description'
	UNION
	SELECT '%ShortDatePattern%' AS KeyField, 'ShortDatePattern' AS 'Description'

GO
GRANT SELECT ON  [dbo].[pvPortalParameters] TO [public]
GRANT INSERT ON  [dbo].[pvPortalParameters] TO [public]
GRANT DELETE ON  [dbo].[pvPortalParameters] TO [public]
GRANT UPDATE ON  [dbo].[pvPortalParameters] TO [public]
GRANT SELECT ON  [dbo].[pvPortalParameters] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvPortalParameters] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvPortalParameters] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvPortalParameters] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvPortalParameters] TO [Viewpoint]
GO
