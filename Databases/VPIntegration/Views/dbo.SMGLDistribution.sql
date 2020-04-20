SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[SMGLDistribution]
AS
SELECT     dbo.vSMGLDistribution.*
FROM         dbo.vSMGLDistribution






GO
GRANT SELECT ON  [dbo].[SMGLDistribution] TO [public]
GRANT INSERT ON  [dbo].[SMGLDistribution] TO [public]
GRANT DELETE ON  [dbo].[SMGLDistribution] TO [public]
GRANT UPDATE ON  [dbo].[SMGLDistribution] TO [public]
GO
