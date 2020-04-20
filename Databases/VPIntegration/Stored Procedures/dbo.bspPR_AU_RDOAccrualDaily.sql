SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_AU_RDOAccrualDaily]    Script Date: 02/27/2008 13:19:16 ******/
CREATE  proc [dbo].[bspPR_AU_RDOAccrualDaily]
/********************************************************
* CREATED BY: 	EN 10/16/2012 B-10534/TK-18448
* MODIFIED BY:	
*
* USAGE:
* 	Compute RDO hours and amount (rate per hour) for any days with time posted to subject earnings codes 
*	where the daily time posted equals or exceeds the daily threshold.
*	Threshold is stored in bPRRM (Routine Master) MiscAmt1 field.
*	Daily RDO hours is a set per diem value that is stored in bPRRM MiscAmt2 field.
*	Used for RDO accrual earnings code setup with earnings as Subject Earnings.
*
* INPUT PARAMETERS:
*	@prco		PR Company
*	@earncode	earn code
*	@prgroup	PR Group
*	@prenddate	Pay Period Ending Date
*	@employee	Employee
*	@payseq		Pay Sequence
*	@rate		hourly rate
*	@routine	RDO accrual routine name
*
* OUTPUT PARAMETERS:
*	@hours		computed RDO hours
*	@amt		computed amount
*	@errmsg		error message if failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
**********************************************************/
(@prco bCompany = NULL, 
 @earncode bEDLCode = NULL, 
 @prgroup bGroup = NULL, 
 @prenddate bDate = NULL, 
 @employee bEmployee = NULL, 
 @payseq TINYINT, 
 @rate bUnitCost = 0, 
 @routine varchar(10),
 @hours bHrs OUTPUT,
 @amt bDollar OUTPUT, 
 @errmsg VARCHAR(255) = null OUTPUT)
 
AS
SET NOCOUNT ON
	
DECLARE @Threshold bDollar, 
		@DailyRDOHours bDollar

SET DATEFIRST 7 -- This assures that we can distinguish weekdays from weekend days in case user default language 
				-- is set to something other than us_english which would adversely affect the weekday returned by 
				-- DATEPART().

--Given the routine, look up MiscAmt1 (threshold) and MiscAmt2 (daily RDO hours) in PRRM
SELECT @Threshold = MiscAmt1, @DailyRDOHours = MiscAmt2 
FROM bPRRM
WHERE PRCo = @prco AND Routine = @routine

-- Determine how many days employee matched or exceeded the threshold during the pay period
-- and use to compute RDO accrual.
;
WITH TallyHrsWithThreshold(DailyApplicableHours, temp)
AS
	(
	SELECT (CASE WHEN SUM(h.Hours) < @Threshold THEN 0.00 ELSE SUM(h.Hours) END), 'A'
	FROM bPRTH h (NOLOCK)
	WHERE h.PRCo = @prco 
		AND h.PRGroup = @prgroup 
		AND h.PREndDate = @prenddate
		AND h.PaySeq = @payseq
		AND h.Employee = @employee
		AND h.EarnCode IN (SELECT SubjEarnCode FROM bPRES WHERE PRCo=@prco AND EarnCode = @earncode)
		AND DATEPART(WEEKDAY, h.PostDate) NOT IN (1,7) -- this assures that PostDate is not Sunday (day 1) or Saturday (day 7) 
	GROUP BY h.PostDate
	)

SELECT @hours = (@DailyRDOHours * COUNT(*)) * -1 FROM TallyHrsWithThreshold WHERE DailyApplicableHours > 0

SELECT @amt = @rate * @hours


RETURN 0


GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_RDOAccrualDaily] TO [public]
GO
