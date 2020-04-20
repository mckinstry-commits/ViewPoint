SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE View 

[dbo].[viFact_INCurrentInventory]

as

Select    bMSCO.KeyID as MSCoID
		, bHQMT.KeyID as HQMaterialID
		, bINLM.KeyID as INLocationID
		, bHQUM.KeyID as UMID
		, Detail.StdCost
		, Detail.AvgCost
		, Detail.LastCost
		, Detail.StdPrice
		, Detail.OnHand - isnull(Detail.Alloc,0) as UnitsAvailable
		, Detail.OnOrder
From bINMT Detail With (NoLock)	

Inner Join bHQMT With (NoLock)	
	on  bHQMT.MatlGroup = Detail.MatlGroup
	and bHQMT.Material = Detail.Material
	and bHQMT.Type = 'S'

Inner Join bINLM With (NoLock)
	on  bINLM.INCo = Detail.INCo
	and	bINLM.Loc = Detail.Loc

Inner Join bMSCO With (NoLock)
	on bMSCO.MSCo = Detail.INCo

Inner Join  bHQUM
	on bHQUM.UM = bHQMT.StdUM
	
Inner Join vDDBICompanies on vDDBICompanies.Co=Detail.INCo	


	

	
	


	





GO
GRANT SELECT ON  [dbo].[viFact_INCurrentInventory] TO [public]
GRANT INSERT ON  [dbo].[viFact_INCurrentInventory] TO [public]
GRANT DELETE ON  [dbo].[viFact_INCurrentInventory] TO [public]
GRANT UPDATE ON  [dbo].[viFact_INCurrentInventory] TO [public]
GO
