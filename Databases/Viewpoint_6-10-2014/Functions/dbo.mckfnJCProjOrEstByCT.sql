SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/18/2014
-- Description:	Returns the Projected Or Estimated by Cost Type values for reporting purposes.
-- =============================================
CREATE FUNCTION [dbo].[mckfnJCProjOrEstByCT] 
(	
	-- Add the parameters for the function here
	@JCCo bCompany
	, @Contract bContract
	, @Mth bMonth
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT JCCo, Contract, /*Item,*/ CostType, SUM(CASE WHEN ProjMth <= @Mth THEN ProjCost  ELSE OrigEstCost END) AS ProjectedOrEstimated
		FROM brvJCContStat
		WHERE JCCo = @JCCo AND Contract = @Contract AND Mth <= @Mth
		AND CostType IS NOT NULL
	GROUP BY JCCo, Contract, CostType
)
GO
