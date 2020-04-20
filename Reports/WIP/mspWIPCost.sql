IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mspWIPCost]'))
	DROP PROCEDURE [dbo].[mspWIPCost]
GO

-- =================================================================================================================================
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 01/14/2015 Amit Mody			Authored by converting from mfnGetWIPCost
-- 01/22/2015 Amit Mody			Fixed a bug in CurrentCost calculation for service WIP
-- 02/10/2015 Amit Mody			Updated for supporting multiple ExcludeRevenueType (so that non-rev contracts can be processed on locked months)
-- ==================================================================================================================================

CREATE PROCEDURE [dbo].[mspWIPCost] 
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				VARCHAR(10)
,	@inExcludeRevenueType	varchar(255)
AS
BEGIN

DECLARE @firstOfMonth smalldatetime
SELECT @firstOfMonth = dbo.mfnFirstOfMonth(@inMonth)

IF OBJECT_ID('tempdb..#tmpWipCost') IS NOT NULL
    DROP TABLE #tmpWipCost

---------------
-- CONTRACTS --
---------------
SELECT * INTO #tmpWipCost FROM dbo.mckWipCostData WHERE 1=2
INSERT #tmpWipCost
SELECT
	t1.ThroughMonth	
,	t1.JCCo	
,	t1.Contract	
,	t1.ContractDesc
,	NULL AS WorkOrder
,	t1.IsLocked	
,	t1.RevenueType	
,	t1.RevenueTypeName	
,	t1.ContractStatus	
,	t1.ContractStatusDesc	
,	t1.GLDepartment	
,	t1.GLDepartmentName	
,	t1.POC	
,	t1.POCName	
,	SUM(COALESCE(t1.OriginalCost, 0)) AS OriginalCost
,	SUM(COALESCE(t1.CurrentCost, 0)) AS CurrentCost
,	SUM(COALESCE(t1.CurrentEstCost, 0)) AS CurrentEstCost
, 	0 AS CurrMonthCost
,	0 AS PrevCost
,	SUM(COALESCE(t1.ProjectedCost, 0)) AS ProjectedCost
,	CASE SUM(COALESCE(t2.ProjCost,0))
		WHEN 0 THEN 'N'
		ELSE 'Y'
	END AS CostIsOverride
,	COALESCE(SUM(t2.ProjCost), 0) AS OverrideCostTotal
,	0 AS CostOverridePercent 
,	COALESCE(SUM(t1.ProjectedCost), 0) AS OverrideCost
,	COALESCE(SUM(t1.CommittedCost), 0) AS CommittedCost
,	GETDATE() AS ProcessedOn
FROM
	(SELECT * FROM mckWipCostByJobData 
	 WHERE (JCCo=@inCompany OR @inCompany IS NULL)
	   AND (Contract=@inContract or @inContract is null )
	   AND ThroughMonth = @firstOfMonth
	   AND RevenueType NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType))) t1 LEFT OUTER JOIN
	dbo.JCOP t2 ON
	t1.JCCo=t2.JCCo
AND t1.Job=t2.Job
AND t1.ThroughMonth = t2.Month
GROUP BY
	t1.ThroughMonth	
,	t1.JCCo	
,	t1.Contract	
,	t1.ContractDesc
,	t1.IsLocked	
,	t1.RevenueType	
,	t1.RevenueTypeName	
,	t1.ContractStatus	
,	t1.ContractStatusDesc
,	t1.GLDepartment	
,	t1.GLDepartmentName
,	t1.POC
,	t1.POCName

UPDATE ret 
SET ret.CommittedCost = CASE WHEN ret.CommittedCost <= 0 THEN 0 ELSE ret.CommittedCost END
,   ret.CurrMonthCost = COALESCE(currMonth.Cost, 0.000)
,   ret.PrevCost = COALESCE(prevMonth.Cost, 0.000)
FROM #tmpWipCost ret LEFT OUTER JOIN
	(SELECT JCCo, Contract, IsLocked, RevenueType, /* ContractStatus, */ GLDepartment, SUM(COALESCE(CurrentCost, 0.00)) AS Cost 
		 FROM mckWipCostByJobData 
		 WHERE 
			 (JCCo=@inCompany OR @inCompany IS NULL)
		 AND (Contract=@inContract or @inContract is null)
		 AND ThroughMonth = @firstOfMonth
		 AND RevenueType NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType))
		 GROUP BY
			JCCo
		,	Contract
		,	IsLocked	
		,	RevenueType	
		--,	ContractStatus	
		,	GLDepartment) currMonth
	ON	ret.JCCo=currMonth.JCCo
	AND ret.Contract=currMonth.Contract
	AND ret.IsLocked=currMonth.IsLocked
	AND ret.RevenueType=currMonth.RevenueType 
	--AND ret.ContractStatus=currMonth.ContractStatus
	AND ret.GLDepartment=currMonth.GLDepartment LEFT OUTER JOIN
	(SELECT	JCCo, Contract, IsLocked, RevenueType, /* ContractStatus,*/ GLDepartment, COALESCE(JTDActualCost, 0.0) AS Cost
	 FROM	dbo.mckWipArchive
	 WHERE	(JCCo=@inCompany OR @inCompany IS NULL)
		AND (Contract=@inContract or @inContract is null)
		AND ThroughMonth = DATEADD(MONTH, -1, @firstOfMonth)
		AND RevenueType NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType))) prevMonth
	ON	ret.JCCo=prevMonth.JCCo
	AND ret.Contract=prevMonth.Contract
	AND ret.IsLocked=prevMonth.IsLocked
	AND ret.RevenueType=prevMonth.RevenueType 
	--AND ret.ContractStatus=prevMonth.ContractStatus
	AND ret.GLDepartment=prevMonth.GLDepartment
