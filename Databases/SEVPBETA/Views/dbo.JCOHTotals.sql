SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCOHTotals] as
/*****************************************
* Created:	DANF 10/24/2005
* Modfied: GG 04/10/08 - added top 100 percent and order by
*
* Change Order Total View. 
* Profit is Revenue less Cost
* Markup is (Revenue less Cost) divided by Cost times one hundred 
*****************************************/

/*
select 
h.JCCo, h.Job, h.ACO,
IsNull(sum(i.ContractAmt),0) as 'Revenue', 
IsNull(sum(d.EstCost) ,0) As 'EstimatedCost',
IsNull(sum(i.ContractAmt),0) - IsNull(sum(d.EstCost) ,0) as 'Profit',
case 	when IsNull(sum(d.EstCost) ,0) > 0 
		then (IsNull(sum(i.ContractAmt),0) - IsNull(sum(d.EstCost) ,0) ) / IsNull(sum(d.EstCost) ,0)
	 	else 0
		end as 'Markup'
from dbo.JCOI i with (nolock)
left join dbo.JCOD d with (nolock)
on i.JCCo= d.JCCo and i.Job = d.Job and i.ACO = d.ACO
left join dbo.JCOH h with (nolock)
on h.JCCo= i.JCCo and h.Job = i.Job and h.ACO = i.ACO
group by  h.JCCo, h.Job, h.ACO
*/

WITH EstCost (JCCo, Job, ACO, ACOItem,  EstCost ) as	
	( select JCCo, Job, ACO, ACOItem,  sum(EstCost) from dbo.JCOD with (nolock)
		group by JCCo, Job, ACO, ACOItem)
select top 100 percent i.JCCo, i.Job, i.ACO,  
	IsNull(sum(i.ContractAmt),0) as 'Revenue', 
	IsNull(sum(d.EstCost) ,0) As 'EstimatedCost',
	IsNull(sum(i.ContractAmt),0) - IsNull(sum(d.EstCost) ,0) as 'Profit',
	case 	when IsNull(sum(d.EstCost) ,0) > 0 
			then (IsNull(sum(i.ContractAmt),0) - IsNull(sum(d.EstCost) ,0) ) / IsNull(sum(d.EstCost) ,0)
	 		else 0
			end as 'Markup'
from dbo.JCOI i (nolock)
left join EstCost d (nolock) on i.JCCo= d.JCCo and i.Job = d.Job and i.ACO = d.ACO and i.ACOItem = d.ACOItem
group by  i.JCCo, i.Job, i.ACO
order by  i.JCCo, i.Job, i.ACO

GO
GRANT SELECT ON  [dbo].[JCOHTotals] TO [public]
GRANT INSERT ON  [dbo].[JCOHTotals] TO [public]
GRANT DELETE ON  [dbo].[JCOHTotals] TO [public]
GRANT UPDATE ON  [dbo].[JCOHTotals] TO [public]
GO
