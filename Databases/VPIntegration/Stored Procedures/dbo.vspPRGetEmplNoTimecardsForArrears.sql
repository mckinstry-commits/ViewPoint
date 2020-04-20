SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPRGetEmplNoTimecardsForArrears]
/************************************************************************************************
* CREATED BY:   KK 08/20/2012 B-10150/TK-17205 Created for Arrears/Payback enhancement
*
* MODIFIED By:  EN 08/28/2012 B-10150/TK-17205 allow for possible negative arrears amounts
*				KK 08/28/2012 B-10150/TK-17205 repair select getting employees with no t/c
*				KK 09/11/2012 B-10150/TK-17205 change no timecard search to look in PRTH (t/c header) rather than SQ
*				KK 09/11/2012 B-10150/TK-17205 Created a conditional to delete old arrears history records and insert new
*				KK 10/02/2012 B-10150/TK-16682 Added a check to clear arrears history and bounce out if there are no timecards
*											   for this pay period.
*				KK 10/11/2012 D-06041/TK-18503 Modified selection criteria for deleting employees when reprocessing to clear ALL 
*											   employees with no timecards regardless of eligibility on any level.
*				KK 10/18/2012 D-06083/TK-18611 PR Arrears should calculate arrears with no timecard specific to the sequence NOT paid in
*
* USAGE: Called from bspPRPRocess to create table of employees with no timecards who are 
*		 eligible for arrears/payback
*		 Calls stored proc to process for arrears, vspPRProcessArrears
*     PR Employee must be checked "Y" yes for:
*		1. Active for Arrears/Payback (PREH)
*		2. Eligible for Arrears/Payback (PRED)
*		3. Subject to Arrears/Payback (PRDL)
*
* INPUT PARAMETERS
*   @prco			PR Co to validate agains t
*   @dedncode		PR Dedn code to validate against
*	@prgroup		Employees pr group
*	@enddate		Pay period end date
*	@payseq			Pay period sequence
*
* OUTPUT PARAMETERS
*   @msg		error message if error occurs otherwise Description of Ded/Earnings/Liab Code
*
* RETURN VALUE
*   0         Success
*   1         Failure
************************************************************************************************/ 

(@prco bCompany = 0, 
 @prgroup bGroup = NULL,
 @employee bEmployee = NULL, -- Only comes in if processing as single employee
 @enddate bDate = NULL,
 @payseq smallint = NULL,
 @msg varchar(90) OUTPUT)

AS
SET NOCOUNT ON

DECLARE @dlcode bEDLCode,
		@arrearsamt bDollar,
		@predamt bDollar,
		@prdlamt bDollar,
		@rcode tinyint
		
--------------------------------------------------------------------------
/*	Create table variable to hold eligible employees/dlcodes			*/
--------------------------------------------------------------------------
--Check that the pay sequence passed in is valid for this pay period
IF @payseq IS NOT NULL
BEGIN
	IF NOT EXISTS (SELECT * FROM dbo.bPRPS
				   WHERE PRCo = @prco
						AND PRGroup = @prgroup
						AND PREndDate = @enddate
						AND PaySeq = @payseq)
	BEGIN
		RETURN 0
	END	
END

DECLARE @EmplDednCodeNoTimecard TABLE
(	
	employee bEmployee,
	dedncode bEDLCode,
	payseq tinyint,
	loopkey varchar(14)
)

