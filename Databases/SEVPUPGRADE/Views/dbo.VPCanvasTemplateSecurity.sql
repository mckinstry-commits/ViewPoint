SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[VPCanvasTemplateSecurity] as select a.* From vVPCanvasTemplateSecurity a
GO
GRANT SELECT ON  [dbo].[VPCanvasTemplateSecurity] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasTemplateSecurity] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasTemplateSecurity] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasTemplateSecurity] TO [public]
GO
