SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMDistribution] as select a.* From vPMDistribution a
GO
GRANT SELECT ON  [dbo].[PMDistribution] TO [public]
GRANT INSERT ON  [dbo].[PMDistribution] TO [public]
GRANT DELETE ON  [dbo].[PMDistribution] TO [public]
GRANT UPDATE ON  [dbo].[PMDistribution] TO [public]
GRANT SELECT ON  [dbo].[PMDistribution] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMDistribution] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMDistribution] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMDistribution] TO [Viewpoint]
GO
