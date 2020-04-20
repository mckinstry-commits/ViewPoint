SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[viDim_MSTruckTypes]

as

Select
	  bMSCO.KeyID AS MSCoID	  	
	, bMSTT.KeyID as TruckTypeID
	, bMSTT.Description as TruckTypeDescription

From bMSTT	
Inner Join bMSCO With (NoLock) on bMSCO.MSCo = bMSTT.MSCo

union all

Select
		Null
		, 0
		, 'Unassigned'	
		



GO
GRANT SELECT ON  [dbo].[viDim_MSTruckTypes] TO [public]
GRANT INSERT ON  [dbo].[viDim_MSTruckTypes] TO [public]
GRANT DELETE ON  [dbo].[viDim_MSTruckTypes] TO [public]
GRANT UPDATE ON  [dbo].[viDim_MSTruckTypes] TO [public]
GRANT SELECT ON  [dbo].[viDim_MSTruckTypes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_MSTruckTypes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_MSTruckTypes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_MSTruckTypes] TO [Viewpoint]
GO
