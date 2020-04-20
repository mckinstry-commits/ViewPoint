--DROP FUNCTION mfnSplitCsvParam
IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='FUNCTION' AND ROUTINE_SCHEMA='dbo' AND ROUTINE_NAME='mfnSplitCsvParam')
BEGIN
	PRINT 'DROP FUNCTION mfnSplitCsvParam'
	DROP FUNCTION dbo.mfnSplitCsvParam
END
go

PRINT 'CREATE FUNCTION mfnSplitCsvParam'
go

--create FUNCTION mfnSplitCsvParam
create FUNCTION dbo.mfnSplitCsvParam
(
	@csvParam	VARCHAR(500)
)
RETURNS
@ParsedList table
(
	Val CHAR(1)
)
AS
BEGIN
	DECLARE @char CHAR(1), @Pos INT

	SET @csvParam = LTRIM(RTRIM(@csvParam))+ ','
	SET @Pos = CHARINDEX(',', @csvParam, 1)

	IF REPLACE(@csvParam, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @char = LTRIM(RTRIM(LEFT(@csvParam, @Pos - 1)))
			IF @char <> ''
			BEGIN
				INSERT INTO @ParsedList (Val) 
				VALUES (@char)
			END
			SET @csvParam = RIGHT(@csvParam, LEN(@csvParam) - @Pos)
			SET @Pos = CHARINDEX(',', @csvParam, 1)

		END
	END	
	RETURN
END
GO

--Test Script
--SELECT * from dbo.mfnSplitCsvParam(null)
--SELECT * from dbo.mfnSplitCsvParam('')
--SELECT * from dbo.mfnSplitCsvParam(',,,')
--SELECT * from dbo.mfnSplitCsvParam('N')
--SELECT * from dbo.mfnSplitCsvParam('M,A,C')
--SELECT * from dbo.mfnSplitCsvParam(',,M,,A,,,C,,,')
--SELECT * from dbo.mfnSplitCsvParam('MAC')

--DROP FUNCTION mfnGetWIPCostByJob
IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='FUNCTION' AND ROUTINE_SCHEMA='dbo' AND ROUTINE_NAME='mfnGetWIPCostByJob')
BEGIN
	PRINT 'DROP FUNCTION mfnGetWIPCostByJob'
	DROP FUNCTION dbo.mfnGetWIPCostByJob
END
go

-- =================================================================================================================================
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 09/15/2014 Bill Orebaugh		Authored
-- 09/29/2014 Amit Mody			Added ProcessedOn to return table schema and updated join
-- 02/10/2015 Amit Mody			Updated for supporting multiple ExcludeRevenueType (so that non-rev contracts can be processed on locked months)
-- ==================================================================================================================================

PRINT 'CREATE FUNCTION mfnGetWIPCostByJob'
go
create FUNCTION dbo.mfnGetWIPCostByJob
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				VARCHAR(10) --bContract
,	@inIsLocked				CHAR(1) --bYN
,	@inExcludeWorkStream	varchar(255)
,	@inExcludeRevenueType	varchar(255)
)
RETURNS @retTable TABLE
(
	ThroughMonth			SMALLDATETIME	null
,	JCCo					TINYINT			null
,	Contract				VARCHAR(10)		NULL
,	ContractDesc			VARCHAR(60)  	NULL
,	Job						VARCHAR(10)		NULL
,	IsLocked				CHAR(1)			NULL	--bYN		
,	RevenueType				varchar(10)		null
,	RevenueTypeName			VARCHAR(60)		null
,	ContractStatus			varchar(10)		null
,	ContractStatusDesc		VARCHAR(60)		null
,	GLDepartment			VARCHAR(4)		null
,	GLDepartmentName		VARCHAR(60)		null
,	POC						INT				NULL	--bEmployee		
,	POCName					VARCHAR(60)		null
,	OriginalCost			decimal(18,2)	null
,	CurrentCost				decimal(18,2)	null
,	CurrentEstCost			decimal(18,2)	null
,	ProjectedCost			decimal(18,2)	null
,	CommittedCost			decimal(18,2)	null
,	ProcessedOn				DateTime		null
)
AS
BEGIN

DECLARE @firstOfMonth smalldatetime
SELECT @firstOfMonth = dbo.mfnFirstOfMonth(@inMonth)

INSERT @retTable
SELECT 
	@firstOfMonth AS ThroughMonth
,	jcci.JCCo
,	ltrim(rtrim(jcci.Contract)) as Contract
,	jccm.Description AS ContractDescription
,	jcjp.Job
,	jcci.udLockYN as IsLocked
,	COALESCE(jcci.udRevType,'C') as RevenueType
,	vddcic.DisplayValue AS RevenueTypeName
,	jccm.ContractStatus 
,	CASE jccm.ContractStatus 
		WHEN 0 THEN CAST(jccm.ContractStatus AS VARCHAR(4)) + '-Pending'
		ELSE vddci.DisplayValue 
	END AS ContractStatusDesc	
,	glpi.Instance as GLDepartment
,	glpi.Description as GLDepartmentName
,	jccm.udPOC as POC
,	jcmp.Name as POCName
,	COALESCE(sum(jccp.OrigEstCost),0) as OriginalCost
,	COALESCE(sum(jccp.CurrEstCost),0) as CurrentEstCost
,	COALESCE(sum(jccp.ActualCost),0) as CurrentCost
,	COALESCE(sum(jccp.ProjCost),0) as ProjectedCost
--,	COALESCE(sum(jccp.TotalCmtdCost),0) as CommittedCost
,	SUM(CASE WHEN COALESCE(jccp.RemainCmtdCost, 0) <= 0 THEN 0 ELSE jccp.RemainCmtdCost END) as CommittedCost
--,	COALESCE(sum(jccp.RecvdNotInvcdCost),0) as CommittedCost
,	GETDATE() as ProcessedOn
FROM
	dbo.JCCI jcci JOIN	
	dbo.JCCM jccm ON
		jcci.JCCo=jccm.JCCo
	AND jcci.Contract=jccm.Contract
	AND (jcci.JCCo=@inCompany OR @inCompany IS NULL)
	AND ( ltrim(rtrim(jcci.Contract))=@inContract or @inContract is null ) LEFT OUTER JOIN
	dbo.JCDM jcdm ON
		jcci.JCCo=jcdm.JCCo
	AND jcci.Department=jcdm.Department JOIN
	dbo.GLPI glpi ON
		jcdm.GLCo=glpi.GLCo
	AND glpi.PartNo=3
	AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4) LEFT JOIN
	dbo.JCMP jcmp ON
		jccm.JCCo=jcmp.JCCo
	AND jccm.udPOC=jcmp.ProjectMgr left outer JOIN
	dbo.vDDCIc vddcic ON
		vddcic.ComboType='RevenueType'
	AND vddcic.DatabaseValue=COALESCE(jcci.udRevType,'C') LEFT OUTER JOIN
	dbo.vDDCI vddci ON
		vddci.ComboType='JCContractStatus'
	AND vddci.DatabaseValue=jccm.ContractStatus	JOIN
	dbo.JCJP jcjp on
		jcci.JCCo=jcjp.JCCo
	and jcci.Contract=jcjp.Contract
	and jcci.Item=jcjp.Item JOIN
	dbo.JCJM jcjm ON
		jcjp.JCCo=jcjm.JCCo
	AND jcjp.Job=jcjm.Job 
	AND (jcjm.udProjWrkstrm NOT IN (@inExcludeWorkStream) OR @inExcludeWorkStream IS null) LEFT OUTER JOIN
	dbo.JCCP jccp ON
		jcjp.JCCo=jccp.JCCo
	and jcjp.Job=jccp.Job
	and jcjp.Phase=jccp.Phase
	and jcjp.PhaseGroup=jccp.PhaseGroup		
	and jccp.Mth <= @firstOfMonth
WHERE
	COALESCE(jcci.udRevType,'C') NOT IN (SELECT * from dbo.mfnSplitCsvParam(@inExcludeRevenueType))
group by
	jcci.JCCo
,	jcci.Contract
,	jccm.Description
,	jcjp.Job
,	jcci.udLockYN 
,	jcci.udRevType 
,	vddcic.DisplayValue
,	jccm.ContractStatus 
,	glpi.Instance
,	glpi.Description 
,	jccm.udPOC
,	jcmp.Name 
,	vddci.DisplayValue
,	vddci.DatabaseValue

RETURN

END
GO

-- Test Script
-- SELECT distinct RevenueType from dbo.mfnGetWIPCostByJob(1,'12/1/2014',null,null,null,'M,A,C')


--DROP FUNCTION mfnGetWIPRevenueByItem
IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='FUNCTION' AND ROUTINE_SCHEMA='dbo' AND ROUTINE_NAME='mfnGetWIPRevenueByItem')
BEGIN
	PRINT 'DROP FUNCTION mfnGetWIPRevenueByItem'
	DROP FUNCTION dbo.mfnGetWIPRevenueByItem
END
go

--create function mfnGetWIPRevenueByItem
PRINT 'CREATE FUNCTION mfnGetWIPRevenueByItem'
go
create FUNCTION dbo.mfnGetWIPRevenueByItem
(
	@inMonth				smalldatetime
,	@inCompany				tinyint
,	@inContract				VARCHAR(10) --bContract
)
RETURNS @retTable TABLE
(
	ThroughMonth			SMALLDATETIME	null
,	JCCo					TINYINT			null
,	Contract				VARCHAR(10)		NULL
,	ContractDesc			VARCHAR(60)  	null
,	Item					VARCHAR(16)		NULL
,	CGCJobNumber			VARCHAR(20)		NULL
,	IsLocked				CHAR(1)			NULL	--bYN
,	RevenueType				varchar(10)		null
,	ContractStatus			varchar(10)		null
,	ContractStatusDesc		VARCHAR(60)		null
,	POC						INT				NULL	--bEmployee
,	RevenueIsOverride		CHAR(1)			NULL	--bYN
,	OverrideRevenueTotal	decimal(18,2)	null
,	RevenueOverridePercent	decimal(18,15)	NULL
,	OrigContractAmt			decimal(18,2)	null
,	CurrContractAmt			decimal(18,2)	null
,	ProjContractAmt			decimal(18,2)	null	
,	RevenueWIPAmount		decimal(18,2)	null		
,	CurrentBilledAmount		decimal(18,2)	null
,	MarkUpRate				numeric(8,6)	null
,	StrLineTermStart		SMALLDATETIME	null
,	StrLineTerm				tinyint			null
,	Department				varchar(10)		null
,	SalesPerson				int				null
,	VerticalMarket			varchar(10)		null
)
AS
BEGIN

DECLARE @firstOfMonth smalldatetime
SELECT @firstOfMonth = dbo.mfnFirstOfMonth(@inMonth)

INSERT @retTable
SELECT
	@firstOfMonth AS ThroughMonth
