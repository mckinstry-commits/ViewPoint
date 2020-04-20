SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viDim_MSUnitMeasures]

as

With MSUnitMeasures

as

(select distinct UM From bMSTD)

Select bHQUM.KeyID as UMID,
	   bHQUM.UM,
	   bHQUM.Description as UMDescription
From bHQUM
Inner Join MSUnitMeasures m
	on m.UM = bHQUM.UM
	
union all

Select 0, Null, 'Unassigned' 
	
			
GO
GRANT SELECT ON  [dbo].[viDim_MSUnitMeasures] TO [public]
GRANT INSERT ON  [dbo].[viDim_MSUnitMeasures] TO [public]
GRANT DELETE ON  [dbo].[viDim_MSUnitMeasures] TO [public]
GRANT UPDATE ON  [dbo].[viDim_MSUnitMeasures] TO [public]
GO
