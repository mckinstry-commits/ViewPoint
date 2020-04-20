SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/17/2014
-- Description:	Get JCIP, revenue projections values by Contract
-- =============================================
CREATE FUNCTION [dbo].[mckfnJCIPbyContract] 
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
	--DECLARE @JCCo bCompany = 101, @Contract bContract = '022814-', @Mth bMonth = '2014-09-01 00:00:00'
	-- Add the SELECT statement with parameter references here
	SELECT cm.JCCo, cm.Contract, SUM(ip.BilledAmt) AS SUMContractBilledAmt, SUM(ip.BilledTax) AS SUMContractBilledTax, SUM(ip.CurrentRetainAmt) AS SUMContractCurrentRetainAmt, SUM(ip.ProjDollars) AS SUMContractProjDollars, SUM(ip.ReceivedAmt) AS SUMContractReceivedAmt
	FROM dbo.JCIP ip 
	INNER JOIN dbo.JCCM cm ON cm.JCCo = ip.JCCo AND cm.Contract = ip.Contract
	WHERE cm.JCCo = @JCCo AND cm.Contract = @Contract AND Mth <= @Mth
	GROUP BY cm.JCCo, cm.Contract
)
GO