,	jcci.JCCo
,	ltrim(rtrim(jcci.Contract)) as Contract
,	jccm.Description AS ContractDesc
,	jcci.Item
,	jccm.udCGCJobNum AS CGCJobNumber
,	jcci.udLockYN as IsLocked
,	COALESCE(jcci.udRevType,'C') as RevenueType
,	jccm.ContractStatus 
,	CASE jccm.ContractStatus 
		WHEN 0 THEN CAST(jccm.ContractStatus AS VARCHAR(4)) + '-Pending'
		ELSE vddci.DisplayValue 
	END AS ContractStatusDesc	
,	jccm.udPOC as POC
,	case coalesce(jcor.RevCost,0)
		when 0 then 'N'
		else 'Y' 
	end as RevenueIsOverride
,	COALESCE(jcor.RevCost,0) AS OverrideRevenueTotal
,	(CASE WHEN jcci.udLockYN = 'N' THEN 0 ELSE
		CASE COALESCE(tot.ProjContractAmtTotal, 0) 
		WHEN 0 THEN 
			CASE COALESCE(tot.CurrContractAmtTotal, 0) 
			WHEN 0 
			THEN 
				CASE WHEN coalesce(jcor.RevCost,0) <> 0 --[RevenueIsOverride]='Y'
				THEN 1	ELSE 0 END
			ELSE 
				CASE WHEN (coalesce(sum(jcip.ContractAmt),0) / tot.CurrContractAmtTotal) < 0 THEN 0
					 WHEN (coalesce(sum(jcip.ContractAmt),0) / tot.CurrContractAmtTotal) > 1 THEN 1
					 ELSE CAST((coalesce(sum(jcip.ContractAmt),0) / tot.CurrContractAmtTotal) AS DECIMAL(18,15))
				END
			END
		ELSE 
			CASE WHEN (coalesce(sum(jcip.ProjDollars),0) / tot.ProjContractAmtTotal) < 0 THEN 0
				 WHEN (coalesce(sum(jcip.ProjDollars),0) / tot.ProjContractAmtTotal) > 1 THEN 1
				 ELSE CAST((coalesce(sum(jcip.ProjDollars),0) / tot.ProjContractAmtTotal) AS DECIMAL(18,15))
			END
		END
	END) as RevenueOverridePercent
,	COALESCE(sum(jcip.OrigContractAmt),0) as OrigContractAmt
,	COALESCE(sum(jcip.ContractAmt),0) as CurrContractAmt
,	COALESCE(sum(jcip.ProjDollars),0) as ProjContractAmt
,	(CASE [ContractStatus]
	   WHEN 1 THEN
			(CASE 
				WHEN COALESCE(jcor.RevCost,0) = 0 --[RevenueIsOverride]='N'
				THEN 
					(CASE WHEN (COALESCE(SUM(jcip.ProjDollars),0) = 0 and jcci.ProjPlug='N') --ProjContractAmt
							THEN COALESCE(SUM(jcip.ContractAmt),0) --CurrContractAmt
							ELSE COALESCE(SUM(jcip.ProjDollars),0) --ProjContractAmt
						END)
				ELSE COALESCE(jcor.RevCost,0) * --OverrideRevenueTotal
					(CASE WHEN jcci.udLockYN = 'N' THEN 0 ELSE
						CASE COALESCE(tot.ProjContractAmtTotal, 0) 
						WHEN 0 THEN 
							CASE COALESCE(tot.CurrContractAmtTotal, 0) 
							WHEN 0 
							THEN 
								CASE WHEN coalesce(jcor.RevCost,0) <> 0 --[RevenueIsOverride]='Y'
								THEN 1	ELSE 0 END
							ELSE CAST((coalesce(sum(jcip.ContractAmt),0) /* CurrContractAmt */ / tot.CurrContractAmtTotal) AS DECIMAL(12,8))
							END
						ELSE CAST((coalesce(sum(jcip.ProjDollars),0) /*ProjContractAmt */ / tot.ProjContractAmtTotal) AS DECIMAL(12,8))
						END
					END)
				END)
	   ELSE COALESCE(SUM(jcip.BilledAmt),0) --CurrentBilledAmount
	   END) as RevenueWIPAmount
,	COALESCE(SUM(jcip.BilledAmt),0) AS CurrentBilledAmount
,	jcci.MarkUpRate
,	jccm.udTermMth as StrLineTermStart
,	jccm.udTerm as StrLineTerm
,	jcci.Department
,	jccm.udSalesPerson as SalesPerson
,	jccm.udVerticalMarket as VerticalMarket
FROM
	(SELECT * FROM dbo.JCCI 
	 WHERE (JCCo=@inCompany OR @inCompany IS NULL)
	 AND ( ltrim(rtrim(Contract))=@inContract or @inContract is null )
	) jcci INNER JOIN
	dbo.JCIP jcip ON
			jcci.JCCo=jcip.JCCo
		AND jcci.Contract=jcip.Contract
		AND jcci.Item=jcip.Item 
		AND jcip.Mth <= @firstOfMonth INNER JOIN
	dbo.JCCM jccm ON
			jcci.JCCo=jccm.JCCo
		AND jcci.Contract=jccm.Contract LEFT OUTER JOIN
	dbo.JCOR jcor ON
			jccm.JCCo=jcor.JCCo
		AND jccm.Contract=jcor.Contract
		AND jcor.Month = @firstOfMonth LEFT OUTER JOIN
	dbo.vDDCI vddci ON
			vddci.ComboType='JCContractStatus'
		AND vddci.DatabaseValue=jccm.ContractStatus LEFT OUTER JOIN
	(SELECT	jcci.JCCo, jcci.Contract, SUM(jcip.ProjDollars) AS ProjContractAmtTotal, SUM(jcip.ContractAmt) AS CurrContractAmtTotal
	 FROM	dbo.JCCI jcci JOIN
			dbo.JCIP jcip ON
			jcci.JCCo=jcip.JCCo
		AND jcci.Contract=jcip.Contract
		AND jcci.Item=jcip.Item
		AND jcip.Mth <= @firstOfMonth
	 WHERE jcci.udLockYN = 'Y'
	 GROUP BY 
			jcci.JCCo, 
			jcci.Contract) tot
	ON	jcci.JCCo=tot.JCCo
	AND jcci.Contract=tot.Contract
group by
	jcci.JCCo
,	jcci.Contract
,	jccm.Description
,	vddci.DisplayValue 
,	jcci.Item
,	jcci.ProjPlug
,	jccm.udCGCJobNum
,	jcci.udLockYN
,	jcci.udRevType
,	jccm.ContractStatus 
,	jccm.udPOC
,	jcci.MarkUpRate
,	jccm.udTermMth
,	jccm.udTerm
,	tot.ProjContractAmtTotal
,	tot.CurrContractAmtTotal
,	jcci.Department
,	jccm.udSalesPerson
,	jccm.udVerticalMarket
,	jcor.RevCost

RETURN 
END
GO
-- SELECT * FROM dbo.mfnGetWIPRevenueByItem ('11/1/2014', 20, '21001-')

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
	FROM	ARTL artl
			JOIN dbo.SMWorkOrder smwo 
			ON artl.udSMWorkOrderID=smwo.SMWorkOrderID
			--JOIN ARTH arth
			--ON artl.ARCo=arth.ARCo
			--	AND artl.Mth=arth.Mth
			--	AND artl.ARTrans=arth.ARTrans 
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
	SET		ret.GLDepartment = COALESCE(d.Instance, '') 
	,		ret.GLDepartmentName = COALESCE(d.Description, '')
	,		ret.RevenueTypeName = COALESCE(smwo.CostingMethod,'Cost')
	,		ret.ContractStatus = CASE WHEN smwo.WOStatus=0 THEN 1 ELSE 0 END
	,		ret.ContractStatusDesc = CASE WHEN smwo.WOStatus=0 THEN 'Open' ELSE 'Closed' END
	,		ret.POCName = COALESCE(smwo.ContactName, '')
	,		ret.MarkUpRate = COALESCE(smwo.udMarkupPct, 0)
	FROM	#tmpWipRev ret
			JOIN SMWorkOrder smwo 
				ON ret.JCCo=smwo.SMCo 
				AND	ret.WorkOrder=smwo.WorkOrder
			LEFT JOIN
			 (SELECT distinct c.SMWorkOrderID, glpi.Instance, glpi.Description 
				FROM SMDetailTransaction c
				JOIN GLPI glpi ON
					 c.GLCo=glpi.GLCo
				 AND glpi.PartNo=3
				 AND glpi.Instance=SUBSTRING(c.GLAccount,10,4)
			  WHERE	c.Posted=1 
				AND c.GLCo=@inCompany
				AND c.Mth<= @firstOfMonth) d 
			ON	smwo.SMWorkOrderID=d.SMWorkOrderID
	WHERE	Contract IS NULL

	--------------------------------------------------
	---- Following code is moved to mspWIPRevenue ----
	--------------------------------------------------
	--UPDATE ret 
	--SET  ret.PrevEarnedRevenue = COALESCE(prevMonth.JTDEarnedRev, 0.000)
	--FROM #tmpWipRev ret JOIN
	--	(SELECT	JCCo, WorkOrder, ContractStatus, GLDepartment, COALESCE(JTDEarnedRev, 0.0) AS JTDEarnedRev
	--	 FROM	dbo.mckWipArchive
	--	 WHERE	ThroughMonth = DATEADD(MONTH, -1, @firstOfMonth)
	--	  AND	WorkOrder IS NOT NULL) prevMonth
	--	ON	ret.JCCo=prevMonth.JCCo
	--	AND ret.WorkOrder=prevMonth.WorkOrder
	--	AND ret.ContractStatus=prevMonth.ContractStatus
	--	AND ret.GLDepartment=prevMonth.GLDepartment
	--WHERE	ret.WorkOrder IS NOT NULL
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
SET ret.CurrMonthCost = COALESCE(currMonth.Cost, 0.000)
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
	,	glpi.Instance as GLDepartment
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
		LEFT OUTER JOIN	GLPI glpi ON
				c.GLCo=glpi.GLCo
				AND glpi.PartNo=3
				AND glpi.Instance=SUBSTRING(c.GLAccount,10,4) 
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
	,	glpi.Instance
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

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mspWIPArchive]'))
	DROP PROCEDURE [dbo].[mspWIPArchive]
GO

-- =================================================================================================================================
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 01/14/2015 Amit Mody			Authored by converting from mfnGetWIPArchive
-- 02/10/2015 Amit Mody			Updated for supporting multiple ExcludeRevenueType (so that non-rev contracts can be processed on locked months)
-- ==================================================================================================================================

CREATE PROCEDURE [dbo].[mspWIPArchive] 
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				VARCHAR(10)
,	@inExcludeRevenueType	varchar(255)
AS
BEGIN

DECLARE @firstOfMonth smalldatetime
SELECT @firstOfMonth = dbo.mfnFirstOfMonth(@inMonth)

IF OBJECT_ID('tempdb..#tmpWip') IS NOT NULL
    DROP TABLE #tmpWip

