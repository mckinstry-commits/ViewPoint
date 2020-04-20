SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   view [dbo].[PMDistributionGroup] as select * from vPMDistributionGroup

GO
GRANT SELECT ON  [dbo].[PMDistributionGroup] TO [public]
GRANT INSERT ON  [dbo].[PMDistributionGroup] TO [public]
GRANT DELETE ON  [dbo].[PMDistributionGroup] TO [public]
GRANT UPDATE ON  [dbo].[PMDistributionGroup] TO [public]
GO
