SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*==========================================================

Author:  Mike Brewer
Create date: 3/15/2010
Issue: 135792
This procedure is used by Other Monies subreport
in the PR Record of Employment report. It returns amounts for 
specified EDLCodes paid on an Employee's last payroll.

Revision History
Date		Author	Issue					Description
10/28/2011	Czeslaw	CL-143979 / V1-D-03632	Overhaul, numerous revisions throughout, compare
											versions in SVN repository history for details

==========================================================*/

CREATE PROCEDURE  [dbo].[vrptPREmployeeROEOther] (
	@PRCo bCompany,
	@Employee bEmployee,
	@OtherCode VARCHAR(200),
	@FinalPayperiod DATETIME
)

AS

---------------------------------------------------------
--declare @PRCo bCompany
--set @PRCo = 1

--declare @Employee bEmployee
--set @Employee = 1

--declare @OtherCode Varchar(200)
--set @OtherCode = '1,2'

--declare @FinalPayperiod datetime
--set @FinalPayperiod = '2011-11-04 00:00:00'
---------------------------------------------------------

DECLARE	@PRGroup bGroup

SELECT	@PRGroup = PRGroup
FROM	PREH
WHERE	PRCo = @PRCo
AND		Employee = @Employee

-- Strip any space characters out of user-supplied value for @OtherCode

IF @OtherCode IN (NULL,'')
	BEGIN
		SELECT @OtherCode = NULL
	END
ELSE
	BEGIN
		SELECT @OtherCode = REPLACE(@OtherCode,' ','')
	END


SELECT	PRDT.PRCo,
		PRDT.Employee,
		PRDT.EDLCode,
		PREC.Description,
		PRDT.Amount		
FROM	PRDT
		INNER JOIN
		PRSQ
			ON  PRDT.PRCo = PRSQ.PRCo
			AND PRDT.PRGroup = PRSQ.PRGroup
			AND PRDT.Employee = PRSQ.Employee
			AND PRDT.PREndDate = PRSQ.PREndDate
			AND PRDT.PaySeq = PRSQ.PaySeq
		LEFT OUTER JOIN
		PREC
			ON PRDT.PRCo = PREC.PRCo
			AND PRDT.EDLCode = PREC.EarnCode
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup = @PRGroup
AND PRDT.Employee = @Employee
AND PRDT.PREndDate = @FinalPayperiod
AND PRDT.EDLType = 'E'
AND CHARINDEX(',' + CONVERT(VARCHAR(8),PRDT.EDLCode) + ',', ',' + @OtherCode + ',') > 0
AND PRSQ.Processed = 'Y'
GO
GRANT EXECUTE ON  [dbo].[vrptPREmployeeROEOther] TO [public]
GO
