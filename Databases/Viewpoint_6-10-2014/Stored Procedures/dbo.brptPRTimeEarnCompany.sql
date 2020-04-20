SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE	[dbo].[brptPRTimeEarnCompany] (
       @PRCo bCompany,
       @PRGroup bGroup,
       @BeginPRDate bDate = '01/01/1950',
       @EndPRDate bDate = '12/31/2050',
       @BeginJCCo bCompany = 0,
       @EndJCCo bCompany = 255,
       @NonTrueEarn char(1) = 'Y',
       @BegEmployee bEmployee = 0,
       @EndEmployee bEmployee = 999999,
       @NonJob char(1) = 'Y',
       @BegPRDept bDept = ' ',
       @EndPRDept bDept = 'zzzzzzzzzz'
)

/*
-- Test values 2011-0602
       @PRCo bCompany = 124,
       @PRGroup bGroup = 0,
       @BeginPRDate bDate = '03/01/2010',
       @EndPRDate bDate = '03/31/2010',
       @BeginJCCo bCompany = 0,
       @EndJCCo bCompany = 255,
       @NonTrueEarn char(1) = 'Y'
       @BegEmployee bEmployee = 0,
       @EndEmployee bEmployee = 999999,
       @NonJob char(1) = 'Y',
       @BegPRDept bDept = ' ',
       @EndPRDept bDept = 'zzzzzzzzzz'
)
*/

AS

/*

NOTE:
Stored procedures brptPRTime, brptPRTimeEarn, brptPRTimeEarnCompany,brptPRTimeExpense and brptPRTimeExpenseDept are all related.  
If a change is made to one of them, review and verify the other stored procedures for a related change.

CREATED BY:		CWW		06/15/11
PURPOSE: This stored procedure extracts the earnings for a specific company(@PRCo).
MODIFIED BY:	
				CWW		06/15/11	New
*/

WITH 


-- Create initial CTE for Earnings (E) AND Add-ons (A)
PREarningsIntial
		(PRCo,TimeCardType, Job, Dept, DeptDescription, PRDept, JCDept, JCCo, EarnCode, Hours, EarnAmt, STE, ECDesc, EarnCodeFactor, TrueEarns, CodeType)
