SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE view [dbo].[PMOIPCOTotals] as
/*****************************************
* Created:	GF 09/22/2005 6.x only
* Modfied: GG 04/01/08 - added top 100 percent and order by
*			GF 12/20/2008 - issue #129669 - addon cost based on cost type
*			GF 05/15/2010 - issue #138206 - fix for old add-ons not showing as cost
*
*
* Provides a view of PM PCO Item Totals for 6.x
* Returns PCO Revenue, PCO Phase Cost, PCO Addon Cost,
* ACO Revenue, ACO Phase Cost, ACO Addon Cost for a
* PMCo, Project, PCOType, PCO, PCOItem.
* Used to display totals in PM Pending Change Orders Form.
*
*****************************************/

select top 100 percent a.PMCo, a.Project, a.PCOType, a.PCO, a.PCOItem,
	'PCOItemRevTotal'=isnull((case a.FixedAmountYN when 'Y' then a.FixedAmount else a.PendingAmount end), 0),
	'PCOItemPhaseCost'=isnull((PCOItemPhaseCost),0),
	'PCOItemAddonCost'=isnull((PCOItemAddonCost),0),
	'PCOItemAddonTotal'=isnull((PCOItemAddonTotal),0),
	'ACOItemRevTotal'=isnull(a.ApprovedAmt,0),
	'ACOItemPhaseCost'=isnull((ACOItemPhaseCost),0),
	'ACOItemAddonCost'=isnull((ACOItemAddonCost),0),
	'ACOItemAddonTotal'=isnull((ACOItemAddonTotal),0),
	'PCOMarkUpTotal'=isnull((PCOMarkUpTotal),0),
	'PCOItemNetAddonTotal'=isnull((PCOItemNetAddonTotal),0),
	'PCOItemSubAddonTotal'=isnull((PCOItemSubAddonTotal),0),
	'PCOItemGrandAddonTotal'=isnull((PCOItemGrandAddonTotal),0)
