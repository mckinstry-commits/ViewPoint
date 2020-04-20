SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************
 * Created By: 10/15/2010 huyh
 * Modfied By:
 *
 * Provides a view of PM Document Distribution rows
 * for use in PM Test Logs Report. 
 *
 *****************************************/
   
CREATE view [dbo].[vrvPMDistTestLogs] as 
SELECT a.*, b.FirstName, b.LastName, c.FirmName 
FROM dbo.PMDistribution a
INNER JOIN PMPM b ON a.SentToContact = b.ContactCode 
AND a.VendorGroup = b.VendorGroup 
AND a.SentToFirm = b.FirmNumber
INNER JOIN PMFM c ON a.SentToFirm = c.FirmNumber 
AND a.VendorGroup = c.VendorGroup 
AND a.VendorGroup = b.VendorGroup 
AND a.SentToFirm = c.FirmNumber
WHERE a.TestType IS NOT NULL AND a.TestCode IS NOT NULL




GO
GRANT SELECT ON  [dbo].[vrvPMDistTestLogs] TO [public]
GRANT INSERT ON  [dbo].[vrvPMDistTestLogs] TO [public]
GRANT DELETE ON  [dbo].[vrvPMDistTestLogs] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMDistTestLogs] TO [public]
GO
