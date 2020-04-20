SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[HQProjectStatusCodes]
AS
SELECT     *
FROM         dbo.vHQProjectStatusCodes





GO
GRANT SELECT ON  [dbo].[HQProjectStatusCodes] TO [public]
GRANT INSERT ON  [dbo].[HQProjectStatusCodes] TO [public]
GRANT DELETE ON  [dbo].[HQProjectStatusCodes] TO [public]
GRANT UPDATE ON  [dbo].[HQProjectStatusCodes] TO [public]
GRANT SELECT ON  [dbo].[HQProjectStatusCodes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQProjectStatusCodes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQProjectStatusCodes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQProjectStatusCodes] TO [Viewpoint]
GO
