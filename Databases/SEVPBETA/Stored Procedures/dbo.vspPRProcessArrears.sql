
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPRProcessArrears]
/************************************************************************************************
* CREATED BY:   KK 08/20/2012
* MODIFIED By:	EN 08/28/2012 B-10150/TK-17205 Do not post to PRArrears if arrears or payback amount is 0
*				EN 08/28/2012 B-10150/TK-17205 Use dbo.vfDateOnly() instead of GETDATE() in PRArrears Insert statement
*												to get today's date without timestamp.
*				KK 09/12/2012 B-10150/TK-17205 Moved deletion of arrears history record to vspPRGerEmplNoTimecardsForArrears
*												Added condition for arrears sequencing to "refresh"
*				KK 05/21/2013 TFS-47844 Removed superfulous code, added clause to NOT add records with timecards
*
* USAGE:	Called from vspPRGerEmplNoTimecardsForArrears
*			Processes employee/deduction code for Arrears
*			Only valid eligible employee/DL code combinations will be processed here
*			1. Active for Arrears/Payback (PREH) = "Y" Yes
*			2. Eligible for Arrears/Payback (PRED) = "Y" Yes
*			3. Subject to Arrears/Payback (PRDL) = "Y" Yes
*
* INPUT PARAMETERS
*   @prco			PR Co to validate agains t
*	@prgroup		Employees pr group
*	@enddate		Pay period end date
*   @employee		PR Employee to validate against
*	@payseq			Pay period sequence
*   @dlcode			PR Dedn code to validate against
*	@arrearsamt		Amount to accrue to arrears
*	@paybackamt		Amount to payback
*	@timecardYN		Flag to signify if the employee has a timecard or not
*
* OUTPUT PARAMETERS
*   @msg		error message if error occurs otherwise Description of Ded/Earnings/Liab Code
* RETURN VALUE
*   0         Success
*   1         Failure
************************************************************************************************/ 

(@prco bCompany = 0, 
 @employee bEmployee = NULL, 
 @dlcode bEDLCode = NULL,
 @arrearsamt bDollar = 0,
 @paybackamt bDollar = 0,
 @prgroup bGroup = NULL,
 @enddate bDate = NULL,
 @payseq smallint = NULL,
 @timecardYN bYN = NULL,
 @msg varchar(90) OUTPUT)

AS
SET NOCOUNT ON

DECLARE @nextseq smallint

-- Confirm input params are not null
IF @prco IS NULL
BEGIN
	SELECT @msg = 'Missing PR Company!'
	RETURN 1
END
IF @employee IS NULL
BEGIN
	SELECT @msg = 'Missing employee!'
	RETURN 1
END
IF @dlcode IS NULL
BEGIN
	SELECT @msg = 'Missing deduction code!'
	RETURN 1
END

----Check that this record does not have a timecard entry
IF EXISTS (SELECT * FROM dbo.bPRTH
		   WHERE PRCo = @prco
			 AND PRGroup = @prgroup
			 AND PREndDate = @enddate
			 AND Employee = @employee
			 AND PaySeq = @payseq
			 AND Amt >= 0.00)
BEGIN
	RETURN 0
END	

-- Get the next available Seq Empl/Dedn in PRArrears
SELECT @nextseq = ISNULL(MAX(Seq + 1), 1)
FROM dbo.vPRArrears 
WHERE PRCo = @prco
  AND Employee = @employee 			
  AND DLCode = @dlcode  

--------------------------------------------------------------------------
/*				Insert record in PR Arrears table						*/
--------------------------------------------------------------------------
-- Insert into PRArrears
INSERT INTO dbo.vPRArrears (PRCo,			Employee,			DLCode,
							Seq,			Date,				ArrearsAmt,
							PaybackAmt,		PRGroup,			PREndDate,
							PaySeq,			EDLType)
					SELECT  @prco,			@employee,			@dlcode,
							@nextseq,		dbo.vfDateOnly(),	@arrearsamt,
							@paybackamt,	@prgroup,			@enddate,
							@payseq,		'D'	


RETURN 0

GO

GRANT EXECUTE ON  [dbo].[vspPRProcessArrears] TO [public]
GO
