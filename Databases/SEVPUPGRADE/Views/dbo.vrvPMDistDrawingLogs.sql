SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











/*****************************************
 * Created By: huyh
 * Modfied By:
 *
 * Provides a view of PM Document Distribution rows
 * for use in PM Drawing Logs reports. 
 *
 *****************************************/
   
CREATE view [dbo].[vrvPMDistDrawingLogs] as 
SELECT a.*, b.FirstName, b.LastName, c.FirmName 
FROM dbo.PMDistribution a
INNER JOIN PMPM b ON a.SentToContact = b.ContactCode 
AND a.VendorGroup = b.VendorGroup 
AND a.SentToFirm = b.FirmNumber
INNER JOIN PMFM c ON a.SentToFirm = c.FirmNumber 
AND a.VendorGroup = c.VendorGroup 
AND a.VendorGroup = b.VendorGroup 
AND a.SentToFirm = c.FirmNumber
WHERE a.DrawingType IS NOT NULL AND a.Drawing IS NOT NULL














GO
GRANT SELECT ON  [dbo].[vrvPMDistDrawingLogs] TO [public]
GRANT INSERT ON  [dbo].[vrvPMDistDrawingLogs] TO [public]
GRANT DELETE ON  [dbo].[vrvPMDistDrawingLogs] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMDistDrawingLogs] TO [public]
GO
