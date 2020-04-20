SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**********************************************************************************    
    
Author: DanW    
Create date: 08/23/2012    
    
Usage: Used by Connects to merge the pPortalDetailsField and pPortalDetailsFieldCustom
	   tables.  This view is mapped into Connects Linq To SQL, so any modifications need to
	   get remapped in the code
        
**********************************************************************************/    
CREATE VIEW [dbo].[pvDetailsField]
AS

SELECT ISNULL(c.DetailsFieldID,p.DetailsFieldID) AS DetailsFieldID, 
       ISNULL(c.DetailsID, p.DetailsID) AS DetailsID, 
       ISNULL(c.ColumnName, p.ColumnName) AS ColumnName,
       ISNULL(c.LabelText, p.LabelText) AS LabelText, 
       ISNULL(c.Editable, p.Editable) AS Editable, 
       ISNULL(c.Visible, p.Visible) AS Visible, 
       ISNULL(c.DetailsFieldOrder, p.DetailsFieldOrder) AS DetailsFieldOrder, 
       ISNULL(c.DataFormatID, p.DataFormatID) AS DataFormatID, 
       ISNULL(c.MaxLength, p.MaxLength) AS MaxLength, 
       ISNULL(c.[Required], p.[Required]) AS [Required], 
       ISNULL(c.TextMode, p.TextMode) AS TextMode, 
       ISNULL(c.Form, p.Form) AS Form, 
       ISNULL(c.Seq, p.Seq) AS Seq, 
       ISNULL(c.TextID, p.TextID) AS TextID,
       c.HasLookup
FROM  dbo.pPortalDetailsFieldCustom AS c 
FULL OUTER JOIN dbo.pPortalDetailsField AS p ON p.DetailsFieldID = c.DetailsFieldID

GO
GRANT SELECT ON  [dbo].[pvDetailsField] TO [public]
GRANT INSERT ON  [dbo].[pvDetailsField] TO [public]
GRANT DELETE ON  [dbo].[pvDetailsField] TO [public]
GRANT UPDATE ON  [dbo].[pvDetailsField] TO [public]
GRANT SELECT ON  [dbo].[pvDetailsField] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvDetailsField] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvDetailsField] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvDetailsField] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvDetailsField] TO [Viewpoint]
GO