SELECT * INTO #tmpWip FROM dbo.mckWipArchive WHERE 1=2
INSERT #tmpWip
SELECT 
   [JCCo]
  ,[WorkOrder]
  ,[Contract]
  ,[CGCJobNumber]
  ,[ThroughMonth]
  ,[ContractDesc]
  ,[IsLocked]
  ,[RevenueType]
  ,[RevenueTypeName]
  ,[ContractStatus]
  ,[ContractStatusDesc]
  ,[GLDepartment]
  ,[GLDepartmentName]
  ,[POC]
  ,[POCName]
  ,[OrigContractAmt]
  ,[CurrContractAmt]
  ,[ProjContractAmt]
  ,[RevenueIsOverride]
  ,[OverrideRevenueTotal]
  ,[RevenueOverridePercent]
  ,[RevenueOverrideAmount]
  ,[RevenueWIPAmount]
  ,[CurrentBilledAmount] AS JTDBilled
  ,[SalesPersonID]
  ,[SalesPerson]
  ,[VerticalMarket]
  ,[MarkUpRate]
  ,[StrLineTermStart]
  ,[StrLineTerm] 
  ,[StrLineMTDEarnedRev]
  ,[StrLinePrevJTDEarnedRev]
  ,[CurrEarnedRevenue]
  ,[PrevEarnedRevenue]
  ,0 as [YTDEarnedRev]
  ,[OriginalCost]
  ,[CurrentEstCost] CurrentEstCost
  ,[CurrentCost] JTDActualCost
  ,[ProjectedCost]
  ,[CostIsOverride]
  ,[OverrideCostTotal]
  ,[CostOverridePercent]
  ,[OverrideCost]
  ,[CommittedCost]
  ,[CostWIPAmount]
  ,[CurrMonthCost]
  ,[PrevCost]
  ,0 as [YTDActualCost]
  ,[RevenueProcessedOn]
  ,[CostProcessedOn]

-- CALCULATED COLUMNS FOLLOW
  ,COALESCE(RevenueWIPAmount,0)-COALESCE(CostWIPAmount,0) AS ProjFinalGM
  ,COALESCE(CostWIPAmount,0)-COALESCE(CurrentCost,0) AS EstimatedCostToComplete
  ,CASE [RevenueType]
		WHEN 'A' THEN
			CASE [ContractStatus]	
			WHEN 1 THEN													-- Open SL contract 
				(CASE WHEN COALESCE(RevenueWIPAmount,0)-COALESCE(CostWIPAmount,0) < 0
					THEN COALESCE(RevenueWIPAmount,0)-COALESCE(CostWIPAmount,0)+COALESCE([CurrentCost],0)
					ELSE (StrLineMTDEarnedRev + PrevEarnedRevenue)
				 END)
			ELSE COALESCE([CurrentBilledAmount],0)						-- Soft/Hard closed SL contract
			END
	    WHEN 'M' THEN 
			CASE [ContractStatus]	
			WHEN 1 THEN 
				CASE WHEN [CurrentCost] <= 0 THEN 0 ELSE (COALESCE([CurrentCost],0) * (1 + MarkUpRate)) END	-- Open C+M contract 
			ELSE COALESCE([CurrentBilledAmount],0)						-- Soft/Hard closed C+M contract
			END
	    WHEN 'C' THEN													-- Cost-to-cost contract in open or closed status
			(CASE WHEN COALESCE(RevenueWIPAmount,0)-COALESCE(CostWIPAmount,0) < 0
				THEN COALESCE(RevenueWIPAmount,0)-COALESCE(CostWIPAmount,0)+COALESCE([CurrentCost],0)
				ELSE [RevenueWIPAmount] * 
					 CASE [RevenueType]
	 					WHEN 'C' THEN
							CASE WHEN (([ContractStatus]=2 OR [ContractStatus]=3) AND CurrentCost=0) THEN 1.0 -- Closed Cost-to-Cost contract with JTD Actual Cost = 0: Force 100% project completion
							ELSE 
		     						CAST(CASE COALESCE(CostWIPAmount,0) 
			     					WHEN 0 THEN 0.00 
			     					ELSE COALESCE(CurrentCost,0)/CostWIPAmount 
 			     					END AS DECIMAL(18,10)) 
							END
	 				ELSE
						CAST(CASE COALESCE(CostWIPAmount,0) 
		     				WHEN 0 THEN 0.00 
		     				ELSE COALESCE(CurrentCost,0)/CostWIPAmount 
 		     				END AS DECIMAL(18,10)) 
	 				END
			 END)
		ELSE 0.0														-- Non-revenue contract in open or closed status
	   END AS JTDEarnedRev
  ,CASE [RevenueType]
	 WHEN 'C' THEN
		CASE WHEN (([ContractStatus]=2 OR [ContractStatus]=3) AND CurrentCost=0) THEN 1.0 -- Closed Cost-to-Cost contract with JTD Actual Cost = 0: Force 100% project completion
		ELSE 
		     CAST(CASE COALESCE(CostWIPAmount,0) 
			     WHEN 0 THEN 0.00 
			     ELSE COALESCE(CurrentCost,0)/CostWIPAmount 
 			     END AS DECIMAL(18,10)) 
		END
	 ELSE
		CAST(CASE COALESCE(CostWIPAmount,0) 
		     WHEN 0 THEN 0.00 
		     ELSE COALESCE(CurrentCost,0)/CostWIPAmount 
 		     END AS DECIMAL(18,10)) 
	 END AS PercentComplete
  ,0 AS MTDEarnedRev
  ,(COALESCE(CurrentCost, 0) - CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(PrevCost, 0) END) AS MTDActualCost
  ,0 AS [ContractIsPositive]
  ,0 AS [ProjFinalGMPerc]
  ,0 AS [JTDEarnedGM]
  ,0 AS [Overbilled]
  ,0 AS [Underbilled]
FROM	dbo.mvwWIPJoin CurrWIP 
WHERE 	ThroughMonth=@firstOfMonth
	AND (JCCo=@inCompany OR @inCompany IS NULL)
	AND (Contract=@inContract or @inContract is null )
	AND RevenueType NOT IN (SELECT * from dbo.mfnSplitCsvParam(@inExcludeRevenueType))

----------------------------------------------
---UPDATE PrevEarnedRevenue for Work-Orders---
----------------------------------------------
IF ('M' NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType)))
BEGIN
	UPDATE ret
	SET  ret.PrevEarnedRevenue = COALESCE(prevMonth.JTDEarnedRev, 0.000)
	--,	 ret.PrevCost = COALESCE(prevMonth.Cost, 0.000)
	FROM #tmpWip ret JOIN
		(SELECT	JCCo, WorkOrder, /* ContractStatus,*/ GLDepartment, COALESCE(JTDEarnedRev, 0.0) AS JTDEarnedRev --, COALESCE(JTDActualCost, 0.0) AS Cost
		 FROM	dbo.mckWipArchive
		 WHERE	ThroughMonth = DATEADD(MONTH, -1, @firstOfMonth)
		  AND	WorkOrder IS NOT NULL) prevMonth
		ON	ret.JCCo=prevMonth.JCCo
		AND ret.WorkOrder=prevMonth.WorkOrder
		--AND ret.ContractStatus=prevMonth.ContractStatus
		AND ret.GLDepartment=prevMonth.GLDepartment
	WHERE	ret.WorkOrder IS NOT NULL
END

----------------
---UPDATE MTD---
----------------
UPDATE #tmpWip
SET MTDEarnedRev = CASE [RevenueType]
			WHEN 'A' THEN StrLineMTDEarnedRev
			WHEN 'M' THEN 
				CASE WHEN [JTDActualCost] <= 0 THEN 0 
				ELSE (COALESCE(JTDEarnedRev, 0) - CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(PrevEarnedRevenue, 0) END)
				END
			ELSE (COALESCE(JTDEarnedRev, 0) - CASE [IsLocked] WHEN 'N' THEN 0 ELSE COALESCE(PrevEarnedRevenue, 0) END)
   		   END
WHERE 1=1

-------------------
---UPDATE LAST 5---
-------------------
UPDATE #tmpWip
SET YTDEarnedRev = MTDEarnedRev 
  , YTDActualCost = MTDActualCost 
  , ContractIsPositive = CASE WHEN COALESCE(ProjFinalGM,0) < 0
				THEN 0
				ELSE 1 
   			     END 
  , ProjFinalGMPerc = CAST(CASE COALESCE(RevenueWIPAmount,0) 
				WHEN 0 THEN 0.00 
				ELSE ProjFinalGM/RevenueWIPAmount
			   	END AS DECIMAL(18,10)) 
  , JTDEarnedGM = CASE [RevenueType]
			 WHEN 'M' 
			 THEN 
				CASE WHEN [JTDActualCost] <= 0 THEN 0 
				ELSE (COALESCE(JTDEarnedRev,0)-COALESCE([JTDActualCost],0))
				END
			 WHEN 'N' THEN [JTDEarnedRev] - [JTDActualCost]
			 ELSE -- for C and A revenue types
				CASE WHEN COALESCE(ProjFinalGM,0) < 0 
				 THEN ProjFinalGM
				 ELSE COALESCE(JTDEarnedRev,0)-COALESCE([JTDActualCost],0)
				END
			 END
  , Overbilled =  CASE [RevenueType]
			 WHEN 'M' 
			 THEN 
				CASE WHEN [JTDActualCost] <= 0 THEN 0 
				ELSE 
					CASE WHEN (COALESCE([JTDBilled],0)-COALESCE([JTDEarnedRev],0) < 0)
					THEN 0.0
					ELSE COALESCE([JTDBilled],0)-COALESCE([JTDEarnedRev],0)
		     			END
				END
			 ELSE
				CASE WHEN (COALESCE([JTDBilled],0)-COALESCE([JTDEarnedRev],0) < 0)
				THEN 0.0
				ELSE COALESCE([JTDBilled],0)-COALESCE([JTDEarnedRev],0)
		     		END
			 END
  , Underbilled = CASE [RevenueType]
			 WHEN 'M' 
			 THEN 
				CASE WHEN [JTDActualCost] <= 0 THEN 0 
				ELSE 
					CASE WHEN (COALESCE([JTDEarnedRev],0)-COALESCE([JTDBilled],0) < 0)
					THEN 0.0
					ELSE COALESCE([JTDEarnedRev],0)-COALESCE([JTDBilled],0)
		     			END
				END
			 ELSE
				CASE WHEN (COALESCE([JTDEarnedRev],0)-COALESCE([JTDBilled],0) < 0)
				THEN 0.0
				ELSE COALESCE([JTDEarnedRev],0)-COALESCE([JTDBilled],0)
		     		END
			 END

WHERE 1=1

----------------
---UPDATE YTD---
----------------
DECLARE @startYear smalldatetime
SET @startYear=DATEADD(yy, DATEDIFF(yy,0,@firstOfMonth), 0)

