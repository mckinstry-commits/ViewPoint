SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/******************************************/
CREATE view [dbo].[JCForecastTotalsCost] as 
/*******************************************************************************
* Created By:	GF 08/13/2009 - issue #129897 - JC Contract Forecast
* Modified By:
*
*
* Used by the JC Contract Master and PM Contract Master related grids
* to show cost numbers by Month.
*
*
**********************************************************************************/


select b.JCCo, b.Contract, b.ForecastMonth,
		cast(dbo.vfPMPendingCosts(b.JCCo, b.Contract, b.ForecastMonth) +
				isnull(sum(cc.CurrEstCost),0) as numeric(20,2)) as CurrentEstimate,

		cast(isnull(sum(cc.ActualCost),0) as numeric(20,2)) as ActualToDate,
	
   		cast(isnull((select sum(ol.EstCost)
			from dbo.bPMOL ol with (nolock)
   			join dbo.bPMOI oi with (nolock) on ol.PMCo=oi.PMCo and ol.Project=oi.Project
			and isnull(ol.PCOType,'')=isnull(oi.PCOType,'')
			and isnull(ol.PCO,'')=isnull(oi.PCO,'') and isnull(ol.PCOItem,'')=isnull(oi.PCOItem,'')
			and isnull(ol.ACO,'')=isnull(oi.ACO,'') and isnull(ol.ACOItem,'')=isnull(oi.ACOItem,'')
   			join dbo.bPMSC sc with (nolock) on sc.Status = oi.Status
   			left join dbo.bPMDT dt with (nolock) on dt.DocType = oi.PCOType
   			left join dbo.bJCJM jm with (nolock) on jm.JCCo=b.JCCo and jm.Contract=b.Contract
   			where oi.PMCo = b.JCCo and oi.Project = jm.Job and b.Contract is not null
			and ol.InterfacedDate is null ----and oi.ApprovedDate is not null and oi.ApprovedDate <= b.ForecastMonth
   			and isnull(dt.IncludeInProj,'N') = 'Y' 
   			and isnull(sc.IncludeInProj,'N') = 'C'), 0)
			as numeric(20,2)) as IncludedCOAmt
		
		
from dbo.JCForecastMonth b with (nolock)
left join dbo.bJCJM j with (nolock) on j.JCCo=b.JCCo and j.Contract=b.Contract
left join dbo.bJCCP cc with (nolock) on cc.JCCo=b.JCCo and cc.Job=j.Job and cc.Mth <= b.ForecastMonth

group by b.JCCo, b.Contract, b.ForecastMonth








































GO
GRANT SELECT ON  [dbo].[JCForecastTotalsCost] TO [public]
GRANT INSERT ON  [dbo].[JCForecastTotalsCost] TO [public]
GRANT DELETE ON  [dbo].[JCForecastTotalsCost] TO [public]
GRANT UPDATE ON  [dbo].[JCForecastTotalsCost] TO [public]
GRANT SELECT ON  [dbo].[JCForecastTotalsCost] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCForecastTotalsCost] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCForecastTotalsCost] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCForecastTotalsCost] TO [Viewpoint]
GO
