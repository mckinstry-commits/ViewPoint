SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************************************    
    
Author: ChrisG    
Create date: 02/16/2012    
    
Usage: Used by Connects to merge the pPortalDataGridColumns and pPortalDataGridColumnsCustom
	   tables.  This view is mapped into Connects Linq To SQL, so any modifications need to
	   get remapped in the code
        
**********************************************************************************/    
CREATE VIEW [dbo].[pvDataGridColumns]
AS

SELECT ISNULL(p.DataGridColumnID, c.DataGridColumnID) As DataGridColumnID, 
	   ISNULL(p.DataGridID, c.DataGridID) As DataGridID, 
	   ISNULL(p.ColumnName, c.ColumnName) As ColumnName, 
	   ISNULL(c.HeaderText, p.HeaderText) AS HeaderText, 
	   ISNULL(c.Visible, p.Visible) AS Visible, 
	   ISNULL(c.ColumnOrder, p.ColumnOrder) AS ColumnOrder, 
	   p.DataFormatID, 
	   ISNULL(c.DefaultValue, p.DefaultValue) AS DefaultValue, 
	   ISNULL(c.ColumnWidth, 
	   p.ColumnWidth) AS ColumnWidth, 
	   p.MaxLength, 
	   p.ChangesAllowedOnAdd, 
	   p.ChangesAllowedOnUpdate, 
	   ISNULL(c.IsRequired, p.IsRequired) AS IsRequired, p.Form, 
       p.Seq, 
       p.TextID,
	   p.DoNotCopy,
	   c.HasLookup
FROM dbo.pPortalDataGridColumnsCustom AS c 
FULL OUTER JOIN dbo.pPortalDataGridColumns AS p ON p.DataGridColumnID = c.DataGridColumnID

GO
GRANT SELECT ON  [dbo].[pvDataGridColumns] TO [public]
GRANT INSERT ON  [dbo].[pvDataGridColumns] TO [public]
GRANT DELETE ON  [dbo].[pvDataGridColumns] TO [public]
GRANT UPDATE ON  [dbo].[pvDataGridColumns] TO [public]
GRANT SELECT ON  [dbo].[pvDataGridColumns] TO [VCSPortal]
GO