UPDATE ret
SET    	ret.YTDEarnedRev = ret.YTDEarnedRev + COALESCE(wip.YTDEarnedRev, 0)
,	ret.YTDActualCost = ret.YTDActualCost + COALESCE(wip.YTDActualCost, 0)
FROM   	#tmpWip ret JOIN 
   	(SELECT @firstOfMonth as ThroughMonth, JCCo, Contract, IsLocked, RevenueType, ContractStatus, GLDepartment, sum(MTDEarnedRev) as YTDEarnedRev, sum(MTDActualCost) as YTDActualCost
	 FROM   mckWipArchive
	 WHERE  Contract IS NOT NULL
		AND (@inMonth IS NULL OR (ThroughMonth BETWEEN @startYear AND DATEADD(MONTH, -1, @firstOfMonth)))
		AND (JCCo=@inCompany OR @inCompany IS NULL)
		AND (Contract=@inContract OR @inContract IS NULL)
		AND RevenueType NOT IN (SELECT * from dbo.mfnSplitCsvParam(@inExcludeRevenueType))
	 GROUP BY JCCo, Contract, IsLocked, RevenueType, ContractStatus, GLDepartment) wip
ON	ret.ThroughMonth=wip.ThroughMonth AND
	ret.JCCo=wip.JCCo AND
	ret.Contract=wip.Contract AND
	ret.IsLocked=wip.IsLocked AND
	ret.RevenueType=wip.RevenueType AND
	--ret.ContractStatus=wip.ContractStatus AND
	ret.GLDepartment=wip.GLDepartment

IF EXISTS (SELECT 1 FROM dbo.mckWipArchive WHERE (JCCo=@inCompany OR @inCompany IS NULL) 
											 AND (ThroughMonth=@firstOfMonth OR @inMonth IS NULL) 
											 AND (Contract=@inContract OR @inContract IS NULL)
											 AND RevenueType NOT IN (SELECT * from dbo.mfnSplitCsvParam(@inExcludeRevenueType)))
BEGIN
	DELETE dbo.mckWipArchive WHERE (JCCo=@inCompany OR @inCompany IS NULL) 
							   AND (ThroughMonth=@firstOfMonth OR @inMonth IS NULL) 
							   AND (Contract=@inContract OR @inContract IS NULL)
							   AND RevenueType NOT IN (SELECT * from dbo.mfnSplitCsvParam(@inExcludeRevenueType))
END
INSERT dbo.mckWipArchive SELECT * FROM #tmpWip

DROP TABLE #tmpWip

END
GO

--Test Script
--EXEC mspWIPArchive 1, '12/1/2014', null

ALTER procedure [dbo].[mspGetWIPData]
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				VARCHAR(10) --bContract
,	@inIsLocked				CHAR(1)		--bYN
,	@inExcludeWorkStream	varchar(255)
,	@inExcludeRevenueType	varchar(255)
)
AS
BEGIN

	--Check for GL Period Closing
	--IF NOT	EXISTS (SELECT IsMonthOpen from vfGLClosedMonths('GL',@inMonth) WHERE GLCo=@inCompany AND IsMonthOpen=1)
	--BEGIN
	--	RETURN -1
	--END
	--ELSE

	IF (@inMonth IS NOT NULL) --AND @inMonth >= '12/1/2014')
	BEGIN	
		EXEC dbo.mspWIPRevenue @inCompany,@inMonth,@inContract,@inExcludeRevenueType

		IF EXISTS (SELECT 1 FROM dbo.mckWipCostByJobData WHERE (JCCo=@inCompany OR @inCompany IS NULL) 
														   AND (ThroughMonth=@inMonth OR @inMonth IS NULL) 
														   AND (Contract=@inContract OR @inContract IS NULL)
														   AND RevenueType NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType)))
		BEGIN
			DELETE dbo.mckWipCostByJobData WHERE (JCCo=@inCompany OR @inCompany IS NULL) 
											 AND (ThroughMonth=@inMonth OR @inMonth IS NULL) 
											 AND (Contract=@inContract OR @inContract IS NULL)
											 AND RevenueType NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType))
		END
		INSERT dbo.mckWipCostByJobData SELECT * FROM dbo.mfnGetWIPCostByJob(@inCompany,@inMonth,@inContract,@inIsLocked,@inExcludeWorkStream,@inExcludeRevenueType)

		EXEC dbo.mspWIPCost @inCompany,@inMonth,@inContract,@inExcludeRevenueType	

		EXEC dbo.mspWIPArchive @inCompany,@inMonth,@inContract,@inExcludeRevenueType
	END	
END

/****** Object:  StoredProcedure [dbo].[vspWIPReport]    Script Date: 12/30/2014 4:55:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 11/18/2014 Arun Thomas		Changed the where condition to handle null value 
**								properly and to map pocname parameter to poc
** 12/30/2014 Amit Mody			Updated Where clauses to fix missing rows on reports
** 1/6/2015   Amit Mody			Included WorkOrder field on E and I reports
** 1/30/2015  Amit Mody			Filtered E and I reports to exclude unlocked 
**								contract items and pending/hard-closed contracts,
**								Removed join with JCCOCompany
** 2/2/2015   Amit Mody			Added JCCM Department field to QA edition
** 2/10/2015   Amit Mody		Excluded non-revenue contracts from all editions
******************************************************************************/

ALTER PROC [dbo].[vspWIPReport] 
		@ReportType CHAR(1) = 'E',
		@JCCo TINYINT = 1, 
		@GLDepartment VARCHAR(4) = NULL, 
		@POC bProjectMgr = NULL, 
		@Contract VARCHAR(50) = NULL,
		@SalesPersonID BIGINT = NULL,
		@ThroughMonth date = NULL
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

IF @ThroughMonth IS NULL 
	SET @ThroughMonth = DATEADD(m,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()), 0));
ELSE
	SET @ThroughMonth = dbo.mckfFirstDayOfMonth(@ThroughMonth);

IF (LTRIM(RTRIM(@GLDepartment)) = '') SET @GLDepartment = NULL;
IF @Contract IS NOT NULL SET @Contract=ltrim(rtrim(@Contract));

IF @ReportType = 'Q' 
	BEGIN
		SELECT 
				[ThroughMonth] AS [Through Month],
				A.[JCCo] AS [JC Company],
				A.[Contract] AS [Contract],
				[Contract Description] AS [Contract Description],
				[WorkOrder] AS [Work Order],
				[IsLocked] AS [Is Locked?],
				--[RevenueType] AS [RevenueType],
				[RevenueTypeName] AS [Revenue Type],
				--[ContractStatus] AS [ContractStatus],
				[ContractStatusDesc] AS [Contract Status],
				ISNULL(B.[Department], '') AS [Contract Department],
				[GLDepartment] AS [GL Department],
				[GLDepartmentName] AS [GL Department Name],
				[POC] AS [POC],
				[POCName] AS [POC Name],
				A.[OrigContractAmt] AS [Original Contract Amount],
				[CurrContractAmt] AS [Current Contract Amount],
				[ProjContractAmt] AS [Projected Contract Amount],
				[RevenueIsOverride] AS [Is Revenue Override?],
				[RevenueOverrideTotal] AS [Revenue Override Total],
				[RevenueOverridePercent] AS [Revenue Override %],
				[RevenueOverrideAmount] AS [Revenue Override Amount],
				[Projected Final Contract Value] AS [Projected Final Contract Amount],
				[JTD Billed] AS [JTD Billed],
				[JTD Actual Cost] AS [JTD Actual Cost],
				[Original Cost Budget] AS [Original Cost Budget],
				[Estimated Cost] AS [Estimated Cost],
				[CommittedCostAmount] AS [Open Committed Cost],
				[ProjectedCost] AS [Projected Cost],
				[CostIsOverride] AS [Is Cost Override?],
				[CostOverrideTotal] AS [Cost Override Total],
				[CostOverridePercent] AS [Cost Override %],
				[CostOverrideAmount] AS [Cost Override Amount],
				[Projected Final Cost] AS [Projected Final Cost],
				[EstimatedCostToComplete] AS [Estimated Cost To Complete],
				[Percent Complete] AS [Percent Complete],
				[Projected Final Gross Margin] AS [Projected Final Gross Margin],
				[Projected Final Gross Margin %] AS [Projected Final Gross Margin %],
				[JTD Earned Revenue] AS [JTD Earned Revenue],
				[JTD Earned Gross Margin] AS [JTD Earned Gross Margin],
				[Overbilled] AS [Overbilled],
				[Underbilled] AS [Underbilled],
				[MTD Earned Revenue] AS [MTD Earned Revenue],
				[MTD Actual Cost] AS [MTD Actual Cost],
				[MTD Earned Gross Margin] AS [MTD Earned Gross Margin],
				CAST(CASE COALESCE([MTD Earned Revenue],0) 
					 WHEN 0 THEN 0.00 
					 ELSE [MTD Earned Gross Margin]/[MTD Earned Revenue]
			   		 END 
				AS DECIMAL(18,10)) AS [MTD Earned Gross Margin %],
				[YTD Earned Revenue] AS [YTD Earned Revenue],
				[YTD Actual Cost] AS [YTD Actual Cost],
				[YTD Earned Gross Margin] AS [YTD Earned Gross Margin],
				[ContractIsPositive] AS [Is Contract Positive?],
				CAST([SalesPersonID] AS VARCHAR(50)) + ' - ' + [SalesPerson] AS [Sales Person],
				[VerticalMarket] AS [Vertical Market],
				[Markup] AS [Markup],
				[Straight Line Term Start] AS [Straight Line Term Start],
				[Straight Line Term Months] AS [Straight Line Term Months],
				[CGCJobNumber] AS [CGC Job Number],
				[Batch Processed On] AS [Batch Processed On]
			FROM dbo.mvwWIPReport A --JOIN JCCOCompany B ON A.JCCo = B.JCCo
				LEFT JOIN dbo.JCCM B
				ON A.JCCo=B.JCCo AND A.Contract=ltrim(rtrim(B.Contract))
			WHERE 
				A.ThroughMonth = @ThroughMonth AND
				A.RevenueType <> 'N' AND
				(@JCCo IS NULL OR A.JCCo = @JCCo) AND
				(@GLDepartment IS NULL OR A.GLDepartment = @GLDepartment) AND
				(@POC IS NULL OR A.POC = @POC) AND
				(@Contract IS NULL OR A.[Contract] = @Contract) AND
				(@SalesPersonID IS NULL OR A.SalesPersonID = @SalesPersonID)
	END
