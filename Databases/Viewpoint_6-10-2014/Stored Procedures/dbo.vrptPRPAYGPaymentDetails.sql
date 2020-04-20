SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************************************************************
Copyright 2013 Viewpoint Construction Software. All rights reserved.
Purpose:
	Extract payment detail for the PAYG payroll summary of 
	individual earnings, deduction, and liability codes 
	to the payroll end date level.
	
Created:	CWirtz	06/22/11
Modified:	DML		03/21/13 Modified to include ETP items. 
			JayR	05/17/13 Removed copyright symbol as it prevents database compares.
			CUC		05/21/13 Removed ETP items.
 
***************************************************************************************/

/***************************************************************************************

Test Harness
DECLARE	@return_value int

EXEC	@return_value = [dbo].[vrptPRPAYGPaymentDetails]
		@PRCo = 141,
		@TaxYear = N'2011',
		@Employee = 0

SELECT	'Return Value' = @return_value

GO

***************************************************************************************/

CREATE  PROCEDURE [dbo].[vrptPRPAYGPaymentDetails]
         (@PRCo bCompany = null
         ,@TaxYear char(4) = null
         ,@Employee bEmployee =null)

AS      
         
DECLARE @BegEmp bEmployee			--Calculated
DECLARE @EndEmp bEmployee			--Calculated

DECLARE @TaxYearInt smallint

SET @TaxYearInt = CAST (@TaxYear AS smallint)

PRINT @TaxYearInt


--SET employee selection range.  A parameter value of 0 returns all employees. 
--Otherwise, the specific employee is only selected
If @Employee = 0  
BEGIN
	SET	@BegEmp = 0
	SET	@EndEmp = 999999

END
ELSE
BEGIN
	SET	@BegEmp = @Employee
	SET	@EndEmp = @Employee
END;


        
-- Extract all payments for each employee.  In subsequent steps, this data 
--will be used to determine the first time an employee was paid in a given tax year.
WITH PAYGTaxYear(PRCo, Employee, PaidDate,PaidMth,TaxYear)
AS
(
SELECT 
	 PRDT.PRCo
	,PRDT.Employee
	,PRSQ.PaidDate
	,PRSQ.PaidMth
	,@TaxYear
FROM 
		PRSQ PRSQ (NOLOCK)
		INNER JOIN dbo.PRDT PRDT (NOLOCK) 
			ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
				AND PRSQ.PREndDate = PRDT.PREndDate AND PRDT.Employee=PRSQ.Employee
				AND PRSQ.PaySeq = PRDT.PaySeq 
				
WHERE 
		@PRCo = PRDT.PRCo
		AND PRDT.Employee BETWEEN @BegEmp AND @EndEmp
		AND  @TaxYearInt = CASE WHEN(DATEPART(mm,PRSQ.PaidMth) BETWEEN 7 and 12) 
							THEN DATEPART(yyyy,PRSQ.PaidMth) + 1 ELSE DATEPART(yyyy,PRSQ.PaidMth)  END
		AND PRSQ.PaidDate IS NOT NULL
)
,
-- Generate the first paid date for each employee in the fiscal tax year.
PAYGFirstPaidDateInTaxYear

AS
(
	SELECT 
	PRCo, TaxYear, Employee, MIN(PaidDate) as PaidDate, MIN(PaidMth ) as FirstPaidMth
	FROM PAYGTaxYear 
	GROUP BY PRCo, TaxYear, Employee
)
,
-- Read all employee payments for the first month they were paid in a specific tax year.
-- These payments will be compared with the employee's accumulations for the corresponding 
-- month and any differences will be preloaded(plugged) data from another system or process.
-- NOTE: This data is aggregated to the same level as the employee's accumulations in table PREA
PREASplitMth
AS
(
SELECT PRDT.PRCo,PRDT.Employee,PRDT.EDLType,PRDT.EDLCode
	,SUM(PRDT.Hours) AS Hours
	,SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END) AS Amount
	,SUM(PRDT.SubjectAmt) AS SubjectAmt
	,SUM(PRDT.EligibleAmt) AS EligibleAmt
	,f.FirstPaidMth
FROM PAYGFirstPaidDateInTaxYear f
	INNER JOIN dbo.PRSQ PRSQ (nolock) 
		ON f.PRCo = PRSQ.PRCo AND f.Employee= PRSQ.Employee AND f.FirstPaidMth = PRSQ.PaidMth 
	INNER JOIN PRDT PRDT (nolock) 
		ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup AND PRDT.Employee=PRSQ.Employee
			AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
GROUP BY PRDT.PRCo,PRDT.Employee,PRDT.EDLType,PRDT.EDLCode,f.FirstPaidMth
)