WHERE	1=1

-------------------------
-- SERVICE WORK-ORDERS --
-------------------------
IF ('M' NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType)))
BEGIN
	INSERT #tmpWipCost
	SELECT
		@firstOfMonth AS ThroughMonth
	,	wo.SMCo AS JCCo
	,	NULL AS Contract	
	,	NULL AS ContractDesc
	,	wo.WorkOrder as WorkOrder
	,	NULL AS IsLocked
	,	'M' as RevenueType 
	,	COALESCE(wo.CostingMethod,'Cost') AS RevenueTypeName
	,	CASE WHEN wo.WOStatus=0 THEN 1 ELSE 0 END AS ContractStatus	--Normalizing WorkOrderStatus to ContractStatus definition (1=Open, 0,2,3=Closed)
	,	CASE WHEN wo.WOStatus=0 THEN 'Open' ELSE 'Closed' END AS ContractStatusDesc
	,	s.Department as GLDepartment
	,	glpi.Description as GLDepartmentName
	,	NULL AS POC
	,	wo.ContactName AS POCName
	,	0 as OriginalCost
	,   SUM(c.Amount) as CurrentCost
	,	0 as CurrentEstCost
	,	0 as CurrMonthCost
	,	0 as PrevCost
	,	0 as ProjectedCost
	,	'N' as CostIsOverride
	,	0 as OverrideCostTotal
	,	1 as CostOverridePercent
	,	0 as OverrideCost
	,	0 as CommittedCost
	,	GETDATE() AS ProcessedOn
	FROM
		SMWorkOrder wo 
		JOIN SMDetailTransaction c ON
				wo.SMWorkOrderID=c.SMWorkOrderID
		JOIN vrvSMServiceSiteCustomer ssc ON 
				wo.SMCo=ssc.SMCo 
				AND wo.ServiceSite=ssc.ServiceSite
		JOIN dbo.SMServiceCenter s ON 
				wo.ServiceCenter = s.ServiceCenter AND wo.SMCo = s.SMCo
		LEFT OUTER JOIN	GLPI glpi ON
				wo.SMCo=glpi.GLCo
				AND glpi.PartNo=3
				AND glpi.Instance=s.Department 
	WHERE	c.Posted=1
		AND wo.SMCo=@inCompany
		AND c.GLCo =@inCompany
		AND c.Mth <= @firstOfMonth
		AND ssc.Type='Customer'
	group by
		wo.SMCo
	,	wo.WorkOrder
	,	wo.WOStatus
	,	wo.CostingMethod
	,	s.Department
	,	glpi.Description 
	,	wo.ContactName

	UPDATE ret 
	SET  ret.PrevCost = COALESCE(prevMonth.Cost, 0.000)
	FROM #tmpWipCost ret LEFT OUTER JOIN
		(SELECT	JCCo, WorkOrder, /* ContractStatus,*/ GLDepartment, COALESCE(JTDActualCost, 0.0) AS Cost
		 FROM	dbo.mckWipArchive
		 WHERE	ThroughMonth = DATEADD(MONTH, -1, @firstOfMonth)
		  AND	WorkOrder IS NOT NULL) prevMonth
		ON	ret.JCCo=prevMonth.JCCo
		AND ret.WorkOrder=prevMonth.WorkOrder
		--AND ret.ContractStatus=prevMonth.ContractStatus
		AND ret.GLDepartment=prevMonth.GLDepartment
	WHERE	ret.WorkOrder IS NOT NULL
END

IF EXISTS (SELECT 1 FROM dbo.mckWipCostData WHERE (JCCo=@inCompany OR @inCompany IS NULL) 
											  AND (ThroughMonth=@firstOfMonth OR @inMonth IS NULL) 
											  AND (Contract=@inContract OR @inContract IS NULL)
											  AND RevenueType NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType)))
BEGIN
	DELETE dbo.mckWipCostData WHERE (JCCo=@inCompany OR @inCompany IS NULL) 
								AND (ThroughMonth=@firstOfMonth OR @inMonth IS NULL) 
								AND (Contract=@inContract OR @inContract IS NULL)
								AND RevenueType NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType))
END
INSERT dbo.mckWipCostData SELECT * FROM #tmpWipCost

DROP TABLE #tmpWipCost

END
GO

--Test Script
--EXEC mspWIPCost 1, '12/1/2014', null