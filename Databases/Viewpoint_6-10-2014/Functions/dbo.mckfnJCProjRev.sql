SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/17/2014
-- Description:	Returns Revenue Projections by JCCo and Contract
-- =============================================
CREATE FUNCTION [dbo].[mckfnJCProjRev] 
(	
	-- Add the parameters for the function here
	@JCCo bCompany, 
	@Contract bContract
    , @Mth bMonth
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT r.JCCo AS JCCo, r.Contract AS Contract,SUM(r.ProjDollars) AS ProjRev, SUM(r.EstRevenue_Mth) AS EstRevMth
			FROM dbo.vrvJCIPProjRev r
			WHERE r.JCCo = @JCCo AND r.Contract = @Contract AND (r.Mth <= @Mth OR @Mth IS NULL)
			GROUP BY r.JCCo, r.Contract
)
GO
