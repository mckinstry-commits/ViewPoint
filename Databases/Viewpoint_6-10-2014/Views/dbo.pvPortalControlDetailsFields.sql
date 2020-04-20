SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[pvPortalControlDetailsFields]
AS
SELECT     dbo.pPortalControls.PortalControlID, dbo.pPortalControls.Name AS PortalControlName, dbo.pPortalControls.Description, dbo.pPortalControls.ChildControl, 
                      dbo.pPortalControls.Path, dbo.pPortalControls.Notes, dbo.pPortalControls.Status, dbo.pPortalControls.Help, dbo.pPortalControls.ClientModified, 
                      dbo.pPortalControls.PrimaryTable, dbo.pvPortalControlTables.TableID, dbo.pPortalHTMLTables.DetailsID, dbo.pPortalDetails.Name AS DetailsName, 
                      dbo.pPortalDetails.GetStoredProcedureID, dbo.pPortalDetails.AddStoredProcedureID, dbo.pPortalDetails.UpdateStoredProcedureID, 
                      dbo.pPortalDetails.DeleteStoredProcedureID, dbo.pPortalDetails.ParameterMissingMessageID, dbo.pPortalDetails.DetailsHeader, 
                      dbo.pPortalDetailsField.DetailsFieldID, dbo.pPortalDetailsField.ColumnName, dbo.pPortalDetailsField.LabelText, dbo.pPortalDetailsField.Editable, 
                      dbo.pPortalDetailsField.Required, dbo.pPortalDetailsField.TextMode, dbo.pPortalDetailsField.MaxLength, dbo.pPortalDetailsField.DetailsFieldOrder, 
                      dbo.pPortalDetailsField.Visible, dbo.pPortalDetailsField.DataFormatID
FROM         dbo.pPortalControls INNER JOIN
                      dbo.pvPortalControlTables ON dbo.pPortalControls.PortalControlID = dbo.pvPortalControlTables.PortalControlID INNER JOIN
                      dbo.pPortalHTMLTables ON dbo.pvPortalControlTables.TableID = dbo.pPortalHTMLTables.HTMLTableID INNER JOIN
                      dbo.pPortalDetails ON dbo.pPortalHTMLTables.DetailsID = dbo.pPortalDetails.DetailsID INNER JOIN
                      dbo.pPortalDetailsField ON dbo.pPortalDetails.DetailsID = dbo.pPortalDetailsField.DetailsID
GO
GRANT SELECT ON  [dbo].[pvPortalControlDetailsFields] TO [public]
GRANT INSERT ON  [dbo].[pvPortalControlDetailsFields] TO [public]
GRANT DELETE ON  [dbo].[pvPortalControlDetailsFields] TO [public]
GRANT UPDATE ON  [dbo].[pvPortalControlDetailsFields] TO [public]
GRANT SELECT ON  [dbo].[pvPortalControlDetailsFields] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvPortalControlDetailsFields] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvPortalControlDetailsFields] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvPortalControlDetailsFields] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvPortalControlDetailsFields] TO [Viewpoint]
GO