,
-- Determine any preloaded data when it is also the same month the employee was first paid.
PREAPreLoadedForSplitMonth
AS
(
SELECT PREA.PRCo,PREA.Employee,PREA.Mth,PREA.EDLType,PREA.EDLCode
	,(ISNULL(PREA.Hours,0) -  ISNULL(g.Hours,0)) AS Hours
	,(ISNULL(PREA.Amount,0) -  ISNULL(g.Amount,0)) AS Amount
	,(ISNULL(PREA.SubjectAmt,0) -  ISNULL(g.SubjectAmt,0)) AS SubjectAmt
	,(ISNULL(PREA.EligibleAmt,0) -  ISNULL(g.EligibleAmt,0)) AS EligibleAmt
	,g.FirstPaidMth
FROM PREA
	LEFT OUTER JOIN PREASplitMth g
		ON PREA.PRCo = g.PRCo AND PREA.Employee = g.Employee
			AND PREA.Mth = g.FirstPaidMth 
			AND PREA.EDLType = g.EDLType
			AND PREA.EDLCode = g.EDLCode
WHERE
		@PRCo = PREA.PRCo
		AND PREA.Employee BETWEEN @BegEmp AND @EndEmp
		AND  @TaxYearInt = CASE WHEN(DATEPART(mm,PREA.Mth) BETWEEN 7 and 12) 
							THEN DATEPART(yyyy,PREA.Mth) + 1 ELSE DATEPART(yyyy,PREA.Mth)  END
		AND PREA.Mth = g.FirstPaidMth					

)
-- Create table with all preloaded data
,
PREAAllPreloadedData
AS
(
SELECT	 PREA.PRCo,PREA.Employee,PREA.Mth,PREA.EDLType,PREA.EDLCode
		,PREA.Hours,PREA.Amount,PREA.SubjectAmt,PREA.EligibleAmt, f.FirstPaidMth
FROM PREA 
LEFT OUTER JOIN PAYGFirstPaidDateInTaxYear f
		ON f.PRCo = PREA.PRCo AND f.Employee= PREA.Employee-- AND f.PaidMth = PRSQ.PaidMth 
WHERE
		@PRCo = PREA.PRCo
		AND PREA.Employee BETWEEN @BegEmp AND @EndEmp
		AND  @TaxYearInt = CASE WHEN(DATEPART(mm,PREA.Mth) BETWEEN 7 and 12) 
							THEN DATEPART(yyyy,PREA.Mth) + 1 ELSE DATEPART(yyyy,PREA.Mth)  END
		AND PREA.Mth < f.FirstPaidMth		
		
		AND
		NOT(PREA.Hours = 0 AND PREA.Amount = 0 AND PREA.SubjectAmt = 0 AND PREA.EligibleAmt= 0)

UNION ALL

SELECT	PRCo,Employee,Mth,EDLType,EDLCode,Hours,Amount,SubjectAmt,EligibleAmt,FirstPaidMth
FROM PREAPreLoadedForSplitMonth h
WHERE 
		NOT(Hours = 0 AND Amount = 0 AND SubjectAmt = 0 AND EligibleAmt= 0)

		
)
,
--PreLoadedData	1=Data was not preloaded in PREA
--PreLoadedData	2=Data was preloaded in PREA by Balance Forward Process

--Extract PAYG employee data at the detail level

