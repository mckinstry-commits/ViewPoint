SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[PMOHTotals]  AS 
/*****************************************
* Created:	GF 11/15/2005 6.x only
* Modfied:	GG 04/10/08 - added top 100 percent and order by
*			GF 12/20/2008 - issue #129669 - addon cost based on cost type 
*			GF 05/15/2010 - issue #138206 - fix for old add-ons not showing as cost
*			GF 02/28/2011 - issue #143378 - do not calculate approved add-ons from PCO
*
*
* Provides a view of PM ACO Totals for 6.x
* Returns PCO Revenue, PCO Phase Cost, PCO Addon Cost,
* ACO Revenue, ACO Phase Cost, ACO Addon Cost for a
* PMCo, Project, ACO. Used to display totals
* in PM Approved Change Orders Form.
*
*****************************************/

select top 100 percent a.PMCo, a.Project, a.ACO, 
	'PCORevTotal'=isnull((PCORevTotal),0),
	'PCOPhaseCost'=isnull((PCOPhaseCost),0),
	'PCOAddonCost'=isnull((PCOAddonCost),0),
	'ACORevTotal'=isnull((ACORevTotal),0),
	'ACOPhaseCost'=isnull((ACOPhaseCost),0),
	'ACOAddonCost'=isnull((ACOAddonCost),0)
from dbo.bPMOH a with (nolock)
	/* approved revenue */
	left join (select b.PMCo, b.Project, b.ACO, ACORevTotal=isnull(sum(b.ApprovedAmt),0)
			from bPMOI b with (nolock) where b.ACO is not null
			group by b.PMCo, b.Project, b.ACO)
	aco on aco.PMCo=a.PMCo and aco.Project=a.Project and aco.ACO=a.ACO
	/* approved phase cost */
	left join (select h.PMCo, h.Project, h.ACO, ACOPhaseCost=isnull(sum(h.EstCost),0)
    		from bPMOL h with (nolock) where h.ACO is not null 
    		group by h.PMCo, h.Project, h.ACO)
   	acocost on acocost.PMCo=a.PMCo and acocost.Project=a.Project and acocost.ACO=a.ACO
	/* approved addon cost */
	left join (select j.PMCo, j.Project, j.ACO, ACOAddonCost=isnull(sum(i.AddOnAmount),0)
    		from bPMOA i with (nolock)
			join bPMOI j with (nolock) on j.PMCo=i.PMCo and j.Project=i.Project and j.PCOType=i.PCOType
			and j.PCO=i.PCO and j.PCOItem=i.PCOItem and isnull(j.ACO,'') <> ''
			join bPMPA k with (nolock) on k.PMCo=i.PMCo and k.Project=i.Project
			----#138206
			and k.AddOn=i.AddOn and k.CostType is not NULL
			----#143378
			WHERE 1=2
			--where j.PCO is not null and not exists(select 1 from dbo.bPMOL l with (nolock) where l.PMCo=j.PMCo
			--		and l.Project=j.Project and l.PCOType=j.PCOType and l.PCO=j.PCO
			--		and l.PCOItem=j.PCOItem and l.CostType=k.CostType and l.CreatedFromAddOn='Y')
			----#138206
			----#143378
    		group by j.PMCo, j.Project, j.ACO)
   	acocostadd on acocostadd.PMCo=a.PMCo and acocostadd.Project=a.Project and acocostadd.ACO=a.ACO
   	
   	
	/* pending revenue */
	left join (select c.PMCo, c.Project, c.ACO, 
			PCORevTotal=isnull(sum(case c.FixedAmountYN when 'Y' then c.FixedAmount else c.PendingAmount end),0)
    		from bPMOI c with (nolock) where c.PCO is not null
    		group by c.PMCo, c.Project, c.ACO)
   	pco on pco.PMCo=a.PMCo and pco.Project=a.Project and pco.ACO=a.ACO
	/* pending phase cost */
	left join (select d.PMCo, d.Project, d.ACO, PCOPhaseCost=isnull(sum(d.EstCost),0)
    		from bPMOL d with (nolock) where d.PCO is not null 
    		group by d.PMCo, d.Project, d.ACO)
   	pcocost on pcocost.PMCo=a.PMCo and pcocost.Project=a.Project and pcocost.ACO=a.ACO
	/* pending addon cost */
	left join (select e.PMCo, e.Project, e.ACO, PCOAddonCost=isnull(sum(f.AddOnAmount),0)
    		from bPMOA f with (nolock)
			join bPMOI e with (nolock) on e.PMCo=f.PMCo and e.Project=f.Project
			and e.PCOType=f.PCOType and e.PCO=f.PCO and e.PCOItem=f.PCOItem
			join bPMPA g with (nolock) on g.PMCo=f.PMCo and g.Project=f.Project
			and g.AddOn=f.AddOn and g.CostType is not null
			----#138206
			where e.PCO is not null ----and e.ACOItem is null
			and not exists(select 1 from dbo.bPMOL l with (nolock) where l.PMCo=e.PMCo
						and l.Project=e.Project and l.PCOType=e.PCOType and l.PCO=e.PCO
						and l.PCOItem=e.PCOItem and l.CostType=g.CostType and l.CreatedFromAddOn='Y')
			----#138206
    		group by e.PMCo, e.Project, e.ACO)
   	pcocostadd on pcocostadd.PMCo=a.PMCo and pcocostadd.Project=a.Project and pcocostadd.ACO=a.ACO
   	
where a.ACO is not null
group by a.PMCo, a.Project, a.ACO, ACORevTotal, ACOPhaseCost, ACOAddonCost, PCORevTotal, PCOPhaseCost, PCOAddonCost
order by a.PMCo, a.Project, a.ACO





GO
GRANT SELECT ON  [dbo].[PMOHTotals] TO [public]
GRANT INSERT ON  [dbo].[PMOHTotals] TO [public]
GRANT DELETE ON  [dbo].[PMOHTotals] TO [public]
GRANT UPDATE ON  [dbo].[PMOHTotals] TO [public]
GRANT SELECT ON  [dbo].[PMOHTotals] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMOHTotals] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMOHTotals] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMOHTotals] TO [Viewpoint]
GO
