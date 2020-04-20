SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[pvUserDetails]
AS
SELECT     dbo.pUsers.UserID, dbo.pUsers.UserName, dbo.pUsers.FirstName, dbo.pUsers.MiddleName, dbo.pUsers.LastName, dbo.pUsers.LastLogin, 
                      dbo.HQGP.Description AS CustomerGroup, dbo.ARCM.Name AS Customer, dbo.APVM.Name AS VendorName, dbo.PMFM.FirmName, 
                      dbo.PMPM.FirstName AS ContactFirstName, dbo.PMPM.LastName AS ContactLastName, dbo.pUsers.VPUserName, HRCompany.Name AS HRCo, dbo.DDUP.HRRef, 
                      PRCompany.Name AS PRCo, dbo.DDUP.Employee AS PRRef
FROM         dbo.pUsers LEFT OUTER JOIN
                      dbo.HQGP ON dbo.pUsers.CustGroup = dbo.HQGP.Grp LEFT OUTER JOIN
                      dbo.ARCM ON dbo.pUsers.CustGroup = dbo.ARCM.CustGroup AND dbo.pUsers.Customer = dbo.ARCM.Customer LEFT OUTER JOIN
                      dbo.APVM ON dbo.pUsers.VendorGroup = dbo.APVM.VendorGroup AND dbo.pUsers.Vendor = dbo.APVM.Vendor LEFT OUTER JOIN
                      dbo.PMFM ON dbo.pUsers.VendorGroup = dbo.PMFM.VendorGroup AND dbo.pUsers.FirmNumber = dbo.PMFM.FirmNumber LEFT OUTER JOIN
                      dbo.PMPM ON dbo.pUsers.VendorGroup = dbo.PMPM.VendorGroup AND dbo.pUsers.FirmNumber = dbo.PMPM.FirmNumber AND 
                      dbo.pUsers.Contact = dbo.PMPM.ContactCode LEFT OUTER JOIN
                      dbo.DDUP ON dbo.pUsers.VPUserName = dbo.DDUP.VPUserName LEFT OUTER JOIN
                      dbo.HQCO AS HRCompany ON dbo.DDUP.HRCo = HRCompany.HQCo LEFT OUTER JOIN
                      dbo.HQCO AS PRCompany ON dbo.DDUP.PRCo = PRCompany.HQCo

GO
GRANT SELECT ON  [dbo].[pvUserDetails] TO [public]
GRANT INSERT ON  [dbo].[pvUserDetails] TO [public]
GRANT DELETE ON  [dbo].[pvUserDetails] TO [public]
GRANT UPDATE ON  [dbo].[pvUserDetails] TO [public]
GRANT SELECT ON  [dbo].[pvUserDetails] TO [VCSPortal]
GO