PRAUEmployeeItemAmountsExt 
(	 SortValue, PreLoadedData, UnionSetOrdinal, RecType, PRCo, TaxYear, Employee, BeginDate, EndDate, SummarySeq
	,ItemCode, TotalAmount, EDLType, EDLCode, EDLDescription ,SubjectAmt, EligibleAmt
	,EDLAmount, LSAType, PREndDate, PaidDate, PaidMth ,ItemOrder, FBTBeginDate	, FBTEndDate
	,ItemDescription, AFGAmount
)	
AS
--Select all employee items (deductions, liabilities and earnings codes) used in PAYG Summary reports
(


--PRAUEmployeeItemAmounts
--Select all employee items (deductions, liabilities and earnings codes) used in PAYG Summary reports
SELECT 
	 1 AS SortValue
	,1 AS PreLoadedData
	,1 AS UnionSetOrdinal
	,'PRAUEmployeeItemAmounts' AS RecType
	,e.PRCo
	,e.TaxYear
	,e.Employee
	,e.BeginDate
	,e.EndDate
	,e.SummarySeq
	,e.ItemCode
	,e.Amount AS TotalAmount
	,f.EDLType,f.EDLCode
	,(CASE WHEN PRDT.EDLType='E' THEN PREC.Description ELSE PRDL.Description END) AS EDLDescription
	,PRDT.SubjectAmt 
	,PRDT.EligibleAmt
	,(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END) AS EDLAmount
	,(CASE PREC.ATOCategory WHEN 'LSAT' THEN 'T' WHEN 'LSAR' THEN 'R' ELSE NULL END) AS LSAType
	,PRSQ.PREndDate
	,PRSQ.PaidDate
	,PRSQ.PaidMth
	,PRAUItems.ItemOrder
	,NULL AS FBTBeginDate
	,NULL AS FBTEndDate
	,PRAUItems.ItemDescription
	,NULL AS AFGAmount  --AFG Allowances Fees & Giving
	
FROM PRAUEmployeeItemAmounts e
	INNER JOIN vrvPRPAYGEmployerATOSuperItems f
			ON e.PRCo = f.PRCo AND e.TaxYear = f.TaxYear AND e.ItemCode = f.ItemCode
	INNER JOIN PRDT PRDT (nolock)
		ON e.PRCo = PRDT.PRCo AND e.Employee = PRDT.Employee AND f.EDLType = PRDT.EDLType AND f.EDLCode = PRDT.EDLCode
	INNER JOIN dbo.PRSQ PRSQ (nolock) 
		ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
			AND PRSQ.PREndDate = PRDT.PREndDate AND PRDT.Employee=PRSQ.Employee AND PRSQ.PaySeq = PRDT.PaySeq 
	INNER JOIN PRAUItems PRAUItems (nolock)
		ON PRAUItems.ItemCode = f.ItemCode AND(( e.TaxYear >= BeginTaxYear AND EndTaxYear IS NULL)
												OR (e.TaxYear BETWEEN BeginTaxYear AND EndTaxYear))
	LEFT OUTER JOIN PREC PREC(nolock)		
		ON PREC.PRCo = PRDT.PRCo AND PREC.EarnCode = PRDT.EDLCode AND PRDT.EDLType='E'
	LEFT OUTER JOIN PRDL PRDL(nolock)		
		ON PRDL.PRCo = PRDT.PRCo AND PRDL.DLCode = PRDT.EDLCode AND PRDT.EDLType<>'E'
				
WHERE		PRSQ.PaidDate BETWEEN e.BeginDate AND e.EndDate
			AND e.ItemCode NOT IN ('GR','FBT')
			AND PRSQ.CMRef IS NOT NULL
			AND @PRCo = PRDT.PRCo
			AND PRDT.Employee BETWEEN @BegEmp AND @EndEmp
			AND  @TaxYearInt = CASE WHEN(DATEPART(mm,PRSQ.PaidMth) BETWEEN 7 and 12) 
								THEN DATEPART(yyyy,PRSQ.PaidMth) + 1 ELSE DATEPART(yyyy,PRSQ.PaidMth)  END
			AND PRSQ.PaidDate IS NOT NULL
UNION ALL
--For FBT Reporting period is from April 1st through March 31st of the following year.
--This is different from the normal tax year of July 1st through the June 30th.
SELECT 
	 1 AS SortValue
	,1 AS PreLoadedData
	,2 AS UnionSetOrdinal
	,'PRAUEmployeeItemAmounts' AS RecType
	,e.PRCo
	,e.TaxYear
	,e.Employee
	,e.BeginDate
	,e.EndDate
	,e.SummarySeq
	,e.ItemCode
	,e.Amount AS TotalAmount
	,f.EDLType
	,f.EDLCode
	,(CASE WHEN PRDT.EDLType='E' THEN PREC.Description ELSE PRDL.Description END) AS EDLDescription
	,PRDT.SubjectAmt 
	,PRDT.EligibleAmt
	,(CASE WHEN PRDT.UseOver = 'Y' THEN (CASE WHEN PRDT.EDLType='D' THEN (PRDT.OverAmt  * -1) ELSE PRDT.OverAmt  END) 
		ELSE (CASE WHEN PRDT.EDLType='D' THEN (PRDT.Amount * -1) ELSE PRDT.Amount END) END) AS EDLAmount
	,(CASE PREC.ATOCategory WHEN 'LSAT' THEN 'T' WHEN 'LSAR' THEN 'R' ELSE NULL END) AS LSAType
	,PRSQ.PREndDate
	,PRSQ.PaidDate
	,PRSQ.PaidMth
	,PRAUItems.ItemOrder
	,g.FBTBeginDate
	,g.FBTEndDate
	,PRAUItems.ItemDescription
	,NULL AS AFGAmount  --AFG Allowances Fees & Giving
	
FROM PRAUEmployeeItemAmounts e
	INNER JOIN vrvPRPAYGEmployerATOSuperItems f
			ON e.PRCo = f.PRCo AND e.TaxYear = f.TaxYear AND e.ItemCode = f.ItemCode
	INNER JOIN PRDT PRDT (nolock)
		ON e.PRCo = PRDT.PRCo AND e.Employee = PRDT.Employee AND f.EDLType = PRDT.EDLType AND f.EDLCode = PRDT.EDLCode
	INNER JOIN dbo.PRSQ PRSQ (nolock) 
		ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
			AND PRSQ.PREndDate = PRDT.PREndDate AND PRDT.Employee=PRSQ.Employee AND PRSQ.PaySeq = PRDT.PaySeq 
	INNER JOIN PRAUItems PRAUItems (nolock)
		ON PRAUItems.ItemCode = f.ItemCode AND(( e.TaxYear >= BeginTaxYear AND EndTaxYear IS NULL)
												OR (e.TaxYear BETWEEN BeginTaxYear AND EndTaxYear))
	LEFT OUTER JOIN vrvPRPAYGFBTDateRange g
			ON e.PRCo = g.PRCo AND e.TaxYear = g.TaxYear AND e.ItemCode = g.ItemCode 
				AND e.SummarySeq = g.SummarySeq AND e.Employee = g.Employee
	LEFT OUTER JOIN PREC PREC(nolock)		
		ON PREC.PRCo = PRDT.PRCo AND PREC.EarnCode = PRDT.EDLCode AND PRDT.EDLType='E'
	LEFT OUTER JOIN PRDL PRDL(nolock)		
		ON PRDL.PRCo = PRDT.PRCo AND PRDL.DLCode = PRDT.EDLCode AND PRDT.EDLType<>'E'		
		
WHERE		PRSQ.PaidDate BETWEEN  g.FBTBeginDate AND g.FBTEndDate  --NOTE: This is FBT reporting range and not Summary Seq Range
			AND e.ItemCode ='FBT'
			AND PRSQ.CMRef IS NOT NULL
			AND @PRCo = PRDT.PRCo
			AND PRDT.Employee BETWEEN @BegEmp AND @EndEmp
			AND  @TaxYearInt = CASE WHEN(DATEPART(mm,PRSQ.PaidMth) BETWEEN 7 and 12) 
								THEN DATEPART(yyyy,PRSQ.PaidMth) + 1 ELSE DATEPART(yyyy,PRSQ.PaidMth)  END
			AND PRSQ.PaidDate IS NOT NULL

UNION ALL
--PRAUEmployeeMiscItemAmounts
---- Select all employee miscellanous items (allowances, union/professional and workplace giving) used in PAYG Summary reports
SELECT 
	 2 AS SortValue
	,1 AS PreLoadedData
	,3 AS UnionSetOrdinal
	,'PRAUEmployeeMiscItemAmounts' AS RecType
	,e.PRCo
	,e.TaxYear
	,e.Employee
	,e.BeginDate
	,e.EndDate
	,e.SummarySeq
	,e.ItemCode
	,e.Amount AS TotalAmount
	,f.EDLType
	,f.EDLCode
	,(CASE WHEN PRDT.EDLType='E' THEN PREC.Description ELSE PRDL.Description END) AS EDLDescription
	,PRDT.SubjectAmt 
	,PRDT.EligibleAmt
	,(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END) AS EDLAmount
	,NULL AS LSAType
	,PRSQ.PREndDate,PRSQ.PaidDate,PRSQ.PaidMth
	,PRAUItems.ItemOrder
	,NULL AS FBTBeginDate
	,NULL AS FBTEndDate
	,PRAUItems.ItemDescription	
	
	,(SELECT SUM(Amount) 	
		FROM PRAUEmployeeMiscItemAmounts h
		WHERE e.PRCo=h.PRCo AND e.TaxYear=h.TaxYear AND e.Employee=h.Employee AND e.SummarySeq=h.SummarySeq AND e.ItemCode=h.ItemCode
		GROUP BY 	h.PRCo,h.TaxYear,h.Employee,h.SummarySeq,h.ItemCode ) AS AFGAmount  --AFG Allowances Fees & Giving
	
FROM PRAUEmployeeMiscItemAmounts e
	INNER JOIN PRAUEmployerMiscItems f
		ON e.PRCo = f.PRCo AND e.TaxYear = f.TaxYear AND e.ItemCode = f.ItemCode AND f.EDLType = e.EDLType AND f.EDLCode = e.EDLCode
	INNER JOIN PRDT PRDT (nolock)
		ON e.PRCo = PRDT.PRCo AND e.Employee = PRDT.Employee AND f.EDLType = PRDT.EDLType AND f.EDLCode = PRDT.EDLCode
	INNER JOIN dbo.PRSQ PRSQ (nolock) 
		ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
			AND PRSQ.PREndDate = PRDT.PREndDate AND PRDT.Employee=PRSQ.Employee AND PRSQ.PaySeq = PRDT.PaySeq 
	INNER JOIN PRAUItems PRAUItems (nolock)
		ON PRAUItems.ItemCode = f.ItemCode AND(( e.TaxYear >= BeginTaxYear AND EndTaxYear IS NULL)
												OR (e.TaxYear BETWEEN BeginTaxYear AND EndTaxYear))
	LEFT OUTER JOIN PREC PREC(nolock)		
		ON PREC.PRCo = PRDT.PRCo AND PREC.EarnCode = PRDT.EDLCode AND PRDT.EDLType='E'
	LEFT OUTER JOIN PRDL PRDL(nolock)		
		ON PRDL.PRCo = PRDT.PRCo AND PRDL.DLCode = PRDT.EDLCode AND PRDT.EDLType<>'E'		
		
WHERE		PRSQ.PaidDate BETWEEN e.BeginDate AND e.EndDate
			AND PRSQ.CMRef IS NOT NULL
			AND @PRCo = PRDT.PRCo
			AND PRDT.Employee BETWEEN @BegEmp AND @EndEmp
			AND  @TaxYearInt = CASE WHEN(DATEPART(mm,PRSQ.PaidMth) BETWEEN 7 and 12) 
								THEN DATEPART(yyyy,PRSQ.PaidMth) + 1 ELSE DATEPART(yyyy,PRSQ.PaidMth)  END
			AND PRSQ.PaidDate IS NOT NULL


--Gross Payments
UNION ALL
SELECT
 	 1 AS SortValue
	,1 AS PreLoadedData
	,4 AS UnionSetOrdinal
	,'GrossAmounts' AS RecType
	,e.PRCo
	,e.TaxYear
	,e.Employee
	,e.BeginDate
	,e.EndDate
	,e.SummarySeq
	,e.ItemCode
	,e.Amount AS TotalAmount
	,PRDT.EDLType
	,PRDT.EDLCode
	,(CASE WHEN PRDT.EDLType='E' THEN PREC.Description ELSE PRDLBasis.Description END) AS EDLDescription
	,PRDT.SubjectAmt  
	,PRDT.EligibleAmt
--NOTE:Pretax deductions are not included in gross payments
	,(CASE WHEN PRDT.UseOver = 'Y' THEN (CASE WHEN PRDLBasis.PreTax='Y' THEN (PRDT.OverAmt  * -1) ELSE PRDT.OverAmt  END) 
			ELSE (CASE WHEN PRDLBasis.PreTax='Y' THEN (PRDT.Amount * -1) ELSE PRDT.Amount END) END) AS EDLAmount
	,NULL AS LSAType
	,PRSQ.PREndDate
	,PRSQ.PaidDate
	,PRSQ.PaidMth
	,PRAUItems.ItemOrder
	,NULL AS FBTBeginDate
	,NULL AS FBTEndDate
	,PRAUItems.ItemDescription
	,NULL  AS AFGAmount  --AFG Allowances Fees & Giving
	
FROM PRDB PRDB
INNER JOIN PRDL PRDL
	ON PRDB.PRCo = PRDL.PRCo and PRDB.DLCode = PRDL.DLCode 
LEFT JOIN PRDL PRDLBasis
	ON PRDB.PRCo = PRDLBasis.PRCo and PRDB.EDLCode = PRDLBasis.DLCode  AND PRDB.EDLType = 'D'

LEFT JOIN PREC PREC
	ON PRDB.PRCo = PREC.PRCo and PRDB.EDLCode = PREC.EarnCode 
INNER JOIN PRDT PRDT
	ON PRDB.PRCo = PRDT.PRCo and PRDB.EDLCode = PRDT.EDLCode and PRDT.EDLType=PRDB.EDLType
INNER JOIN dbo.PRSQ PRSQ (nolock) 
	ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup AND PRDT.Employee=PRSQ.Employee
		AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 		
INNER JOIN PRAUEmployeeItemAmounts e
	ON e.PRCo = PRDT.PRCo AND e.Employee = PRDT.Employee AND e.ItemCode='GR'
INNER JOIN PRAUItems PRAUItems (nolock)
	ON PRAUItems.ItemCode = e.ItemCode AND(( e.TaxYear >= BeginTaxYear AND EndTaxYear IS NULL)
											OR (e.TaxYear BETWEEN BeginTaxYear AND EndTaxYear))	
WHERE PRDB.PRCo=PRDT.PRCo 
AND PRDL.ATOCategory='T'
--Criterion below (at present) effectively excludes from Gross Payments any payment under an earncode whose ATOCategory is 'AT' or 'LSE'
AND ISNULL(PREC.ATOCategory,'') NOT IN (SELECT ATOCategory FROM PRAUItemsATOCategories WHERE ItemCode='GR' AND ATOCategory <>'T')
--Criterion below excludes from Gross Payments any payment under an earncode whose ATOCategory appears in list
AND ISNULL(PREC.ATOCategory,'') NOT IN ('ETP','ETPR','ETPV','ETPU','ETPD','LSAT','LSAR','LSB')
AND PRSQ.PaidDate BETWEEN    e.BeginDate AND e.EndDate
			AND @PRCo = PRDT.PRCo
			AND PRDT.Employee BETWEEN @BegEmp AND @EndEmp
			AND  @TaxYearInt = CASE WHEN(DATEPART(mm,PRSQ.PaidMth) BETWEEN 7 and 12) 
								THEN DATEPART(yyyy,PRSQ.PaidMth) + 1 ELSE DATEPART(yyyy,PRSQ.PaidMth)  END
			AND PRSQ.PaidDate IS NOT NULL

UNION ALL

--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

SELECT 
	 1 AS SortValue
	,2 AS PreLoadedData		--Loaded by Balance Forward Process
	,5 AS UnionSetOrdinal
	,'PRAUEmployeeItemAmounts' AS RecType
	,e.PRCo
	,e.TaxYear
	,e.Employee
	,e.BeginDate
	,e.EndDate
	,e.SummarySeq
	,e.ItemCode
	,e.Amount AS TotalAmount
	,f.EDLType,f.EDLCode
	,(CASE WHEN i.EDLType='E' THEN PREC.Description ELSE PRDL.Description END) AS EDLDescription
	,i.SubjectAmt 
	,i.EligibleAmt
	,i.Amount AS EDLAmount
	,(CASE PREC.ATOCategory WHEN 'LSAT' THEN 'T' WHEN 'LSAR' THEN 'R' ELSE NULL END) AS LSAType
	,i.Mth AS PREndDate		--For preloaded data Set PREndDate,PaidDate and PaidMth to month 
	,i.Mth AS PaidDate		--the data was preloaded for
	,i.Mth AS PaidMth
	,PRAUItems.ItemOrder
	,NULL AS FBTBeginDate
	,NULL AS FBTEndDate
	,PRAUItems.ItemDescription
	,NULL AS AFGAmount  --AFG Allowances Fees & Giving
	
FROM PRAUEmployeeItemAmounts e
	INNER JOIN vrvPRPAYGEmployerATOSuperItems f
			ON e.PRCo = f.PRCo AND e.TaxYear = f.TaxYear AND e.ItemCode = f.ItemCode		
	INNER JOIN PREAAllPreloadedData i
			ON e.PRCo = i.PRCo AND e.Employee = i.Employee AND f.EDLType = i.EDLType AND f.EDLCode = i.EDLCode
	INNER JOIN PRAUItems PRAUItems (nolock)
		ON PRAUItems.ItemCode = f.ItemCode AND(( e.TaxYear >= BeginTaxYear AND EndTaxYear IS NULL)
												OR (e.TaxYear BETWEEN BeginTaxYear AND EndTaxYear))
	LEFT OUTER JOIN PREC PREC(nolock)		
		ON PREC.PRCo = i.PRCo AND PREC.EarnCode = i.EDLCode AND i.EDLType='E'
	LEFT OUTER JOIN PRDL PRDL(nolock)		
		ON PRDL.PRCo = i.PRCo AND PRDL.DLCode = i.EDLCode AND i.EDLType<>'E'
		
				
WHERE		i.Mth BETWEEN e.BeginDate AND e.EndDate
			AND e.ItemCode NOT IN ('GR','FBT')
--			AND PRSQ.CMRef IS NOT NULL
			AND @PRCo = i.PRCo
			AND i.Employee BETWEEN @BegEmp AND @EndEmp
			AND  @TaxYearInt = CASE WHEN(DATEPART(mm,i.Mth) BETWEEN 7 and 12) 
								THEN DATEPART(yyyy,i.Mth) + 1 ELSE DATEPART(yyyy,i.Mth)  END
--			AND PRSQ.PaidDate IS NOT NULL


UNION ALL
--For FBT Reporting period is from April 1st through March 31st of the following year.
--This is different from the normal tax year of July 1st through the June 30th.
SELECT 
	 1 AS SortValue
	,2 AS PreLoadedData		--Loaded by Balance Forward Process
	,6 AS UnionSetOrdinal
	,'PRAUEmployeeItemAmounts' AS RecType
	,e.PRCo
	,e.TaxYear
	,e.Employee
	,e.BeginDate
	,e.EndDate
	,e.SummarySeq
	,e.ItemCode
	,e.Amount AS TotalAmount
	,f.EDLType
	,f.EDLCode
	,(CASE WHEN i.EDLType='E' THEN PREC.Description ELSE PRDL.Description END) AS EDLDescription
	,i.SubjectAmt 
	,i.EligibleAmt
	,(CASE WHEN i.EDLType='D' THEN (i.Amount * -1) ELSE i.Amount END) AS EDLAmount
--	,(CASE WHEN PRDT.UseOver = 'Y' THEN (CASE WHEN PRDT.EDLType='D' THEN (PRDT.OverAmt  * -1) ELSE PRDT.OverAmt  END) 
--		ELSE (CASE WHEN PRDT.EDLType='D' THEN (PRDT.Amount * -1) ELSE PRDT.Amount END) END) AS EDLAmount
	,(CASE PREC.ATOCategory WHEN 'LSAT' THEN 'T' WHEN 'LSAR' THEN 'R' ELSE NULL END) AS LSAType
	,i.Mth AS PREndDate		--For preloaded data Set PREndDate,PaidDate and PaidMth to month 
	,i.Mth AS PaidDate		--the data was preloaded for
	,i.Mth AS PaidMth
	,PRAUItems.ItemOrder
	,g.FBTBeginDate
	,g.FBTEndDate
	,PRAUItems.ItemDescription
	,NULL AS AFGAmount  --AFG Allowances Fees & Giving
	
FROM PRAUEmployeeItemAmounts e
	INNER JOIN vrvPRPAYGEmployerATOSuperItems f
			ON e.PRCo = f.PRCo AND e.TaxYear = f.TaxYear AND e.ItemCode = f.ItemCode
	INNER JOIN PREAAllPreloadedData i
			ON e.PRCo = i.PRCo AND e.Employee = i.Employee AND f.EDLType = i.EDLType AND f.EDLCode = i.EDLCode
	INNER JOIN PRAUItems PRAUItems (nolock)
		ON PRAUItems.ItemCode = f.ItemCode AND(( e.TaxYear >= BeginTaxYear AND EndTaxYear IS NULL)
												OR (e.TaxYear BETWEEN BeginTaxYear AND EndTaxYear))
	LEFT OUTER JOIN vrvPRPAYGFBTDateRange g
			ON e.PRCo = g.PRCo AND e.TaxYear = g.TaxYear AND e.ItemCode = g.ItemCode 
				AND e.SummarySeq = g.SummarySeq AND e.Employee = g.Employee
	LEFT OUTER JOIN PREC PREC(nolock)		
		ON PREC.PRCo = i.PRCo AND PREC.EarnCode = i.EDLCode AND i.EDLType='E'
	LEFT OUTER JOIN PRDL PRDL(nolock)		
		ON PRDL.PRCo = i.PRCo AND PRDL.DLCode = i.EDLCode AND i.EDLType<>'E'
		
WHERE		i.Mth BETWEEN  g.FBTBeginDate AND g.FBTEndDate  --NOTE: This is FBT reporting range and not Summary Seq Range
			AND e.ItemCode ='FBT'
--			AND PRSQ.CMRef IS NOT NULL
			AND @PRCo = i.PRCo
			AND i.Employee BETWEEN @BegEmp AND @EndEmp
			AND  @TaxYearInt = CASE WHEN(DATEPART(mm,i.Mth) BETWEEN 7 and 12) 
								THEN DATEPART(yyyy,i.Mth) + 1 ELSE DATEPART(yyyy,i.Mth)  END
--			AND PRSQ.PaidDate IS NOT NULL


UNION ALL
--PRAUEmployeeMiscItemAmounts
---- Select all employee miscellanous items (allowances, union/professional and workplace giving) used in PAYG Summary reports
SELECT 
	 2 AS SortValue
	,2 AS PreLoadedData		--Loaded by Balance Forward Process
	,7 AS UnionSetOrdinal
	,'PRAUEmployeeMiscItemAmounts' AS RecType
	,e.PRCo
	,e.TaxYear
	,e.Employee
	,e.BeginDate
	,e.EndDate
	,e.SummarySeq
	,e.ItemCode
	,e.Amount AS TotalAmount
	,f.EDLType
	,f.EDLCode
	,(CASE WHEN i.EDLType='E' THEN PREC.Description ELSE PRDL.Description END) AS EDLDescription
	,i.SubjectAmt 
	,i.EligibleAmt
	,i.Amount AS EDLAmount
	,NULL AS LSAType
	,i.Mth AS PREndDate		--For preloaded data Set PREndDate,PaidDate and PaidMth to month 
	,i.Mth AS PaidDate		--the data was preloaded for
	,i.Mth AS PaidMth	,PRAUItems.ItemOrder
	,NULL AS FBTBeginDate
	,NULL AS FBTEndDate
	,PRAUItems.ItemDescription	
	
	,(SELECT SUM(Amount) 	
		FROM PRAUEmployeeMiscItemAmounts h
		WHERE e.PRCo=h.PRCo AND e.TaxYear=h.TaxYear AND e.Employee=h.Employee AND e.SummarySeq=h.SummarySeq AND e.ItemCode=h.ItemCode
		GROUP BY 	h.PRCo,h.TaxYear,h.Employee,h.SummarySeq,h.ItemCode ) AS AFGAmount  --AFG Allowances Fees & Giving
	
FROM PRAUEmployeeMiscItemAmounts e
	INNER JOIN PRAUEmployerMiscItems f
		ON e.PRCo = f.PRCo AND e.TaxYear = f.TaxYear AND e.ItemCode = f.ItemCode AND f.EDLType = e.EDLType AND f.EDLCode = e.EDLCode
	INNER JOIN PREAAllPreloadedData i
			ON e.PRCo = i.PRCo AND e.Employee = i.Employee AND f.EDLType = i.EDLType AND f.EDLCode = i.EDLCode
	INNER JOIN PRAUItems PRAUItems (nolock)
		ON PRAUItems.ItemCode = f.ItemCode AND(( e.TaxYear >= BeginTaxYear AND EndTaxYear IS NULL)
												OR (e.TaxYear BETWEEN BeginTaxYear AND EndTaxYear))
	LEFT OUTER JOIN PREC PREC(nolock)		
		ON PREC.PRCo = i.PRCo AND PREC.EarnCode = i.EDLCode AND i.EDLType='E'
	LEFT OUTER JOIN PRDL PRDL(nolock)		
		ON PRDL.PRCo = i.PRCo AND PRDL.DLCode = i.EDLCode AND i.EDLType<>'E'
		
WHERE		i.Mth BETWEEN e.BeginDate AND e.EndDate
			--AND PRSQ.CMRef IS NOT NULL
			AND @PRCo = i.PRCo
			AND i.Employee BETWEEN @BegEmp AND @EndEmp
			AND  @TaxYearInt = CASE WHEN(DATEPART(mm,i.Mth) BETWEEN 7 and 12) 
								THEN DATEPART(yyyy,i.Mth) + 1 ELSE DATEPART(yyyy,i.Mth)  END
--			AND PRSQ.PaidDate IS NOT NULL



--Gross Payments
UNION ALL
SELECT
 	 1 AS SortValue
	,2 AS PreLoadedData		--Loaded by Balance Forward Process
	,8 AS UnionSetOrdinal
	,'GrossAmounts' AS RecType
	,e.PRCo
	,e.TaxYear
	,e.Employee
	,e.BeginDate
	,e.EndDate
	,e.SummarySeq
	,e.ItemCode
	,e.Amount AS TotalAmount
	,i.EDLType
	,i.EDLCode
	,(CASE WHEN i.EDLType='E' THEN PREC.Description ELSE PRDLBasis.Description END) AS EDLDescription
	,i.SubjectAmt  
	,i.EligibleAmt
--NOTE:Pretax deductions are not included in gross payments
	,(CASE WHEN PRDLBasis.PreTax='Y' THEN (i.Amount * -1) ELSE i.Amount END)  AS EDLAmount
	,NULL AS LSAType
	,i.Mth AS PREndDate		--For preloaded data Set PREndDate,PaidDate and PaidMth to month 
	,i.Mth AS PaidDate		--the data was preloaded for
	,i.Mth AS PaidMth
	,PRAUItems.ItemOrder
	,NULL AS FBTBeginDate
	,NULL AS FBTEndDate
	,PRAUItems.ItemDescription
	,NULL  AS AFGAmount  --AFG Allowances Fees & Giving
	
FROM PRDB PRDB
INNER JOIN PRDL PRDL
	ON PRDB.PRCo = PRDL.PRCo and PRDB.DLCode = PRDL.DLCode 
LEFT JOIN PRDL PRDLBasis
	ON PRDB.PRCo = PRDLBasis.PRCo and PRDB.EDLCode = PRDLBasis.DLCode  AND PRDB.EDLType = 'D'

LEFT JOIN PREC PREC
	ON PRDB.PRCo = PREC.PRCo and PRDB.EDLCode = PREC.EarnCode 

INNER JOIN PREAAllPreloadedData i
		ON PRDB.PRCo = i.PRCo AND PRDB.EDLType = i.EDLType AND PRDB.EDLCode = i.EDLCode
	
INNER JOIN PRAUEmployeeItemAmounts e
	ON e.PRCo = i.PRCo AND e.Employee = i.Employee AND e.ItemCode='GR'
INNER JOIN PRAUItems PRAUItems (nolock)
	ON PRAUItems.ItemCode = e.ItemCode AND(( e.TaxYear >= BeginTaxYear AND EndTaxYear IS NULL)
											OR (e.TaxYear BETWEEN BeginTaxYear AND EndTaxYear))	
WHERE PRDB.PRCo=i.PRCo 
AND PRDL.ATOCategory='T'
--Criterion below (at present) effectively excludes from Gross Payments any payment under an earncode whose ATOCategory is 'AT' or 'LSE'
AND ISNULL(PREC.ATOCategory,'') NOT IN (SELECT ATOCategory FROM PRAUItemsATOCategories WHERE ItemCode='GR' AND ATOCategory <>'T')
--Criterion below excludes from Gross Payments any payment under an earncode whose ATOCategory appears in list
AND ISNULL(PREC.ATOCategory,'') NOT IN ('ETP','ETPR','ETPV','ETPU','ETPD','LSAT','LSAR','LSB')
AND i.Mth BETWEEN    e.BeginDate AND e.EndDate
			AND @PRCo = i.PRCo
			AND i.Employee BETWEEN @BegEmp AND @EndEmp
			AND  @TaxYearInt = CASE WHEN(DATEPART(mm,i.Mth) BETWEEN 7 and 12) 
								THEN DATEPART(yyyy,i.Mth) + 1 ELSE DATEPART(yyyy,i.Mth)  END
--			AND PRSQ.PaidDate IS NOT NULL


--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/*

UNION All


SELECT
	 3 AS SortValue
	,2 AS PreLoadedData
	,'PREAPreLoad' AS RecType
	,i.PRCo
	,@TaxYear AS TaxYear
	,i.Employee
	,NULL AS BeginDate
	,NULL AS EndDate
	,NULL AS SummarySeq
	,NULL AS ItemCode
	,NULL AS TotalAmount
	,i.EDLType
	,i.EDLCode
	,(CASE WHEN i.EDLType='E' THEN PREC.Description ELSE PRDL.Description END) AS EDLDescription
	,i.SubjectAmt 
	,i.EligibleAmt
	,i.Amount
	,NULL AS LSAType
	,NULL AS PREndDate
	,NULL AS PaidDate
	,i.Mth AS PaidMth
	,NULL AS ItemOrder
	,NULL AS FBTBeginDate
	,NULL AS FBTEndDate
	,NULL AS ItemDescription
	,NULL AS AFGAmount  --AFG Allowances Fees & Giving
FROM
PREAAllPreloadedData i
	LEFT OUTER JOIN PREC PREC(nolock)		
		ON PREC.PRCo = i.PRCo AND PREC.EarnCode = i.EDLCode AND i.EDLType='E'
	LEFT OUTER JOIN PRDL PRDL(nolock)		
		ON PRDL.PRCo = i.PRCo AND PRDL.DLCode = i.EDLCode AND i.EDLType<>'E'
*/
)
,
--Extract Employee's name and the company name
PRAUPayrollSummary
AS
(
SELECT 	 
	 j.SortValue, j.PreLoadedData, j.UnionSetOrdinal, j.RecType, j.PRCo, j.TaxYear, j.Employee, j.BeginDate, j.EndDate, j.SummarySeq
	,j.ItemCode, j.TotalAmount, j.EDLType, j.EDLCode, j.EDLDescription , j.SubjectAmt, j.EligibleAmt
	,j.EDLAmount, j.LSAType, j.PREndDate, j.PaidDate, j.PaidMth , j.ItemOrder, j.FBTBeginDate, j.FBTEndDate
	,j.ItemDescription, j.AFGAmount
	,PRAUEmployees.Surname
	,PRAUEmployees.GivenName
	,HQCO.Name

FROM PRAUEmployeeItemAmountsExt j
	LEFT OUTER JOIN PRAUEmployees PRAUEmployees (NOLOCK)
		ON j.PRCo = PRAUEmployees.PRCo AND j.TaxYear = PRAUEmployees.TaxYear AND j.Employee = PRAUEmployees.Employee
	LEFT OUTER JOIN HQCO HQCO (NOLOCK)
		ON j.PRCo = HQCO.HQCo
		



)


SELECT 
 	 SortValue, PreLoadedData, UnionSetOrdinal, RecType, PRCo, TaxYear, Employee, BeginDate, EndDate, SummarySeq
	,ItemCode, TotalAmount, EDLType, EDLCode, EDLDescription, SubjectAmt, EligibleAmt
	,EDLAmount, LSAType, PREndDate, PaidDate, PaidMth, ItemOrder, FBTBeginDate, FBTEndDate
	,ItemDescription, AFGAmount, Surname, GivenName, Name
FROM PRAUPayrollSummary



--SELECT * FROM PAYGFirstPaidDateInTaxYear
--SELECT * FROM PREAPreLoaded
--SELECT * from PREASplitMth

--SELECT * FROM PREABackoutPaidData
--SELECT * FROM PREAAllPreloadedData
--SELECT * FROM PRAUEmployeeItemAmountsExt









GO
GRANT EXECUTE ON  [dbo].[vrptPRPAYGPaymentDetails] TO [public]
GO
