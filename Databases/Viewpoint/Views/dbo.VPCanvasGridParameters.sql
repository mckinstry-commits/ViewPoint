SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[VPCanvasGridParameters]
AS
SELECT * FROM vVPCanvasGridParameters;

GO
GRANT SELECT ON  [dbo].[VPCanvasGridParameters] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridParameters] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridParameters] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridParameters] TO [public]
GO