from dbo.bPMOI a with (nolock)
	---- pending phase cost
	left join (select d.PMCo, d.Project, d.PCOType, d.PCO, d.PCOItem, PCOItemPhaseCost=isnull(sum(d.EstCost),0)
    		from bPMOL d with (nolock) where d.PCO is not null and d.PCOItem is not null
    		group by d.PMCo, d.Project, d.PCOType, d.PCO, d.PCOItem)
   	pcocost on pcocost.PMCo=a.PMCo and pcocost.Project=a.Project and pcocost.PCOType=a.PCOType and pcocost.PCO=a.PCO and pcocost.PCOItem=a.PCOItem
	---- pending markup total
	left join (select m.PMCo, m.Project, m.PCOType, m.PCO, m.PCOItem, PCOMarkUpTotal = Round(sum(m.IntMarkUpAmt) + sum(m.ConMarkUpAmt),2)
		from PMOMTotals m with (nolock) where m.PCO is not null and m.PCOItem is not null
		group by m.PMCo, m.Project, m.PCOType, m.PCO, m.PCOItem)
	pcomarkup on pcomarkup.PMCo=a.PMCo and pcomarkup.Project=a.Project and pcomarkup.PCOType=a.PCOType and pcomarkup.PCO=a.PCO and pcomarkup.PCOItem=a.PCOItem

	---- pending addon cost - addon cost type must not be empty to be considered cost
	left join (select e.PMCo, e.Project, e.PCOType, e.PCO, e.PCOItem, PCOItemAddonCost=isnull(sum(f.AddOnAmount),0)
    		from bPMOA f with (nolock)
			join bPMOI e with (nolock) on e.PMCo=f.PMCo and e.Project=f.Project
			and e.PCOType=f.PCOType and e.PCO=f.PCO and e.PCOItem=f.PCOItem
			join bPMPA g with (nolock) on g.PMCo=f.PMCo and g.Project=f.Project
			and g.AddOn=f.AddOn and g.CostType is not null
			where e.PCO is not null and e.PCOItem is not null ----and e.ACOItem is null
			----#138206
			and not exists(select 1 from dbo.bPMOL l with (nolock) where l.PMCo=e.PMCo
					and l.Project=e.Project and l.PCOType=e.PCOType and l.PCO=e.PCO
					and l.PCOItem=e.PCOItem and l.CostType=g.CostType and l.CreatedFromAddOn='Y')
			----#138206
    		group by e.PMCo, e.Project, e.PCOType, e.PCO, e.PCOItem)
   	pcocostadd on pcocostadd.PMCo=a.PMCo and pcocostadd.Project=a.Project and pcocostadd.PCOType=a.PCOType and pcocostadd.PCO=a.PCO and pcocostadd.PCOItem=a.PCOItem
   	
	---- pending addon total - same as above except ignore addon costtype
	left join (select e.PMCo, e.Project, e.PCOType, e.PCO, e.PCOItem, PCOItemAddonTotal=isnull(sum(f.AddOnAmount),0)
    		from bPMOA f with (nolock)
			join bPMOI e with (nolock) on e.PMCo=f.PMCo and e.Project=f.Project and e.PCOType=f.PCOType and e.PCO=f.PCO and e.PCOItem=f.PCOItem
			join bPMPA g with (nolock) on g.PMCo=f.PMCo and g.Project=f.Project and g.AddOn=f.AddOn
			where e.PCO is not null and e.PCOItem is not null
    		group by e.PMCo, e.Project, e.PCOType, e.PCO, e.PCOItem)
   	pcoaddontotal on pcoaddontotal.PMCo=a.PMCo and pcoaddontotal.Project=a.Project and pcoaddontotal.PCOType=a.PCOType and pcoaddontotal.PCO=a.PCO and pcoaddontotal.PCOItem=a.PCOItem
	---- pending net addon total
	left join (select e.PMCo, e.Project, e.PCOType, e.PCO, e.PCOItem, PCOItemNetAddonTotal=isnull(sum(f.AddOnAmount),0)
    		from bPMOA f with (nolock)
			join bPMOI e with (nolock) on e.PMCo=f.PMCo and e.Project=f.Project and e.PCOType=f.PCOType and e.PCO=f.PCO and e.PCOItem=f.PCOItem
			join bPMPA g with (nolock) on g.PMCo=f.PMCo and g.Project=f.Project and g.AddOn=f.AddOn
			where e.PCO is not null and e.PCOItem is not null and f.TotalType='N'
    		group by e.PMCo, e.Project, e.PCOType, e.PCO, e.PCOItem)
   	pconetaddontotal on pconetaddontotal.PMCo=a.PMCo and pconetaddontotal.Project=a.Project and pconetaddontotal.PCOType=a.PCOType and pconetaddontotal.PCO=a.PCO and pconetaddontotal.PCOItem=a.PCOItem
	---- pending subtotal addon total
	left join (select e.PMCo, e.Project, e.PCOType, e.PCO, e.PCOItem, PCOItemSubAddonTotal=isnull(sum(f.AddOnAmount),0)
    		from bPMOA f with (nolock)
			join bPMOI e with (nolock) on e.PMCo=f.PMCo and e.Project=f.Project and e.PCOType=f.PCOType and e.PCO=f.PCO and e.PCOItem=f.PCOItem
			join bPMPA g with (nolock) on g.PMCo=f.PMCo and g.Project=f.Project and g.AddOn=f.AddOn
			where e.PCO is not null and e.PCOItem is not null and f.TotalType='S'
    		group by e.PMCo, e.Project, e.PCOType, e.PCO, e.PCOItem)
   	pcosubaddontotal on pcosubaddontotal.PMCo=a.PMCo and pcosubaddontotal.Project=a.Project and pcosubaddontotal.PCOType=a.PCOType and pcosubaddontotal.PCO=a.PCO and pcosubaddontotal.PCOItem=a.PCOItem
	---- pending grand total addon total
	left join (select e.PMCo, e.Project, e.PCOType, e.PCO, e.PCOItem, PCOItemGrandAddonTotal=isnull(sum(f.AddOnAmount),0)
    		from bPMOA f with (nolock)
			join bPMOI e with (nolock) on e.PMCo=f.PMCo and e.Project=f.Project and e.PCOType=f.PCOType and e.PCO=f.PCO and e.PCOItem=f.PCOItem
			join bPMPA g with (nolock) on g.PMCo=f.PMCo and g.Project=f.Project and g.AddOn=f.AddOn
			where e.PCO is not null and e.PCOItem is not null and f.TotalType='G'
    		group by e.PMCo, e.Project, e.PCOType, e.PCO, e.PCOItem)
   	pcograndaddontotal on pcograndaddontotal.PMCo=a.PMCo and pcograndaddontotal.Project=a.Project and pcograndaddontotal.PCOType=a.PCOType and pcograndaddontotal.PCO=a.PCO and pcograndaddontotal.PCOItem=a.PCOItem
	---- approved phase cost
	left join (select h.PMCo, h.Project, h.PCOType, h.PCO, h.PCOItem, ACOItemPhaseCost=isnull(sum(h.EstCost),0)
    		from bPMOL h with (nolock) where h.ACO is not null and h.ACOItem is not null
    		group by h.PMCo, h.Project, h.PCOType, h.PCO, h.PCOItem)
   	acocost on acocost.PMCo=a.PMCo and acocost.Project=a.Project and acocost.PCOType=a.PCOType and acocost.PCO=a.PCO and acocost.PCOItem=a.PCOItem
   	
	---- approved addon cost - addon cost type must not be empty to be considered cost
	left join (select j.PMCo, j.Project, j.PCOType, j.PCO, j.PCOItem, ACOItemAddonCost=isnull(sum(i.AddOnAmount),0)
    		from bPMOA i with (nolock)
			join bPMOI j with (nolock) on j.PMCo=i.PMCo and j.Project=i.Project
			and j.PCOType=i.PCOType and j.PCO=i.PCO and j.PCOItem=i.PCOItem and isnull(j.ACO,'') <> ''
			join bPMPA k with (nolock) on k.PMCo=i.PMCo and k.Project=i.Project
			and k.AddOn=i.AddOn and k.CostType is not null
			where j.ACO is not null and j.ACOItem is not null
			----#138206
			and not exists(select 1 from dbo.bPMOL l with (nolock) where l.PMCo=j.PMCo
					and l.Project=j.Project and l.PCOType=j.PCOType and l.PCO=j.PCO
					and l.PCOItem=j.PCOItem and l.CostType=k.CostType and l.CreatedFromAddOn='Y')
			----#138206
    		group by j.PMCo, j.Project, j.PCOType, j.PCO, j.PCOItem)
   	acocostadd on acocostadd.PMCo=a.PMCo and acocostadd.Project=a.Project and acocostadd.PCOType=a.PCOType and acocostadd.PCO=a.PCO and acocostadd.PCOItem=a.PCOItem
   	
	---- approved addon total - same as above except ignore addon cost type
	left join (select j.PMCo, j.Project, j.PCOType, j.PCO, j.PCOItem, ACOItemAddonTotal=isnull(sum(i.AddOnAmount),0)
    		from bPMOA i with (nolock)
			join bPMOI j with (nolock) on j.PMCo=i.PMCo and j.Project=i.Project and j.PCOType=i.PCOType and j.PCO=i.PCO and j.PCOItem=i.PCOItem and isnull(j.ACO,'') <> ''
			join bPMPA k with (nolock) on k.PMCo=i.PMCo and k.Project=i.Project and k.AddOn=i.AddOn
			where j.ACO is not null and j.ACOItem is not null
    		group by j.PMCo, j.Project, j.PCOType, j.PCO, j.PCOItem)
   	acoaddontotal on acoaddontotal.PMCo=a.PMCo and acoaddontotal.Project=a.Project and acoaddontotal.PCOType=a.PCOType and acoaddontotal.PCO=a.PCO and acoaddontotal.PCOItem=a.PCOItem
where a.PCO is not null and a.PCOItem is not null
group by a.PMCo, a.Project, a.PCOType, a.PCO, a.PCOItem, a.FixedAmount, a.FixedAmountYN, a.PendingAmount, a.ApprovedAmt,
	PCOItemPhaseCost, PCOItemAddonCost, PCOItemAddonTotal, ACOItemPhaseCost, ACOItemAddonCost, ACOItemAddonTotal,
	PCOMarkUpTotal, PCOItemNetAddonTotal, PCOItemSubAddonTotal, PCOItemGrandAddonTotal
order by a.PMCo, a.Project, a.PCOType, a.PCO, a.PCOItem





GO
GRANT SELECT ON  [dbo].[PMOIPCOTotals] TO [public]
GRANT INSERT ON  [dbo].[PMOIPCOTotals] TO [public]
GRANT DELETE ON  [dbo].[PMOIPCOTotals] TO [public]
GRANT UPDATE ON  [dbo].[PMOIPCOTotals] TO [public]
GRANT SELECT ON  [dbo].[PMOIPCOTotals] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMOIPCOTotals] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMOIPCOTotals] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMOIPCOTotals] TO [Viewpoint]
GO
