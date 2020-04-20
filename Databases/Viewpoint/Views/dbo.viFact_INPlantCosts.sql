SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE view [dbo].[viFact_INPlantCosts]

as

With

PlantPhaseMaterials

as

(Select   bINMT.INCo
		, bINMT.Loc
		, bINMT.PhaseGroup
		, bINMT.CostPhase
		, min(bINMT.MatlGroup) as MatlGroup
		, min(bINMT.Material) as Material
   From bINMT With (NoLock) 
	Where bINMT.CostPhase is not null
    Group By bINMT.INCo, bINMT.Loc, bINMT.PhaseGroup, bINMT.CostPhase)
    
    

select    --bINLM.INCo
		  bMSCO.KeyID as MSCoID
		--, bINLM.Loc
		, bJCJM.KeyID as JobID
		, isnull(bHQMT.KeyID,0) as HQMaterialID
		, bHQUM.KeyID as UMID
		, bINLM.KeyID as INLocationID
		, bJCJP.KeyID as JobPhaseID
		, bJCCT.KeyID as JCCostTypeID	
		--, isnull(bJCCD.Material,'')
		--, bJCCD.Job
		--, bJCCD.PhaseGroup
		--, bJCCD.Phase  	
		--, bJCCD.CostType
		, bJCCT.KeyID as CostTypeID
		--, bJCCD.ActualDate
		, datediff(dd, '1/1/1950', bJCCD.ActualDate) as ActualDateID
		, isnull(Cast(cast(FiscalMonth.GLCo as varchar(3))+cast(Datediff(dd,'1/1/1950',FiscalMonth.Mth) as varchar(10)) as int),0) as 'FiscalMthID'
		--, bJCCD.Mth
		, bJCCD.ActualHours as PlantHours
		, bJCCD.ActualCost as PlantCost
		, Null as ProductionUnits
		, Null as AdjustedUnits


From bJCCD With (nolock)

Inner Join bJCCO With(nolock)
	on bJCCO.JCCo = bJCCD.JCCo
	
Inner Join bJCJM With (nolock)
	on  bJCJM.JCCo = bJCCD.JCCo
	and bJCJM.Job = bJCCD.Job

Inner Join bJCJP With (NoLock)
	on  bJCJP.JCCo = bJCCD.JCCo
	and	bJCJP.Job = bJCCD.Job
	and bJCJP.PhaseGroup = bJCCD.PhaseGroup
	and bJCJP.Phase = bJCCD.Phase

Inner Join bJCCT With (NoLock)
	on  bJCCT.PhaseGroup = bJCCD.PhaseGroup
	and	bJCCT.CostType = bJCCD.CostType	

Inner Join bINLM With (nolock)
	on  bINLM.JCCo = bJCJM.JCCo
	and bINLM.Job = bJCJM.Job

Left Outer Join PlantPhaseMaterials p With (NoLock)
	on  p.INCo = bINLM.INCo
	and	p.Loc = bINLM.Loc
	and p.PhaseGroup = bJCJP.PhaseGroup
	and p.CostPhase = bJCJP.Phase

Left Outer Join bINMT With (NoLock)
	on  bINMT.INCo = p.INCo
	and	bINMT.Loc = p.Loc
	and bINMT.MatlGroup = p.MatlGroup
	and bINMT.Material = p.Material

Inner Join bMSCO With (NoLock)
	on bMSCO.MSCo = bINLM.INCo	
	
Left Outer Join bHQMT With (NoLock)	
	on  bHQMT.MatlGroup = p.MatlGroup
	and bHQMT.Material = p.Material	
	and bHQMT.Type = 'S'

Left Outer Join bHQUM
	on bHQUM.UM = bHQMT.StdUM	

LEFT OUTER JOIN bGLFP FiscalMonth With (NoLock)
	ON FiscalMonth.GLCo=bJCCO.GLCo
	AND FiscalMonth.Mth=bJCCD.Mth
	
Inner Join vDDBICompanies j With (NoLock)
	ON j.Co=bJCCD.JCCo
	
Inner Join vDDBICompanies i on i.Co=bINLM.INCo		


Where bJCCD.ActualCost <> 0 

union all

select    --bINLM.INCo
		  bMSCO.KeyID as MSCoID
		--, bINLM.Loc
		, 0 as JobID
		, isnull(bHQMT.KeyID,0) as HQMaterialID
		, bHQUM.KeyID as UMID
		, bINLM.KeyID as INLocationID
		, 0 as JobPhaseID
		, 0 as CostTypeID
		--, isnull(bJCCD.Material,'')
		--, bJCCD.Job
		--, bJCCD.PhaseGroup
		--, bJCCD.Phase  	
		--, bJCCD.CostType
		, 0 as CostTypeID
		--, bJCCD.ActualDate
		, datediff(dd, '1/1/1950', bINDT.ActDate) as ActualDateID
		, isnull(Cast(cast(FiscalMonth.GLCo as varchar(3))+cast(Datediff(dd,'1/1/1950',FiscalMonth.Mth) as varchar(10)) as int),0) as 'FiscalMthID'
		--, bJCCD.Mth
		, null as PlantHours
		, null as PlantCost
		, case when bINDT.TransType = 'Prod' then bINDT.StkUnits end as ProductionUnits
		, case when bINDT.TransType = 'Adj' then bINDT.StkUnits end as AdjustedUnits


From bINDT With (nolock)


Inner Join bINLM With (nolock)
	on  bINLM.INCo = bINDT.INCo
	and bINLM.Loc = bINDT.Loc


Inner Join bMSCO With (NoLock)
	on bMSCO.MSCo = bINDT.INCo	
	
Inner Join bHQMT With (NoLock)	
	on  bHQMT.MatlGroup = bINDT.MatlGroup
	and bHQMT.Material = bINDT.Material	
	and bHQMT.Type = 'S'
	
Inner Join  bHQUM
	on bHQUM.UM = bHQMT.StdUM	

LEFT OUTER JOIN bGLFP FiscalMonth With (NoLock)
	ON FiscalMonth.GLCo=bMSCO.GLCo
	AND FiscalMonth.Mth=bINDT.Mth
	
Inner Join vDDBICompanies With (NoLock)
	ON vDDBICompanies.Co=bINDT.INCo

Where  bINDT.TransType in ('Prod','Adj')




	








GO
GRANT SELECT ON  [dbo].[viFact_INPlantCosts] TO [public]
GRANT INSERT ON  [dbo].[viFact_INPlantCosts] TO [public]
GRANT DELETE ON  [dbo].[viFact_INPlantCosts] TO [public]
GRANT UPDATE ON  [dbo].[viFact_INPlantCosts] TO [public]
GO
