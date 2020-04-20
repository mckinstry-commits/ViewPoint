IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mspWIPRevenue]'))
	DROP PROCEDURE [dbo].[mspWIPRevenue]
GO

-- =================================================================================================================================
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 01/14/2015 Amit Mody			Authored by converting from mfnGetWIPArchive
-- 02/10/2015 Amit Mody			Updated for supporting multiple ExcludeRevenueType (so that non-rev contracts can be processed on locked months)
-- ==================================================================================================================================

CREATE PROCEDURE [dbo].[mspWIPRevenue] 
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				VARCHAR(10) --bContract
,	@inExcludeRevenueType	varchar(255)
AS
BEGIN
DECLARE @firstOfMonth smalldatetime
SELECT @firstOfMonth = dbo.mfnFirstOfMonth(@inMonth)

IF OBJECT_ID('tempdb..#tmpWipRev') IS NOT NULL
    DROP TABLE #tmpWipRev

---------------
-- CONTRACTS --
---------------
SELECT * INTO #tmpWipRev FROM dbo.mckWipRevenueData WHERE 1=2
INSERT #tmpWipRev
SELECT
	@firstOfMonth AS ThroughMonth
,	itemWip.JCCo
,	itemWip.Contract
,	itemWip.ContractDesc
,	itemWip.CGCJobNumber
,	NULL as WorkOrder
,	itemWip.IsLocked
,	itemWip.RevenueType
,	vddcic.DisplayValue AS RevenueTypeName
,	itemWip.ContractStatus 
,	itemWip.ContractStatusDesc	
,	glpi.Instance as GLDepartment
,	glpi.Description as GLDepartmentName
,	itemWip.POC
,	jcmp.Name as POCName
,	sum(itemWip.OrigContractAmt) as OrigContractAmt
,	sum(itemWip.CurrContractAmt) as CurrContractAmt
,	0 as CurrEarnedRevenue
,	0 as PrevEarnedRevenue
,	sum(itemWip.ProjContractAmt) as ProjContractAmt
,	itemWip.RevenueIsOverride
,	avg(itemWip.OverrideRevenueTotal) as OverrideRevenueTotal
,	CASE WHEN sum(itemWip.RevenueOverridePercent) > 1 THEN 1 ELSE sum(itemWip.RevenueOverridePercent) END as RevenueOverridePercent
, 	sum(itemWip.OverrideRevenueTotal * itemWip.RevenueOverridePercent) as RevenueOverrideAmount
,	SUM(itemWip.CurrentBilledAmount) AS CurrentBilledAmount
,	SUM(itemWip.RevenueWIPAmount) AS RevenueWIPAmount
,	COALESCE(jcmp_sp.ProjectMgr, '') as SalesPersonID
,	COALESCE(jcmp_sp.Name, '') as SalesPerson
,	COALESCE(vm.VerticalMarketDesc, '') as VerticalMarket
,	itemWip.MarkUpRate
,	itemWip.StrLineTermStart
,	itemWip.StrLineTerm
,	0 as StrLineMTDEarnedRev
,	0 as StrLinePrevJTDEarnedRev
,	GETDATE() as ProcessedOn
,	itemWip.Department
FROM 
	(SELECT * FROM dbo.mfnGetWIPRevenueByItem (@firstOfMonth, @inCompany, @inContract)) itemWip
	JOIN
	dbo.JCDM jcdm ON
		itemWip.JCCo=jcdm.JCCo
	AND itemWip.Department=jcdm.Department JOIN
	dbo.GLPI glpi ON
		jcdm.GLCo=glpi.GLCo
	AND glpi.PartNo=3
	AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4) LEFT OUTER JOIN
	dbo.JCMP jcmp ON
		itemWip.JCCo=jcmp.JCCo
	AND itemWip.POC=jcmp.ProjectMgr LEFT OUTER JOIN
	dbo.vDDCIc vddcic ON
		vddcic.ComboType='RevenueType'
	AND vddcic.DatabaseValue=COALESCE(itemWip.RevenueType,'C') LEFT OUTER JOIN
	dbo.JCMP jcmp_sp ON
		itemWip.JCCo=jcmp_sp.JCCo
	AND itemWip.SalesPerson=jcmp_sp.ProjectMgr LEFT OUTER JOIN
	dbo.udVerticalMarket vm ON
		itemWip.VerticalMarket=vm.VerticalMarketCode
