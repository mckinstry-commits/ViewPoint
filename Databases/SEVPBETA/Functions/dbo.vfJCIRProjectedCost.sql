SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vfJCIRProjectedCost](@Company int, @Mth smalldatetime, @Contract varchar(30), @Item varchar(30))
RETURNS TABLE
AS
/********************************************
* Created By:	GF 04/20/2010 - issue #139161
* Modified By:
*
* returns projected cost for a contract and item for use in JCIRTotals - JC Revenue Projections.
*
********************************************/


--RETURN (SELECT sum(c.ProjCost) as 'ProjCost'
--			FROM dbo.bJCCP c with (nolock)
--			join dbo.bJCJP p with (nolock) on p.JCCo=c.JCCo and p.Job=c.Job and p.Phase=c.Phase and p.Item=@Item
--			join dbo.bJCJM j with (nolock) on j.JCCo=c.JCCo and j.Job=c.Job
--			where c.JCCo=@Company and c.Mth <= @Mth and c.Job=j.Job and j.JCCo=@Company 
--			and j.Contract=@Contract and p.JCCo=@Company and p.Job=j.Job and p.Item=@Item)

RETURN (SELECT sum(c.ProjCost) as 'ProjCost'
		FROM dbo.bJCJM j
		JOIN dbo.bJCJP p ON p.JCCo=j.JCCo AND p.Job=j.Job AND p.Contract=j.Contract
		JOIN dbo.bJCCP c ON c.JCCo=j.JCCo AND c.Job=j.Job AND c.PhaseGroup=p.PhaseGroup AND c.Phase=p.Phase
		WHERE j.JCCo = @Company AND j.Contract = @Contract AND p.Item= @Item AND c.Mth <= @Mth)
GO
GRANT SELECT ON  [dbo].[vfJCIRProjectedCost] TO [public]
GO