ELSE IF @ReportType = 'I'
	BEGIN
		SELECT 
			[ThroughMonth] AS [Through Month],
			A.[JCCo] AS [JC Company],
			[Contract] AS [Contract],
			[Contract Description] AS [Contract Description],
			[WorkOrder] AS [Work Order],
			[RevenueTypeName] AS [Revenue Type],
			[ContractStatusDesc] AS [Contract Status],
			[GLDepartment] AS [GL Department],
			[GLDepartmentName] AS [GL Department Name],
			[POC] AS [POC],
			[POCName] AS [POC Name],
			[Projected Final Contract Value] AS [Projected Final Contract Amount],
			[JTD Billed] AS [JTD Billed],
			[JTD Actual Cost] AS [JTD Actual Cost],
			[Projected Final Cost] AS [Projected Final Cost],
			[Estimated Cost] AS [Estimated Cost],
			[EstimatedCostToComplete] AS [Estimated Cost To Complete],
			[Percent Complete] AS [Percent Complete],
			[Projected Final Gross Margin] AS [Projected Final Gross Margin],
			[Projected Final Gross Margin %] AS [Projected Final Gross Margin %],
			[JTD Earned Revenue] AS [JTD Earned Revenue],
			[JTD Earned Gross Margin] AS [JTD Earned Gross Margin],
			[Overbilled] AS [Overbilled],
			[Underbilled] AS [Underbilled],
			[MTD Earned Revenue] AS [MTD Earned Revenue],
			[MTD Earned Gross Margin] AS [MTD Earned Gross Margin],
			CAST(CASE COALESCE([MTD Earned Revenue],0) 
					 WHEN 0 THEN 0.00 
					 ELSE [MTD Earned Gross Margin]/[MTD Earned Revenue]
			   		 END 
				AS DECIMAL(18,10)) AS [MTD Earned Gross Margin %],
			CAST([SalesPersonID] AS VARCHAR(50)) + ' - ' + [SalesPerson] AS [Sales Person],
			[VerticalMarket] AS [Vertical Market],
			[CGCJobNumber] AS [CGC Job Number]			
		FROM dbo.mvwWIPReport A --JOIN JCCOCompany B ON A.JCCo = B.JCCo
		WHERE
			((A.Contract IS NOT NULL AND A.IsLocked = 'Y') OR (A.WorkOrder IS NOT NULL)) AND
			A.ContractStatus IN (1,2) AND
			A.ThroughMonth = @ThroughMonth AND
			A.RevenueType <> 'N' AND
			(@JCCo IS NULL OR A.JCCo = @JCCo) AND
			(@GLDepartment IS NULL OR A.GLDepartment = @GLDepartment) AND
			(@POC IS NULL OR A.POC = @POC) AND
			(@Contract IS NULL OR A.[Contract] = @Contract) AND
			(@SalesPersonID IS NULL OR A.SalesPersonID = @SalesPersonID)			
	END
ELSE IF @ReportType = 'E'
	BEGIN
		SELECT
			A.[JCCo] AS [JC Company],
			[Contract] AS [Contract],
			[Contract Description] AS [Contract Description],
			[WorkOrder] AS [Work Order],
			SUM([Projected Final Contract Value]) AS [Projected Final Contract Amount],
			SUM([JTD Billed]) AS [JTD Billed],
			SUM([JTD Actual Cost]) AS [JTD Actual Cost],
			SUM([Projected Final Cost]) AS [Projected Final Cost],
			SUM([EstimatedCostToComplete]) AS [Estimated Cost To Complete],
			SUM([Percent Complete]) AS [Percent Complete],
			SUM([Projected Final Gross Margin]) AS [Projected Final Gross Margin],
			SUM([Projected Final Gross Margin %]) AS [Projected Final Gross Margin %],
			SUM([JTD Earned Revenue]) AS [JTD Earned Revenue],
			SUM([JTD Earned Gross Margin]) AS [JTD Earned Gross Margin],
			SUM([Overbilled]) AS [Overbilled],
			SUM([Underbilled]) AS [Underbilled],
			[CGCJobNumber] AS [CGC Job Number]
		FROM dbo.mvwWIPReport A --JOIN JCCOCompany B ON A.JCCo = B.JCCo
		WHERE
			((A.Contract IS NOT NULL AND A.IsLocked = 'Y') OR (A.WorkOrder IS NOT NULL)) AND
			A.ThroughMonth = @ThroughMonth AND
			A.ContractStatus IN (1,2) AND
			A.RevenueType <> 'N' AND
			(@JCCo IS NULL OR A.JCCo = @JCCo) AND
			(@GLDepartment IS NULL OR A.GLDepartment = @GLDepartment) AND
			(@POC IS NULL OR A.POC = @POC) AND
			(@Contract IS NULL OR A.[Contract] = @Contract) AND
			(@SalesPersonID IS NULL OR A.SalesPersonID = @SalesPersonID)
		GROUP BY A.[JCCo], [Contract],[Contract Description],[WorkOrder],[CGCJobNumber]
	END
GO

GRANT EXECUTE
    ON OBJECT::[dbo].[vspWIPReport] TO [MCKINSTRY\ViewpointUsers];
GO

--Test Script
--EXEC  [dbo].[vspWIPReport] 'Q', 1 --(12/1/2014)
--EXEC  [dbo].[vspWIPReport] 'I', 1, null, null, null, null, '1/1/2015'
--EXEC  [dbo].[vspWIPReport] 'E', 1, null, null, null, null, '1/1/2015'


--DROP TABLE mckProjectReport
IF EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='mckProjectReport')
BEGIN
	PRINT 'DROP TABLE mckProjectReport'
	DROP TABLE dbo.mckProjectReport
END
go

--create table mckProjectReport
PRINT 'CREATE TABLE mckProjectReport'
go
CREATE TABLE dbo.mckProjectReport
(
	[Month] smalldatetime NOT NULL
,	[JCCo] [tinyint] NOT NULL
,	[GL Department] [varchar](4) NOT NULL
,	[GL Department Name] [varchar](60) NULL
,	[Contract] [varchar](10) NOT NULL
, 	[Contract Description] [varchar](60) NULL
,	[Revenue Type] [varchar](10) NULL
,	[Sales Person] [varchar](30) NULL
,	[Customer #] int NULL
,	[Customer Name] [varchar](60) NULL
,	[Customer Contact Name] [varchar](30) NULL
,	[Customer Phone Number] [varchar](20) NULL
,	[Customer Email Address] [varchar](60) NULL
,   [Current Contract Value] [decimal](18, 2) NULL
,	[Projected Contract Value] [decimal](18, 2) NULL
,	[Pending COs (Calculated)] [decimal](18, 2) NULL
,	[Projected Contract Value Previous Month] [decimal](18, 2) NULL
,	[JTD Costs Previous Month] [decimal](18, 2) NULL
,	[Cost Projections Previous Month] [decimal](18, 2) NULL
,	[% Complete Previous Month] [numeric](18, 10) NULL
,	[Current JTD Costs] [decimal](18, 2) NULL
,	[Current JTD Amount Billed] [decimal](18, 2) NULL
,	[Current JTD Revenue Earned] [numeric](38, 8) NULL
,	[Current JTD Net Under Over Billed] [decimal](18, 2) NULL
,	[JTD Net Cash Position] [numeric](38, 2) NULL
,	[Current Retention Unbilled] [numeric](12, 2) NULL
,	[Unpaid A/R Balance] [numeric](38, 2) NULL
,	[AR Current Amount] [numeric](38, 2) NULL
,	[AR 31-60 Days Amount] [numeric](38, 2) NULL
,	[AR 61-90 Days Amount] [numeric](38, 2) NULL
,	[AR Over 90 Amount] [numeric](38, 2) NULL
,	[Current Projected Final Contract Amount] [numeric](29, 8) NULL
,	[Current Projected Final Cost] [decimal](37, 17) NULL
,	[Current Projected Final Gross Margin] [numeric](38, 17) NULL
,	[Current Projected Final Gross Margin %] DECIMAL(18,10) NULL
,	[MOM Variance of Projected Final Contract Amount] [numeric](29, 8) NULL
,	[MOM Variance of Projected Final Cost] [decimal](37, 17) NULL
,	[MOM Variance of Projected Final Gross Margin] [numeric](38, 17) NULL
,	[MOM Variance of Projected Final Gross Margin %] DECIMAL(18,10) NULL
,	[Processed On] [datetime] NULL
)
go

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckProjectReport_Month_JCCo_GLDepartment_Contract')
    DROP INDEX IX_mckProjectReport_Month_JCCo_GLDepartment_Contract ON dbo.mckProjectReport;
GO
CREATE NONCLUSTERED INDEX IX_mckProjectReport_Month_JCCo_GLDepartment_Contract
    ON dbo.mckProjectReport (Month, JCCo, [GL Department], Contract);
GO

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckProjectReport_Month_JCCo')
    DROP INDEX IX_mckProjectReport_Month_JCCo ON dbo.mckProjectReport;
GO
CREATE NONCLUSTERED INDEX IX_mckProjectReport_Month_JCCo
    ON dbo.mckProjectReport (Month, JCCo);
GO

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckProjectReport_Month_JCCo_Contract')
    DROP INDEX IX_mckProjectReport_Month_JCCo_Contract ON dbo.mckProjectReport;
GO
CREATE NONCLUSTERED INDEX IX_mckProjectReport_Month_JCCo_Contract
    ON dbo.mckProjectReport (Month, JCCo, Contract);
GO

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckProjectReport_Month_JCCo_GLDepartment')
    DROP INDEX IX_mckProjectReport_Month_JCCo_GLDepartment ON dbo.mckProjectReport;
GO
CREATE NONCLUSTERED INDEX IX_mckProjectReport_Month_JCCo_GLDepartment
    ON dbo.mckProjectReport (Month, JCCo, [GL Department]);
GO

GRANT SELECT ON dbo.mckProjectReport TO [public]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptProjectReport]'))
	DROP PROCEDURE [dbo].[mckrptProjectReport]
GO

-- =======================================================================================================================
-- Author:		Amit Mody
-- Create date: 10/06/2014
-- Date       Author            Description
-- ---------- ----------------- ------------------------------------------------------------------------------------------
-- 10/08/2014 Amit Mody			Updated
-- 11/03/2014 Amit Mody			Added filtering ability by Company, Department, Contract and PoC
-- 11/11/2014 Amit Mody			Aggregating WIP numbers by contract, updated parameters
-- 11/18/2014 Amit Mody			Added net cash position and AR aged amount calculations
-- 12/08/2014 Amit Mody			Adding date parameter
-- 1/8/2015   Amit Mody			Performance tuning for mitigating table locks
-- 1/20/2015  Amit Mody			Adding Department to selection
-- 1/22/2015  Amit Mody			Attempting elimination of table locks by employing a temp table in lieu of complex joins
-- 1/29/2015  Amit Mody			As Excel/VBA throws error 1004, removing temp table and moving to scheduled processing
-- 2/18/2015  Amit Mody			Added a parameter for generating report for revenue vs. non-revenue contracts
-- =======================================================================================================================

CREATE PROCEDURE [dbo].[mckrptProjectReport] 
	@reportMonth datetime = null
,	@company tinyint = null
,	@dept varchar(10) = null
,	@revType varchar(10) = null
,	@contract varchar(10) = null
AS
BEGIN

DECLARE @thisMonth DateTime
SELECT @thisMonth=dbo.mfnFirstOfMonth(@reportMonth)

SELECT	
--	[Month],
	[JCCo]
