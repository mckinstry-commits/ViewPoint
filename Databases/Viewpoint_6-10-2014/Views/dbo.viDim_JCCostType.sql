SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[viDim_JCCostType]

as

With CTDesc
(CostTypeDescription,
 CostTypeOrder,	
 CTDescID)

as

(select Description,
	   min(CostType),
	   row_number() over (order by (select 1))
From bJCCT
Group By Description)

select  bJCCT.KeyID as CostTypeID
        ,bJCCT.PhaseGroup
        ,bJCCT.CostType
		,CTDesc.CostTypeOrder
        ,bJCCT.Description
		,CTDesc.CTDescID
        ,bJCCT.Abbreviation
        ,bJCCT.TrackHours
        ,case when bJCCT.JBCostTypeCategory='L' then 'Labor'
			  when bJCCT.JBCostTypeCategory='B' then 'Burden'
			  when bJCCT.JBCostTypeCategory='M' then 'Material'
			  when bJCCT.JBCostTypeCategory='S' then 'Subcontract'
			  when bJCCT.JBCostTypeCategory='E' then 'Equipment'
			  when bJCCT.JBCostTypeCategory='O' then 'Other'
		 end as JBCostTypeCategory
From bJCCT With (NoLock)
Join CTDesc on CTDesc.CostTypeDescription=bJCCT.Description

union all

select   0 as CostTypeID
        ,null
        ,null
		,null
        ,'Unassigned'
		,null
        ,null
        ,null
        ,null



GO
GRANT SELECT ON  [dbo].[viDim_JCCostType] TO [public]
GRANT INSERT ON  [dbo].[viDim_JCCostType] TO [public]
GRANT DELETE ON  [dbo].[viDim_JCCostType] TO [public]
GRANT UPDATE ON  [dbo].[viDim_JCCostType] TO [public]
GRANT SELECT ON  [dbo].[viDim_JCCostType] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_JCCostType] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_JCCostType] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_JCCostType] TO [Viewpoint]
GO
