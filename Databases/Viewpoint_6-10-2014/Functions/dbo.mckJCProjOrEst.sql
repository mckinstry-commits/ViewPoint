SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/18/2014
-- Description:	Returns the ProjectedOrEstimated value for a provided JCCo, Contract, ThroughMth
-- =============================================
CREATE FUNCTION [dbo].[mckJCProjOrEst] 
(
	-- Add the parameters for the function here
	@JCCo bCompany, @Contract bContract, @Mth bMonth
)
RETURNS bDollar
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ProjOrEst bDollar

	-- Add the T-SQL statements to compute the return value here
	SELECT @ProjOrEst = SUM(CASE WHEN ProjMth <= @Mth THEN ProjCost  ELSE OrigEstCost END) --AS ProjectedOrEstimated
		 FROM brvJCContStat
		WHERE JCCo = @JCCo AND Contract = @Contract AND Mth <= @Mth
	-- Return the result of the function
	RETURN @ProjOrEst

END
GO
