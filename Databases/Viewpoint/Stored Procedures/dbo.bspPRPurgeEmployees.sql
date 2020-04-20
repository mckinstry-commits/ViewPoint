SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRPurgeEmployees]    Script Date: 12/20/2007 10:30:28 ******/
   CREATE procedure [dbo].[bspPRPurgeEmployees]
   /***********************************************************
    * CREATED BY: EN 6/10/98
    * MODIFIED By : EN 6/10/98
    *               EN 4/4/00 - remove deletion of PRED/PRAE/PRCW/PRDD/PREL/PRLB entries in this routine
    *                              because it's handled in the PREH delete trigger
    *               EN 4/28/00 - Checking for employee entries PRDH but employee isn't in that table; I think it was supposed
    *                              to be PRDT so I changed it.  Also coded to check in some tables which it wasn't checking in
    *                              though I felt it should: PRCA, PRCX, PRSQ, PRIA, PRDS, PRVP, PRAB
    *		GG 12/14/00 - rewritten to check for relevant detail and delete setup info with Employee header
    *				-- added data integrity check back into bPREH delete trigger
	*				EN 12/20/07 - #126524  swap order of bPREL and bPRLB delete to avoid trigger errors
	*				MV 10/15/12 - B-10534/TK-18444 - added vPRArrears table to employee purge check and fixed logic errors
    *
    * USAGE:
    * Called by PR Purge program to remove inactive employee who have no entries in Accumulations (bPREA),
    * Timecards (bPRTH), Payment History (bPRPH), Leave History (bPRLH), or W-2s (bPRWE).
    * Can restrict by a specific employee and/or through a specified termination date.
    * Removes Employee Header (PREH), Deduction/Liability overrides (PRED),
    * Auto earnings (PRAE), Crew makeup (PRCW), Direct Deposit distributions
    * (PRDD), and Employee Leave setup information (PREL/PRLB).
    *
    * INPUT PARAMETERS
    *   @prco		PR Company
    *   @xemployee		Employee to delete (optional)
    *   @termdate		Termination data to delete through (optional)
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    *
    * RETURN VALUE
    *   0 =  success,  1 =   fail
    *****************************************************/
   
   	(@prco bCompany,
   	 @xemployee bEmployee,
   	 @termdate bDate,
   	 @errmsg varchar(255) output)
   	 
	AS
	SET NOCOUNT ON
	DECLARE @rcode int, @employee bEmployee
   
	SELECT @rcode = 0, @employee = null
   
	IF @xemployee IS NOT NULL
	BEGIN
		IF EXISTS 
			(
				SELECT 1 
				FROM dbo.PREH e 
				WHERE 
					(
						PRCo = @prco AND e.Employee = isnull(@xemployee,e.Employee)
   						AND ISNULL(e.TermDate,'') <= ISNULL(@termdate, ISNULL(e.TermDate,'')) AND e.ActiveYN = 'N'
	   				)
   					-- check for detail
   				AND 
					(
						e.Employee IN (SELECT Employee FROM bPREA where PRCo = @prco and Employee = @xemployee)
						OR e.Employee IN (SELECT Employee FROM bPRTH WHERE PRCo = @prco and Employee = @xemployee)
						OR e.Employee IN (SELECT Employee FROM bPRPH WHERE PRCo = @prco and Employee = @xemployee)
						OR e.Employee IN (SELECT Employee FROM bPRLH WHERE PRCo = @prco and Employee = @xemployee)
						OR e.Employee IN (SELECT Employee FROM bPRWE WHERE PRCo = @prco and Employee = @xemployee)
						OR e.Employee IN (SELECT Employee FROM vPRArrears WHERE PRCo = @prco and Employee = @xemployee)
					)
   			)
   			BEGIN
				SELECT @errmsg = 'Employee has Accumulation, Timecard, Payment History, Leave History or Arrears/Payback History records that must be purged prior to purging Employee record.', @rcode = 1
				GOTO bspexit
			END
	END
	
   SELECT @employee = min(e.Employee)
   FROM dbo.PREH e
   WHERE PRCo = @prco AND e.Employee = isnull(@xemployee,e.Employee)
   	AND ISNULL(e.TermDate,'') <= ISNULL(@termdate, ISNULL(e.TermDate,'')) AND e.ActiveYN = 'N'
   	-- check for detail
   	AND e.Employee NOT IN (SELECT Employee FROM dbo.bPREA WHERE PRCo = @prco AND Employee = e.Employee)
   	AND e.Employee NOT IN (SELECT Employee FROM dbo.bPRTH WHERE PRCo = @prco AND Employee = e.Employee)
   	AND e.Employee NOT IN (SELECT Employee FROM dbo.bPRPH WHERE PRCo = @prco AND Employee = e.Employee)
   	AND e.Employee NOT IN (SELECT Employee FROM dbo.bPRLH WHERE PRCo = @prco AND Employee = e.Employee)
   	AND e.Employee NOT IN (SELECT Employee FROM dbo.bPRWE WHERE PRCo = @prco AND Employee = e.Employee)
   	AND e.Employee NOT IN (SELECT Employee FROM dbo.vPRArrears WHERE PRCo= @prco AND Employee = e.Employee)
   WHILE @employee is not null
   BEGIN
	   -- remove Employee header and setup info
		BEGIN TRANSACTION
		DELETE bPRED WHERE PRCo = @prco and Employee = @employee	-- Employee DLs
		DELETE bPRAE WHERE PRCo = @prco and Employee = @employee	-- Auto Earnings
		DELETE bPRCW WHERE PRCo = @prco and Employee = @employee	-- Crew Makeup
		DELETE bPRDD WHERE PRCo = @prco and Employee = @employee	-- Deposit Distributions
		DELETE bPRLB WHERE PRCo = @prco and Employee = @employee	-- Employee Leave Basis
		DELETE bPREL WHERE PRCo = @prco and Employee = @employee	-- Employee Leave Codes
		DELETE bPREH WHERE PRCo = @prco and Employee = @employee	-- Employee Header (must be DELETEd last)
		COMMIT TRANSACTION
	   
	   SELECT @employee = min(e.Employee)
	   FROM dbo.PREH e
	   WHERE e.PRCo = @prco	and e.Employee = isnull(@xemployee,e.Employee)
	   	AND ISNULL(e.TermDate,'') <= ISNULL(@termdate, ISNULL(e.TermDate,'')) AND e.ActiveYN = 'N'
   		-- check for detail
   		AND e.Employee NOT IN (SELECT Employee FROM dbo.bPREA WHERE PRCo = @prco AND Employee = e.Employee)
   		AND e.Employee NOT IN (SELECT Employee FROM dbo.bPRTH WHERE PRCo = @prco AND Employee = e.Employee)
   		AND e.Employee NOT IN (SELECT Employee FROM dbo.bPRPH WHERE PRCo = @prco AND Employee = e.Employee)
   		AND e.Employee NOT IN (SELECT Employee FROM dbo.bPRLH WHERE PRCo = @prco AND Employee = e.Employee)
   		AND e.Employee NOT IN (SELECT Employee FROM dbo.bPRWE WHERE PRCo = @prco AND Employee = e.Employee)
	   	AND e.Employee NOT IN (SELECT Employee FROM dbo.vPRArrears WHERE PRCo= @prco AND Employee = e.Employee)
   		AND e.Employee > @employee
   END
   
   bspexit:
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPurgeEmployees] TO [public]
GO
