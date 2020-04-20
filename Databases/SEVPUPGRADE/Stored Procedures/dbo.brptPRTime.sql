SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE	[dbo].[brptPRTime] (
       @PRCo bCompany,
       @PRGroup bGroup,
       @BeginPRDate bDate = '01/01/1950',
       @EndPRDate bDate = '12/31/2050',
       @BeginJCCo bCompany = 0,
       @EndJCCo bCompany = 255,
       @NonTrueEarn char(1) = 'Y',
       @NonJob char(1) = 'Y'
)

/*
-- Use following SQL and associated parameter values
-- for a test of this stored procedure

DECLARE	@return_value int

EXEC	@return_value = [dbo].[brptPRTime]
		@PRCo = 124,
		@PRGroup = 0,
		@BeginPRDate = '03/01/2010',
		@EndPRDate = '03/31/2010',
		@BeginJCCo = 0,
		@EndJCCo = 255,
		@NonTrueEarn = N'Y',
		@NonJob = N'N'

SELECT	'Return Value' = @return_value

GO
*/

AS

/*
CREATED BY:		Anon	08/28/99


NOTE: If a change is made to this stored procedure, it is very likely the same change will be required 
in stored procedure brptPRTimeExpense

MODIFIED BY:	ET		04/02/03	Fixed to make ANSI standard for Crystal 9.0. Fixed to use tables instead of views. Issue 20721.
				CR		09/29/03	Changed PaySeq FROM a numeric field to a tinyint field - report would not run in Crystal 9.0.
				CR		09/29/03	Added PREC.TrueEarn <> 'N' for issue 20692.
				CR		10/28/03	Removed PREC.TrueEarn <> 'N'.
				CR		12/18/03	Added CASE statement in WHERE clause for PRGroups. Issue 22840.
				DW		10/22/04	Add with (nolock). Issue 25882.
				CWW		06/02/11	Rewrote stored procedure to shift processing burden FROM Crystal file to SQL Server; removed
									multiple subreports FROM Crystal file, improving performance. Issue CL-120404.
									Added PRTH.Type 'S' to CASE statements to support Service type time cards for 6.4.1.
									Row number in CTEs will allow earnings and liabilities to print on the same line in the report.
									Row number is effectively line number in report.
*/


WITH 


-- Create initial CTE for Earnings (E) AND Add-ons (A)
PREarningsInitial
		(Employee, TimeCardType, Job, Dept, PRorJCDepartment, Department, DeptDescription, PRDept, JCDept, JCCo
		, EarnCode, Hours, EarnAmt, STE, ECDesc, EarnCodeFactor, TrueEarns, CodeType, Phase)
AS (
	SELECT	PRTH.Employee, PRTH.Type, PRTH.Job,
			Dept = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL) 
					THEN ('PR' + PRTH.PRDept) 
					ELSE ('JC' + PRTH.JCDept) END),
			PRorJCDepartment = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL) 
					THEN ('PR') 
					ELSE ('JC') END),
			Department = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL) 
					THEN (PRTH.PRDept) 
					ELSE (PRTH.JCDept) END),		
			DeptDescription = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL)
					THEN PRDP.Description 
					ELSE JCDM.Description END),		
			PRTH.PRDept, PRTH.JCDept, PRTH.JCCo, PRTH.EarnCode, PRTH.Hours, PRTH.Amt,
			STE = ROUND((CASE WHEN PREC.Factor <> 0 THEN PRTH.Amt/PREC.Factor ELSE 0 END),2),
			PREC.Description, PREC.Factor, PREC.TrueEarns, 'E',
			PRTH.Phase
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
 
	SELECT	PRTH.Employee, PRTH.Type, PRTH.Job,
			Dept = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL) 
					THEN ('PR' + PRTH.PRDept) 
					ELSE ('JC' + PRTH.JCDept) END),
			PRorJCDepartment = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL) 
					THEN ('PR') 
					ELSE ('JC') END),
			Department = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL) 
					THEN (PRTH.PRDept) 
					ELSE (PRTH.JCDept) END),		
			DeptDescription = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL)
					THEN PRDP.Description 
					ELSE JCDM.Description END),
			PRTH.PRDept, PRTH.JCDept, PRTH.JCCo, PRTA.EarnCode, NULL AS Hours, PRTA.Amt,
			STE = ROUND((CASE WHEN PREC.Factor <> 0 THEN PRTA.Amt/PREC.Factor ELSE 0 END),2),
			PREC.Description, PREC.Factor, PREC.TrueEarns, 'A',
			PRTH.Phase
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
		(Employee, Dept, PRorJCDepartment, Department,DeptDescription, PRDept, EarnCode, Hours, EarnAmt, ECDesc, STE, LiabType, LiabAmt, LiabTypeDesc, RowNumber) 