WHERE
	vddcic.DatabaseValue NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType))
group by
	itemWip.JCCo
,	itemWip.Contract
,	itemWip.ContractDesc
,	itemWip.CGCJobNumber
,	itemWip.IsLocked
,	itemWip.RevenueType 
,	vddcic.DisplayValue
,	itemWip.ContractStatus 
,	itemWip.ContractStatusDesc
,	glpi.Instance
,	glpi.Description
,	itemWip.Department
,	itemWip.POC
,	itemWip.RevenueIsOverride
,	jcmp.Name
,  	jcmp_sp.ProjectMgr
,  	jcmp_sp.Name
,	vm.VerticalMarketDesc
,	itemWip.MarkUpRate
,	itemWip.StrLineTermStart
,	itemWip.StrLineTerm

UPDATE ret 
SET	ret.PrevEarnedRevenue = 
		CASE WHEN (ret.RevenueType='A'
					AND ret.StrLineTermStart IS NOT NULL AND ret.StrLineTerm IS NOT NULL AND ret.StrLineTerm > 0 
					AND DATEDIFF(MONTH, dbo.mfnFirstOfMonth(ret.StrLineTermStart), @firstOfMonth) >= 0 
					AND DATEDIFF(MONTH, dbo.mfnFirstOfMonth(ret.StrLineTermStart), @firstOfMonth) < ret.StrLineTerm)
				THEN	COALESCE(prevWIPRev.JTDEarnedRev, (RevenueWIPAmount * DATEDIFF(MONTH, dbo.mfnFirstOfMonth(ret.StrLineTermStart), @firstOfMonth) / ret.StrLineTerm))
				ELSE	COALESCE(prevWIPRev.JTDEarnedRev, 0.000)
		END
FROM #tmpWipRev ret LEFT OUTER JOIN
	(SELECT	JCCo, Contract, IsLocked, RevenueType, /* ContractStatus,*/ GLDepartment, COALESCE(JTDEarnedRev, 0.0) AS JTDEarnedRev
	 FROM	dbo.mckWipArchive
	 WHERE	(JCCo=@inCompany OR @inCompany IS NULL)
		AND (Contract=@inContract or @inContract is null)
		AND ThroughMonth = DATEADD(MONTH, -1, @firstOfMonth)
		AND RevenueType NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType))) prevWIPRev
	ON	ret.JCCo=prevWIPRev.JCCo
	AND ret.Contract=prevWIPRev.Contract
	AND ret.IsLocked=prevWIPRev.IsLocked
	AND ret.RevenueType=prevWIPRev.RevenueType
	--AND	ret.ContractStatus=prevWIPRev.ContractStatus
	AND ret.GLDepartment=prevWIPRev.GLDepartment 
WHERE	1=1

UPDATE ret
SET	   ret.StrLineMTDEarnedRev = dbo.mfnGetStraightLineMTDRevenue(@firstOfMonth, ret.StrLineTermStart, ret.StrLineTerm, ret.PrevEarnedRevenue, ret.RevenueWIPAmount)
FROM   #tmpWipRev ret
WHERE  1=1

