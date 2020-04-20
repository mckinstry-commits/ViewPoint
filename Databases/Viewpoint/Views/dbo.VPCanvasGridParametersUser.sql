SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[VPCanvasGridParametersUser]
AS
SELECT * FROM vVPCanvasGridParametersUser;

GO
GRANT SELECT ON  [dbo].[VPCanvasGridParametersUser] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridParametersUser] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridParametersUser] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridParametersUser] TO [public]
GO
