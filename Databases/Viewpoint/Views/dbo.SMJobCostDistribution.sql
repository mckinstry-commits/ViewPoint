SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[SMJobCostDistribution]
AS
SELECT a.* FROM dbo.vSMJobCostDistribution a
GO
GRANT SELECT ON  [dbo].[SMJobCostDistribution] TO [public]
GRANT INSERT ON  [dbo].[SMJobCostDistribution] TO [public]
GRANT DELETE ON  [dbo].[SMJobCostDistribution] TO [public]
GRANT UPDATE ON  [dbo].[SMJobCostDistribution] TO [public]
GO
