SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   view [dbo].[PMDistributionGroupContact] as select * from vPMDistributionGroupContact

GO
GRANT SELECT ON  [dbo].[PMDistributionGroupContact] TO [public]
GRANT INSERT ON  [dbo].[PMDistributionGroupContact] TO [public]
GRANT DELETE ON  [dbo].[PMDistributionGroupContact] TO [public]
GRANT UPDATE ON  [dbo].[PMDistributionGroupContact] TO [public]
GO
