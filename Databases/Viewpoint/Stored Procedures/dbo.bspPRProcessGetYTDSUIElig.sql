SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRProcessGetYTDSUIElig    Script Date: 8/28/99 9:35:37 AM ******/
CREATE    procedure [dbo].[bspPRProcessGetYTDSUIElig]
/***********************************************************
* CREATED BY:	GG	02/25/1999
* MODIFIED BY:	GG	06/17/1999	- removed PR Group restriction
*				EN	10/09/2002	- issue 18877 change double quotes to single
*				GG	01/06/2003	- #19867 - accumulate YTD SUTA earnings based ON paid month
*				mh	02/19/2010	- #137971 - modified to allow date compares to use other THEN calendar year.
*				CHS	04/08/2011	- #142367 - modified so that if the state is Minnesota, only sum the earnings for MN
*				MV	12/04/2012  - TK19844 - Use bPRSI flag ExcludeOutOfStateSUTAWagesYN to exclude wages from other states
*
* USAGE:
* Accumulates the SUM of an employee's year-to-date
* eligible earnings for all SUTA liabilities.  Used to calculate
* SUTA liability for the current pay period.
*
* Called FROM bspPRProcessState procedure.
*
* INPUT PARAMETERS
*   @prco		PR Company
*   @prgroup	PR Group
*   @prenddate	PR Ending Date
*   @employee	Employee to process
*   @payseq		Payment Sequence #
*	@state		the state currently being looked at
*	@dlcode		the deduction/liability code currently being looked at
*
* OUTPUT PARAMETERS
*   @ytdsuielig    	Year-to-date SUM of all SUTA liability eligible earnings

*   @errmsg  	    	Error message if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
	@state bState, @dlcode bEDLCode,
	@ytdsuielig bDollar output, @errmsg varchar(255) output
   
AS


SET NOCOUNT ON

DECLARE @rcode int, @e1 bDollar, @e2 bDollar, @e3 bDollar, @e4 bDollar, @paidmth bMonth, @ExcludeOutOfStateSUTAWagesYN bYN

SELECT @rcode = 0

-- Get ExcludeOutOfStateSUTAWagesYN flag from bPRSI -- TK19844
SELECT @ExcludeOutOfStateSUTAWagesYN = ExcludeOutOfStateSUTAWagesYN
FROM dbo.PRSI
WHERE PRCo = @prco AND State = @state

-- get paid month, or expected payment month - used for YTD SUTA earnings
SELECT @paidmth = PaidMth
FROM bPRSQ
WHERE PRCo = @prco 
	AND PRGroup = @prgroup 
	AND PREndDate = @prenddate 
	AND Employee = @employee 
	AND PaySeq = @payseq
		
IF @paidmth IS NULL
	BEGIN
	-- use expected paid month 
	SELECT @paidmth = CASE MultiMth WHEN 'Y' THEN EndMth ELSE BeginMth END
	FROM bPRPC
	WHERE PRCo = @prco 
		AND PRGroup = @prgroup 
		AND PREndDate = @prenddate
	END


DECLARE @yearendmth tinyint, @accumbeginmth bMonth, @accumendmth bMonth

SELECT @yearendmth = CASE h.DefaultCountry WHEN 'AU' THEN 6 ELSE 12 END
FROM bHQCO h WITH (NOLOCK) 
WHERE h.HQCo = @prco

EXEC vspPRGetMthsForAnnualCalcs @yearendmth, @paidmth, @accumbeginmth output, @accumendmth output, @errmsg output

--#142367 if the state is Minnesota, only sum the earnings for MN
--IF @state = 'MN'
-- Sum SUTA wages for employee's state only, exclude wages earned in other states.  Currently this is MN and LA. TK-19844
IF @ExcludeOutOfStateSUTAWagesYN = 'Y'
	BEGIN
	
	-- get amounts from PREA
	SELECT @e1 = ISNULL(SUM(ea.EligibleAmt),0.00)
	FROM bPREA ea WITH (NOLOCK)
	JOIN bPRSI si WITH (NOLOCK) ON si.PRCo = ea.PRCo 
									AND si.SUTALiab = ea.EDLCode
	WHERE ea.PRCo = @prco 
		AND ea.Employee = @employee 
		AND ea.Mth BETWEEN @accumbeginmth AND @accumendmth
		AND ea.EDLType = 'L'
		AND ea.EDLCode = @dlcode
	  

	-- get current amounts FROM current AND earlier Pay Periods WHERE Final Accum update has not been run
	SELECT @e2 = ISNULL(SUM(dt.EligibleAmt),0.00)
	FROM bPRDT dt
	JOIN bPRSI si ON si.PRCo = dt.PRCo 
						AND si.SUTALiab = dt.EDLCode
	JOIN bPRSQ sq ON sq.PRCo = dt.PRCo 
						AND sq.PRGroup = dt.PRGroup 
						AND sq.PREndDate = dt.PREndDate
	AND sq.Employee = dt.Employee 
						AND sq.PaySeq = dt.PaySeq
	JOIN bPRPC pc ON pc.PRCo = dt.PRCo 
						AND pc.PRGroup = dt.PRGroup 
						AND pc.PREndDate = dt.PREndDate
	WHERE dt.PRCo = @prco 
		AND dt.Employee = @employee
		AND dt.EDLType = 'L'
		AND ((dt.PREndDate < @prenddate) or (dt.PREndDate = @prenddate AND dt.PaySeq <= @payseq))
		AND ((sq.PaidMth IS NULL AND CASE pc.MultiMth WHEN 'Y' THEN pc.EndMth ELSE pc.BeginMth END BETWEEN @accumbeginmth AND @accumendmth)
			or sq.PaidMth BETWEEN @accumbeginmth AND @accumendmth)
		AND pc.GLInterface = 'N'
		AND dt.EDLCode = @dlcode


	-- get old amounts FROM earlier Pay Periods WHERE Final Accum update has not been run
	SELECT @e3 = ISNULL(SUM(dt.OldEligible),0.00)
	FROM bPRDT dt
	JOIN bPRSI si ON si.PRCo = dt.PRCo 
						AND si.SUTALiab = dt.EDLCode
	JOIN bPRPC pc ON pc.PRCo = dt.PRCo 
						AND pc.PRGroup = dt.PRGroup 
						AND pc.PREndDate = dt.PREndDate
	WHERE dt.PRCo = @prco 
		AND dt.Employee = @employee
		AND dt.EDLType = 'L'
		AND ((dt.PREndDate < @prenddate) OR (dt.PREndDate = @prenddate AND dt.PaySeq < @payseq))
		AND dt.OldMth BETWEEN @accumbeginmth 
		AND @accumendmth
		AND pc.GLInterface = 'N'
		AND dt.EDLCode = @dlcode		
	    	
	   
	SELECT @e4 = ISNULL(SUM(dt.OldEligible),0.00)
	FROM bPRDT dt
	JOIN bPRSI si ON si.PRCo = dt.PRCo AND si.SUTALiab = dt.EDLCode
	WHERE dt.PRCo = @prco 
		AND dt.Employee = @employee
		AND dt.EDLType = 'L'
		AND (dt.PREndDate > @prenddate OR (dt.PREndDate = @prenddate AND dt.PaySeq >= @payseq))
		AND DATEPART(YEAR,dt.OldMth) = DATEPART(YEAR,@paidmth)	
		AND dt.EDLCode = @dlcode
	
	END	

-- Else sum the earnings as usual -- #142367 
ELSE
	BEGIN
	
	SELECT @e1 = ISNULL(SUM(ea.EligibleAmt),0.00)
	FROM bPREA ea WITH (NOLOCK)
	JOIN bPRSI si WITH (NOLOCK) ON si.PRCo = ea.PRCo 
									AND si.SUTALiab = ea.EDLCode
	WHERE ea.PRCo = @prco 
		AND ea.Employee = @employee 
		AND ea.Mth BETWEEN @accumbeginmth AND @accumendmth
		AND ea.EDLType = 'L'

	  

	-- get current amounts FROM current AND earlier Pay Periods WHERE Final Accum update has not been run

	SELECT @e2 = ISNULL(SUM(dt.EligibleAmt),0.00)
	FROM bPRDT dt
	JOIN bPRSI si ON si.PRCo = dt.PRCo 
						AND si.SUTALiab = dt.EDLCode
	JOIN bPRSQ sq ON sq.PRCo = dt.PRCo 
						AND sq.PRGroup = dt.PRGroup 
						AND sq.PREndDate = dt.PREndDate
	AND sq.Employee = dt.Employee 
						AND sq.PaySeq = dt.PaySeq
	JOIN bPRPC pc ON pc.PRCo = dt.PRCo 
						AND pc.PRGroup = dt.PRGroup 
						AND pc.PREndDate = dt.PREndDate
	WHERE dt.PRCo = @prco 
		AND dt.Employee = @employee
		AND dt.EDLType = 'L'
		AND ((dt.PREndDate < @prenddate) or (dt.PREndDate = @prenddate AND dt.PaySeq <= @payseq))
		AND ((sq.PaidMth IS NULL AND CASE pc.MultiMth WHEN 'Y' THEN pc.EndMth ELSE pc.BeginMth END BETWEEN @accumbeginmth AND @accumendmth)
			or sq.PaidMth BETWEEN @accumbeginmth AND @accumendmth)
		AND pc.GLInterface = 'N'


	-- get old amounts FROM earlier Pay Periods WHERE Final Accum update has not been run

	SELECT @e3 = ISNULL(SUM(dt.OldEligible),0.00)
	FROM bPRDT dt
	JOIN bPRSI si ON si.PRCo = dt.PRCo 
						AND si.SUTALiab = dt.EDLCode
	JOIN bPRPC pc ON pc.PRCo = dt.PRCo 
						AND pc.PRGroup = dt.PRGroup 
						AND pc.PREndDate = dt.PREndDate
	WHERE dt.PRCo = @prco 
		AND dt.Employee = @employee
		AND dt.EDLType = 'L'
		AND ((dt.PREndDate < @prenddate) OR (dt.PREndDate = @prenddate AND dt.PaySeq < @payseq))
		AND dt.OldMth BETWEEN @accumbeginmth 
		AND @accumendmth
		AND pc.GLInterface = 'N'
	    	
	   
	SELECT @e4 = ISNULL(SUM(dt.OldEligible),0.00)
	FROM bPRDT dt
	JOIN bPRSI si ON si.PRCo = dt.PRCo AND si.SUTALiab = dt.EDLCode
	WHERE dt.PRCo = @prco 
		AND dt.Employee = @employee
		AND dt.EDLType = 'L'
		AND (dt.PREndDate > @prenddate OR (dt.PREndDate = @prenddate AND dt.PaySeq >= @payseq))
		AND DATEPART(YEAR,dt.OldMth) = DATEPART(YEAR,@paidmth)	
	
	END	




-- Year-to-date SUI eligible earnings = updated accums + net FROM earlier Pay Pds - old FROM later Pay Pds */
SELECT @ytdsuielig = @e1 + (@e2 - @e3) - @e4


   
   
bspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessGetYTDSUIElig] TO [public]
GO
