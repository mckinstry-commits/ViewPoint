SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*==========================================================

Author:  Mike Brewer
Create date: 3/15/2010
Issue: 135792
This procedure is used by Statutory Holiday Pay subreport
in the PR Record of Employment report. It returns holidays
paid on an Employee's last payroll for an individual employee.

Revision History
Date		Author	Issue					Description
11/28/2011	Czeslaw	CL-143979 / V1-D-03632	Added PRGroup to selection criteria
											Removed join to PRHD because unnecessary

==========================================================*/

CREATE PROCEDURE [dbo].[vrptPREmployeeROEStatHoliday] (
	@PRCo bCompany,
	@Employee bEmployee,
	@HoliCode bEDLCode,
	@FinalPayperiod DATETIME
)

AS

DECLARE	@PRGroup bGroup

SELECT	@PRGroup = PRGroup
FROM	PREH
WHERE	PRCo = @PRCo
AND		Employee = @Employee

--SELECT	PRHD.Holiday AS 'Holiday',
--		PRTH.Amt AS 'Amount'
--FROM	PRHD --Holidays
--		INNER JOIN 
--		PRTH --Timecard Header
--			ON PRHD.PRCo = PRTH.PRCo
--			AND PRHD.PRGroup = PRTH.PRGroup
--			AND PRHD.PREndDate = PRTH.PREndDate
--			AND PRHD.Holiday = PRTH.PostDate
--		INNER JOIN
--		PRSQ --Employee Sequence
--			ON PRTH.PRCo = PRSQ.PRCo
--			AND PRTH.PRGroup = PRSQ.PRGroup
--			AND PRTH.Employee = PRSQ.Employee
--			AND PRTH.PREndDate = PRSQ.PREndDate
--			AND PRTH.PaySeq = PRSQ.PaySeq
--WHERE PRTH.PRCo = @PRCo
--AND PRTH.PRGroup = @PRGroup
--AND PRTH.Employee = @Employee
--AND PRTH.PREndDate = @FinalPayperiod
--AND PRTH.EarnCode = @HoliCode
--AND PRSQ.Processed = 'Y'

SELECT	PRTH.PostDate AS 'Holiday',
		PRTH.Amt AS 'Amount'
FROM	PRTH --Timecard Header
		INNER JOIN
		PRSQ --Employee Sequence
			ON PRTH.PRCo = PRSQ.PRCo
			AND PRTH.PRGroup = PRSQ.PRGroup
			AND PRTH.Employee = PRSQ.Employee
			AND PRTH.PREndDate = PRSQ.PREndDate
			AND PRTH.PaySeq = PRSQ.PaySeq
WHERE PRTH.PRCo = @PRCo
AND PRTH.PRGroup = @PRGroup
AND PRTH.Employee = @Employee
AND PRTH.PREndDate = @FinalPayperiod
AND PRTH.EarnCode = @HoliCode
AND PRSQ.Processed = 'Y'
GO
GRANT EXECUTE ON  [dbo].[vrptPREmployeeROEStatHoliday] TO [public]
GO
