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