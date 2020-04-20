SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE	[dbo].[brptPRTimeExpense] (
       @PRCo bCompany = 124,
       @PRGroup bGroup = 0,
       @BegMth bDate = '01/01/1950',
       @EndMth bDate = '12/31/2050',
	   @BegEmployee bEmployee = 0,
	   @EndEmployee bEmployee = 999999,      
       @NonTrueEarn char(1) = 'Y',
       @NonJob char(1) = 'Y'
)

/*
-- Test values 2011-0602
       @PRCo bCompany,
       @PRGroup bGroup,
       @BegMth bDate = '01/01/1950',
       @EndMth bDate = '12/31/2050',
	   @BegEmployee bEmployee = 0,
	   @EndEmployee bEmployee = 999999,      
       @NonTrueEarn char(1) = 'Y',
       @NonJob char(1) = 'Y'
)
*/

AS

/*

NOTE:
Stored procedures brptPRTime, brptPRTimeEarn, brptPRTimeEarnCompany,brptPRTimeExpense and brptPRTimeExpenseDept are all related.  
If a change is made to one of them, review and verify the other stored procedures for a related change.

CREATED BY:		CWW		06/09/11


NOTE: If a change is made to this stored procedure, it is very likely the same change will be required 
in stored procedure brptPRTime

PURPOSE:
Extract employees' earnings and associated liabilities for reporting department costs within the
month it will be expensed.

Row number in CTEs will allow earnings and liabilities to print on the same line in the report.
Row number is effectively line number in report.

MODIFIED BY:	
				CWW		06/09/11	New

*/
DECLARE @LastDayOfMonth bDate
	SET @LastDayOfMonth = DATEADD(day,-1,DATEADD(month,1,@EndMth));


WITH 


-- Create initial CTE for Earnings (E) AND Add-ons (A)
PREarningsInitial
		(ExpMth, Employee, TimeCardType, Job, Dept, DeptDescription, PRDept, JCDept, JCCo
		, EarnCode, Hours, EarnAmt, STE, ECDesc, EarnCodeFactor, TrueEarns, Phase, CodeType)
AS (

	SELECT	
			ExpMth=	(CASE WHEN PRPC.MultiMth = 'Y' THEN 
					(CASE WHEN PRTH.PostDate <= PRPC.CutoffDate then PRPC.BeginMth else PRPC.EndMth end)
					 ELSE PRPC.BeginMth END),
			PRTH.Employee, PRTH.Type, PRTH.Job,
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
			PRTH.PRDept, PRTH.JCDept, PRTH.JCCo, PRTH.EarnCode, PRTH.Hours, PRTH.Amt,
			STE = ROUND((CASE WHEN PREC.Factor <> 0 THEN PRTH.Amt/PREC.Factor ELSE 0 END),2),
			PREC.Description, PREC.Factor, PREC.TrueEarns, PRTH.Phase, 'E'
			
	FROM	PRTH WITH(NOLOCK)
			INNER JOIN PRPC WITH(NOLOCK) 
				ON PRTH.PRCo=PRPC.PRCo and PRTH.PRGroup=PRPC.PRGroup and PRTH.PREndDate=PRPC.PREndDate
			LEFT OUTER JOIN PREC WITH(NOLOCK) 
				ON PREC.PRCo = PRTH.PRCo AND PREC.EarnCode = PRTH.EarnCode
			LEFT OUTER JOIN JCDM WITH(NOLOCK) 
				ON JCDM.JCCo = PRTH.JCCo AND JCDM.Department = PRTH.JCDept
			LEFT OUTER JOIN PRDP WITH(NOLOCK) 
				ON PRDP.PRCo = PRTH.PRCo AND PRDP.PRDept = PRTH.PRDept

	WHERE	PRTH.PRCo = @PRCo 
			AND		(CASE WHEN @PRGroup <> 0 THEN PRTH.PRGroup ELSE @PRGroup END) = @PRGroup
			AND		(CASE WHEN PRPC.MultiMth = 'Y' THEN 
					(CASE WHEN PRTH.PostDate <= PRPC.CutoffDate then PRPC.BeginMth else PRPC.EndMth end)
						ELSE PRPC.BeginMth END) BETWEEN @BegMth AND  @LastDayOfMonth   
			
			AND		(CASE WHEN @NonTrueEarn <> 'Y' THEN PREC.TrueEarns ELSE 'Y' END) = 'Y'
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
			AND PRTH.Employee BETWEEN @BegEmployee and @EndEmployee	

	UNION ALL

	SELECT	
			ExpMth=	(CASE WHEN PRPC.MultiMth = 'Y' THEN 
					(CASE WHEN PRTH.PostDate <= PRPC.CutoffDate then PRPC.BeginMth else PRPC.EndMth end)
					 ELSE PRPC.BeginMth END),
			PRTH.Employee, PRTH.Type, PRTH.Job,
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
			PRTH.PRDept, PRTH.JCDept, PRTH.JCCo, PRTA.EarnCode, NULL AS Hours, PRTA.Amt,
			STE = ROUND((CASE WHEN PREC.Factor <> 0 THEN PRTA.Amt/PREC.Factor ELSE 0 END),2),
			PREC.Description, PREC.Factor, PREC.TrueEarns, PRTH.Phase, 'A'
			
	FROM	PRTH WITH(NOLOCK) 
			INNER JOIN PRTA WITH(NOLOCK) 
				ON PRTA.PRCo = PRTH.PRCo AND PRTA.PRGroup = PRTH.PRGroup AND PRTA.PREndDate = PRTH.PREndDate 
						AND PRTA.Employee = PRTH.Employee AND PRTA.PaySeq = PRTH.PaySeq AND PRTA.PostSeq = PRTH.PostSeq
			INNER JOIN PRPC WITH(NOLOCK) 
				ON PRTH.PRCo=PRPC.PRCo and PRTH.PRGroup=PRPC.PRGroup and PRTH.PREndDate=PRPC.PREndDate
			LEFT OUTER JOIN	PREC WITH(NOLOCK) 
				ON PREC.PRCo = PRTA.PRCo AND PREC.EarnCode = PRTA.EarnCode
			LEFT OUTER JOIN	JCDM WITH(NOLOCK) 
				ON JCDM.JCCo = PRTH.JCCo AND JCDM.Department = PRTH.JCDept
			LEFT OUTER JOIN	PRDP WITH(NOLOCK) 
				ON PRDP.PRCo = PRTH.PRCo AND PRDP.PRDept = PRTH.PRDept

	WHERE	PRTH.PRCo = @PRCo 
			AND		(CASE WHEN @PRGroup <> 0 THEN PRTH.PRGroup ELSE @PRGroup END) = @PRGroup
			AND		(CASE WHEN PRPC.MultiMth = 'Y' THEN 
					(CASE WHEN PRTH.PostDate <= PRPC.CutoffDate then PRPC.BeginMth else PRPC.EndMth end)
						ELSE PRPC.BeginMth END) BETWEEN @BegMth AND  @LastDayOfMonth   
			
			AND		(CASE WHEN @NonTrueEarn <> 'Y' THEN PREC.TrueEarns ELSE 'Y' END) = 'Y'
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
			AND PRTH.Employee BETWEEN @BegEmployee and @EndEmployee	
),

