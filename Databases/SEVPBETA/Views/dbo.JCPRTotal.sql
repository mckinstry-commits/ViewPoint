SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE view [dbo].[JCPRTotal] as
/*****************************************
* Created By:	GF 02/22/2010 - issue #136984 - committed budget for (AUS)
* Modified By:
*
* Provides a view of JC Projection Detail for JC Job Committed Budget
* showing totals for original committment, current committment, contingency, and gain/loss
*
*****************************************/

select a.JCCo, a.Job, a.Phase, a.CostType, a.Mth, a.ResTrans,
	
   		cast(isnull((select sum(p.CurrEstCost)
			from dbo.bJCCP p with (nolock)
			WHERE p.JCCo=a.JCCo AND p.Job=a.Job AND p.Phase=a.Phase AND p.CostType=a.CostType
			AND p.Mth <= a.Mth), 0)
			AS numeric(20,2)) AS RevisedBudget,
			
   		cast(isnull((select sum(b.Amount)
			from dbo.bJCPR b with (nolock)
			WHERE b.JCCo=a.JCCo AND b.Job=a.Job AND b.Phase=a.Phase AND b.CostType=a.CostType
			AND b.BudgetCode = 'COMM' AND (b.Mth < a.Mth OR (b.Mth=a.Mth AND b.ResTrans <= a.ResTrans))), 0)
			AS numeric(20,2)) AS CurrCommit,
			
   		cast(isnull((select sum(b.Amount)
			from dbo.bJCPR b with (nolock)
			WHERE b.JCCo=a.JCCo AND b.Job=a.Job AND b.Phase=a.Phase AND b.CostType=a.CostType
			AND b.BudgetCode = 'CONT' AND (b.Mth < a.Mth OR (b.Mth=a.Mth AND b.ResTrans <= a.ResTrans))), 0)
			AS numeric(20,2)) AS Contingency
	
from bJCPR a WITH (NOLOCK)
group by a.JCCo, a.Job, a.Phase, a.CostType, a.Mth, a.ResTrans, a.BudgetCode




GO
GRANT SELECT ON  [dbo].[JCPRTotal] TO [public]
GRANT INSERT ON  [dbo].[JCPRTotal] TO [public]
GRANT DELETE ON  [dbo].[JCPRTotal] TO [public]
GRANT UPDATE ON  [dbo].[JCPRTotal] TO [public]
GO