--,	[GL Department]
--,	[GL Department Name]
,	[Contract]
, 	[Contract Description]
,	[Sales Person] 
,	[Customer #] 
,	[Customer Name] 
,	[Customer Contact Name] 
,	[Customer Phone Number]
,	[Customer Email Address]
,   	[Current Contract Value]
,	[Projected Contract Value] AS [Projected Final Contract Amount]
,	[Pending COs (Calculated)]
,	[Projected Contract Value Previous Month]
,	[JTD Costs Previous Month]
,	[Cost Projections Previous Month]
,	[% Complete Previous Month]
,	[Current JTD Costs]
,	[Current JTD Amount Billed]
,	[Current JTD Revenue Earned]
,	[Current JTD Net Under Over Billed]
,	[JTD Net Cash Position]
,	[Current Retention Unbilled]
,	[Unpaid A/R Balance]
,	[AR Current Amount]
,	[AR 31-60 Days Amount]
,	[AR 61-90 Days Amount]
,	[AR Over 90 Amount]
,	[Current Projected Final Contract Amount]
,	[Current Projected Final Cost]
,	[Current Projected Final Gross Margin]
,	[Current Projected Final Gross Margin %]
,	[MOM Variance of Projected Final Contract Amount]
,	[MOM Variance of Projected Final Cost]
,	[MOM Variance of Projected Final Gross Margin]
,	[MOM Variance of Projected Final Gross Margin %] 
FROM	dbo.mckProjectReport 
WHERE	Month=@thisMonth 
	AND (@company IS NULL OR JCCo=@company) 
	AND (@dept IS NULL OR [GL Department]=@dept) 
	AND (@revType IS NULL OR [Revenue Type]=@revType)
	AND (@contract IS NULL OR Contract=@contract)

END
GO

--Test Script
--EXEC [dbo].[mckrptProjectReport]
--EXECUTE [dbo].[mckrptProjectReport]  N'11/1/2014', 1
--EXEC [dbo].[mckrptProjectReport] N'11/1/2014', 1, N'0000'
--EXEC [dbo].[mckrptProjectReport] N'11/1/2014', 1, N'0000', 'N'
--EXEC [dbo].[mckrptProjectReport] N'12/1/2014', 1, null, 'N'
--EXEC [dbo].[mckrptProjectReport] N'12/1/2014', 1, null, 'C'


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptProjectReportRefresh]'))
	DROP PROCEDURE [dbo].[mckrptProjectReportRefresh]
GO

-- =======================================================================================================================
-- Author:		Amit Mody
-- Create date: 1/29/2015
-- Date       Author            Description
-- ---------- ----------------- ------------------------------------------------------------------------------------------
-- 2/19/2015  Amit Mody		Added RevenueType and ProcessedOn fields to resultset
-- =======================================================================================================================

CREATE PROCEDURE [dbo].[mckrptProjectReportRefresh] 
	@reportMonth datetime = null
,	@company tinyint = null
,	@dept varchar(10) = null
,	@revType varchar(10) = null
,	@contract varchar(10) = null
AS
BEGIN

DECLARE @thisMonth DateTime
DECLARE @lastMonth DateTime

SELECT @thisMonth=DATEADD(m, DATEDIFF(m, 0, ISNULL(@reportMonth, GETDATE())), 0)
SELECT @lastMonth=DATEADD(m, DATEDIFF(m, 0, ISNULL(@reportMonth, GETDATE())) - 1, 0)

IF OBJECT_ID('tempdb..#tmpProjReport') IS NOT NULL
    DROP TABLE #tmpProjReport

SELECT * INTO #tmpProjReport FROM dbo.mckProjectReport WHERE 1=2

-----------------------------
-- *** WIP DERIVATIVES *** --
-----------------------------
INSERT INTO #tmpProjReport
SELECT 
	@thisMonth AS [Month]
,	wip.JCCo
,	wip.GLDepartment AS [GL Department]
,	wip.GLDepartmentName AS [GL Department Name]
,	wip.Contract
,	'' AS [Contract Description]
,	wip.RevenueType AS [Revenue Type]
,	'' AS [Sales Person]
,	0 AS [Customer #]
,	'' AS [Customer Name]
,	'' AS [Customer Contact Name]
,	'' AS [Customer Phone Number]
,	'' AS [Customer Email Address]
,   wip.[Current Contract Value]
,	wip.[Current WIP Revenue] AS [Projected Contract Value]
,	wip.[Current Contract Value] - wip.[Current WIP Revenue] AS [Pending COs (Calculated)]
,	wip.[Prior WIP Revenue] AS [Projected Contract Value Previous Month]
,	wip.[Prior JTD Actual Cost] AS [JTD Costs Previous Month]
,	wip.[Prior Projected Cost] AS [Cost Projections Previous Month]
,	CASE WHEN (wip.[Prior Projected Cost] = 0) 
		 THEN 0.0 
		 ELSE CAST(wip.[Prior JTD Actual Cost]/wip.[Prior Projected Cost] AS DECIMAL(18,10)) 
	END AS [% Complete Previous Month]
,	wip.[Current JTD Actual Cost] AS [Current JTD Costs]
,	wip.[Current JTD Amount Billed]
,	wip.[Current JTD Revenue Earned]
,	wip.[Current JTD Net Under Over Billed]
,	0 AS [JTD Net Cash Position]
,	0 AS [Current Retention Unbilled]
,	0 AS [Unpaid A/R Balance]
,	0 AS [AR Current Amount]
,	0 AS [AR 31-60 Days Amount]
,	0 AS [AR 61-90 Days Amount]
,	0 AS [AR Over 90 Amount]
,	wip.[Current WIP Revenue] AS [Current Projected Final Contract Amount]
,	wip.[Current WIP Cost] AS [Current Projected Final Cost]
,	wip.[Current WIP GM] AS [Current Projected Final Gross Margin]
,	wip.[Current WIP GM %] AS [Current Projected Final Gross Margin %]
,	wip.[Current WIP Revenue] - wip.[Prior WIP Revenue] AS [MOM Variance of Projected Final Contract Amount]
,	wip.[Current WIP Cost] - wip.[Prior WIP Cost] AS [MOM Variance of Projected Final Cost]
,	wip.[Current WIP GM] - wip.[Prior WIP GM] AS [MOM Variance of Projected Final Gross Margin]
,	wip.[Current WIP GM %] - wip.[Prior WIP GM %] AS [MOM Variance of Projected Final Gross Margin %]
,	GETDATE() AS [Processed On]
FROM
	(SELECT	currWip.JCCo
	 ,		currWip.Contract
	 ,		currWip.GLDepartment
	 ,		currWip.GLDepartmentName
	 ,		currWip.RevenueType
	 ,		SUM(ISNULL(currWip.[CurrContractAmt], 0)) as [Current Contract Value]
	 ,		SUM(ISNULL(currWip.[JTD Actual Cost], 0)) as [Current JTD Actual Cost]
	 ,		SUM(ISNULL(currWip.[JTD Billed], 0)) as [Current JTD Amount Billed]
	 ,		SUM(ISNULL(currWip.[JTD Earned Revenue], 0)) as [Current JTD Revenue Earned]
	 ,		SUM(ISNULL(currWip.Overbilled, 0)) - SUM(ISNULL(currWip.Underbilled, 0)) as [Current JTD Net Under Over Billed]
	 ,		SUM(ISNULL(currWip.[JTD Earned Gross Margin], 0)) as [Current JTD Net Cash Position]
	 ,		SUM(ISNULL(currWip.[Projected Final Cost], 0)) as [Current Projected Cost]
	 ,		SUM(ISNULL(currWip.[Projected Final Contract Value], 0)) as [Current WIP Revenue]
	 ,		SUM(ISNULL(currWip.[Projected Final Cost], 0)) as [Current WIP Cost]
	 ,		SUM(ISNULL(currWip.[Projected Final Gross Margin], 0)) as [Current WIP GM]
	 ,		CASE SUM(ISNULL(currWip.[Projected Final Contract Value], 0)) 
				 WHEN 0
				 THEN 0.0
				 ELSE CAST(SUM(ISNULL(currWip.[Projected Final Gross Margin], 0))/SUM(ISNULL(currWip.[Projected Final Contract Value], 0)) AS DECIMAL(18,10)) 
			END AS [Current WIP GM %]
	 ,		SUM(ISNULL(prevWip.[JTD Actual Cost], 0)) as [Prior JTD Actual Cost]
	 ,		SUM(ISNULL(prevWip.[ProjectedCost], 0)) as [Prior Projected Cost]
	 ,		SUM(ISNULL(prevWip.[JTD Billed], 0)) as [Prior JTD Amount Billed]
	 ,		SUM(ISNULL(prevWip.[JTD Earned Revenue], 0)) as [Prior JTD Revenue Earned]
	 ,		SUM(ISNULL(prevWip.[JTD Earned Revenue], 0)) - SUM(ISNULL(prevWip.[JTD Billed], 0)) as [Prior JTD Net Under Over Billed]
	 ,		SUM(ISNULL(prevWip.[Projected Final Contract Value], 0)) as [Prior WIP Revenue]
	 ,		SUM(ISNULL(prevWip.[Projected Final Cost], 0)) as [Prior WIP Cost]
	 ,		SUM(ISNULL(prevWip.[Projected Final Gross Margin], 0)) as [Prior WIP GM]
	 ,		CASE SUM(ISNULL(prevWip.[Projected Final Contract Value], 0)) 
				 WHEN 0
				 THEN 0.0
				 ELSE CAST(SUM(ISNULL(prevWip.[Projected Final Gross Margin], 0))/SUM(ISNULL(prevWip.[Projected Final Contract Value], 0)) AS DECIMAL(18,10))
			END AS [Prior WIP GM %]
	 FROM	
		(SELECT JCCo, Contract, GLDepartment, GLDepartmentName, IsLocked, RevenueType, [CurrContractAmt], [ProjContractAmt], [ProjectedCost], [JTD Actual Cost], [JTD Billed], [JTD Earned Revenue], Overbilled, Underbilled, [JTD Earned Gross Margin], [Projected Final Contract Value], [Projected Final Cost], [Projected Final Gross Margin]
			FROM dbo.mvwWIPReport 
			WHERE	ThroughMonth=@thisMonth
			AND	Contract IS NOT NULL
			AND (@company IS NULL OR JCCo = @company)
			AND (@contract IS NULL OR Contract = @contract)
			AND (@dept IS NULL OR GLDepartment = @dept)
			AND ContractStatus IN (1,2) 
			AND IsLocked = 'Y') currWip LEFT JOIN
		(SELECT JCCo, Contract, GLDepartment, IsLocked, RevenueType, [CurrContractAmt], [ProjContractAmt], [ProjectedCost], [JTD Actual Cost], [JTD Billed], [JTD Earned Revenue], Overbilled, Underbilled, [JTD Earned Gross Margin], [Projected Final Contract Value], [Projected Final Cost], [Projected Final Gross Margin]
			FROM dbo.mvwWIPReport 
			WHERE	ThroughMonth=@lastMonth
			AND	Contract IS NOT NULL
			AND (@company IS NULL OR JCCo = @company)
			AND (@contract IS NULL OR Contract = @contract)
			AND (@dept IS NULL OR GLDepartment = @dept)
			AND ContractStatus IN (1,2) 
			AND IsLocked = 'Y') prevWip
		ON  currWip.JCCo=prevWip.JCCo
			AND currWip.Contract=prevWip.Contract
			AND currWip.GLDepartment=prevWip.GLDepartment
			AND	currWip.IsLocked=prevWip.IsLocked
			AND	currWip.RevenueType=prevWip.RevenueType
	 GROUP BY
			currWip.JCCo
	 ,		currWip.Contract
	 ,		currWip.GLDepartment
	 ,		currWip.GLDepartmentName
	 ,		currWip.RevenueType
	 ) wip 
ORDER BY 
		wip.JCCo
,		wip.Contract 
	 
---------------------------------
-- *** CONTRACT & CUSTOMER *** --
---------------------------------
UPDATE	wip
SET		[Contract Description]=ISNULL(jccm.Description, '')
,		[Customer #]=ISNULL(jccm.Customer, 0)
,		[Current Retention Unbilled]=ISNULL(jccm.CurrentRetainAmt, 0.0)
,		[Sales Person]=ISNULL(jcmp.Name, '')
,		[Customer Name]=ISNULL(arcm.Name, '')
,		[Customer Contact Name]=ISNULL(arcm.Contact, '')
,		[Customer Phone Number]=ISNULL(arcm.Phone, '')
,		[Customer Email Address]=ISNULL(arcm.EMail, '')
FROM	#tmpProjReport wip 
		LEFT OUTER JOIN dbo.JCCM jccm
			ON	wip.JCCo=jccm.JCCo
			AND wip.Contract=ltrim(rtrim(jccm.Contract))
		LEFT OUTER JOIN dbo.ARCM arcm
			ON jccm.CustGroup=arcm.CustGroup
			AND jccm.Customer=arcm.Customer
		LEFT OUTER JOIN dbo.JCMP jcmp
			ON jcmp.JCCo=jccm.JCCo
			AND jcmp.ProjectMgr=jccm.udPOC

-----------------------------
-- *** AR AGED AMOUNTS *** --
-----------------------------
UPDATE	wip
SET		[Unpaid A/R Balance]=ISNULL(ar.[Current], 0.0) + ISNULL(ar.[31-60 Days], 0.0) + ISNULL(ar.[61-90 Days], 0.0) + ISNULL(ar.[>91 Days], 0.0)
,		[AR Current Amount]=ISNULL(ar.[Current], 0.0)
,		[AR 31-60 Days Amount]=ISNULL(ar.[31-60 Days], 0.0)
,		[AR 61-90 Days Amount]=ISNULL(ar.[61-90 Days], 0.0)
,		[AR Over 90 Amount]=ISNULL(ar.[>91 Days], 0.0)
FROM	#tmpProjReport wip 
		LEFT OUTER JOIN
			(SELECT * FROM dbo.mvwARAgedAmount 
			 WHERE @company IS NULL OR ARCo=@company) ar
		ON	wip.JCCo=ar.ARCo
			AND wip.Contract=ar.Contract

-------------------------------
-- *** NET CASH POSITION *** --
-------------------------------
UPDATE	wip
SET		[JTD Net Cash Position]=ncp.JTDNetCashPosition
FROM	#tmpProjReport wip	
		INNER JOIN
			(SELECT jcs.JCCo, jcs.Contract, glpi.Instance as GLDepartment, (SUM(jcs.ReceivedAmt)-SUM(jcs.ActualCost)) AS JTDNetCashPosition
			 FROM	dbo.brvJCContStat jcs (NOLOCK) LEFT OUTER JOIN
					dbo.JCCI jcci ON	
						jcci.JCCo=jcs.JCCo
					AND jcci.Contract=jcs.Contract
					AND jcci.Item=jcs.Item LEFT OUTER JOIN
					dbo.JCDM jcdm ON
						jcci.JCCo=jcdm.JCCo
					AND jcci.Department=jcdm.Department JOIN
					dbo.GLPI glpi ON
						jcdm.GLCo=glpi.GLCo
					AND glpi.PartNo=3
					AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4)
			 WHERE 	Mth <= @thisMonth
				AND (@company IS NULL OR jcs.JCCo = @company)
				AND (@contract IS NULL OR jcs.Contract = @contract)
			 GROUP BY jcs.JCCo, jcs.Contract, glpi.Instance
			) ncp
		ON	wip.JCCo=ncp.JCCo
		AND wip.Contract=ltrim(rtrim(ncp.Contract))
		AND wip.[GL Department]=ncp.GLDepartment

IF EXISTS (SELECT 1 FROM dbo.mckProjectReport WHERE Month=@thisMonth AND (@company IS NULL OR JCCo=@company) AND (@dept IS NULL OR [GL Department]=@dept) AND (@contract IS NULL OR Contract=@contract))
BEGIN
	DELETE dbo.mckProjectReport WHERE Month=@thisMonth AND (@company IS NULL OR JCCo=@company) AND (@dept IS NULL OR [GL Department]=@dept) AND (@contract IS NULL OR Contract=@contract)
END
INSERT dbo.mckProjectReport SELECT * FROM #tmpProjReport

DROP TABLE #tmpProjReport

END
GO

--Test Script
--EXEC [dbo].[mckrptProjectReportRefresh]
--EXECUTE [dbo].[mckrptProjectReportRefresh] '11/1/2014'
--EXECUTE [dbo].[mckrptProjectReportRefresh] '1/1/2015', 60
--EXEC [dbo].[mckrptProjectReportRefresh] '1/1/2015', 1, '0000'


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptProjectReportParams]'))
	DROP PROCEDURE [dbo].[mckrptProjectReportParams]
