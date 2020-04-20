SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[JCOITotals] as
/*****************************************
* Created: DANF 10/24/2005
* Modfied: GG 04/10/08 - added top 100 percent and order by
*			GF 06/30/2009 - issue #134603 convert to numeric with the markup
*			DAN SO 12/08/2011 - TK-10867 - Arithmetic overflow error - changed FROM 10,2 TO 14,2
*
*
* Change Order Item Total View. 
* Profit is Revenue less Cost
* Markup is (Revenue less Cost) divided by Cost times one hundred 
*****************************************/

WITH EstCost (JCCo, Job, ACO, ACOItem, EstCost ) as	
	( select JCCo, Job, ACO, ACOItem, sum(EstCost) from dbo.JCOD with (nolock)
		group by JCCo, Job, ACO, ACOItem)
select top 100 percent i.JCCo, i.Job, i.ACO, i.ACOItem, 
	cast(IsNull(i.ContractAmt,0) as numeric(14,2))as 'Revenue', 
	cast(IsNull(sum(d.EstCost) ,0) as numeric(14,2)) As 'EstimatedCost',
	cast(IsNull(i.ContractAmt,0) - IsNull(sum(d.EstCost) ,0)as numeric(14,2)) as 'Profit',
	cast(case 	when IsNull(sum(d.EstCost) ,0) > 0 
			then isnull(Round((IsNull(i.ContractAmt,0) - IsNull(sum(d.EstCost) ,0) ) / IsNull(sum(d.EstCost) ,0),2),0)
	 		else 0
			end as numeric(14,2)) as 'Markup'
from dbo.JCOI i (nolock)
left join EstCost d (nolock) on i.JCCo= d.JCCo and i.Job = d.Job and i.ACO = d.ACO and i.ACOItem = d.ACOItem
group by  i.JCCo, i.Job, i.ACO, i.ACOItem, i.ContractAmt
order by  i.JCCo, i.Job, i.ACO, i.ACOItem


GO
GRANT SELECT ON  [dbo].[JCOITotals] TO [public]
GRANT INSERT ON  [dbo].[JCOITotals] TO [public]
GRANT DELETE ON  [dbo].[JCOITotals] TO [public]
GRANT UPDATE ON  [dbo].[JCOITotals] TO [public]
GO
