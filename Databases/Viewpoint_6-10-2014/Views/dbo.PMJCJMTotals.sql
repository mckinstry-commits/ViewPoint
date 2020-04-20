SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************
* Created By:	GF 05/03/2007 6.x
* Modfied By:	GF 11/10/2008 - issue #129664 use new view PMOPTotalsOnly for PCO Side (not include ACO)
*
*
* Provides a view of JC Jobs for PM
* used in PM Change Orders form to return
* project totals.
*
*****************************************/

CREATE view [dbo].[PMJCJMTotals] as select a.PMCo, a.Project,
		'ACORevTotal' = isnull((ACORevTotal),0), 'ACOCosts' = isnull((ACOCosts),0), 'ACOProfit' = isnull((ACOProfit),0),
		'PCORevTotal' = isnull((PCORevTotal),0), 'PCOCosts' = isnull((PCOCosts),0), 'PCOProfit' = isnull((PCOProfit),0),
		'PMFutureCO' = isnull((PMFutureCO),0)
from dbo.JCJMPM a with (nolock)

/*** ACO Side ***/
left join (select b.PMCo, b.Project, 
			'ACORevTotal' = isnull(sum(b.ACORevTotal),0),
			'ACOCosts' = isnull(sum(b.ACOPhaseCost),0) + isnull(sum(b.ACOAddonCost),0),
			'ACOProfit' = isnull(sum(b.ACORevTotal),0) - (isnull(sum(b.ACOPhaseCost),0) + isnull(sum(b.ACOAddonCost),0))
from PMOHTotals b with (nolock) where 1=1 group by b.PMCo, b.Project)
aco on aco.PMCo=a.PMCo and aco.Project=a.Project

/*** PCO Side ***/
left join (select c.PMCo, c.Project, 
			'PCORevTotal' = isnull(sum(c.PCORevTotal),0),
			'PCOCosts' = isnull(sum(c.PCOPhaseCost),0) + isnull(sum(c.PCOAddonCost),0),
			'PCOProfit' = isnull(sum(c.PCORevTotal),0) - (isnull(sum(c.PCOPhaseCost),0) + isnull(sum(c.PCOAddonCost),0))
from PMOPTotalsOnly c with (nolock) where 1=1 group by c.PMCo, c.Project)
pco on pco.PMCo=a.PMCo and pco.Project=a.Project

/*** future CO ***/
left join (select d.PMCo, d.Project, 'PMFutureCO' = isnull(sum(d.FutureCOAmt),0)
from dbo.PMJCJMFuturePMOI d with (nolock) where 1=1 group by d.PMCo, d.Project)
fco on fco.PMCo=a.PMCo and fco.Project=a.Project



GO
GRANT SELECT ON  [dbo].[PMJCJMTotals] TO [public]
GRANT INSERT ON  [dbo].[PMJCJMTotals] TO [public]
GRANT DELETE ON  [dbo].[PMJCJMTotals] TO [public]
GRANT UPDATE ON  [dbo].[PMJCJMTotals] TO [public]
GRANT SELECT ON  [dbo].[PMJCJMTotals] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMJCJMTotals] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMJCJMTotals] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMJCJMTotals] TO [Viewpoint]
GO
