SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[SMCostType]
AS
SELECT  a.* FROM dbo.vSMCostType a




GO
GRANT SELECT ON  [dbo].[SMCostType] TO [public]
GRANT INSERT ON  [dbo].[SMCostType] TO [public]
GRANT DELETE ON  [dbo].[SMCostType] TO [public]
GRANT UPDATE ON  [dbo].[SMCostType] TO [public]
GO
