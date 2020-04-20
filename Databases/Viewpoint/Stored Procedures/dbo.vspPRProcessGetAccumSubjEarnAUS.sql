SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[vspPRProcessGetAccumSubjEarnAUS]    Script Date: 02/27/2008 13:19:16 ******/
CREATE  proc [dbo].[vspPRProcessGetAccumSubjEarnAUS]
/********************************************************
* CREATED BY: 	EN 05/15/2012 D-04874
* MODIFIED BY:  EN 08/29/2012 D-05698/TK-17502 renamed to not specify the the earn code being checked is an addon ... 
*												it can now alternately be an auto earnings code
*
* USAGE:
* 	Gets the total accumulated YTD subject earnings for the specified earnings code.
*
* INPUT PARAMETERS:
*	@prco		PR Company
*	@prgroup	PR Group
*	@prenddate	Pay Period Ending Date
*	@employee	Employee
*	@earncode	Earnings Code
*	@payseq		Payment Sequence
*	@ytdearns	Accumulated YTD Earnings Amount 
*
* OUTPUT PARAMETERS:
*	@errmsg		error message if failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 			failure
**********************************************************/
(@prco bCompany = NULL, 
 @prgroup bGroup = NULL, 
 @prenddate bDate = NULL, 
 @employee bEmployee = NULL, 
 @earncode bEDLCode = NULL, 
 @payseq tinyint = NULL, 
 @ytdearns bDollar = NULL OUTPUT, 
 @errmsg varchar(255) = NULL OUTPUT)

AS
SET NOCOUNT ON

DECLARE @paidmth bMonth,
		@beginmth bMonth, 
		@endmth bMonth

--validate input params
IF @prco IS NULL
BEGIN
	SELECT @errmsg = 'Missing PR Company'
	RETURN 1
END
IF @prgroup IS NULL
BEGIN
	SELECT @errmsg = 'Missing PR Group'
	RETURN 1
END
IF @prenddate IS NULL
BEGIN
	SELECT @errmsg = 'Missing PR Ending Date'
	RETURN 1
END
IF @employee IS NULL
BEGIN
	SELECT @errmsg = 'Missing Employee'
	RETURN 1
END
IF @earncode IS NULL
BEGIN
	SELECT @errmsg = 'Missing Earnings Code'
	RETURN 1
END
IF @payseq IS NULL
BEGIN
	SELECT @errmsg = 'Missing Payment Sequence'
	RETURN 1
END

--determine begin and end month for locating YTD Earnings
IF DATEPART(MONTH,@prenddate) BETWEEN 1 AND 6 
BEGIN
	--when payroll end date is Jan thru June set begin month to July of previous year
	SELECT @beginmth = '7/1/' + CONVERT(varchar,DATEPART(YEAR,@prenddate)-1)
END
ELSE
BEGIN
	--otherwise set begin month to July of current year
	SELECT @beginmth = '7/1/' + CONVERT(varchar,DATEPART(YEAR,@prenddate))
END

SELECT @endmth = CONVERT(varchar,DATEPART(MONTH,@prenddate)) + '/1/' + CONVERT(varchar,DATEPART(YEAR,@prenddate))

--get paid month
SELECT @paidmth = CASE MultiMth WHEN 'Y' THEN EndMth ELSE BeginMth END
FROM dbo.bPRPC WITH (NOLOCK)
WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate

--Get YTD Earnings for Earnings Code
--start with year-to-date PREA accums through the month of this pay period
SELECT @ytdearns = ISNULL(SUM(ea.Amount),0)
FROM dbo.bPREA ea WITH (NOLOCK)
JOIN dbo.bPRES es ON es.PRCo = ea.PRCo AND es.SubjEarnCode = ea.EDLCode
WHERE	ea.PRCo = @prco AND 
		ea.Employee = @employee AND 
		ea.Mth BETWEEN @beginmth AND @endmth AND 
		ea.EDLType = 'E' AND 
		es.EarnCode = @earncode
		
