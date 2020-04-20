SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*****************************************
* Created By: DANF 03/14/2005
* Modfied By: DANF 09/16/05 - Issue 29500 Performance Enahancement to Query.
*				GF 09/29/2008 - issue #126236 changes to include in projections.
*				GF 03/10/2010 - issue #138401 CO units should only be included when UM match
*
*
*
* Provides a view of Future PM Change Orders for Revenue Projections.
*
*****************************************/
   

CREATE view [dbo].[JCFuturePMCO] 
as select 
	oi.PMCo as 'Co',
	oi.Contract AS 'Cnt',
    oi.ContractItem as 'Item',
	oi.ACO as 'ACO',
	oi.ACOItem as 'ACOItem',
	oi.PCOType as 'PCOType',
	oi.PCO as 'PCO',
	oi.PCOItem as 'PCOItem',
	case 
		when oi.ACO is null and oi.FixedAmountYN <> 'Y' then isnull(oi.PendingAmount,0)
		when oi.ACO is null and oi.FixedAmountYN = 'Y'  then isnull(oi.FixedAmount,0)
		when oi.InterfacedDate is null and oi.ACO is not null then isnull(oi.ApprovedAmt,0)
	else
		0
	end as 'Amt',
	----#138401
	isnull(CASE WHEN oi.UM=ci.UM THEN oi.Units ELSE 0 END,0) as 'Units',
	isnull(sc.IncludeInProj,'N') as 'ProjectionOption'

from dbo.bPMOI oi with (nolock)
join dbo.bPMSC sc with (nolock) on sc.Status = oi.Status
----#138401
JOIN dbo.bJCCI ci WITH (NOLOCK) ON ci.JCCo=oi.PMCo AND ci.Contract=oi.Contract AND ci.Item=oi.ContractItem
left join dbo.bPMDT dt with (nolock) on dt.DocType = oi.PCOType
where isnull(dt.IncludeInProj,'Y') = 'Y' and isnull(sc.IncludeInProj,'N') in ('Y','C')




GO
GRANT SELECT ON  [dbo].[JCFuturePMCO] TO [public]
GRANT INSERT ON  [dbo].[JCFuturePMCO] TO [public]
GRANT DELETE ON  [dbo].[JCFuturePMCO] TO [public]
GRANT UPDATE ON  [dbo].[JCFuturePMCO] TO [public]
GRANT SELECT ON  [dbo].[JCFuturePMCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCFuturePMCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCFuturePMCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCFuturePMCO] TO [Viewpoint]
GO
