SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPCanvasGridPartSettingsTemplate
AS
SELECT     KeyID, PartId, LastQuery
FROM         dbo.vVPCanvasGridPartSettingsTemplate

GO
GRANT SELECT ON  [dbo].[VPCanvasGridPartSettingsTemplate] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridPartSettingsTemplate] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridPartSettingsTemplate] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridPartSettingsTemplate] TO [public]
GRANT SELECT ON  [dbo].[VPCanvasGridPartSettingsTemplate] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPCanvasGridPartSettingsTemplate] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPCanvasGridPartSettingsTemplate] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPCanvasGridPartSettingsTemplate] TO [Viewpoint]
GO