GO

-- ==================================================================================================================
-- Author:		Amit Mody
-- Create date: 10/08/2014
-- Change History
-- Date       Author            Description
-- ---------- ----------------- -------------------------------------------------------------------------------------
-- 1/29/2015  Amit Mody			Updated to use mckProjectReport
-- 2/19/2015  Amit Mody			Parameterized for revenue type of contract
-- ==================================================================================================================

CREATE PROCEDURE [dbo].[mckrptProjectReportParams] 
	@returnField varchar(25) = 'CMPN' --'DEPT', 'CNTR', 'POCT'
,	@companies varchar(200) = ''
,	@depts varchar(200) = ''
,	@contracts varchar(200) = ''
,	@pocs varchar(200) = ''
,	@isRev tinyint = 1
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX)

	SET @sql = N'SELECT'+ CASE @returnField	WHEN 'CMPN' THEN ' distinct pr.[JCCo],COALESCE(hqco.Name, '''') AS [JCCoName]'
											WHEN 'DEPT' THEN ' distinct pr.[GL Department] AS [Dept],pr.[GL Department Name] AS [DeptName]'
											WHEN 'CNTR' THEN ' distinct pr.[Contract],pr.[Contract Description] AS [ContractDesc]'
											WHEN 'POCT' THEN ' distinct pr.[Sales Person] AS [POC],pr.[Sales Person] AS [POCName]'
						  END 
						+ ' FROM dbo.mckProjectReport pr'
						+ ' LEFT JOIN dbo.HQCO hqco'
						+ ' ON hqco.HQCo=pr.JCCo'
						+ ' WHERE'
						+ ' hqco.udTESTCo <> ''Y'' AND'
						+ CASE @isRev	WHEN 1 THEN ' pr.[Revenue Type] <> ''N'' AND'
										ELSE ' pr.[Revenue Type] = ''N'' AND'
						  END
						+ CASE @companies	WHEN '' THEN ' pr.JCCo IS NOT NULL AND'
											ELSE ' pr.JCCo IN (' + @companies	+ ') AND'
						  END
						+ CASE @contracts	WHEN '' THEN ' pr.Contract IS NOT NULL AND'
											ELSE ' pr.Contract IN (' + @contracts	+ ') AND'
						  END
						+ CASE @depts	WHEN '' THEN ' pr.[GL Department] IS NOT NULL'
										ELSE ' pr.[GL Department] IN (' + @depts	+ ')'
						  END
						+ CASE @pocs	WHEN '' THEN ''
										ELSE ' AND pr.[Sales Person] IN (' + @pocs	+ ')'
						  END
						+ ' ORDER BY'
						+ CASE @returnField	WHEN 'CMPN' THEN ' pr.JCCo'
											WHEN 'DEPT' THEN ' pr.[GL Department],pr.[GL Department Name]'
											WHEN 'CNTR' THEN ' pr.Contract,pr.[Contract Description]'
											WHEN 'POCT' THEN ' pr.[Sales Person]'
						  END 

	--SELECT @sql
	EXEC sp_executesql @sql

END
GO

--Test Script
--*** CORE TEST CASES ***
--EXEC [mckrptProjectReportParams] 'CMPN'
--EXEC [mckrptProjectReportParams] 'DEPT', 1
--EXEC [mckrptProjectReportParams] 'DEPT', 1, '', '''10054-'''
--EXEC [mckrptProjectReportParams] 'CNTR', 1
--EXEC [mckrptProjectReportParams] 'CNTR', 1, '''0000'''

--EXEC [mckrptProjectReportParams] 'CMPN', '', '', '', '', 0
--EXEC [mckrptProjectReportParams] 'DEPT', 1, '', '', '', 0
--EXEC [mckrptProjectReportParams] 'DEPT', 1, '', '''100115-''', '', 0
--EXEC [mckrptProjectReportParams] 'CNTR', 1, '', '', '', 0
--EXEC [mckrptProjectReportParams] 'CNTR', 1, '''0000''', '', '', 0

--*** OTHER TESTS ***
--EXEC [mckrptProjectReportParams]
--EXEC [mckrptProjectReportParams] 'DEPT'
--EXEC [mckrptProjectReportParams] 'CNTR'
--EXEC [mckrptProjectReportParams] 'POCT'
--EXEC [mckrptProjectReportParams] 'CMPN', '1,20,101' 
--EXEC [mckrptProjectReportParams] 'DEPT', '1', '''0000'',''0280'''
--EXEC [mckrptProjectReportParams] 'CNTR', '1', '', '''10000-'',''14382-'''
--EXEC [mckrptProjectReportParams] 'POCT', '1', '', '', '109'

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptARBandOTax]'))
	DROP PROCEDURE [dbo].[mckrptARBandOTax]
GO

-- =================================================================================================================================
-- Author:		Eric Shafer
-- Create date: 8/8/2014
-- Description:	Reporting proc for AR B and O Tax Report.  
-- Performs PIVOT on the data to dynamically produce columns and aggregates tax values from AR Invoices (ARTH)
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 09/05/2014 Amit Mody			Updated
-- 09/15/2014 Amit Mody			Updated query for location columns and breakdown of tax amount
-- 12/29/2014 Amit Mody			Removed 'Sales Tax as Reported by AR’ field and appended AR transactions without associated contract
-- 01/20/2015 Amit Mody			Rectified join with dbo.udGLDept to fix un-necessarily excluded AR transactions
-- 02/05/2015 Amit Mody			Filtered resultset by ARTransactionTypes A, C, I, M, W
-- ==================================================================================================================================

CREATE PROCEDURE [dbo].[mckrptARBandOTax] 
	@StartDate datetime = null,
	@EndDate datetime = null
AS
BEGIN
	IF ((@StartDate IS NULL) OR (@StartDate > GETDATE()))
	BEGIN
		SET @StartDate = DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)
	END

	IF ((@EndDate IS NULL) OR (@EndDate < @StartDate) OR (@EndDate > GETDATE()))
	BEGIN
		SET @EndDate = GETDATE()
	END
	
	SELECT * FROM
	(SELECT
			  l.ARCo
		,     l.Contract
		,     l.ARTrans
		,     l.ApplyMth
		,     glpi.Instance
		,     glpi.Description AS GLDeptName
		,     ISNULL(udgldept.OperatingUnit, '') AS OperatingUnit
		,     hqtx.TaxCode
		,     hqtl.TaxLink
		,     hqtx2.udReportingCode
		,     glu.City
		,     glu.PostOffice
		,	  dbo.vfHQTaxRate(l.TaxGroup, l.TaxCode,GETDATE()) AS [Sales Tax Rate]
		,	  SUM(l.TaxBasis) /*boTots.TotalAmt*/ * dbo.vfHQTaxRate(l.TaxGroup, l.TaxCode, GETDATE()) AS [Calculated Sales Tax]
		,	  bo.Description AS BOClass
		,     SUM(l.Amount) AS InvoiceAmount
		,     SUM(l.TaxBasis) AS TaxBasis
		,     SUM(l.TaxAmount) AS TaxAmount
		,     (SUM(l.Amount) - SUM(l.TaxAmount)) AS NetAmount
		,	  MAX(hqtx2.NewRate) AS JurisdictionTaxRate
		,     (SUM(l.Amount) - SUM(l.TaxAmount)) * MAX(hqtx2.NewRate) AS JurisdictionTax
	FROM	 dbo.ARTH h
		JOIN dbo.ARTL l ON l.ARCo = h.ARCo AND l.ARTrans = h.ARTrans AND l.Mth = h.Mth
		JOIN dbo.JCCM c ON c.JCCo = h.JCCo AND c.Contract = h.Contract
		LEFT JOIN dbo.udBandOClass bo ON c.udBOClass = bo.BOClassCode
		JOIN dbo.HQTX hqtx ON l.TaxGroup=hqtx.TaxGroup AND l.TaxCode=hqtx.TaxCode
		JOIN dbo.HQTL hqtl ON hqtl.TaxGroup=hqtx.TaxGroup AND hqtl.TaxCode=hqtx.TaxCode 
		JOIN dbo.HQTX hqtx2 ON hqtl.TaxGroup=hqtx2.TaxGroup AND hqtl.TaxLink=hqtx2.TaxCode 
		JOIN dbo.JCCI jcci ON l.JCCo=jcci.JCCo AND l.Contract=jcci.Contract AND l.Item=jcci.Item
		JOIN dbo.JCDM jcdm ON jcci.JCCo=jcdm.JCCo AND jcci.Department=jcdm.Department 
		JOIN dbo.GLPI glpi ON jcdm.JCCo=glpi.GLCo AND glpi.PartNo=3 AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4) 
		LEFT JOIN dbo.udGLDept udgldept ON glpi.GLCo=udgldept.Co AND glpi.Instance=udgldept.GLDept 
		LEFT JOIN dbo.udGeographicLookup glu ON hqtx2.udCityId=glu.McKCityId
	WHERE
		(h.Mth BETWEEN @StartDate AND @EndDate) AND h.ARTransType IN ('A','C','I','M','W')
	GROUP BY
			  l.ARCo
		,     l.Contract
		,     l.ARTrans
		,     l.ApplyMth
		,     l.TaxGroup
		,     l.TaxCode
		,     glpi.Instance
		,     glpi.Description
		,     udgldept.OperatingUnit  
		,     hqtx.TaxCode
		,     hqtl.TaxLink
		,     hqtx2.udReportingCode   
		,     glu.City
		,     glu.PostOffice
		,	  bo.Description
	UNION ALL
	SELECT
			  l.ARCo
		,     COALESCE(l.Contract, '') AS Contract
		,     l.ARTrans
		,     l.ApplyMth
		,     '' AS GLDept
		,     '' AS GLDeptName
		,     '' AS OperatingUnit 
		,     hqtx.TaxCode
		,     hqtl.TaxLink
		,     hqtx2.udReportingCode
		,     glu.City
		,     glu.PostOffice
		,	  dbo.vfHQTaxRate(l.TaxGroup, l.TaxCode,GETDATE()) AS [Sales Tax Rate]
		,	  SUM(l.TaxBasis) * dbo.vfHQTaxRate(l.TaxGroup, l.TaxCode, GETDATE()) AS [Calculated Sales Tax]
		,	  '' AS BOClass
		,     SUM(l.Amount) AS InvoiceAmount
		,     SUM(l.TaxBasis) AS TaxBasis
		,     SUM(l.TaxAmount) AS TaxAmount
		,     (SUM(l.Amount) - SUM(l.TaxAmount)) AS NetAmount
		,	  MAX(hqtx2.NewRate) AS JurisdictionTaxRate
		,     (SUM(l.Amount) - SUM(l.TaxAmount)) * MAX(hqtx2.NewRate) AS JurisdictionTax
	FROM	 dbo.ARTH h
		JOIN dbo.ARTL l ON l.ARCo = h.ARCo AND l.ARTrans = h.ARTrans AND l.Mth = h.Mth
		JOIN dbo.HQTX hqtx ON l.TaxGroup=hqtx.TaxGroup AND l.TaxCode=hqtx.TaxCode
		JOIN dbo.HQTL hqtl ON hqtl.TaxGroup=hqtx.TaxGroup AND hqtl.TaxCode=hqtx.TaxCode 
		JOIN dbo.HQTX hqtx2 ON hqtl.TaxGroup=hqtx2.TaxGroup AND hqtl.TaxLink=hqtx2.TaxCode 
		LEFT OUTER JOIN dbo.udGeographicLookup glu ON hqtx2.udCityId=glu.McKCityId
	WHERE
		(h.Mth BETWEEN @StartDate AND @EndDate) AND h.ARTransType IN ('A','C','I','M','W') AND l.Contract is null
	GROUP BY
			  l.ARCo
		,     l.Contract
		,     l.ARTrans
		,     l.ApplyMth
		,     l.TaxGroup
		,     l.TaxCode
		,     hqtx.TaxCode
		,     hqtl.TaxLink
		,     hqtx2.udReportingCode   
		,     glu.City
		,     glu.PostOffice
	) u
	ORDER BY
		  u.ARCo
	,     u.Contract
	,     u.ARTrans  
	,     u.TaxCode
	,     u.TaxLink
END
GO

--Test Script
--EXEC mckrptARBandOTax
--EXEC mckrptARBandOTax '1/1/2001'
--EXEC mckrptARBandOTax '6/1/2013', '3/31/2014'
--EXEC mckrptARBandOTax '11/1/2014', '12/31/2014'

------------------------------
-- REPROCESS WIP FOR N TYPE --
------------------------------
EXEC [dbo].[mspGetWIPData] 1, '10/1/2014', null, null, null, 'M,A,C'
GO
EXEC [dbo].[mspGetWIPData] 20, '10/1/2014', null, null, null, 'M,A,C'
GO

EXEC [dbo].[mspGetWIPData] 1, '11/1/2014', null, null, null, 'M,A,C'
GO
EXEC [dbo].[mspGetWIPData] 20, '11/1/2014', null, null, null, 'M,A,C'
GO

EXEC [dbo].[mspGetWIPData] 1, '12/1/2014', null, null, null, 'M,A,C'
GO
EXEC [dbo].[mspGetWIPData] 20, '12/1/2014', null, null, null, 'M,A,C'
GO

EXEC [dbo].[mspGetWIPData] 1, '1/1/2015', null, null, null, 'M,A,C'
GO
EXEC [dbo].[mspGetWIPData] 20, '1/1/2015', null, null, null, 'M,A,C'
GO

EXEC [dbo].[mspGetWIPData] 1, '2/1/2015', null, null, null, 'M,A,C'
GO
EXEC [dbo].[mspGetWIPData] 20, '2/1/2015', null, null, null, 'M,A,C'
GO

SELECT ThroughMonth, JCCo, RevenueType, max([Batch Processed On]) from mvwWIPReport group by JCCo, ThroughMonth, RevenueType order by JCCo, ThroughMonth, RevenueType

--------------------------------
-- REPROCESS PROJ REPORT DATA --
--------------------------------
PRINT 'Oct 2014 for 1..'
EXEC dbo.mckrptProjectReportRefresh '10/1/2014', 1
GO

PRINT 'Oct 2014 for 20..'
EXEC dbo.mckrptProjectReportRefresh '10/1/2014', 20
GO

PRINT 'Oct 2014 for 60..'
EXEC dbo.mckrptProjectReportRefresh '10/1/2014', 60
GO

PRINT 'Nov 2014 for 1..'
EXEC dbo.mckrptProjectReportRefresh '11/1/2014', 1
GO

PRINT 'Nov 2014 for 20..'
EXEC dbo.mckrptProjectReportRefresh '11/1/2014', 20
GO

PRINT 'Nov 2014 for 60..'
EXEC dbo.mckrptProjectReportRefresh '11/1/2014', 60
GO

PRINT 'Dec 2014 for 1..'
EXEC dbo.mckrptProjectReportRefresh '12/1/2014', 1
GO

PRINT 'Dec 2014 for 20..'
EXEC dbo.mckrptProjectReportRefresh '12/1/2014', 20
GO

PRINT 'Dec 2014 for 60..'
EXEC dbo.mckrptProjectReportRefresh '12/1/2014', 60
GO

PRINT 'Jan 2015 for 1..'
EXEC dbo.mckrptProjectReportRefresh '1/1/2015', 1
GO

PRINT 'Jan 2015 for 20..'
EXEC dbo.mckrptProjectReportRefresh '1/1/2015', 20
GO

PRINT 'Jan 2015 for 60..'
EXEC dbo.mckrptProjectReportRefresh '1/1/2015', 60
GO

PRINT 'Feb 2015 for 1..'
EXEC dbo.mckrptProjectReportRefresh '2/1/2015', 1
GO

PRINT 'Feb 2015 for 20..'
EXEC dbo.mckrptProjectReportRefresh '2/1/2015', 20
GO

PRINT 'Feb 2015 for 60..'
EXEC dbo.mckrptProjectReportRefresh '2/1/2015', 60
GO