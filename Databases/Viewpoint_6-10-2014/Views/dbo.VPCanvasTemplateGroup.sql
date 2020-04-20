SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPCanvasTemplateGroup
AS
SELECT     KeyID, Description
FROM         dbo.vVPCanvasTemplateGroup

GO
GRANT SELECT ON  [dbo].[VPCanvasTemplateGroup] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasTemplateGroup] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasTemplateGroup] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasTemplateGroup] TO [public]
GRANT SELECT ON  [dbo].[VPCanvasTemplateGroup] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPCanvasTemplateGroup] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPCanvasTemplateGroup] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPCanvasTemplateGroup] TO [Viewpoint]
GO
