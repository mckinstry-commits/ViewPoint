SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[GLDistribution]
AS
SELECT *
FROM dbo.vGLDistribution
GO
GRANT SELECT ON  [dbo].[GLDistribution] TO [public]
GRANT INSERT ON  [dbo].[GLDistribution] TO [public]
GRANT DELETE ON  [dbo].[GLDistribution] TO [public]
GRANT UPDATE ON  [dbo].[GLDistribution] TO [public]
GRANT SELECT ON  [dbo].[GLDistribution] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLDistribution] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLDistribution] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLDistribution] TO [Viewpoint]
GO