;WITH caselist (empl, dcode, pseq) AS 
	(SELECT DISTINCT eh.Employee, 
					 ed.DLCode, 
					(CASE WHEN @payseq IS NOT NULL THEN @payseq
						 WHEN dl.SeqOneOnly = 'Y' THEN 1
						 ELSE ps.PaySeq
					END)
	FROM dbo.bPREH eh						-- Employee Header
	JOIN dbo.bPRED ed ON eh.PRCo = ed.PRCo	-- Employee Dedns/Libs
					 AND eh.Employee = ed.Employee
	JOIN dbo.bPRDL dl ON eh.PRCo = dl.PRCo	-- Dedns/Liabs
					 AND ed.DLCode = dl.DLCode
	JOIN dbo.bPRAF af ON eh.PRCo = af.PRCo	-- Active Frequency
					 AND eh.PRGroup = af.PRGroup
	JOIN dbo.bPRPS ps ON eh.PRCo = ps.PRCo	-- Pay Sequence Control
					 AND eh.PRGroup = ps.PRGroup
	WHERE eh.PRCo = @prco
		AND eh.PRGroup = @prgroup
		AND eh.ArrearsActiveYN = 'Y' --Flagged in PREH active for arrears
		AND eh.Employee = ISNULL(@employee,eh.Employee) --This is a valid employee
		AND eh.Employee NOT IN(SELECT Employee FROM dbo.bPRTH -- Employees with no timecard for a given sequence
								WHERE PRCo = @prco
								  AND PRGroup = @prgroup
								  AND PREndDate = @enddate
								  AND PaySeq = @payseq) -- 06083 (KK)
		AND ed.EligibleForArrearsCalc = 'Y' --Flagged in PRED eligible for this deduction code
		AND dl.SubjToArrearsPayback = 'Y' --Flagged in PRDL subject to arrears
		AND af.PREndDate = @enddate --End date is legit in Pay Period Control active frequency
		AND af.Frequency = ed.Frequency --Frequency in PRED matches an active frequency in Pay Period Control
		AND ps.PREndDate = @enddate) --Pay Sequence control is legit

INSERT INTO @EmplDednCodeNoTimecard (employee,dedncode,payseq,loopkey)
SELECT empl, dcode, pseq,
		(replace(str(convert(char(6),empl),6), space(1),'0') 
		+ replace(str(convert(char(5),dcode),5), space(1),'0') 
		+ replace(str(convert(char(3),pseq),3), space(1),'0')) AS loopkey
FROM caselist

	-- If the user is processing a specified sequence OR the dl code is set to only process seq 1
	-- make sure all other records in the arrears history table have been cleared for this co, empl, 
	-- dlcode, group, enddate NOTE: Payback will be 0 when processing arrears, and enddate and pay 
	-- will be null for employees with no timecards.
DELETE FROM dbo.vPRArrears
		WHERE PRCo = @prco
		AND Employee NOT IN (SELECT Employee FROM dbo.bPRTH
							  WHERE PRCo = @prco
							    AND PRGroup = @prgroup
							    AND PREndDate = @enddate)
		AND PRGroup = @prgroup
		AND PaybackAmt = 0
		AND PREndDate = @enddate

-- We have cleared the PR Arrears History table above, so if there are no 
-- timecards in existance for this company and end date, do not process.
IF NOT EXISTS (SELECT * FROM dbo.bPRTH 
			   WHERE PRCo = @prco 
			     AND PREndDate = @enddate)
BEGIN 
	RETURN 0 
END
----------------------------------------------------------------------------
/*	Processing loop to get arrears amount and call vspPRProcessArrears	*/
--------------------------------------------------------------------------
-- Loop through the table
DECLARE @loopkey char(14)
SELECT @loopkey = MIN(loopkey) FROM @EmplDednCodeNoTimecard
WHILE (@loopkey IS NOT NULL)
BEGIN
	SELECT @employee = employee, 
		   @dlcode = dedncode, 
		   @payseq = payseq 
	FROM @EmplDednCodeNoTimecard
	WHERE loopkey = @loopkey
	-- Get the amount to put in arrears: This will be the override rate amount
	-- from PRED if it exists, otherwise we will use amount #1 in PRDL
	SELECT @predamt = RateAmt 
	FROM dbo.bPRED
	WHERE PRCo = @prco
		AND Employee = @employee
		AND DLCode = @dlcode
	SELECT @prdlamt = RateAmt1 
	FROM dbo.bPRDL
	WHERE PRCo = @prco
		AND DLCode = @dlcode
		
	IF @predamt <> 0 SELECT @arrearsamt = @predamt
	ELSE SELECT @arrearsamt = @prdlamt

	--Call stored procedure to put record into arrears table
	EXEC @rcode = vspPRProcessArrears @prco, 
	  						 @employee,
	  						 @dlcode,
	  						 @arrearsamt,
	  						 0, -- Payback will ever be processed for empls w/o a timecard
	  						 @prgroup,
	  						 @enddate,
	  						 @payseq,
	  						 'N', -- TimecardYN = No
	  						 @msg output
	IF @rcode = 1
	BEGIN
		RETURN 1
	END
	SELECT @loopkey = MIN(loopkey) 
	FROM @EmplDednCodeNoTimecard
	WHERE loopkey > @loopkey
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPRGetEmplNoTimecardsForArrears] TO [public]
GO
