SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[mspGenerateWIP]
(
	@inThroughMonth SMALLDATETIME = null
,	@inJCCo TINYINT = 101
,	@inPOC	TINYINT = NULL
)

AS

SET NOCOUNT ON

SELECT @inThroughMonth = dbo.mfnFirstOfMonth(@inThroughMonth)
 
DECLARE wipcur CURSOR FOR
SELECT 
	jccm.JCCo
,	LTRIM(RTRIM(jccm.Contract)) AS Contract 
,	COALESCE(jccm.Description,'<Empty>') AS ContractDesc
,	jcmp.ProjectMgr AS POC
,	jcmp.Name AS POCName
,	jccm.ContractStatus
,	CASE jccm.ContractStatus 
		WHEN 0 THEN CAST(jccm.ContractStatus AS VARCHAR(4)) + '-Pending'
		ELSE vddci.DisplayValue 
	END AS ContractStatusDesc	
,	CASE jccm.ContractStatus 
		WHEN 0 THEN CAST(jccm.ContractStatus AS VARCHAR(4)) + '-Pending'
		ELSE vddci.DatabaseValue 
	END AS ContractStatusValue	
FROM 
	dbo.JCCM jccm JOIN
	dbo.JCMP jcmp ON
		jccm.JCCo=jcmp.JCCo
	and	jccm.udPOC=jcmp.ProjectMgr 
	AND ( jccm.JCCo=@inJCCo OR @inJCCo IS NULL )
	and ( jccm.udPOC=@inPOC or @inPOC is null ) LEFT OUTER JOIN
	vDDCI vddci ON
		vddci.ComboType='JCContractStatus'
	AND vddci.DatabaseValue=jccm.ContractStatus	
ORDER BY
	jccm.JCCo
,	jccm.Contract	
FOR READ ONLY

DECLARE @rcnt					INT
DECLARE @rev_rcnt					INT

DECLARE @JCCo					bCompany
DECLARE @Contract				bContract
DECLARE @ContractDesc			bDesc
DECLARE @POC					bEmployee
DECLARE @POCName				VARCHAR(50)
DECLARE @ContractStatus			TINYINT
DECLARE @ContractStatusDesc		bDesc
DECLARE @ContractStatusValue	VARCHAR(30)

DECLARE @GLDept						VARCHAR(4)
DECLARE @GLDeptName					bDesc
DECLARE @RevenueType				VARCHAR(10)		
DECLARE @RevenueTypeName			bDesc
DECLARE @IsLocked					bYN
DECLARE @OriginalContractAmount		DECIMAL(18,2)
DECLARE @CurrentContractAmount		DECIMAL(18,2)
DECLARE @ProjectedContractAmount	DECIMAL(18,2)
DECLARE @CurrentBilledAmount		DECIMAL(18,2)
DECLARE @PercentOfContractTotal		DECIMAL(8,2)
DECLARE @RevenueOveride				DECIMAL(18,2)
DECLARE @OverrideProjectedContractAmount 			DECIMAL(18,2)
DECLARE @IsOverride					bYN
DECLARE @DeptCount					int
DECLARE @TotalCurrentContractAmount	DECIMAL(18,2)

SELECT @rcnt=0

PRINT REPLICATE('=',250)
PRINT
	CAST('#' AS CHAR(12))
+	CAST('JCCo' AS CHAR(8))
+	CAST('Contract' AS CHAR(20))
+	CAST('ContractDesc' AS CHAR(40))
+	CAST('POC' AS CHAR(8))
+	CAST('DeptCnt' AS CHAR(8))
+	'Note'	

	PRINT REPLICATE('-',250)
	PRINT
			CAST(' ' AS CHAR(12))
		+	REPLICATE(' ',16)
		+	CAST('GLDept' AS CHAR(8))
		+	CAST('GLDeptName' AS CHAR(30))
		+	CAST('RevType' AS CHAR(8))
		+	CAST('RevTypeName' AS CHAR(30))
		+	CAST('Lck' AS CHAR(4))
		+	CAST('OriginalContract$' AS CHAR(20))
		+	CAST('CurrentContract$' AS CHAR(20))
		+	CAST('ProjectedContract$' AS CHAR(20))
		+	CAST('CurrentBilled$' AS CHAR(20))
		+	CAST('PctOfContractTotal' AS CHAR(20))
		+	CAST('ORProjectedContract$' AS CHAR(20))
		+	'OR'
	--PRINT REPLICATE('-',250)
	
PRINT REPLICATE('=',250)

OPEN wipcur
FETCH wipcur INTO
	@JCCo					--bCompany
,	@Contract				--bContract
,	@ContractDesc			--bDesc
,	@POC					--bEmployee
,	@POCName				--VARCHAR(50)
,	@ContractStatus			--TINYINT
,	@ContractStatusDesc		--bDesc
,	@ContractStatusValue	--VARCHAR(30)



