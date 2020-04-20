SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[vspPRProcessGetDLYTDSubjectAmount]
/***********************************************************
* CREATED BY:	 EN 11/27/2012 D-05383/#146657
* MODIFIED BY:   EN 6/07/2013 User Story 4859/Task 51770/#NS-42396 Allow for potential pre-tax deductions when determining YTD earnings
*
* USAGE:
* Returns employee's YTD subject basis earnings for the specified deduction or liability code.
* Called from bspPRProcessFed.
*
* INPUT PARAMETERS
*   @prco	        PR Company
*   @prgroup        PR Group
*   @prenddate	    PR Ending Date
*   @employee	    Employee to process
*   @payseq	    	Payment Sequence #
*   @dlcode			Dedn/liab code
*
* OUTPUT PARAMETERS
*   @accumsubj 		Accumulated dedn/liab subject amount (minus pre-tax dedns) based on limit period
*   @errmsg  	    Error message if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@prco bCompany,
@prgroup bGroup, 
@prenddate bDate, 
@employee bEmployee, 
@payseq tinyint,
@dlcode bEDLCode, 
@accumsubj bDollar OUTPUT, 
@errmsg varchar(255) OUTPUT

AS
SET NOCOUNT ON

DECLARE @PaidMonth bMonth, 
		@BeginMonth bMonth, 
		@EndMonth bMonth

-- get paid month to be used for non-monthly limits
SELECT @PaidMonth = PaidMth
FROM dbo.bPRSQ
WHERE PRCo = @prco 
	  AND PRGroup = @prgroup 
	  AND PREndDate = @prenddate 
	  AND Employee = @employee 
	  AND PaySeq = @payseq
IF @PaidMonth IS NULL
BEGIN
	SELECT @PaidMonth = CASE MultiMth WHEN 'Y' THEN EndMth ELSE BeginMth END
	FROM dbo.bPRPC
	WHERE PRCo = @prco 
		  AND PRGroup = @prgroup 
		  AND PREndDate = @prenddate
END

-- get begin and end month
EXEC vspPRGetMthsForAnnualCalcs 12, @PaidMonth, @BeginMonth OUTPUT, @EndMonth OUTPUT, @errmsg OUTPUT

-- compute subject amount
SELECT	@accumsubj =   (SELECT ISNULL(SUM(ea.Amount),0.00) --get wages that have been posted to employee accums
						FROM dbo.bPREA ea
						JOIN dbo.bPRDB db ON db.PRCo = ea.PRCo AND db.EDLCode = ea.EDLCode
						WHERE ea.PRCo = @prco 
							  AND ea.Employee = @employee
							  AND (ea.Mth BETWEEN @BeginMonth AND @EndMonth)
							  AND ea.EDLType = 'E' AND db.DLCode = @dlcode
					   )
				   +
					   (
						   (SELECT ISNULL(SUM(dt.Amount),0.00) --add wages that have been paid in open pay pds
							FROM dbo.bPRDT dt
							JOIN dbo.bPRDB db ON db.PRCo = dt.PRCo AND db.EDLCode = dt.EDLCode
							JOIN dbo.bPRSQ sq ON sq.PRCo = dt.PRCo AND sq.PRGroup = dt.PRGroup AND sq.PREndDate = dt.PREndDate
												AND sq.Employee = dt.Employee AND sq.PaySeq = dt.PaySeq
							JOIN dbo.bPRPC pc ON pc.PRCo = dt.PRCo AND pc.PRGroup = dt.PRGroup AND pc.PREndDate = dt.PREndDate
							WHERE dt.PRCo = @prco 
								  AND dt.Employee = @employee
								  AND dt.EDLType = 'E' AND db.DLCode = @dlcode
								  AND ((dt.PREndDate < @prenddate) OR (dt.PREndDate = @prenddate AND dt.PaySeq <= @payseq))
								  AND ((sq.PaidMth IS NULL
										AND (CASE pc.MultiMth WHEN 'Y' THEN pc.EndMth ELSE pc.BeginMth END BETWEEN @BeginMonth AND @EndMonth)
									   )
									   OR (sq.PaidMth BETWEEN @BeginMonth AND @EndMonth))
								  AND pc.GLInterface = 'N'
						   )
					   -
						   (SELECT ISNULL(SUM(dt.OldAmt),0.00) --subtract from open pay pd wages any wages posted to empl accums
							FROM dbo.bPRDT dt
							JOIN dbo.bPRDB db ON db.PRCo = dt.PRCo AND db.EDLCode = dt.EDLCode
							JOIN dbo.bPRPC pc ON pc.PRCo = dt.PRCo AND pc.PRGroup = dt.PRGroup AND pc.PREndDate = dt.PREndDate
							WHERE dt.PRCo = @prco AND dt.Employee = @employee	
								  AND dt.EDLType = 'E' AND db.DLCode = @dlcode
								  AND ((dt.PREndDate < @prenddate) OR (dt.PREndDate = @prenddate AND dt.PaySeq < @payseq))
 								  AND (dt.OldMth BETWEEN @BeginMonth AND @EndMonth)
 								  AND pc.GLInterface = 'N'
 						   )
 					   )
 				   -	
					   (SELECT ISNULL(SUM(dt.OldAmt),0.00) --subtract from above amount any wages paid and posted to empl accums to the current pay pd/pay seq or future pay pds
						FROM dbo.bPRDT dt
						JOIN dbo.bPRDB db ON db.PRCo = dt.PRCo AND db.EDLCode = dt.EDLCode
						WHERE dt.PRCo = @prco AND dt.Employee = @employee
							  AND dt.EDLType = 'E' AND db.DLCode = @dlcode
							  AND (dt.PREndDate > @prenddate OR (dt.PREndDate = @prenddate AND dt.PaySeq >= @payseq))
							  AND (dt.OldMth BETWEEN @BeginMonth AND @EndMonth
					   )
				   )


-------------------------------------------------------------------------------
-- DETERMINE YTD PRE-TAX DEDUCTIONS INCLUDING ANY FOR THE CURRENT PAY PERIOD --
-------------------------------------------------------------------------------
DECLARE @PreTaxDedns bDollar

SELECT	@PreTaxDedns =  
 (SELECT ISNULL(SUM(ea.Amount),0.00) --get wages that have been posted to employee accums
						FROM dbo.bPREA ea
						JOIN dbo.bPRDB db ON db.PRCo = ea.PRCo AND db.EDLCode = ea.EDLCode
						WHERE ea.PRCo = @prco 
							  AND ea.Employee = @employee
							  AND (ea.Mth BETWEEN @BeginMonth AND @EndMonth)
							  AND ea.EDLType = 'D' AND db.DLCode = @dlcode AND db.EDLType = 'D'
					   )
				   +
					   (
						   (SELECT ISNULL(SUM(
											  CASE WHEN dt.UseOver = 'Y' THEN dt.OverAmt ELSE dt.Amount END
											  ),0.00) --add wages that have been paid in open pay pds
							FROM dbo.bPRDT dt
							JOIN dbo.bPRDB db ON db.PRCo = dt.PRCo AND db.EDLCode = dt.EDLCode
							JOIN dbo.bPRSQ sq ON sq.PRCo = dt.PRCo AND sq.PRGroup = dt.PRGroup AND sq.PREndDate = dt.PREndDate
												AND sq.Employee = dt.Employee AND sq.PaySeq = dt.PaySeq
							JOIN dbo.bPRPC pc ON pc.PRCo = dt.PRCo AND pc.PRGroup = dt.PRGroup AND pc.PREndDate = dt.PREndDate
							WHERE dt.PRCo = @prco 
								  AND dt.Employee = @employee
								  AND dt.EDLType = 'D' AND db.DLCode = @dlcode AND db.EDLType = 'D'
								  AND ((dt.PREndDate < @prenddate) OR (dt.PREndDate = @prenddate AND dt.PaySeq <= @payseq))
								  AND ((sq.PaidMth IS NULL
										AND (CASE pc.MultiMth WHEN 'Y' THEN pc.EndMth ELSE pc.BeginMth END BETWEEN @BeginMonth AND @EndMonth)
									   )
									   OR (sq.PaidMth BETWEEN @BeginMonth AND @EndMonth))
								  AND pc.GLInterface = 'N'
						   )
					   -
						   (SELECT ISNULL(SUM(dt.OldAmt),0.00) --subtract from open pay pd wages any wages posted to empl accums
							FROM dbo.bPRDT dt
							JOIN dbo.bPRDB db ON db.PRCo = dt.PRCo AND db.EDLCode = dt.EDLCode
							JOIN dbo.bPRPC pc ON pc.PRCo = dt.PRCo AND pc.PRGroup = dt.PRGroup AND pc.PREndDate = dt.PREndDate
							WHERE dt.PRCo = @prco AND dt.Employee = @employee	
								  AND dt.EDLType = 'D' AND db.DLCode = @dlcode AND db.EDLType = 'D'
								  AND ((dt.PREndDate < @prenddate) OR (dt.PREndDate = @prenddate AND dt.PaySeq < @payseq))
 								  AND (dt.OldMth BETWEEN @BeginMonth AND @EndMonth)
 								  AND pc.GLInterface = 'N'
 						   )
 					   )
 				   -	
					   (SELECT ISNULL(SUM(dt.OldAmt),0.00) --subtract from above amount any wages paid and posted to empl accums to the current pay pd/pay seq or future pay pds
						FROM dbo.bPRDT dt
						JOIN dbo.bPRDB db ON db.PRCo = dt.PRCo AND db.EDLCode = dt.EDLCode
						WHERE dt.PRCo = @prco AND dt.Employee = @employee
							  AND dt.EDLType = 'D' AND db.DLCode = @dlcode AND db.EDLType = 'D'
							  AND (dt.PREndDate > @prenddate OR (dt.PREndDate = @prenddate AND dt.PaySeq >= @payseq))
							  AND (dt.OldMth BETWEEN @BeginMonth AND @EndMonth
					   )
				   )

--------------------------------------------------------
-- SUBTRACT YTD PRE-TAX DEDUCTIONS FROM THE YTD WAGES --
--------------------------------------------------------
SELECT @accumsubj = @accumsubj - @PreTaxDedns

    
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspPRProcessGetDLYTDSubjectAmount] TO [public]
GO