AS (
	SELECT	@PRCo,PRTH.Type, PRTH.Job,
			Dept = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL) 
					THEN ('PR' + PRTH.PRDept) 
					ELSE ('JC' + PRTH.JCDept) END),
			DeptDescription = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL)
					THEN PRDP.Description 
					ELSE JCDM.Description END),
			PRTH.JCCo, PRTH.PRDept, PRTH.JCDept, PRTH.EarnCode, PRTH.Hours, PRTH.Amt,
			STE = ROUND((CASE WHEN PREC.Factor <> 0 THEN PRTH.Amt/PREC.Factor ELSE 0 END),2),
			PREC.Description, PREC.Factor, PREC.TrueEarns, 'E'
	FROM	PRTH WITH(NOLOCK)
			LEFT OUTER JOIN
			PREC WITH(NOLOCK) ON PREC.PRCo = PRTH.PRCo AND PREC.EarnCode = PRTH.EarnCode
			LEFT OUTER JOIN 
			JCDM WITH(NOLOCK) ON JCDM.JCCo = PRTH.JCCo AND JCDM.Department = PRTH.JCDept
			LEFT OUTER JOIN 
			PRDP WITH(NOLOCK) ON PRDP.PRCo = PRTH.PRCo AND PRDP.PRDept = PRTH.PRDept
	WHERE	PRTH.PRCo = @PRCo 
	AND		(CASE WHEN @PRGroup <> 0 THEN PRTH.PRGroup ELSE @PRGroup END) = @PRGroup
	AND		PRTH.PREndDate BETWEEN @BeginPRDate AND @EndPRDate
	AND		ISNULL(PRTH.JCCo,0) >= @BeginJCCo
	AND		ISNULL(PRTH.JCCo,0) <= @EndJCCo
	AND		PRTH.PRDept BETWEEN @BegPRDept and @EndPRDept
	AND		(CASE WHEN @NonTrueEarn <> 'Y' THEN PREC.TrueEarns ELSE 'Y' END) = 'Y'
	AND		PRTH.Employee BETWEEN @BegEmployee AND @EndEmployee
	AND  (
			(CASE 
				WHEN @NonJob = 'N' THEN 'SELECT REC'
				WHEN @NonJob = 'Y' THEN ISNULL(PRTH.Phase,'SELECT REC') 
				ELSE 'DROP REC' END)= 'SELECT REC'
			OR
			(CASE WHEN @NonJob = 'N' THEN 'SELECT REC'
				WHEN @NonJob ='Y' AND PRTH.Type = 'M' THEN 'SELECT REC'--Mechcanic time cards only
				ELSE 'DROP REC' END) = 'SELECT REC'	
		)
		
	UNION ALL
 
	SELECT	@PRCo,PRTH.Type, PRTH.Job,
			Dept = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL) 
					THEN ('PR' + PRTH.PRDept) 
					ELSE ('JC' + PRTH.JCDept) END),
			DeptDescription = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL)
					THEN PRDP.Description 
					ELSE JCDM.Description END),
			PRTH.JCCo, PRTH.PRDept, PRTH.JCDept, PRTA.EarnCode, NULL AS Hours, PRTA.Amt,
			STE = ROUND((CASE WHEN PREC.Factor <> 0 THEN PRTA.Amt/PREC.Factor ELSE 0 END),2),
			PREC.Description, PREC.Factor, PREC.TrueEarns, 'A'
	FROM	PRTH WITH(NOLOCK) 
			INNER JOIN 
			PRTA WITH(NOLOCK) ON PRTA.PRCo = PRTH.PRCo AND PRTA.PRGroup = PRTH.PRGroup AND PRTA.PREndDate = PRTH.PREndDate 
						AND PRTA.Employee = PRTH.Employee AND PRTA.PaySeq = PRTH.PaySeq AND PRTA.PostSeq = PRTH.PostSeq
			LEFT OUTER JOIN
			PREC WITH(NOLOCK) ON PREC.PRCo = PRTA.PRCo AND PREC.EarnCode = PRTA.EarnCode
			LEFT OUTER JOIN
			JCDM WITH(NOLOCK) ON JCDM.JCCo = PRTH.JCCo AND JCDM.Department = PRTH.JCDept
			LEFT OUTER JOIN
			PRDP WITH(NOLOCK) ON PRDP.PRCo = PRTH.PRCo AND PRDP.PRDept = PRTH.PRDept
	WHERE	PRTH.PRCo = @PRCo
	AND		(CASE WHEN @PRGroup<>0 THEN PRTH.PRGroup ELSE @PRGroup END) = @PRGroup
	AND		PRTH.PREndDate BETWEEN @BeginPRDate AND @EndPRDate
	AND		ISNULL(PRTH.JCCo,0) >= @BeginJCCo
	AND		ISNULL(PRTH.JCCo,0) <= @EndJCCo
	AND		PRTH.PRDept BETWEEN @BegPRDept and @EndPRDept
	AND		(CASE WHEN @NonTrueEarn <> 'Y' THEN PREC.TrueEarns ELSE 'Y' END) = 'Y'
	AND		PRTH.Employee BETWEEN @BegEmployee AND @EndEmployee
	AND  (
			(CASE 
				WHEN @NonJob = 'N' THEN 'SELECT REC'
				WHEN @NonJob = 'Y' THEN ISNULL(PRTH.Phase,'SELECT REC') 
				ELSE 'DROP REC' END)= 'SELECT REC'
			OR
			(CASE WHEN @NonJob = 'N' THEN 'SELECT REC'
				WHEN @NonJob ='Y' AND PRTH.Type = 'M' THEN 'SELECT REC'
				ELSE 'DROP REC' END) = 'SELECT REC'	
		)
),


-- Create CTE for Earnings (E) AND Add-ons (A) with row number AND aggregation
PREarnings
		( PRCo,EarnCode, Hours, EarnAmt, ECDesc, STE, RowNumber) 
AS (
	SELECT	PRCo,  EarnCode, SUM(Hours), SUM(EarnAmt), 
			MAX(ECDesc), SUM(STE),
			ROW_NUMBER() OVER (PARTITION BY  PRCo ORDER BY  EarnCode)
	FROM	PREarningsIntial
	GROUP BY PRCo, EarnCode
)

SELECT PRCo,EarnCode, Hours, EarnAmt, ECDesc, STE, RowNumber FROM PREarnings


--Debug statements
--SELECT * FROM PREarningsInitial

--SELECT * FROM PRDepartmentCosts








GO
GRANT EXECUTE ON  [dbo].[brptPRTimeEarnCompany] TO [public]
GO
