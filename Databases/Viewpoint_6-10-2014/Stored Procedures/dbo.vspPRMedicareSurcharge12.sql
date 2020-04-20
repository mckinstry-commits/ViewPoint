SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[vspPRMedicareSurcharge12]    Script Date: 12/13/2007 15:22:31 ******/
CREATE PROC [dbo].[vspPRMedicareSurcharge12]
/********************************************************
* CREATED BY: 	EN 11/27/2012	D-05383/#146657
*				DAN SO 09/03/2013	Bug:59956/Task:59957 - Original bug fix works perfect as long as it was in place BEFORE
*															hitting the threshold.  We have some customers that hit the threshold
*															before getting the fix in place, so we need to extend the bug fix to 
*															adjust Eligible and Calculated amounts on the current payroll to correct
*															amounts withheld.  Will also get the Threshold value from PR Routine Master
*															Misc. Amt #1 field and the Rate value from PR Deductions/Liabilities Rate #1
*															field instead of using hardcoded values. 
*
* USAGE:
* 	Calculates Additional Medicare Surcharge (deduction). 
*	If employee's YTD wages have exceeded the threshold, compute the surcharge as a rate of gross
*	of the wages that exceed the threshold. 
*
* INPUT PARAMETERS:
*	@PRCo		PR Company
*	@DLCode		Additonal Medicare Deduction Code
*	@CalcBasis	Subject Earnings
*	@TS			Total Subject Amount from Accums
*	@TE			Total Eligible Amount from Accums
*	@TC			Total Calculate Amount from Accums
*
* OUTPUT PARAMETERS:
*	@MedSurchargeAmt	Calculated Medicare Surcharge Amount
*	@EligAmt			Eligible Amount
*	@ErrorMsg			Error Message
*
* RETURN VALUE:
*   @rcode
* 		0 	    Success
*		1 		Failure
**********************************************************/
(@PRCo bCompany, @DLCode bEDLCode, @CalcBasis bDollar, 
 @TS bDollar, @TE bDollar, @TC bDollar,
 @MedSurchargeAmt bDollar OUTPUT, @EligAmt bDollar OUTPUT,
 @ErrorMsg VARCHAR(255) OUTPUT)
	 	

AS
SET NOCOUNT ON

--------------------------------------------------------------------
-- CALCULATE AND POSSIBLY ADJUST ELIGIBLE AND CALCULATED AMOUNTS  --
-- IF THERE ARE NOT ANY DIFFERENCES:							  --
--		@DiffInElig AND @DiffInCalc WILL BE 0					  --
--		SO THE RETURNED AMOUNTS WILL BE THE CURRENT AMOUNTS		  --
--------------------------------------------------------------------

DECLARE @CurrentElig bDollar, @CurrentCalc bDollar,
		@ShouldBeElig bDollar, @ShouldBeCalc bDollar,
		@DiffInElig bDollar, @DiffInCalc bDollar,
		@Threshold bDollar, @Rate bUnitCost,
		@RetEligible bDollar, @RetCalc bDollar,
		@rcode TINYINT

BEGIN TRY

	-- SET DEFAULT VALUES --
	SET @RetEligible = 0
	SET @RetCalc = 0
	SET @rcode = 0

	-- GET Threshold AND Rate --
	SELECT	@Threshold = m.MiscAmt1, @Rate = l.RateAmt1
      FROM	bPRRM m
      JOIN	bPRDL l 
	    ON  m.PRCo=l.PRCo AND m.Routine=l.Routine
     WHERE  m.PRCo = @PRCo AND l.DLCode = @DLCode

	-- CHECK EXISTING SUBJECT AMOUNT + CURRENT SUBJECT AMOUNT AGAINST THRESHOLD --
	IF (@TS + @CalcBasis) > @Threshold
		BEGIN
			-- CURRENT AMOUNTS --
			SET @CurrentElig = @CalcBasis
			SET @CurrentCalc = @CalcBasis * @Rate

			-- WHAT THE AMOUNTS SHOULD BE --
			SET @ShouldBeElig = @TS - @Threshold   
			SET @ShouldBeCalc = @ShouldBeElig * @Rate

			-- CALCULATE POSSIBLE DIFFERENCES  --
			SET @DiffInElig = @ShouldBeElig - @TE
			SET @DiffInCalc = @ShouldBeCalc - @TC

			-- SET CORRECTED AMOUNTS --
			SET @RetEligible = @DiffInElig +  @CurrentElig	
			SET @RetCalc = @DiffInCalc + @CurrentCalc	
		END	

	-- RETURN AMOUNTS --
	SET @EligAmt = @RetEligible	
	SET @MedSurchargeAmt = @RetCalc


END TRY

--------------------
-- ERROR HANDLING --
--------------------
BEGIN CATCH
	SET @rcode = 1
	SET @ErrorMsg = ERROR_PROCEDURE() + ': ' + ERROR_MESSAGE()	
END CATCH

------------------
-- EXIT ROUTINE --
------------------
vspExit:
	RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPRMedicareSurcharge12] TO [public]
GO
