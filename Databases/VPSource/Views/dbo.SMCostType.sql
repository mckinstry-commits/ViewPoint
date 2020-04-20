
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMCostType] as select a.* From vSMCostType a
GO

GRANT SELECT ON  [dbo].[SMCostType] TO [public]
GRANT INSERT ON  [dbo].[SMCostType] TO [public]
GRANT DELETE ON  [dbo].[SMCostType] TO [public]
GRANT UPDATE ON  [dbo].[SMCostType] TO [public]
GO
