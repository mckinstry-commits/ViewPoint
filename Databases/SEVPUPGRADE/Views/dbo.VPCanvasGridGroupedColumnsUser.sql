SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[VPCanvasGridGroupedColumnsUser]
AS
SELECT * FROM vVPCanvasGridGroupedColumnsUser;
GO
GRANT SELECT ON  [dbo].[VPCanvasGridGroupedColumnsUser] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridGroupedColumnsUser] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridGroupedColumnsUser] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridGroupedColumnsUser] TO [public]
GO
