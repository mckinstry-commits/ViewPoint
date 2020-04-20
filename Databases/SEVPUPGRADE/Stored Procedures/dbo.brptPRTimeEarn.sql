SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE	[dbo].[brptPRTimeEarn] (
       @PRCo bCompany,
       @PRGroup bGroup,
       @BeginPRDate bDate = '01/01/1950',
       @EndPRDate bDate = '12/31/2050',
       @BeginJCCo bCompany = 0,
       @EndJCCo bCompany = 255,
       @NonTrueEarn char(1) = 'Y',
       @BegEmployee bEmployee = 0,
       @EndEmployee bEmployee = 999999,
       @Dept varchar(12),
       @NonJob char(1) = 'Y'
)

/*
-- Use following SQL and associated parameter values
-- for a test of this stored procedure
DECLARE	@return_value int

EXEC	@return_value = [dbo].[brptPRTimeEarn]
		@PRCo = 124,
		@PRGroup = 0,
		@BeginPRDate = '03/01/2010',
		@EndPRDate = '03/31/2010',
		@BeginJCCo = 0,
		@EndJCCo = 255,
		@NonTrueEarn = N'Y',
		@BegEmployee = 0,
		@EndEmployee = 999999,
		@Dept = N'PR01',
		@NonJob = N'N'

SELECT	'Return Value' = @return_value

GO
*/

AS

/*

NOTE:
Stored procedures brptPRTime, brptPRTimeEarn, brptPRTimeEarnCompany,brptPRTimeExpense and brptPRTimeExpenseDept are all related.  
If a change is made to one of them, review and verify the other stored procedures for a related change.

CREATED BY:		CWW		06/02/11
PURPOSE: This stored procedure extracts the earnings for a specific department.
MODIFIED BY:	
				CWW		06/02/11	New
*/

WITH 


-- Create initial CTE for Earnings (E) AND Add-ons (A)
PREarningsIntial
		(TimeCardType, Job, Dept, DeptDescription, PRDept, JCDept, JCCo, EarnCode, Hours, EarnAmt, STE, ECDesc, EarnCodeFactor, TrueEarns, CodeType)
AS (
	SELECT	PRTH.Type, PRTH.Job,
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
 
	SELECT	PRTH.Type, PRTH.Job,
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
),


-- Create CTE for Earnings (E) AND Add-ons (A) with row number AND aggregation
PREarnings
		(Dept, DeptDescription, EarnCode, Hours, EarnAmt, ECDesc, STE, RowNumber) 
AS (
	SELECT	Dept, MAX(DeptDescription), EarnCode, SUM(Hours), SUM(EarnAmt), 
			MAX(ECDesc), SUM(STE),
			ROW_NUMBER() OVER (PARTITION BY  Dept ORDER BY Dept, EarnCode)
	FROM	PREarningsIntial
	WHERE	PREarningsIntial.Dept = @Dept
	GROUP BY Dept, EarnCode
)


--Debug statements
--SELECT * FROM PREarningsInitial
SELECT * FROM PREarnings

--SELECT * FROM PRDepartmentCosts






GO
GRANT EXECUTE ON  [dbo].[brptPRTimeEarn] TO [public]
GO
