SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[SMEMUsageBreakdownDistribution]
AS
SELECT     dbo.vSMEMUsageBreakdownDistribution.*
FROM         dbo.vSMEMUsageBreakdownDistribution





GO
GRANT SELECT ON  [dbo].[SMEMUsageBreakdownDistribution] TO [public]
GRANT INSERT ON  [dbo].[SMEMUsageBreakdownDistribution] TO [public]
GRANT DELETE ON  [dbo].[SMEMUsageBreakdownDistribution] TO [public]
GRANT UPDATE ON  [dbo].[SMEMUsageBreakdownDistribution] TO [public]
GO
