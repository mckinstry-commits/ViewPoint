SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/******************************************/
CREATE view [dbo].[JCForecastTotalsRev] as 
/*******************************************************************************
* Created By:	GF 08/13/2009 - issue #129897 - JC Contract Forecast
* Modified By:
*
*
* Used by the JC Contract Master related grid to show revenue numbers by Month.
*
**********************************************************************************/


select b.JCCo, b.Contract, b.ForecastMonth,
		cast(isnull(sum(cr.ContractAmt),0) as numeric(20,2)) as CurrentContract,
		cast(isnull(sum(cr.BilledAmt),0) as numeric(20,2)) as BilledToDate,
		cast(dbo.vfJCMthRevForecastAmt (b.JCCo, b.Contract, b.ForecastMonth,b.RevenuePct) as numeric(20,2)) as ForecastMthRevenue
		
from dbo.JCForecastMonth b with (nolock)
left join dbo.bJCIP cr with (nolock) on cr.JCCo=b.JCCo and cr.Contract=b.Contract and cr.Mth <= b.ForecastMonth

group by b.JCCo, b.Contract, b.ForecastMonth, b.RevenuePct




GO
GRANT SELECT ON  [dbo].[JCForecastTotalsRev] TO [public]
GRANT INSERT ON  [dbo].[JCForecastTotalsRev] TO [public]
GRANT DELETE ON  [dbo].[JCForecastTotalsRev] TO [public]
GRANT UPDATE ON  [dbo].[JCForecastTotalsRev] TO [public]
GO
