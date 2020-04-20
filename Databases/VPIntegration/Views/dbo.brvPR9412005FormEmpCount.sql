SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[brvPR9412005FormEmpCount]
AS
   
/*****************************************************************************************

Author:			CR
Date Created:	3/31/2005
Reports:		PR 941 Federal Form (PR941FillForm.rpt); specifically, subreports
				PREmployeeCount.rpt and EmployeeCount.rpt

Purpose:		Returns a count of distinct employees (by company, year, and quarter)
				that have at least one pay sequence for any pay period that includes
				one of these special quarterly dates: March 12 (Q1); June 12 (Q2);
				September 12 (Q3); December 12 (Q4). (These dates are specified in
				IRS regulations.)
				
Revision History      
Date		Author	Issue	Description
2/20/2008	CWirtz	131801	Added code to select data when a pay period crosses a month
							boundary (specifically, BeginDate occurs in prior month)
11/16/2012	Czeslaw	147490	Rewrote view to accomodate "multi-month" pay periods
							for which either:
							a) BeginDate occurs in month prior to third month of quarter
							and PREndDate occurs in third month of quarter; or
							b) BeginDate occurs in third month of quarter and PREndDate
							occurs in month subsequent to third month of quarter.

*****************************************************************************************/

SELECT			--Pay periods that include date March 12 (Quarter 1)
	'PRCo'		= PRPC.PRCo,
	'PRYear'	= YEAR(PRPC.BeginDate),
	'PRMonth'	= 3,
	'EmpCount'	= COUNT(DISTINCT PRSQ.Employee)
FROM dbo.PRPC PRPC
JOIN dbo.PRSQ PRSQ ON PRPC.PRCo = PRSQ.PRCo AND PRPC.PRGroup = PRSQ.PRGroup AND PRPC.PREndDate = PRSQ.PREndDate
WHERE	(
			MONTH(PRPC.BeginDate) = 2										--BeginDate in February, PREndDate in March
			AND (MONTH(PRPC.PREndDate) = 3 AND DAY(PRPC.PREndDate) >= 12)
)
OR		(
			(MONTH(PRPC.BeginDate) = 3 AND DAY(PRPC.BeginDate) <= 12)		--BeginDate in March, PREndDate in March or April
			AND ((MONTH(PRPC.PREndDate) = 3 AND DAY(PRPC.PREndDate) >= 12) OR MONTH(PRPC.PREndDate) = 4)
)
GROUP BY PRPC.PRCo, YEAR(PRPC.BeginDate)

UNION

SELECT			--Pay periods that include date June 12 (Quarter 2)
	'PRCo'		= PRPC.PRCo,
	'PRYear'	= YEAR(PRPC.BeginDate),
	'PRMonth'	= 6,
	'EmpCount'	= COUNT(DISTINCT PRSQ.Employee)
FROM dbo.PRPC PRPC
JOIN dbo.PRSQ PRSQ ON PRPC.PRCo = PRSQ.PRCo AND PRPC.PRGroup = PRSQ.PRGroup AND PRPC.PREndDate = PRSQ.PREndDate
WHERE	(
			MONTH(PRPC.BeginDate) = 5										--BeginDate in May, PREndDate in June
			AND (MONTH(PRPC.PREndDate) = 6 AND DAY(PRPC.PREndDate) >= 12)
)
OR		(
			(MONTH(PRPC.BeginDate) = 6 AND DAY(PRPC.BeginDate) <= 12)		--BeginDate in June, PREndDate in June or July
			AND ((MONTH(PRPC.PREndDate) = 6 AND DAY(PRPC.PREndDate) >= 12) OR MONTH(PRPC.PREndDate) = 7)
)
GROUP BY PRPC.PRCo, YEAR(PRPC.BeginDate)

UNION

SELECT			--Pay periods that include date September 12 (Quarter 3)
	'PRCo'		= PRPC.PRCo,
	'PRYear'	= YEAR(PRPC.BeginDate),
	'PRMonth'	= 9,
	'EmpCount'	= COUNT(DISTINCT PRSQ.Employee)
FROM dbo.PRPC PRPC
JOIN dbo.PRSQ PRSQ ON PRPC.PRCo = PRSQ.PRCo AND PRPC.PRGroup = PRSQ.PRGroup AND PRPC.PREndDate = PRSQ.PREndDate
WHERE	(
			MONTH(PRPC.BeginDate) = 8										--BeginDate in August, PREndDate in September
			AND (MONTH(PRPC.PREndDate) = 9 AND DAY(PRPC.PREndDate) >= 12)
)
OR		(
			(MONTH(PRPC.BeginDate) = 9 AND DAY(PRPC.BeginDate) <= 12)		--BeginDate in September, PREndDate in September or October
			AND ((MONTH(PRPC.PREndDate) = 9 AND DAY(PRPC.PREndDate) >= 12) OR MONTH(PRPC.PREndDate) = 10)
)
GROUP BY PRPC.PRCo, YEAR(PRPC.BeginDate)

UNION

SELECT			--Pay periods that include date December 12 (Quarter 4)
	'PRCo'		= PRPC.PRCo,
	'PRYear'	= YEAR(PRPC.BeginDate),
	'PRMonth'	= 12,
	'EmpCount'	= COUNT(DISTINCT PRSQ.Employee)
FROM dbo.PRPC PRPC
JOIN dbo.PRSQ PRSQ ON PRPC.PRCo = PRSQ.PRCo AND PRPC.PRGroup = PRSQ.PRGroup AND PRPC.PREndDate = PRSQ.PREndDate
WHERE	(
			MONTH(PRPC.BeginDate) = 11										--BeginDate in November, PREndDate in December
			AND (MONTH(PRPC.PREndDate) = 12 AND DAY(PRPC.PREndDate) >= 12)
)
OR		(
			(MONTH(PRPC.BeginDate) = 12 AND DAY(PRPC.BeginDate) <= 12)		--BeginDate in December, PREndDate in December or January of subsequent year
			AND (
					(MONTH(PRPC.PREndDate) = 12 AND DAY(PRPC.PREndDate) >= 12)
					OR (MONTH(PRPC.PREndDate) = 1 AND YEAR(PRPC.PREndDate) = YEAR(DATEADD(yy,1,PRPC.BeginDate)))
			)
)
GROUP BY PRPC.PRCo, YEAR(PRPC.BeginDate)
GO
GRANT SELECT ON  [dbo].[brvPR9412005FormEmpCount] TO [public]
GRANT INSERT ON  [dbo].[brvPR9412005FormEmpCount] TO [public]
GRANT DELETE ON  [dbo].[brvPR9412005FormEmpCount] TO [public]
GRANT UPDATE ON  [dbo].[brvPR9412005FormEmpCount] TO [public]
GO
