SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****************************************/
CREATE view [dbo].[PMOICalc] as
/*****************************************
 * Created:
 * Modfied: GG - 04/10/08 - added top 100 percent and order by
 *			GF 08/10/2010 - issue #134534 markup amounts can be rounded to nearest whole dollar
 *
 *
 * Provides a view of PM Change Order Items
 * with calculations for markups. Used in
 * Used in 6.x form PMPCOSItemsMarkups. Also
 * used in SP's bspPMImportUpload, bspPMOICalcPendingAmt.
 * 
 *
*****************************************/

select top 100 percent m.PMCo,m.Project,m.PCOType,m.PCO,m.PCOItem,m.PhaseGroup,m.CostType,
			m.IntMarkUp, m.ConMarkUp, NetAmount=sum(isnull(i.EstCost,0)),
			IntMUAmt = isnull(t.IntMarkUpAmt,0), 
			ContractMUAmt = isnull(t.ConMarkUpAmt,0),
			GrossAmt = sum(isnull(EstCost,0)) + isnull(t.IntMarkUpAmt,0) + isnull(t.ConMarkUpAmt,0)
from dbo.PMOM m
join dbo.PMOMTotals t on t.PMCo=m.PMCo and t.Project=m.Project and t.PCOType=m.PCOType
and t.PCO=m.PCO and t.PCOItem=m.PCOItem and t.PhaseGroup=m.PhaseGroup and t.CostType=m.CostType
left join dbo.PMOL i on i.PMCo=m.PMCo and i.Project=m.Project and i.PCOType=m.PCOType
and i.PCO=m.PCO and i.PCOItem=m.PCOItem and i.PhaseGroup=m.PhaseGroup and i.CostType=m.CostType
group by m.PMCo,m.Project,m.PCOType,m.PCO,m.PCOItem,m.PhaseGroup,m.CostType,m.IntMarkUp, m.ConMarkUp, t.IntMarkUpAmt, t.ConMarkUpAmt
order by m.PMCo,m.Project,m.PCOType,m.PCO,m.PCOItem


----select top 100 percent m.PMCo,m.Project,m.PCOType,m.PCO,m.PCOItem,m.PhaseGroup,m.CostType,
----			IntMarkUp, ConMarkUp, NetAmount=sum(isnull(EstCost,0)),
--------#134534
----			IntMUAmt = case when c.RoundAmount = 'Y' then isnull(Round(sum(EstCost) * isnull(m.IntMarkUp,0),0),0) else isnull(Round(sum(EstCost) * isnull(m.IntMarkUp,0),2),0) end,
----			ContractMUAmt = case when c.RoundAmount = 'Y' then isnull(Round(sum((EstCost + Round((EstCost*isnull(m.IntMarkUp,0)),2))*isnull(m.ConMarkUp,0)),0),0) else isnull(Round(sum((EstCost + Round((EstCost*isnull(m.IntMarkUp,0)),2))*isnull(m.ConMarkUp,0)),2),0) end,
----			----IntMUAmt=Round(sum(isnull(EstCost,0)*IsNull(IntMarkUp,0)),2),
----			----ContractMUAmt=Round(sum((isnull(EstCost,0) + Round((isnull(EstCost,0) * IsNull(IntMarkUp,0)),2) )*IsNull(ConMarkUp,0)),2),
----			GrossAmt = sum(isnull(EstCost,0))
----					+ case when c.RoundAmount = 'Y'
----						   then Round(sum(isnull(EstCost,0) * IsNull(IntMarkUp,0)),0) + Round(sum((isnull(EstCost,0) + Round((isnull(EstCost,0) * IsNull(IntMarkUp,0)),0) )*IsNull(ConMarkUp,0)),0)
----						   else Round(sum(isnull(EstCost,0) * IsNull(IntMarkUp,0)),2) + Round(sum((isnull(EstCost,0) + Round((isnull(EstCost,0) * IsNull(IntMarkUp,0)),2) )*IsNull(ConMarkUp,0)),2)
----						   end
--------sum(isnull(EstCost,0)) + Round(sum(isnull(EstCost,0) * IsNull(IntMarkUp,0)),2)
--------			+ Round(sum((isnull(EstCost,0) + Round((isnull(EstCost,0) * IsNull(IntMarkUp,0)),2) )*IsNull(ConMarkUp,0)),2)
--------#134534
----from dbo.PMOL i with (nolock)
----join dbo.bPMOM m on i.PMCo=m.PMCo and i.Project=m.Project and i.PCOType=m.PCOType
----	and i.PCO=m.PCO and i.PCOItem=m.PCOItem and i.PhaseGroup=m.PhaseGroup and i.CostType=m.CostType
----left join dbo.bPMPC c on c.PMCo=i.PMCo and c.Project=i.Project and c.PhaseGroup=i.PhaseGroup and c.CostType=i.CostType
----group by m.PMCo,m.Project,m.PCOType,m.PCO,m.PCOItem,m.PhaseGroup,m.CostType,c.RoundAmount,i.EstCost,IntMarkUp,ConMarkUp
----order by m.PMCo,m.Project,m.PCOType,m.PCO,m.PCOItem






GO
GRANT SELECT ON  [dbo].[PMOICalc] TO [public]
GRANT INSERT ON  [dbo].[PMOICalc] TO [public]
GRANT DELETE ON  [dbo].[PMOICalc] TO [public]
GRANT UPDATE ON  [dbo].[PMOICalc] TO [public]
GO
