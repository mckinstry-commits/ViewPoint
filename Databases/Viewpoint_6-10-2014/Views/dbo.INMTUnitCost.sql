SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INMTUnitCost] as
/*****************************************
* Created:	GP 11/03/2008
* Modfied:
*
*
*
*****************************************/


with INCostMethod(INCo, Location, MatlGroup, Material, LocGroup, Category,
			INCO_CostMethod, INLM_CostMethod, INLO_CostMethod, CostMethod) as
	(select a.INCo, a.Loc, a.MatlGroup, a.Material, m.LocGroup, h.Category,
				c.CostMethod, m.CostMethod, o.CostMethod,
			'CostMethod' = case when isnull(o.CostMethod,0) <> 0 then o.CostMethod
							when isnull(m.CostMethod,0) <> 0 then m.CostMethod
							else c.CostMethod end
		from bINMT a with (nolock)
		join bINCO c with (nolock) on c.INCo=a.INCo
		join bINLM m with (nolock) on m.INCo=a.INCo and m.Loc=a.Loc
		join bHQMT h with (nolock) on h.MatlGroup=a.MatlGroup and h.Material=a.Material
		left join bINLO o with (nolock) on o.INCo=a.INCo and o.Loc=a.Loc and o.MatlGroup=a.MatlGroup and o.Category=h.Category)


	select c.INCo, c.Location, c.MatlGroup, c.Material, c.CostMethod,
			'UnitCost' = case when c.CostMethod = 1 then a.AvgCost
							when c.CostMethod = 2 then a.LastCost
							when c.CostMethod = 3 then a.StdCost end,
			'ECM' = case when c.CostMethod = 1 then a.AvgECM
							when c.CostMethod = 2 then a.LastECM
							when c.CostMethod = 3 then a.StdECM end
	from INCostMethod c join bINMT a with (nolock) on c.INCo=a.INCo and c.Location=a.Loc 
	and c.MatlGroup=a.MatlGroup and c.Material=a.Material

GO
GRANT SELECT ON  [dbo].[INMTUnitCost] TO [public]
GRANT INSERT ON  [dbo].[INMTUnitCost] TO [public]
GRANT DELETE ON  [dbo].[INMTUnitCost] TO [public]
GRANT UPDATE ON  [dbo].[INMTUnitCost] TO [public]
GRANT SELECT ON  [dbo].[INMTUnitCost] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INMTUnitCost] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INMTUnitCost] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INMTUnitCost] TO [Viewpoint]
GO
