SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[VPCanvasGridColumnsUser]
AS
SELECT * FROM vVPCanvasGridColumnsUser;

GO
GRANT SELECT ON  [dbo].[VPCanvasGridColumnsUser] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridColumnsUser] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridColumnsUser] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridColumnsUser] TO [public]
GRANT SELECT ON  [dbo].[VPCanvasGridColumnsUser] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPCanvasGridColumnsUser] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPCanvasGridColumnsUser] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPCanvasGridColumnsUser] TO [Viewpoint]
GO
