SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/****************************************/
CREATE view [dbo].[PMOPTotalsOnly] as
/*****************************************
* Created:	GF 09/22/2005 6.x only
* Modfied:	GG 04/10/08 - added top 100 percent and order by
*			GF 11/10/2008 - issue #129664 use new view PMOPTotalsOnly for PCO Side (not include ACO)
*			GF 12/20/2008 - issue #129669 - addon cost based on cost type
*			GF 03/28/2011 - TK-03289 add key id
*
*
* Provides a view of PM PCO Totals Only (NO ACO) for 6.x
* Returns PCO Revenue, PCO Phase Cost, PCO Addon Cost,
* for a PMCo, Project, PCOType, PCO. Used to display totals
* in PM Change Orders Form.
*
*****************************************/

select top 100 percent a.PMCo, a.Project, a.PCOType, a.PCO, a.KeyID,
	'PCORevTotal'=isnull((PCORevTotal),0),
	'PCOPhaseCost'=isnull((PCOPhaseCost),0),
	'PCOAddonCost'=isnull((PCOAddonCost),0)
from dbo.bPMOP a with (nolock)
	/* pending revenue */
	left join (select c.PMCo, c.Project, c.PCOType, c.PCO, 
			PCORevTotal=isnull(sum(case c.FixedAmountYN when 'Y' then c.FixedAmount else c.PendingAmount end),0)
    		from bPMOI c with (nolock) where c.PCO is not null and isnull(c.ACOItem,'') = ''
    		group by c.PMCo, c.Project, c.PCOType, c.PCO)
   	pco on pco.PMCo=a.PMCo and pco.Project=a.Project and pco.PCOType=a.PCOType and pco.PCO=a.PCO
	/* pending phase cost */
	left join (select d.PMCo, d.Project, d.PCOType, d.PCO, PCOPhaseCost=isnull(sum(d.EstCost),0)
    		from bPMOL d with (nolock) where d.PCO is not null and isnull(d.ACOItem,'') = ''
    		group by d.PMCo, d.Project, d.PCOType, d.PCO)
   	pcocost on pcocost.PMCo=a.PMCo and pcocost.Project=a.Project and pcocost.PCOType=a.PCOType and pcocost.PCO=a.PCO
	/* pending addon cost */
	left join (select e.PMCo, e.Project, e.PCOType, e.PCO, PCOAddonCost=isnull(sum(f.AddOnAmount),0)
    		from bPMOA f with (nolock)
			join bPMOI e with (nolock) on e.PMCo=f.PMCo and e.Project=f.Project
			and e.PCOType=f.PCOType and e.PCO=f.PCO and e.PCOItem=f.PCOItem
			join bPMPA g with (nolock) on g.PMCo=f.PMCo and g.Project=f.Project
			and g.AddOn=f.AddOn and g.CostType is not null
			where e.PCO is not null and isnull(e.ACOItem,'') = '' and f.RevACOItemId is null
    		group by e.PMCo, e.Project, e.PCOType, e.PCO)
   	pcocostadd on pcocostadd.PMCo=a.PMCo and pcocostadd.Project=a.Project and pcocostadd.PCOType=a.PCOType and pcocostadd.PCO=a.PCO

where a.PCO is not null
group by a.PMCo, a.Project, a.PCOType, a.PCO, PCORevTotal, PCOPhaseCost, PCOAddonCost, a.KeyID
order by a.PMCo, a.Project, a.PCOType, a.PCO










GO
GRANT SELECT ON  [dbo].[PMOPTotalsOnly] TO [public]
GRANT INSERT ON  [dbo].[PMOPTotalsOnly] TO [public]
GRANT DELETE ON  [dbo].[PMOPTotalsOnly] TO [public]
GRANT UPDATE ON  [dbo].[PMOPTotalsOnly] TO [public]
GO
