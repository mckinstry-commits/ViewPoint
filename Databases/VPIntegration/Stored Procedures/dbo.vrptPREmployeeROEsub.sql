SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*==========================================================

Author:  Mike Brewer
Create date: 3/15/2010
Issue: 135792
This procedure is used by Insurable Earnings table subreport
in the PR Record of Employment report. It returns earnings
broken down by pay period for a certain number of past consecutive
pay periods.

Revision History
Date		Author	Issue					Description
10/28/2011	Czeslaw	CL-143979 / V1-D-03632	Overhaul, numerous revisions throughout, compare
											versions in SVN repository history for details

==========================================================*/

CREATE procedure  [dbo].[vrptPREmployeeROEsub] (
	@PRCo bCompany,
	@Employee bEmployee,
	@RRSPCode bEDLCode,
	@MinPeriodHours DATETIME,
	@MaxPeriodHours DATETIME
)

AS

---------------------------------------------------------
--declare @PRCo bCompany
--set @PRCo = 1

--declare @Employee bEmployee
--set @Employee = 1

--declare @RRSPCode bEDLCode
--set @RRSPCode = 0

--declare @MinPeriodHours datetime
--set @MinPeriodHours = '2008-04-11 00:00:00'

--declare @MaxPeriodHours datetime
--set @MaxPeriodHours = '2011-11-04 00:00:00'
---------------------------------------------------------

DECLARE	@PRGroup bGroup

SELECT	@PRGroup = PRGroup
FROM	PREH
WHERE	PRCo = @PRCo
AND		Employee = @Employee


DECLARE @PREndDateTable TABLE (
	PREndDate DATETIME
)

INSERT INTO @PREndDateTable
SELECT	PREndDate
FROM	PRPC
WHERE	PRCo = @PRCo
AND		PRGroup = @PRGroup
AND		PREndDate BETWEEN @MinPeriodHours AND @MaxPeriodHours




SELECT	ROW_NUMBER() OVER(ORDER BY p.PREndDate DESC) AS 'RN',
		CAST(ROW_NUMBER() OVER(ORDER BY p.PREndDate DESC) AS VARCHAR) + ')' AS 'RowNumber',
		p.PREndDate,
		SUM(ISNULL(x.Amount,0)) AS 'B15c-EarningsByPayPeriod'
FROM	@PREndDateTable p
		LEFT OUTER JOIN
		(
			SELECT	PRDT.PREndDate,
					SUM(ISNULL(PRDT.Amount,0)) AS 'Amount'
			FROM	PRDT
					INNER JOIN
					PREC
						ON PRDT.PRCo = PREC.PRCo
						AND PRDT.EDLCode = PREC.EarnCode
					INNER JOIN
					PRSQ
						ON  PRDT.PRCo = PRSQ.PRCo
						AND PRDT.PRGroup = PRSQ.PRGroup
						AND PRDT.Employee = PRSQ.Employee
						AND PRDT.PREndDate = PRSQ.PREndDate
						AND PRDT.PaySeq = PRSQ.PaySeq
			WHERE PRDT.PRCo = @PRCo
			AND PRDT.PRGroup = @PRGroup
			AND PRDT.Employee = @Employee
			AND PRDT.PREndDate BETWEEN @MinPeriodHours AND @MaxPeriodHours
			AND PRDT.EDLType = 'E'
			AND PREC.TrueEarns = 'Y'
			AND PRSQ.Processed = 'Y'
			GROUP BY PRDT.PREndDate

			UNION ALL

			SELECT	PRDT.PREndDate,
					SUM(ISNULL(PRDT.Amount,0)) AS 'Amount'
			FROM	PRDT
					INNER JOIN
					PRSQ
						ON  PRDT.PRCo = PRSQ.PRCo
						AND PRDT.PRGroup = PRSQ.PRGroup
						AND PRDT.Employee = PRSQ.Employee
						AND PRDT.PREndDate = PRSQ.PREndDate
						AND PRDT.PaySeq = PRSQ.PaySeq
			WHERE PRDT.PRCo = @PRCo
			AND PRDT.PRGroup = @PRGroup
			AND PRDT.Employee = @Employee
			AND PRDT.PREndDate BETWEEN @MinPeriodHours AND @MaxPeriodHours
			AND PRDT.EDLType = 'L'
			AND PRDT.EDLCode = @RRSPCode
			AND PRSQ.Processed = 'Y'
			GROUP BY PRDT.PREndDate
		)x
			ON p.PREndDate = x.PREndDate
GROUP BY p.PREndDate
GO
GRANT EXECUTE ON  [dbo].[vrptPREmployeeROEsub] TO [public]
GO