WHILE @@fetch_status=0
BEGIN
	SELECT @rcnt=@rcnt + 1, @rev_rcnt=0
	
	SELECT 
		@DeptCount = COUNT(*) 
	,	@TotalCurrentContractAmount=SUM(CurrentContractAmount)
	FROM 
	(
	SELECT
		substring(jcdm.OpenRevAcct,10,4) as GLDept
	,	glpi.Description as GLDeptName
	,	COALESCE(jcci.udRevType,'C') AS RevenueType
	,	vddcic.DisplayValue AS RevenueTypeName
	,	jcci.udLockYN AS IsLocked
	,	sum(jcip.OrigContractAmt) as OriginalContractAmount
	,	sum(jcip.ContractAmt) as CurrentContractAmount
	,	case sum(jcip.ProjDollars) when 0 then sum(jcip.ContractAmt) else sum(jcip.ProjDollars) end as ProjectedContractAmount
	,	SUM(jcci.BilledAmt) AS CurrentBilledAmount
	FROM 
		JCCI jcci JOIN
		JCIP jcip ON
			jcci.JCCo=jcip.JCCo
		AND jcci.Contract=jcip.Contract
		AND jcci.Item=jcip.Item
		AND jcip.Mth <= @inThroughMonth
		AND jcci.JCCo=@JCCo
		AND LTRIM(RTRIM(jcci.Contract))=@Contract 		
		AND jcci.udLockYN = 'Y' 
		AND COALESCE(jcci.udRevType,'C') = 'C'  JOIN
		JCDM jcdm on
			jcci.JCCo=jcdm.JCCo
		and jcci.Department=jcdm.Department JOIN
		GLPI glpi on
			glpi.PartNo=3
		AND glpi.GLCo=jcdm.GLCo
		and glpi.Instance=substring(jcdm.OpenRevAcct,10,4) left outer JOIN
		vDDCIc vddcic ON
			vddcic.ComboType='RevenueType'
		AND vddcic.DatabaseValue=COALESCE(jcci.udRevType,'C')
	GROUP BY
		substring(jcdm.OpenRevAcct,10,4) 
	,	glpi.Description 
	,	COALESCE(jcci.udRevType,'C') 
	,	vddcic.DisplayValue 
	,	jcci.udLockYN 
	) t1
		
	IF @DeptCount > 0
	BEGIN
		
	PRINT
		CAST(@rcnt AS CHAR(12))
	+	CAST(COALESCE(@JCCo,999) AS CHAR(8))
	+	CAST(COALESCE(@Contract,'<null>') AS CHAR(20))
	+	CAST(COALESCE(@ContractDesc,'<null>') AS CHAR(40))
	+	CAST(COALESCE(@POC,'<null>') AS CHAR(8))
	+	CAST(COALESCE(@DeptCount,0) AS CHAR(8))
	+	'Data thru ' + convert(VARCHAR(10),dbo.mfnFirstOfMonth(@inThroughMonth),101)	
	

		
	DECLARE wipcurrev CURSOR FOR
	SELECT
		substring(jcdm.OpenRevAcct,10,4) as GLDept
	,	glpi.Description as GLDeptName
	,	COALESCE(jcci.udRevType,'C') AS RevenueType
	,	vddcic.DisplayValue AS RevenueTypeName
	,	jcci.udLockYN AS IsLocked
	,	sum(jcip.OrigContractAmt) as OriginalContractAmount
	,	sum(jcip.ContractAmt) as CurrentContractAmount
	,	case sum(jcip.ProjDollars) when 0 then sum(jcip.ContractAmt) else sum(jcip.ProjDollars) end as ProjectedContractAmount
	,	SUM(jcci.BilledAmt) AS CurrentBilledAmount
	,	CASE @TotalCurrentContractAmount
			WHEN 0 THEN 0.000
			ELSE sum(jcip.ContractAmt)/@TotalCurrentContractAmount 
		END AS PercentOfContractTotal

	FROM 
		JCCI jcci JOIN
		JCIP jcip ON
			jcci.JCCo=jcip.JCCo
		AND jcci.Contract=jcip.Contract
		AND jcci.Item=jcip.Item
		AND jcip.Mth <= @inThroughMonth
		AND jcci.JCCo=@JCCo
		AND LTRIM(RTRIM(jcci.Contract))=@Contract  
		AND jcci.udLockYN = 'Y' 
		AND COALESCE(jcci.udRevType,'C') = 'C' JOIN
		JCDM jcdm on
			jcci.JCCo=jcdm.JCCo
		and jcci.Department=jcdm.Department JOIN
		GLPI glpi on
			glpi.PartNo=3
		AND glpi.GLCo=jcdm.GLCo
		and glpi.Instance=substring(jcdm.OpenRevAcct,10,4) left outer JOIN
		vDDCIc vddcic ON
			vddcic.ComboType='RevenueType'
		AND vddcic.DatabaseValue=COALESCE(jcci.udRevType,'C')
	GROUP BY
		substring(jcdm.OpenRevAcct,10,4) 
	,	glpi.Description 
	,	COALESCE(jcci.udRevType,'C') 
	,	vddcic.DisplayValue 
	,	jcci.udLockYN 
	ORDER BY
		substring(jcdm.OpenRevAcct,10,4) 
	,	COALESCE(jcci.udRevType,'C') 
	FOR READ ONLY

	--GET REVENUE OVERRIDE VALUE for DISTRIBUTION 
	--JCOP - Cost
	--JCOR - Revenue
		
	select @RevenueOveride = RevCost FROM JCOR WHERE JCCo=@JCCo AND Month=@inThroughMonth AND Contract=@Contract
	
	OPEN wipcurrev
	FETCH wipcurrev INTO
		@GLDept						--VARCHAR(4)
	,	@GLDeptName					--bDesc
	,	@RevenueType				--TINYINT		
	,	@RevenueTypeName			--bDesc
	,	@IsLocked					--bYN
	,	@OriginalContractAmount		--DECIMAL(18,2)
	,	@CurrentContractAmount		--DECIMAL(18,2)
	,	@ProjectedContractAmount	--DECIMAL(18,2)
	,	@CurrentBilledAmount		--DECIMAL(18,2)	
	,	@PercentOfContractTotal	
	
	WHILE @@fetch_status=0
	BEGIN
		SELECT @rev_rcnt=@rev_rcnt+1
		
		IF @RevenueOveride <> 0
			SELECT @OverrideProjectedContractAmount = @RevenueOveride * @PercentOfContractTotal, @IsOverride='Y'
		ELSE
			SELECT @OverrideProjectedContractAmount=@ProjectedContractAmount, @IsOverride='N'
		
		--SELECT * FROM JCOR WHERE Contract LIKE '%080600%'
		PRINT
			CAST(CAST(@rcnt AS varCHAR(12)) + '.' + CAST(@rev_rcnt AS varCHAR(12)) AS CHAR(12))
		+	REPLICATE(' ',16)
		--	CAST(COALESCE(@JCCo,999) AS CHAR(8))
		--+	CAST(COALESCE(@Contract,'<null') AS CHAR(20))
		--+	CAST(COALESCE(@ContractDesc,'<null') AS CHAR(40))
		--+	CAST(COALESCE(@POC,'<null') AS CHAR(8))
		--+	CAST(COALESCE(@POCName,'<null') AS CHAR(30))
		+	CAST(COALESCE(@GLDept,'<null>') AS CHAR(8))
		+	CAST(COALESCE(@GLDeptName,'<null>') AS CHAR(30))
		+	CAST(COALESCE(@RevenueType,'<null>') AS CHAR(8))
		+	CAST(COALESCE(@RevenueTypeName,'<null>') AS CHAR(30))
		+	CAST(COALESCE(@IsLocked,'<null>') AS CHAR(4))
		+	CAST(COALESCE(@OriginalContractAmount,0.00) AS CHAR(20))
		+	CAST(COALESCE(@CurrentContractAmount,0.00) AS CHAR(20))
		+	CAST(COALESCE(@ProjectedContractAmount,0.00) AS CHAR(20))
		+	CAST(COALESCE(@CurrentBilledAmount,0.00) AS CHAR(20))
		+	CAST(COALESCE(@PercentOfContractTotal,0.00) AS CHAR(20))
		+	CAST(COALESCE(@OverrideProjectedContractAmount,0.00) AS CHAR(20))
		+	@IsOverride

		
		FETCH wipcurrev INTO
			@GLDept						--VARCHAR(4)
		,	@GLDeptName					--bDesc
		,	@RevenueType				--TINYINT		
		,	@RevenueTypeName			--bDesc
		,	@IsLocked					--bYN
		,	@OriginalContractAmount		--DECIMAL(18,2)
		,	@CurrentContractAmount		--DECIMAL(18,2)
		,	@ProjectedContractAmount	--DECIMAL(18,2)
		,	@CurrentBilledAmount		--DECIMAL(18,2)		
		,	@PercentOfContractTotal		
	END
	
	CLOSE wipcurrev
	DEALLOCATE wipcurrev

	PRINT REPLICATE('-',250)
	
	END
	

	FETCH wipcur INTO
		@JCCo					--bCompany
	,	@Contract				--bContract
	,	@ContractDesc			--bDesc
	,	@POC					--bEmployee
	,	@POCName				--VARCHAR(50)
	,	@ContractStatus			--TINYINT
	,	@ContractStatusDesc		--bDesc
	,	@ContractStatusValue	--VARCHAR(30)	
END

CLOSE wipcur
DEALLOCATE wipcur
GO
