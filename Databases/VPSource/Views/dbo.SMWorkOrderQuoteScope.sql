SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create VIEW [dbo].[SMWorkOrderQuoteScope]
AS 
SELECT 
	a.*
	, isnull(a.LaborCostEst,0)
	  + isnull(a.MaterialCostEst,0)
	  + isnull(a.EquipmentCostEst,0)
	  + isnull(a.SubcontractCostEst,0)
	  + isnull(a.OtherCostEst,0) as CostEstTotal		
FROM vSMWorkOrderQuoteScope a
GO
GRANT SELECT ON  [dbo].[SMWorkOrderQuoteScope] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderQuoteScope] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderQuoteScope] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderQuoteScope] TO [public]
GO