AS (
	SELECT	Employee, Dept, PRorJCDepartment, Department, MAX(DeptDescription), PRDept, EarnCode, SUM(Hours), SUM(EarnAmt), 
			MAX(ECDesc), SUM(STE), NULL AS LiabType, NULL AS LiabAmt, NULL AS LiabTypeDesc,
			ROW_NUMBER() OVER (PARTITION BY Employee, PRorJCDepartment, Department,Dept, PRDept ORDER BY Employee, PRorJCDepartment, Department,Dept, PRDept, EarnCode)
	FROM	PREarningsInitial
	GROUP BY PRorJCDepartment, Department, Employee, Dept, PRDept, EarnCode
),


-- Create initial CTE for Liabilities
PRLiabilityInitial
		(Employee, TimeCardType, Job, Dept,PRorJCDepartment, Department,  DeptDescription, PRDept, JCDept, LiabType, LiabAmt, LiabTypeDesc) 
AS (
	SELECT	PRTH.Employee, PRTH.Type, PRTH.Job,
			Dept = (
				CASE 
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL)
					THEN ('PR' + PRTH.PRDept) 
					ELSE ('JC' + PRTH.JCDept) END),
			PRorJCDepartment = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL) 
					THEN ('PR') 
					ELSE ('JC') END),
			Department = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL) 
					THEN (PRTH.PRDept) 
					ELSE (PRTH.JCDept) END),		
			DeptDescription = (
				CASE
					WHEN PRTH.Type IN ('M','S') OR PRTH.Job IS NULL OR (PRTH.Job IS NOT NULL AND PRTH.JCDept IS NULL)
					THEN PRDP.Description 
					ELSE JCDM.Description END),
			PRTH.PRDept, PRTH.JCDept, PRDL.LiabType, PRTL.Amt, HQLT.Description
	FROM	PRTH WITH(NOLOCK)  
			INNER JOIN
			PRTL WITH(NOLOCK) ON PRTL.PRCo = PRTH.PRCo AND PRTL.PRGroup = PRTH.PRGroup AND PRTL.PREndDate = PRTH.PREndDate 
						AND PRTL.Employee = PRTH.Employee AND PRTL.PaySeq = PRTH.PaySeq AND PRTL.PostSeq = PRTH.PostSeq
			LEFT OUTER JOIN
			PRDL WITH(NOLOCK) ON PRDL.PRCo = PRTL.PRCo AND PRDL.DLCode = PRTL.LiabCode
			LEFT OUTER JOIN
			HQLT WITH(NOLOCK) ON HQLT.LiabType = PRDL.LiabType
			LEFT OUTER JOIN
			JCDM WITH(NOLOCK) ON JCDM.JCCo = PRTH.JCCo AND JCDM.Department = PRTH.JCDept  
			LEFT OUTER JOIN
			PRDP WITH(NOLOCK) ON PRDP.PRCo = PRTH.PRCo AND PRDP.PRDept = PRTH.PRDept       
	WHERE	PRTH.PRCo = @PRCo 
	AND		(CASE WHEN @PRGroup <> 0 THEN PRTH.PRGroup ELSE @PRGroup END) = @PRGroup
	AND		PRTH.PREndDate BETWEEN @BeginPRDate AND @EndPRDate
	AND		ISNULL(PRTH.JCCo,0) >= @BeginJCCo
	AND		ISNULL(PRTH.JCCo,0) <= @EndJCCo
	AND		PRTL.LiabCode IS NOT NULL
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


-- Create CTE for Liabilities with row number AND aggregation
PRLiability
		(Employee, Dept, PRorJCDepartment, Department, DeptDescription, PRDept, EarnCode, Hours, EarnAmt, ECDesc, STE, LiabType, LiabAmt, LiabTypeDesc, RowNumber) 
