SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







/****************************************/
CREATE view [dbo].[PMOMTotals] as 
/*****************************************
* Created:	GF 04/03/2006 (6.x only)
* Modfied: GG 04/10/08 - added top 100 percent and order by
*			GF 08/09/2010 - issue #134534 markup amounts can be rounded to nearest whole dollar
*
*
* Provides a view of PM Change Order Item
* markups (PMOM) with Internal Markup Amount
* and Contractual Markup Amount.
* For use in the PCO item forms.
*
* THIS VIEW IS USED IN PM CHANGE ORDER REQUEST REPORTS
* DO NOT REMOVE OR CHANGE COLUMNS NAMES WITHOUT CHECKING WITH RP DEVEL.
*
*****************************************/

with EstCost (PMCo, Project, PCOType, PCO, PCOItem, PhaseGroup, CostType, EstCost) as
	(select PMCo, Project, PCOType, PCO, PCOItem, PhaseGroup, CostType,
		sum(EstCost) from bPMOL with (nolock)
		group by PMCo, Project, PCOType, PCO, PCOItem, PhaseGroup, CostType)
select top 100 percent a.PMCo, a.Project, a.PCOType, a.PCO, a.PCOItem, a.PhaseGroup, a.CostType, a.IntMarkUp, a.ConMarkUp,
----#134534
		'IntMarkUpAmt'= case when c.RoundAmount = 'Y' then isnull(Round(sum(d.EstCost) * isnull(a.IntMarkUp,0),0),0) else isnull(Round(sum(d.EstCost) * isnull(a.IntMarkUp,0),2),0) end,
		'ConMarkUpAmt'= case when c.RoundAmount = 'Y' then isnull(Round(sum((d.EstCost + Round((d.EstCost*isnull(a.IntMarkUp,0)),2))*isnull(a.ConMarkUp,0)),0),0) else isnull(Round(sum((d.EstCost + Round((d.EstCost*isnull(a.IntMarkUp,0)),2))*isnull(a.ConMarkUp,0)),2),0) end
----#134534
from dbo.bPMOM a
left join EstCost d on a.PMCo=d.PMCo and a.Project=d.Project and a.PCOType=d.PCOType
and a.PCO=d.PCO and a.PCOItem=d.PCOItem and a.PhaseGroup=d.PhaseGroup and a.CostType=d.CostType
left join dbo.PMPC c on c.PMCo=a.PMCo and c.Project=a.Project and c.PhaseGroup=a.PhaseGroup and c.CostType=a.CostType
group by a.PMCo, a.Project, a.PCOType, a.PCO, a.PCOItem, a.PhaseGroup, a.CostType, a.IntMarkUp, a.ConMarkUp, c.RoundAmount
order by a.PMCo, a.Project, a.PCOType, a.PCO, a.PCOItem, a.PhaseGroup, a.CostType










GO
GRANT SELECT ON  [dbo].[PMOMTotals] TO [public]
GRANT INSERT ON  [dbo].[PMOMTotals] TO [public]
GRANT DELETE ON  [dbo].[PMOMTotals] TO [public]
GRANT UPDATE ON  [dbo].[PMOMTotals] TO [public]
GO
