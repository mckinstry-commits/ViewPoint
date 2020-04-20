SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspPRDLSubjectToArrearsPaybackVal]
/***********************************************************
* CREATED by:	CHS 08/14/2012
* Modified by:	CHS 09/26/2012	B-10989
*				MV	10/10/2012	D-06029 validate for bPRED Override Method - Use rate of gross.
*
* Usage:
*	Validate checkbox
* 	In PRDL the Subject to Arrears/Payback check box relates to the Eligible 
*	for Arrears/Payback check box in PRED.  The check box being checked in PRDL 
*	on a deduction code activates the eligible check box in PRED at the employee 
*	level and allows set up.  If this flag has been checked on any employee (activated) 
*	for an employee we should not allow the Subject to Arrears/Payback box in PRDL 
*	to be unchecked.
*
* Input params:
*	@PRCO		PR company
*	@DLCode		DL Code
*	@SubjectToArrearsYN	value of check box
*
* Output params:
*	@EligibleOuput	output value of check box
*	@msg		Vendor Name or error message
*
* Return code:
*	0 = success, 1 = failure
*****************************************************/
(	@PRCO INT, 
	@DLCode bEDLCode, 
	@SubjectToArrearsYN bYN,
	@msg VARCHAR(255) OUTPUT
)

	AS
	SET NOCOUNT ON

	DECLARE @RecordCount int,
			@Employee bEmployee
	
	--D-06029/TK-18395
	IF @SubjectToArrearsYN = 'Y'
	BEGIN
		-- validate for Employees with this deduction code that are using override calc method - rate of gross.
		SELECT DLCode 
		FROM dbo.bPRED
		WHERE PRCo = @PRCO 
			AND DLCode = @DLCode
			AND OverCalcs = 'M'
		
		SELECT @RecordCount = @@rowcount
		 		
		IF ISNULL(@RecordCount, 0) > 0
			BEGIN
			SELECT @msg = 'Cannot check Subject to Arrears for this Deduction code. '
			SELECT @msg = @msg + cast(@RecordCount as varchar(10)) + ' employee(s) with this Deduction code in PR Employee Dedn/Liabs '
			SELECT @msg = @msg + 'are using override calculation method - rate of gross.'
			SELECT @msg
			
			RETURN 1		
			END
	END --End SubjectToArrears = Y

	IF ISNULL(@SubjectToArrearsYN,'N') = 'N'
	BEGIN
		-- PRED EligibleForArrearsCalc = 'Y' 
		SELECT Employee 
		FROM bPRED
		WHERE PRCo = @PRCO 
			AND EligibleForArrearsCalc = 'Y' 
			AND DLCode = @DLCode
		GROUP BY Employee			

		SELECT @RecordCount = @@rowcount 
		
		IF ISNULL(@RecordCount, 0) > 0
		BEGIN
			SELECT @msg =  'Cannot disable Subject to Arrears for this Deduction code. This code is set up as eligible on '
			SELECT @msg = @msg + cast(@RecordCount as varchar(10)) + ' employee(s) in PR Employee Dedn/Liabs.'
			SELECT @msg
			
			RETURN 1		
		END


		-- PRED (LifeToDateArrears - LifeToDatePayback) <> 0
		SELECT Employee 
		FROM bPRED
		WHERE PRCo = @PRCO 
			AND DLCode = @DLCode
			AND (LifeToDateArrears - LifeToDatePayback) <> 0
		GROUP BY Employee			

		SELECT @RecordCount = @@rowcount 
		
		IF ISNULL(@RecordCount, 0) > 0
		BEGIN
			SELECT @msg = 'Cannot disable Subject to Arrears for this Deduction code. This code has an outstanding life-to-date'
			SELECT @msg = @msg + ' Arrears/Payback balance on ' + cast(@RecordCount as varchar(10)) + ' employee(s) in PR Employee Dedn/Liabs.'
			SELECT @msg
			
			RETURN 1		

		END
		
		---- bPRDT			
		SELECT Employee
		FROM bPRDT t
			JOIN PRPC c on t.PRCo = c.PRCo 
				AND t.PRGroup = c.PRGroup 
				AND t.PREndDate = c.PREndDate 				
		WHERE t.PRCo = @PRCO 
			AND t.EDLType = 'D'
			AND t.EDLCode = @DLCode
			AND (t.PaybackAmt <> 0 OR t.PaybackOverAmt <> 0)
			AND c.DateClosed IS NULL
		GROUP BY Employee		
			
		SELECT @RecordCount = @@rowcount 
		
		IF ISNULL(@RecordCount, 0) > 0
		BEGIN
			SELECT @msg =  'Cannot disable Subject to Arrears for this Deduction code. This code is in use by '
			SELECT @msg = @msg + cast(@RecordCount as varchar(10)) + ' employees in open pay period(s).'
			SELECT @msg
			
			RETURN 1		
		END
		
	END -- End SubjectToArrears = N
					

	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPRDLSubjectToArrearsPaybackVal] TO [public]
GO
