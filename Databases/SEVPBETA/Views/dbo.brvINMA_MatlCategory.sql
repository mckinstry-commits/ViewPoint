SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
  CREATE view [dbo].[brvINMA_MatlCategory] as
  
  SELECT INMA.INCo, INMA.Loc, INMA.MatlGroup, INMA.Material, INMA.Mth, INMA.BeginQty, INMA.BeginValue, INMA.BeginLastCost, 
  	INMA.BeginLastECM, INMA.BeginAvgCost, INMA.BeginAvgECM, INMA.BeginStdCost, INMA.BeginStdECM, INMA.PurchaseQty, 
  	INMA.PurchaseCost, INMA.ProdQty, INMA.ProdCost, INMA.UsageQty, INMA.UsageCost, INMA.ARSalesQty, INMA.ARSalesCost, 
  	INMA.ARSalesRev, INMA.JCSalesQty, INMA.JCSalesCost, INMA.JCSalesRev, INMA.INSalesQty, INMA.INSalesCost, INMA.INSalesRev, 
  	INMA.EMSalesQty, INMA.EMSalesCost, INMA.EMSalesRev, INMA.TrnsfrInQty, INMA.TrnsfrInCost, INMA.TrnsfrOutQty, 
  	INMA.TrnsfrOutCost, INMA.AdjQty, INMA.AdjCost, INMA.ExpQty, INMA.ExpCost, INMA.EndQty, INMA.EndValue, INMA.EndLastCost,
  	HQMT.Category, 
  	INMA.EndLastECM, INMA.EndAvgCost, INMA.EndAvgECM, INMA.EndStdCost, INMA.EndStdECM, INMA.UniqueAttchID 
  
  FROM INMA 
  left outer join HQMT on
  	HQMT.MatlGroup = INMA.MatlGroup and
  	HQMT.Material = INMA.Material
  
  
  
 



GO
GRANT SELECT ON  [dbo].[brvINMA_MatlCategory] TO [public]
GRANT INSERT ON  [dbo].[brvINMA_MatlCategory] TO [public]
GRANT DELETE ON  [dbo].[brvINMA_MatlCategory] TO [public]
GRANT UPDATE ON  [dbo].[brvINMA_MatlCategory] TO [public]
GO
