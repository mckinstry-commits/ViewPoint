SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		GF 
-- Create date: 08/10/2010
-- Description:	returns a pending change order items
-- internal and contractual markup dollars.
-- =============================================
CREATE FUNCTION [dbo].[vfPMPCOItemCostTypeMUAmount] 
(
	---- Add the parameters for the function here
	@PMCo		Integer = null,
	@Project	varchar(30) = null,
	@PCOType	varchar(30) = null,
	@PCO		varchar(30) = null,
	@PCOItem	varchar(30) = null,
	@CostType	integer = null
)
RETURNS TABLE 
AS
RETURN 
(
	---- if cost type is not null, then markups are based on the estimate costs for the cost type only
	select top 100 percent case when c.RoundAmount = 'Y' 
			then isnull(Round(sum(d.EstCost) * isnull(a.IntMarkUp,0),0),0) 
			else isnull(Round(sum(d.EstCost) * isnull(a.IntMarkUp,0),2),0)
			end as 'IntMarkUpAmt',
		   case when c.RoundAmount = 'Y'
			then isnull(Round(sum((d.EstCost + Round((d.EstCost*isnull(a.IntMarkUp,0)),2))*isnull(a.ConMarkUp,0)),0),0)
			else isnull(Round(sum((d.EstCost + Round((d.EstCost*isnull(a.IntMarkUp,0)),2))*isnull(a.ConMarkUp,0)),2),0)
			end as 'ConMarkUpAmt'
	from dbo.bPMOM a
	left join dbo.bPMOL d on a.PMCo=d.PMCo and a.Project=d.Project and a.PCOType=d.PCOType
	and a.PCO=d.PCO and a.PCOItem=d.PCOItem and a.PhaseGroup=d.PhaseGroup and a.CostType=d.CostType
	left join dbo.bPMPC c on c.PMCo=a.PMCo and c.Project=a.Project and c.PhaseGroup=a.PhaseGroup and c.CostType=a.CostType
	where a.PMCo=@PMCo and a.Project=@Project and a.PCOType=@PCOType and a.PCO=@PCO
	and a.PCOItem=@PCOItem and a.CostType=@CostType
	group by a.PMCo, a.Project, a.PCOType, a.PCO, a.PCOItem, a.PhaseGroup, a.CostType, a.IntMarkUp, a.ConMarkUp, c.RoundAmount
	order by a.PMCo, a.Project, a.PCOType, a.PCO, a.PCOItem, a.PhaseGroup, a.CostType
)

GO
GRANT SELECT ON  [dbo].[vfPMPCOItemCostTypeMUAmount] TO [public]
GO
