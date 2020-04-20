SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspPR_AU_Standard]
/***********************************************************/
-- CREATED BY: EN 3/12/2013  TFS-39858
-- MODIFIED BY: DAN SO 05/21/2013 - Story 50738 - return Eligible amount
--
-- USAGE:
-- Tax routine to compute tax on Early Retirement earnings in the case of voluntary (standard)
-- redundancy.
--
-- This wrapper calls stored procedure vspPR_AU_ETP_TaxComputations which was designed to handle
-- the tax computation for any possible ETP situation.  In this case the stored procedure will
-- be called for the instance of voluntary redundancy.
--
-- INPUT PARAMETERS
--   @PRCo						PR Company
--	 @Employee					Employee
--   @PREndDate					End Date of payroll period being processed
--   @SubjectAmt				Subject Amount on which to base the computation
--
-- OUTPUT PARAMETERS
--	 @TaxAmount					Computed tax amount
--	 @EligibleAmt				Amount to be taxed
--   @Message					Error message if error occurs	
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
/******************************************************************/
(
 @PRCo bCompany = NULL,
 @Employee bEmployee = NULL,
 @PREndDate bDate = NULL,
 @SubjectAmt bDollar = 0,
 @TaxAmount bDollar OUTPUT,
 @EligibleAmt bDollar OUTPUT,	-- 50738 --
 @ErrorMsg varchar(255) OUTPUT
)
AS

BEGIN TRY
	SET NOCOUNT ON

	DECLARE	@Return_Value int

	SELECT @Return_Value = 0


	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @PRCo IS NULL
		BEGIN
			SET @Return_Value = 1
			SET @ErrorMsg = 'Missing PR Company!'
			GOTO vspExit
		END
		
	IF @Employee IS NULL
		BEGIN
			SET @Return_Value = 1
			SET @ErrorMsg = 'Missing Employee!'
			GOTO vspExit
		END

	IF @PREndDate IS NULL
		BEGIN
			SET @Return_Value = 1
			SET @ErrorMsg = 'Missing Payroll Ending Date!'
			GOTO vspExit
		END

	---------------------------------------
	-- CALL vspPR_AU_ETP_TaxComputations --
	---------------------------------------
	EXEC	@Return_Value = [dbo].[vspPR_AU_ETP_TaxComputations]
			@PRCo,
			@Employee,
			@PREndDate,
			@ATOETPType = 'ETP',
			@SubjectAmt = @SubjectAmt,
			@TotalAmtWithheld = @TaxAmount OUTPUT,
			@ETPTaxableAmt = @EligibleAmt OUTPUT,	-- 50738 --
			@ErrorMsg = @ErrorMsg OUTPUT

END TRY

--------------------
-- ERROR HANDLING --
--------------------
BEGIN CATCH
	SET @Return_Value = 1
	SET @ErrorMsg = ERROR_PROCEDURE() + ': ' + ERROR_MESSAGE()	
END CATCH

------------------
-- EXIT ROUTINE --
------------------
vspExit:
	RETURN @Return_Value


GO
GRANT EXECUTE ON  [dbo].[vspPR_AU_Standard] TO [public]
GO
