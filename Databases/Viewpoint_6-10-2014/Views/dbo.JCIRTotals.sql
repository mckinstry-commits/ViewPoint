SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/*****************************************
* Created By:	GF 04/17/2010 - issue #139161
* Modfied By:	GF 01/20/2011 - issue #143041 - columns values not unique error in Future Amount
*				GF 03/11/2011 - issue #143587
*
*
* Provides totals for revenue and cost for revenue projections JCRevProj.
* Also returns future change order totals from both JC and PM Change Orders.
*
* JCIP.CurrentUnits
* JCIP.CurrentContract
*
* functions used
* dbo.vfJCIRCurrentContract		JC Revenue Contract Item total units and amount
* dbo.vfJCIRFutureJCChgOrders	JC Future Change Orders JC change orders that are in the future
* dbo.JCFuturePMCO				PM Future Change Orders using the include and status flags
* dbo.vfJCIRProjectedCost		JCCP Projected Cost Total projected cost total for item
*
*
*****************************************/

CREATE view [dbo].[JCIRTotals] as


select r.Co, r.Contract, r.Item,
		cast(isnull(i.CurrentUnits,0) as numeric(18,3)) as CurrentUnits,
		cast(isnull(i.CurrentContract,0) as numeric(20,2)) as CurrentContract
		,
		----#143587
		cast(isnull(SUM(j.Units),0) +
				ISNULL((select sum(isnull(p.Units,0)) from dbo.JCFuturePMCO p where p.Co = r.Co
						and p.Cnt=r.Contract and p.Item=r.Item),0)
		as numeric(18,3)) as FutureUnits
		,
		---- #143041
		cast(isnull(SUM(j.Amt),0) +
				ISNULL((select sum(isnull(p.Amt,0)) from dbo.JCFuturePMCO p where p.Co = r.Co
						and p.Cnt=r.Contract and p.Item=r.Item),0)
		as numeric(20,2)) as FutureAmount
		,
		cast(isnull(c.ProjCost,0) as numeric(20,2)) as ProjCost
		,
		cast(isnull((select sum(isnull(p.Units,0)) from dbo.JCFuturePMCO p where p.Co = r.Co
					and p.Cnt=r.Contract and p.Item=r.Item and p.ProjectionOption='C'),0)
		as numeric(18,3)) as IncludedCOUnits
		,
		cast(isnull((select sum(isnull(p.Amt,0)) from dbo.JCFuturePMCO p where p.Co = r.Co
					and p.Cnt=r.Contract and p.Item=r.Item and p.ProjectionOption='C'),0)
		as numeric(20,2)) as IncludedCOAmt
		
from dbo.JCIR r
OUTER
APPLY 
dbo.vfJCIRCurrentContract (r.Co, r.Mth, r.Contract, r.Item) i
OUTER
APPLY 
dbo.vfJCIRFutureJCChgOrders (r.Co, r.Mth, r.Contract, r.Item) j
OUTER
APPLY
dbo.vfJCIRProjectedCost (r.Co, r.Mth, r.Contract, r.Item) c

group by r.Co, r.Contract, r.Item,
		i.CurrentUnits
		,
		i.CurrentContract
		----#143587
		--,
		--j.Units
		---- #143041
		----,
		----j.Amt
		,
		c.ProjCost





















GO
GRANT SELECT ON  [dbo].[JCIRTotals] TO [public]
GRANT INSERT ON  [dbo].[JCIRTotals] TO [public]
GRANT DELETE ON  [dbo].[JCIRTotals] TO [public]
GRANT UPDATE ON  [dbo].[JCIRTotals] TO [public]
GRANT SELECT ON  [dbo].[JCIRTotals] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCIRTotals] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCIRTotals] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCIRTotals] TO [Viewpoint]
GO
