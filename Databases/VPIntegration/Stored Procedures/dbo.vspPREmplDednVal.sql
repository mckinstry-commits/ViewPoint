SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPREmplDednVal    Script Date: 8/28/99 9:33:15 AM ******/
CREATE  proc [dbo].[vspPREmplDednVal]
/************************************************************************************************
* CREATED BY: EN 08/07/2012
* MODIFIED By : 
*
* USAGE:
* Validates deduction code and existance of employee/deduction combination 
* in PRED where deduction is marked as Subject to Arrears/Payback in PRDL.
*
* INPUT PARAMETERS
*   @prco		PR Co to validate agains t
*   @employee	PR Craft to validate against
*   @dedncode	PR Class to validate against
* OUTPUT PARAMETERS
*	@arrearstotal	total arrears amount from PRArrears for this employee/dedncode
*	@paybacktotal	total payback amount from PRArrears for this employee/dedncode
*	@lifetodatebalance	computed as LifeToDateArrears minus LifeToDatePayback from PRED table
*   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
* RETURN VALUE
*   0         success
*   1         Failure
************************************************************************************************/ 

(@prco bCompany = 0, 
 @employee bEmployee = NULL, 
 @dedncode bEDLCode = NULL, 
 @arrearstotal bDollar OUTPUT,
 @paybacktotal bDollar OUTPUT,
 @lifetodatebalance bDollar OUTPUT,
 @msg varchar(90) OUTPUT)

AS
SET NOCOUNT ON

DECLARE @subjtoarrearspayback bYN

-- confirm input params are not null
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
IF @dedncode IS NULL
BEGIN
	SELECT @msg = 'Missing deduction code!'
	RETURN 1
END

SELECT @msg = [Description],
	   @subjtoarrearspayback = SubjToArrearsPayback
FROM dbo.PRDL
WHERE PRCo = @prco AND DLCode = @dedncode
IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'PR Deduction Code not on file!'
	RETURN 1
END
IF @subjtoarrearspayback = 'N'
BEGIN
	SELECT @msg = 'Deduction Code must be subject to arrears/payback!'
	RETURN 1
END

IF NOT EXISTS (SELECT * 
		   FROM dbo.PRED 
		   WHERE PRCo = @prco AND 
				 Employee = @employee AND 
				 DLCode = @dedncode)
IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'Employee/Deduction combination not on file!'
	RETURN 1
END

--load amounts into return params
SET @arrearstotal = dbo.vfPRArrearsPaybackHistoryArrearsAmtTotal(@prco, @employee, @dedncode)
SET @paybacktotal = dbo.vfPRArrearsPaybackHistoryPaybackAmtTotal(@prco, @employee, @dedncode)
SET @lifetodatebalance = dbo.vfPREmplDLLifeToDateBalance(@prco, @employee, @dedncode)


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspPREmplDednVal] TO [public]
GO