--add PRDT amounts from earlier Pay Periods where Final Accum update has not been run
SELECT @ytdearns = @ytdearns + ISNULL(SUM(dt.Amount),0)
FROM dbo.bPRDT dt WITH (NOLOCK)
JOIN dbo.bPRES es ON es.PRCo = dt.PRCo AND 
					 es.SubjEarnCode = dt.EDLCode
JOIN dbo.bPRSQ sq WITH (NOLOCK) ON	sq.PRCo = dt.PRCo AND 
									sq.PRGroup = dt.PRGroup AND 
									sq.PREndDate = dt.PREndDate AND 
									sq.Employee = dt.Employee AND 
									sq.PaySeq = dt.PaySeq
JOIN dbo.bPRPC pc WITH (NOLOCK) ON	pc.PRCo = dt.PRCo AND 
									pc.PRGroup = dt.PRGroup AND 
									pc.PREndDate = dt.PREndDate
WHERE	dt.PRCo = @prco AND 
		dt.PRGroup = @prgroup AND 
		dt.Employee = @employee AND 
		dt.EDLType = 'E' AND 
		es.EarnCode = @earncode AND 
		(
		 (dt.PREndDate < @prenddate) OR 
		 (dt.PREndDate = @prenddate AND dt.PaySeq < @payseq)
		) AND 
		(
		 (sq.PaidMth IS NULL AND 
		  DATEPART(YEAR,CASE pc.MultiMth WHEN 'Y' THEN pc.EndMth ELSE pc.BeginMth END) = DATEPART(YEAR,@paidmth)) 
		  OR 
		 (DATEPART(YEAR,sq.PaidMth) = DATEPART(YEAR,@paidmth))
		) AND 
		pc.GLInterface = 'N'

--subtract PRDT old amounts from earlier Pay Periods where non-final update was run but not the final
SELECT @ytdearns = @ytdearns - ISNULL(SUM(dt.OldAmt),0)
FROM dbo.bPRDT dt WITH (NOLOCK)
JOIN dbo.bPRES es ON es.PRCo = dt.PRCo AND 
					 es.SubjEarnCode = dt.EDLCode
JOIN dbo.bPRPC pc WITH (NOLOCK) ON	pc.PRCo = dt.PRCo AND 
									pc.PRGroup = dt.PRGroup AND 
									pc.PREndDate = dt.PREndDate
WHERE	dt.PRCo = @prco AND 
		dt.PRGroup = @prgroup AND 
		dt.Employee = @employee AND 
		dt.EDLType = 'E' AND 
		es.EarnCode = @earncode AND 
		(
		 (dt.PREndDate < @prenddate) OR 
		 (dt.PREndDate = @prenddate AND dt.PaySeq < @payseq)
		) AND 
		dt.OldMth BETWEEN @beginmth AND @endmth AND 
		pc.GLInterface = 'N'					
	
--subtract PRDT old amounts from current and later Pay Periods where non-final update was run that augmented accums
SELECT @ytdearns = @ytdearns - ISNULL(SUM(dt.OldAmt),0)
FROM dbo.bPRDT dt WITH (NOLOCK)
JOIN dbo.bPRES es ON es.PRCo = dt.PRCo AND 
					 es.SubjEarnCode = dt.EDLCode
WHERE	dt.PRCo = @prco AND 
		dt.PRGroup = @prgroup AND 
		dt.Employee = @employee AND 
		dt.EDLType = 'E' AND 
		es.EarnCode = @earncode AND 
		(
		 (dt.PREndDate > @prenddate) OR 
		 (dt.PREndDate = @prenddate AND dt.PaySeq >= @payseq)
		) AND 
		dt.OldMth BETWEEN @beginmth AND @endmth
	

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPRProcessGetAccumSubjEarnAUS] TO [public]
GO