-------------------------
-- SERVICE WORK-ORDERS --
-------------------------
IF ('M' NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType)))
BEGIN
	INSERT #tmpWipRev
	SELECT
		@firstOfMonth AS ThroughMonth
	,	smwo.SMCo AS JCCo
	,	NULL AS Contract	
	,	NULL AS ContractDesc
	,	NULL AS CGCJobNumber
	,	smwo.WorkOrder as WorkOrder
	,	NULL AS IsLocked
	,	'M' as RevenueType -- WorkOrders are treated as Cost+Markup contracts from accounting standpoint
	,	'Cost' AS RevenueTypeName
	,	0 AS ContractStatus	--Normalizing WorkOrderStatus to ContractStatus definition (1=Open, 0,2,3=Closed)
	,	'Closed' AS ContractStatusDesc
	,	NULL as GLDepartment
	,	NULL as GLDepartmentName
	,	NULL AS POC
	,	NULL AS POCName
	,	0 as OrigContractAmt
	,	0 as CurrContractAmt
	,	0 as CurrEarnedRevenue
	,	0 as PrevEarnedRevenue
	,	0 as ProjContractAmt
	,	'N' as RevenueIsOverride
	,	0 as OverrideRevenueTotal
	,	1 as RevenueOverridePercent
	,	0 as RevenueOverrideAmount
	,	SUM(artl.TaxBasis) as CurrentBilledAmount
	,	0 AS RevenueWIPAmount
	,	NULL as SalesPersonID
	,	NULL as SalesPerson
	,	NULL as VerticalMarket
	,	NULL AS MarkUpRate
	,	NULL as StrLineTermStart
	,	NULL as StrLineTerm
	,	0 as StrLineMTDEarnedRev
	,	0 as StrLinePrevJTDEarnedRev
	,	GETDATE() AS ProcessedOn
	,	NULL as Department
	FROM	ARTL artl
			JOIN dbo.SMWorkOrder smwo 
			ON artl.udSMWorkOrderID=smwo.SMWorkOrderID
			JOIN vrvSMServiceSiteCustomer ssc 
			ON	smwo.SMCo=ssc.SMCo 
				AND smwo.ServiceSite=ssc.ServiceSite
	WHERE
			--arth.Mth=@firstOfMonth
			artl.Mth<=@firstOfMonth
			and ssc.Type='Customer'
			AND artl.ARCo=@inCompany
	GROUP by
			smwo.SMCo
	,		smwo.WorkOrder

	UPDATE	ret
	SET		ret.GLDepartment = s.Department 
	,		ret.GLDepartmentName = COALESCE(glpi.Description, '')
	,		ret.RevenueTypeName = COALESCE(smwo.CostingMethod,'Cost')
	,		ret.ContractStatus = CASE WHEN smwo.WOStatus=0 THEN 1 ELSE 0 END
	,		ret.ContractStatusDesc = CASE WHEN smwo.WOStatus=0 THEN 'Open' ELSE 'Closed' END
	,		ret.POCName = COALESCE(smwo.ContactName, '')
	,		ret.MarkUpRate = COALESCE(smwo.udMarkupPct, 0)
	FROM	#tmpWipRev ret
			JOIN SMWorkOrder smwo 
				ON ret.JCCo=smwo.SMCo 
				AND	ret.WorkOrder=smwo.WorkOrder
			JOIN dbo.SMServiceCenter s ON 
				smwo.ServiceCenter = s.ServiceCenter AND smwo.SMCo = s.SMCo
			LEFT JOIN GLPI glpi ON
				smwo.SMCo=glpi.GLCo
				AND glpi.PartNo=3
				AND glpi.Instance=s.Department 
	WHERE	Contract IS NULL
END

IF EXISTS (SELECT 1 FROM dbo.mckWipRevenueData WHERE (JCCo=@inCompany OR @inCompany IS NULL) 
												 AND (ThroughMonth=@firstOfMonth OR @inMonth IS NULL) 
												 AND (Contract=@inContract OR @inContract IS NULL)
												 AND RevenueType NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType)))
BEGIN
	DELETE dbo.mckWipRevenueData WHERE (JCCo=@inCompany OR @inCompany IS NULL) 
								   AND (ThroughMonth=@firstOfMonth OR @inMonth IS NULL) 
								   AND (Contract=@inContract OR @inContract IS NULL)
								   AND RevenueType NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType))
END

INSERT dbo.mckWipRevenueData SELECT * FROM #tmpWipRev
DROP TABLE #tmpWipRev

END
GO

--Test Script
--EXEC mspWIPRevenue 1, '12/1/2014', null, null
--EXEC mspWIPRevenue 1, '12/1/2014', null, 'N'
--EXEC mspWIPRevenue 1, '10/1/2014', null, 'M,A,C'