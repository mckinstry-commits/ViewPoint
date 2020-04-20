SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPCanvasGridPartSettings
AS
SELECT     KeyID, PartId, LastQuery, Seq
FROM         dbo.vVPCanvasGridPartSettings

GO
GRANT SELECT ON  [dbo].[VPCanvasGridPartSettings] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridPartSettings] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridPartSettings] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridPartSettings] TO [public]
GRANT SELECT ON  [dbo].[VPCanvasGridPartSettings] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPCanvasGridPartSettings] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPCanvasGridPartSettings] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPCanvasGridPartSettings] TO [Viewpoint]
GO
