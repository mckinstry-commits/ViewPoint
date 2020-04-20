SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[mfnGetWIPMaster]
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				bContract
,	@inIsLocked				bYN
,	@inExcludeWorkStream	varchar(255)
,	@inExcludeRevenueType   varchar(255)
)
RETURNS TABLE 
AS 
RETURN
SELECT 
	rev.JCCo					--bCompany		null
,	rev.Contract				--bContract		null
,	rev.ContractDesc			--VARCHAR(60)			null
,	rev.IsLocked				--bYN				null
,	rev.RevenueType				--varchar(10)		null
,	rev.RevenueTypeName			--VARCHAR(60)			null
,	rev.ContractStatus			--varchar(10)		null
,	rev.ContractStatusDesc		--VARCHAR(60)			null
,	rev.GLDepartment			--VARCHAR(4)		null
,	rev.GLDepartmentName		--VARCHAR(60)			null
,	rev.POC						--bEmployee		null
,	rev.POCName					--VARCHAR(60)			null
,	rev.OrigContractAmt			--decimal(18,2)	null
,	rev.CurrContractAmt			--decimal(18,2)	null	
,	rev.ProjContractAmt			--decimal(18,2)	null	
,	rev.RevenueIsOverride		--bYN				null
,	rev.RevenueOverridePercent	--decimal(8,3)	null
,	rev.RevenueOverrideAmount	--decimal(8,3)	null
,	rev.OROrigContractAmt		--decimal(18,2)	null		
,	rev.ORCurrContractAmt		--decimal(18,2)	null		
,	rev.ORProjContractAmt		--decimal(18,2)	null		
,	rev.BilledAmt				--decimal(18,2)	NULL
,	COALESCE(cost.OriginalCost,0.00) AS OriginalCost			--decimal(18,2)	null
,	COALESCE(cost.CurrentCost,0.00)	AS CurrentCost		--decimal(18,2)	null	
,	COALESCE(cost.ProjectedCost	,0.00) AS ProjectedCost			--decimal(18,2)	null	
,	COALESCE(cost.CostIsOverride,'N') AS CostIsOverride			--bYN				null
,	COALESCE(cost.CostOverridePercent,1.00) AS CostOverridePercent	--decimal(8,3)	null
,	COALESCE(cost.CostOverrideAmount,0.00) AS CostOverrideAmount	--decimal(8,3)	null
,	COALESCE(cost.OROriginalCost,0.00) AS OROriginalCost	 		--decimal(18,2)	null		
,	COALESCE(cost.ORCurrentCost,0.00) AS ORCurrentCost			--decimal(18,2)	null		
,	COALESCE(cost.ORProjectedCost,0.00) AS ORProjectedCost		--decimal(18,2)	null	
,	COALESCE(rev.ThroughMonth,cost.ThroughMonth) AS ThroughMonth--			SMALLDATETIME	null
,	COALESCE('REV ' + rev.Note,'') + ' : ' + COALESCE('COST ' + cost.Note,'') AS Note	--VARCHAR(2000)	null	
,	COALESCE(cost.ExcludeWorkstreams,@inExcludeWorkStream) AS ExcludeWorkstreams		--VARCHAR(255)	NULL
,	COALESCE(cost.mckEstCostAtCompletion,0) AS mckEstCostAtCompletion		--decimal(18,2)	NULL
,	COALESCE(cost.mckActualCost,0) AS mckActualCost			--decimal(18,2)	NULL
,	COALESCE(cost.mckEstCostToComplete,0) AS mckEstCostToComplete		--decimal(18,2)	NULL
,	COALESCE(cost.mckRevenuePercentComplete,0) AS mckRevenuePercentComplete	--DECIMAL(8,3)	null
,	dbo.mfnGetPercentComplete(
		rev.JCCo						--tinyint
	,	@inMonth						--smalldatetime
	,	rev.Contract					--	bContract	
	,	@inIsLocked						--bYN
	,	@inExcludeWorkStream			--varchar(255)
	,	@inExcludeRevenueType			--varchar(255)
	,	COALESCE(cost.CurrentCost,0.00)			--decimal(18,2)	
	,	COALESCE(cost.ProjectedCost	,0.00)	--decimal(18,2)	
	,	COALESCE(cost.ORProjectedCost,0.00)	--decimal(18,2)	
	) as mckAdjRevenuePercentComplete
,	rev.mckETCContractValue				--decimal(18,2)	null	
,	rev.mckBilledToDate					--decimal(18,2)	null
FROM 
	dbo.mfnGetWIPRevenue(@inCompany,@inMonth,@inContract,@inIsLocked,@inExcludeWorkStream,@inExcludeRevenueType) rev LEFT OUTER JOIN
	dbo.mfnGetWIPCost(@inCompany,@inMonth,@inContract,@inIsLocked,@inExcludeWorkStream,@inExcludeRevenueType) cost ON
		rev.JCCo=cost.JCCo
	AND rev.Contract=cost.Contract
	AND rev.GLDepartment=cost.GLDepartment

	
GO