AS (
	SELECT	Employee, Dept,PRorJCDepartment, Department, MAX(DeptDescription), PRDept, NULL AS EarnCode, NULL AS Hours, NULL AS EarnAmt,
			NULL AS ECDesc, NULL AS STE, LiabType, SUM(LiabAmt), MAX(LiabTypeDesc),
			ROW_NUMBER() OVER (PARTITION BY Employee, PRorJCDepartment, Department, Dept, PRDept ORDER BY Employee, PRorJCDepartment, Department,Dept, PRDept, LiabType)
	FROM	PRLiabilityInitial
	GROUP BY PRorJCDepartment, Department,Employee, Dept, PRDept, LiabType
),


-- Create CTE to join Earnings/Add-ons with Liabilities for employee AND department based ON row number
PRDepartmentCosts
		(Employee, Dept, PRorJCDepartment, Department, DeptDescription, PRDeptEARN, PRDeptLIAB, EarnCode, Hours, EarnAmt, ECDesc, STE, LiabType, LiabAmt, LiabTypeDesc, RowNumber) 
AS (
	SELECT	ISNULL(PREarnings.Employee,PRLiability.Employee) AS Employee,
			ISNULL(PREarnings.Dept,PRLiability.Dept) AS Dept,
			ISNULL(PREarnings.PRorJCDepartment,PRLiability.PRorJCDepartment) AS PRorJCDepartment,
			ISNULL(PREarnings.Department,PRLiability.Department) AS Department,
			ISNULL(PREarnings.DeptDescription,PRLiability.DeptDescription) AS DeptDescription,
			PREarnings.PRDept AS PRDeptEARN,
			PRLiability.PRDept AS PRDeptLIAB,
			PREarnings.EarnCode, PREarnings.Hours, PREarnings.EarnAmt, PREarnings.ECDesc,
			PREarnings.STE, PRLiability.LiabType, PRLiability.LiabAmt, PRLiability.LiabTypeDesc,
			ISNULL(PREarnings.RowNumber,PRLiability.RowNumber) AS RowNumber
	FROM	PREarnings 
			FULL OUTER JOIN 
			PRLiability ON PRLiability.Employee = PREarnings.Employee 
			AND PRLiability.PRorJCDepartment = PREarnings.PRorJCDepartment 
			AND PRLiability.Department = PREarnings.Department
			AND PRLiability.Dept = PREarnings.Dept AND PRLiability.RowNumber = PREarnings.RowNumber
)


 --Select FINAL RESULT SET to return for the stored procedure
SELECT	@PRCo AS PRCo, HQCO.Name AS CoName, PRDepartmentCosts.Employee,
		PREH.LastName, PREH.FirstName, PREH.MidName, PREH.SortName,
		PRDepartmentCosts.Dept, 
		PRDepartmentCosts.PRorJCDepartment,
		PRDepartmentCosts.Department, 
		PRDepartmentCosts.DeptDescription,
		ISNULL(PRDepartmentCosts.PRDeptEARN,PRDepartmentCosts.PRDeptLIAB) AS PRDept,
		PRDepartmentCosts.EarnCode, PRDepartmentCosts.Hours, PRDepartmentCosts.EarnAmt, PRDepartmentCosts.ECDesc, PRDepartmentCosts.STE,
		PRDepartmentCosts.LiabType, PRDepartmentCosts.LiabAmt, PRDepartmentCosts.LiabTypeDesc, PRDepartmentCosts.RowNumber
FROM	PRDepartmentCosts
		LEFT OUTER JOIN 
		HQCO ON HQCO.HQCo = @PRCo
		LEFT OUTER JOIN 
		PREH ON PREH.PRCo = @PRCo AND PREH.Employee = PRDepartmentCosts.Employee
ORDER BY  PRorJCDepartment desc, Department, Employee, RowNumber

--Debug statements
--SELECT * FROM PREarningsInitial


--SELECT * FROM PREarnings
--SELECT * FROM PRLiabilityInitial
--SELECT * FROM PRLiability
--SELECT * FROM PRDepartmentCosts








GO
GRANT EXECUTE ON  [dbo].[brptPRTime] TO [public]
GO