-- Create CTE for Earnings (E) AND Add-ons (A) with row number AND aggregation
PREarnings
		(ExpMth, Employee, Dept, DeptDescription, PRDept, EarnCode, Hours, EarnAmt, ECDesc, STE, LiabType, LiabAmt, LiabTypeDesc, RowNumber) 
AS (
	SELECT	ExpMth, Employee, Dept, MAX(DeptDescription), PRDept, EarnCode, SUM(Hours), SUM(EarnAmt), 
			MAX(ECDesc), SUM(STE), NULL AS LiabType, NULL AS LiabAmt, NULL AS LiabTypeDesc,
			ROW_NUMBER() OVER (PARTITION BY ExpMth, Employee, Dept, PRDept ORDER BY ExpMth, Employee, Dept, PRDept, EarnCode)
	FROM	PREarningsInitial
	GROUP BY ExpMth, Employee, Dept, PRDept, EarnCode
),

-- Create initial CTE for Liabilities
PRLiabilityInitial
		(ExpMth, Employee, TimeCardType, Job, Dept, DeptDescription, PRDept, JCDept, LiabType, LiabAmt, LiabTypeDesc) 
AS (
	SELECT	
			ExpMth=	(CASE WHEN PRPC.MultiMth = 'Y' THEN 
				(CASE WHEN PRTH.PostDate <= PRPC.CutoffDate then PRPC.BeginMth else PRPC.EndMth end)
				 ELSE PRPC.BeginMth END),
			PRTH.Employee, PRTH.Type, PRTH.Job,
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
			PRTH.PRDept, PRTH.JCDept, PRDL.LiabType, PRTL.Amt, HQLT.Description
			

	FROM	PRTH WITH(NOLOCK)  
			INNER JOIN PRPC WITH(NOLOCK) 
				ON PRTH.PRCo=PRPC.PRCo and PRTH.PRGroup=PRPC.PRGroup and PRTH.PREndDate=PRPC.PREndDate
			INNER JOIN PRTL WITH(NOLOCK) 
				ON PRTL.PRCo = PRTH.PRCo AND PRTL.PRGroup = PRTH.PRGroup AND PRTL.PREndDate = PRTH.PREndDate 
					AND PRTL.Employee = PRTH.Employee AND PRTL.PaySeq = PRTH.PaySeq AND PRTL.PostSeq = PRTH.PostSeq
			LEFT OUTER JOIN	PRDL WITH(NOLOCK) 
				ON PRDL.PRCo = PRTL.PRCo AND PRDL.DLCode = PRTL.LiabCode
			LEFT OUTER JOIN	HQLT WITH(NOLOCK) 
				ON HQLT.LiabType = PRDL.LiabType
			LEFT OUTER JOIN	JCDM WITH(NOLOCK) 
				ON JCDM.JCCo = PRTH.JCCo AND JCDM.Department = PRTH.JCDept  
			LEFT OUTER JOIN	PRDP WITH(NOLOCK) 
				ON PRDP.PRCo = PRTH.PRCo AND PRDP.PRDept = PRTH.PRDept 
			
	WHERE	PRTH.PRCo = @PRCo 
			AND		(CASE WHEN @PRGroup <> 0 THEN PRTH.PRGroup ELSE @PRGroup END) = @PRGroup
			AND		(CASE WHEN PRPC.MultiMth = 'Y' THEN 
					(CASE WHEN PRTH.PostDate <= PRPC.CutoffDate then PRPC.BeginMth else PRPC.EndMth end)
						ELSE PRPC.BeginMth END) BETWEEN @BegMth AND  @LastDayOfMonth   
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
			AND PRTH.Employee BETWEEN @BegEmployee and @EndEmployee	
),
-- Create CTE for Liabilities with row number AND aggregation
PRLiability
		(ExpMth, Employee, Dept, DeptDescription, PRDept, EarnCode, Hours, EarnAmt, ECDesc, STE, LiabType, LiabAmt, LiabTypeDesc, RowNumber) 
