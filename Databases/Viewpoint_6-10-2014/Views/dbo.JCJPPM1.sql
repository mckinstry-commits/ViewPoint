SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  view [dbo].[JCJPPM1] as 
/*****************************************
* Created:	GF 07/21/2005 6.x only
* Modfied: GG 04/10/08 - added top 100 percent and order by
*
* Provides a view of JC Job Phases for 6.x
* with JCCH Cost Type totals for each cost type set up
* in PMCO.ShowCostType(1-10). Used in PMProjectPhases,
* separate from JCJPPM since cannot update from here.
*
*****************************************/

select top 100 percent a.JCCo, a.Job, a.PhaseGroup, a.Phase,
	'PhaseTotal' = cast(isnull(sum(b.OrigCost),0) as numeric (16,2)),
	'CostType1' = cast(sum(case when b.CostType=c.ShowCostType1 then b.OrigCost else 0 end) as numeric(16,2)),
	'CostType2' = cast(sum(case when b.CostType=c.ShowCostType2 then b.OrigCost else 0 end) as numeric(16,2)),
	'CostType3' = cast(sum(case when b.CostType=c.ShowCostType3 then b.OrigCost else 0 end) as numeric(16,2)),
	'CostType4' = cast(sum(case when b.CostType=c.ShowCostType4 then b.OrigCost else 0 end) as numeric(16,2)),
	'CostType5' = cast(sum(case when b.CostType=c.ShowCostType5 then b.OrigCost else 0 end) as numeric(16,2)),
	'CostType6' = cast(sum(case when b.CostType=c.ShowCostType6 then b.OrigCost else 0 end) as numeric(16,2)),
	'CostType7' = cast(sum(case when b.CostType=c.ShowCostType7 then b.OrigCost else 0 end) as numeric(16,2)),
	'CostType8' = cast(sum(case when b.CostType=c.ShowCostType8 then b.OrigCost else 0 end) as numeric(16,2)),
	'CostType9' = cast(sum(case when b.CostType=c.ShowCostType9 then b.OrigCost else 0 end) as numeric(16,2)),
	'CostType10' = cast(sum(case when b.CostType=c.ShowCostType10 then b.OrigCost else 0 end) as numeric(16,2))
from dbo.JCJP a
left join dbo.JCCH b with (nolock) on b.JCCo=a.JCCo and b.Job=a.Job and b.PhaseGroup=a.PhaseGroup and b.Phase=a.Phase
left join dbo.PMCO c with (nolock) on c.PMCo=b.JCCo
group by a.JCCo, a.Job, a.PhaseGroup, a.Phase
order by a.JCCo, a.Job, a.PhaseGroup, a.Phase



GO
GRANT SELECT ON  [dbo].[JCJPPM1] TO [public]
GRANT INSERT ON  [dbo].[JCJPPM1] TO [public]
GRANT DELETE ON  [dbo].[JCJPPM1] TO [public]
GRANT UPDATE ON  [dbo].[JCJPPM1] TO [public]
GRANT SELECT ON  [dbo].[JCJPPM1] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCJPPM1] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCJPPM1] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCJPPM1] TO [Viewpoint]
GO
