SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






/*****************************************/
CREATE VIEW [dbo].[PMOPTotals]  AS 
/*****************************************
* Created:	GF 09/22/2005 6.x only
* Modfied:	GG 04/10/08 - added top 100 percent and order by
*			GF 12/20/2008 - issue #129669 - addon cost based on cost type 
*			GF 05/15/2010 - issue #138206 - fix for old add-ons not showing as cost
*			JG 03/19/2011 - TK-03172 - Added PCOPhasePurchCost
*			GF 03/29/2011 - TK-03298
*
*
* Provides a view of PM PCO Totals for 6.x
* Returns PCO Revenue, PCO Phase Cost, PCO Addon Cost,
* ACO Revenue, ACO Phase Cost, ACO Addon Cost for a
* PMCo, Project, PCOType, PCO. Used to display totals
* in PM Pending Change Orders Form.
*
*****************************************/

select top 100 percent a.PMCo, a.Project, a.PCOType, a.PCO, a.KeyID,
	'PCORevTotal'=isnull((PCORevTotal),0),
	'PCOPhaseCost'=isnull((PCOPhaseCost),0),
	'PCOAddonCost'=isnull((PCOAddonCost),0),
	'ACORevTotal'=isnull((ACORevTotal),0),
	'ACOPhaseCost'=isnull((ACOPhaseCost),0),
	'ACOAddonCost'=isnull((ACOAddonCost),0),
	'PCOPhasePurchCost'=ISNULL((PCOPhasePurchCost),0),
	'PCOMarkUpTotal'=ISNULL((PCOMarkUpTotal),0),
	'PCOAddonTotal'=ISNULL((PCOAddonTotal),0)
from dbo.bPMOP a with (nolock)
	/* PCOMarkUpTotal */	
	left join (select t.PMCo, t.Project, t.PCOType, t.PCO, 
			PCOMarkUpTotal=isnull(sum(t.PCOMarkUpTotal),0),
			PCOAddonTotal=isnull(sum(t.PCOItemAddonTotal),0)
    		from PMOIPCOTotals t with (nolock) where t.PCO is not null 
    		group by t.PMCo, t.Project, t.PCOType, t.PCO)
	pcoitemtot on pcoitemtot.PMCo=a.PMCo and pcoitemtot.Project=a.Project and pcoitemtot.PCOType=a.PCOType and pcoitemtot.PCO=a.PCO
	/* pending revenue */
	left join (select c.PMCo, c.Project, c.PCOType, c.PCO, 
			PCORevTotal=isnull(sum(case c.FixedAmountYN when 'Y' then c.FixedAmount else c.PendingAmount end),0)
    		from bPMOI c with (nolock) where c.PCO is not null 
    		group by c.PMCo, c.Project, c.PCOType, c.PCO)
   	pco on pco.PMCo=a.PMCo and pco.Project=a.Project and pco.PCOType=a.PCOType and pco.PCO=a.PCO
	/* pending phase cost and pending phase purchase cost */
	left join (select d.PMCo, d.Project, d.PCOType, d.PCO, PCOPhaseCost=isnull(sum(d.EstCost),0), PCOPhasePurchCost=isnull(sum(d.PurchaseAmt),0)
    		from bPMOL d with (nolock) where d.PCO is not null 
    		group by d.PMCo, d.Project, d.PCOType, d.PCO)
   	pcocost on pcocost.PMCo=a.PMCo and pcocost.Project=a.Project and pcocost.PCOType=a.PCOType and pcocost.PCO=a.PCO
	/* pending addon cost */
	left join (select e.PMCo, e.Project, e.PCOType, e.PCO, PCOAddonCost=isnull(sum(f.AddOnAmount),0)
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
    		group by e.PMCo, e.Project, e.PCOType, e.PCO)
   	pcocostadd on pcocostadd.PMCo=a.PMCo and pcocostadd.Project=a.Project and pcocostadd.PCOType=a.PCOType and pcocostadd.PCO=a.PCO
	/* approved revenue */
	left join (select b.PMCo, b.Project, b.PCOType, b.PCO, ACORevTotal=isnull(sum(b.ApprovedAmt),0)
			from bPMOI b with (nolock) where b.ACO is not null
			group by b.PMCo, b.Project, b.PCOType, b.PCO)
	aco on aco.PMCo=a.PMCo and aco.Project=a.Project and aco.PCOType=a.PCOType and aco.PCO=a.PCO
	/* approved phase cost */
	left join (select h.PMCo, h.Project, h.PCOType, h.PCO, ACOPhaseCost=isnull(sum(h.EstCost),0)
    		from bPMOL h with (nolock) where h.ACO is not null 
    		group by h.PMCo, h.Project, h.PCOType, h.PCO)
   	acocost on acocost.PMCo=a.PMCo and acocost.Project=a.Project and acocost.PCOType=a.PCOType and acocost.PCO=a.PCO
   	
	/* approved addon cost */
	left join (select j.PMCo, j.Project, j.PCOType, j.PCO, ACOAddonCost=isnull(sum(i.AddOnAmount),0)
    		from bPMOA i with (nolock)
			join bPMOI j with (nolock) on j.PMCo=i.PMCo and j.Project=i.Project
			and j.PCOType=i.PCOType and j.PCO=i.PCO and j.PCOItem=i.PCOItem and isnull(j.ACO,'') <> ''
			join bPMPA k with (nolock) on k.PMCo=i.PMCo and k.Project=i.Project
			and k.AddOn=i.AddOn and k.CostType is not null
			where j.PCO is not null
			----#138206
			and not exists(select 1 from dbo.bPMOL l with (nolock) where l.PMCo=j.PMCo
						and l.Project=j.Project and l.PCOType=j.PCOType and l.PCO=j.PCO
						and l.PCOItem=j.PCOItem and l.CostType=k.CostType and l.CreatedFromAddOn='Y')
			----#138206
    		group by j.PMCo, j.Project, j.PCOType, j.PCO)
   	acocostadd on acocostadd.PMCo=a.PMCo and acocostadd.Project=a.Project and acocostadd.PCOType=a.PCOType and acocostadd.PCO=a.PCO
   	
where a.PCO is not null
group by a.PMCo, a.Project, a.PCOType, a.PCO, a.KeyID, PCORevTotal, ACORevTotal, PCOPhaseCost, PCOAddonCost, ACOPhaseCost, ACOAddonCost, PCOPhasePurchCost, PCOMarkUpTotal, PCOAddonTotal
order by a.PMCo, a.Project, a.PCOType, a.PCO
















GO
GRANT SELECT ON  [dbo].[PMOPTotals] TO [public]
GRANT INSERT ON  [dbo].[PMOPTotals] TO [public]
GRANT DELETE ON  [dbo].[PMOPTotals] TO [public]
GRANT UPDATE ON  [dbo].[PMOPTotals] TO [public]
GO