AS (
	SELECT	ExpMth, Employee, Dept, MAX(DeptDescription), PRDept, NULL AS EarnCode, NULL AS Hours, NULL AS EarnAmt,
			NULL AS ECDesc, NULL AS STE, LiabType, SUM(LiabAmt), MAX(LiabTypeDesc),
			ROW_NUMBER() OVER (PARTITION BY ExpMth, Employee, Dept, PRDept ORDER BY ExpMth, Employee, Dept, PRDept, LiabType)
	FROM	PRLiabilityInitial
	GROUP BY ExpMth, Employee, Dept, PRDept, LiabType
),

-- Create CTE to join Earnings/Add-ons with Liabilities for employee AND department based ON row number
PRDepartmentCosts
		(ExpMth, Employee, Dept, DeptDescription, PRDeptEARN, PRDeptLIAB, EarnCode, Hours, EarnAmt, ECDesc, STE
		, LiabType, LiabAmt, LiabTypeDesc, RowNumber) 
AS (
	SELECT	ISNULL(PREarnings.ExpMth,PRLiability.ExpMth) AS EmpMth,
			ISNULL(PREarnings.Employee,PRLiability.Employee) AS Employee,
			ISNULL(PREarnings.Dept,PRLiability.Dept) AS Dept,
			ISNULL(PREarnings.DeptDescription,PRLiability.DeptDescription) AS DeptDescription,
			PREarnings.PRDept AS PRDeptEARN,
			PRLiability.PRDept AS PRDeptLIAB,
			PREarnings.EarnCode, PREarnings.Hours, PREarnings.EarnAmt, PREarnings.ECDesc,
			PREarnings.STE, PRLiability.LiabType, PRLiability.LiabAmt, PRLiability.LiabTypeDesc,
			ISNULL(PREarnings.RowNumber,PRLiability.RowNumber) AS RowNumber
	FROM	PREarnings 
			FULL OUTER JOIN PRLiability 
				ON PRLiability.ExpMth = PREarnings.ExpMth AND PRLiability.Employee = PREarnings.Employee 
					AND PRLiability.Dept = PREarnings.Dept AND PRLiability.RowNumber = PREarnings.RowNumber
)


 --Select FINAL RESULT SET to return for the stored procedure
SELECT	@PRCo AS PRCo, HQCO.Name AS CoName, PRDepartmentCosts.ExpMth, PRDepartmentCosts.Employee,
		PREH.LastName, PREH.FirstName, PREH.MidName, PREH.SortName,
		PRDepartmentCosts.Dept, 
		SUBSTRING(PRDepartmentCosts.Dept,1,2) AS PRorJCDepartment,
		SUBSTRING(PRDepartmentCosts.Dept,3,10) AS Department, 
		PRDepartmentCosts.DeptDescription,
		ISNULL(PRDepartmentCosts.PRDeptEARN,PRDepartmentCosts.PRDeptLIAB) AS PRDept,
		PRDepartmentCosts.EarnCode, PRDepartmentCosts.Hours, PRDepartmentCosts.EarnAmt, PRDepartmentCosts.ECDesc, PRDepartmentCosts.STE,
		PRDepartmentCosts.LiabType, PRDepartmentCosts.LiabAmt, PRDepartmentCosts.LiabTypeDesc, PRDepartmentCosts.RowNumber
FROM	PRDepartmentCosts
		LEFT OUTER JOIN	HQCO 
			ON HQCO.HQCo = @PRCo
		LEFT OUTER JOIN PREH 
			ON PREH.PRCo = @PRCo AND PREH.Employee = PRDepartmentCosts.Employee
ORDER BY ExpMth, Employee, Dept, RowNumber

--Debug statements
--SELECT * FROM PREarningsInitial
--SELECT * FROM PREarnings
--SELECT * FROM PRLiabilityInitial
--SELECT * FROM PRLiability
--SELECT * FROM PRDepartmentCosts







GO
GRANT EXECUTE ON  [dbo].[brptPRTimeExpense] TO [public]
GO
