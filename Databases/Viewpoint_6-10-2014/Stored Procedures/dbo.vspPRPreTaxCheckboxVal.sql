SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREarnDedLiabVal    Script Date: 8/28/99 9:33:18 AM ******/
CREATE  proc [dbo].[vspPRPreTaxCheckboxVal]
/***********************************************************/
-- CREATED BY:	EN	06/10/2013	- User Story 52440/Task 52442
-- MODIFIED By:	
--
-- USAGE:
-- Validation to ensure that Pre-Tax checkbox in PR Deductions/Liabilities
-- can not be unchecked for a deduction while it is actively set as a pre-tax
-- deduction for another deduction.
--
-- INPUT PARAMETERS
--   @PRCo   	PR Company
--	 @PreTaxYN	bYN
--   @DednCode 	Dedn code to validate
--
-- OUTPUT PARAMETERS
--   @ErrorMsg	error message IF error occurs
--
-- RETURN VALUE
--   0         success
--   1         Failure
--
-- TEST HARNESS
--
-- DECLARE	@ReturnCode int,
--			@ErrorMsg varchar(60)

-- EXEC		@ReturnCode = [dbo].[vspPRPreTaxCheckboxVal]
--			@PRCo = 1,
--			@PreTaxYN = 'N',
--			@DednCode = 3030,
--			@ErrorMsg = @ErrorMsg OUTPUT

-- SELECT	@ReturnCode as 'Return Code', @ErrorMsg as 'Error Message'
--
/******************************************************************/
(
 @PRCo bCompany = 0, 
 @PreTaxYN bYN = NULL,
 @DednCode bEDLCode = NULL, 
 @ErrorMsg varchar(255) OUTPUT
)
   	
AS

BEGIN TRY
	SET NOCOUNT ON

	DECLARE @Return_Value tinyint

	SELECT @Return_Value = 0

	------------------------------------
	-- CHECK PreTaxYN INPUT PARAMETER --
	------------------------------------
	IF @PreTaxYN IS NULL
	BEGIN
		SELECT @ErrorMsg = 'Pre-Tax checkbox value must be specified!', @Return_Value = 1
		GOTO vspExit
	END

	IF @PreTaxYN = 'N'
	BEGIN
		--------------------------------------
		-- CHECK REMAINING INPUT PARAMETERS --
		--------------------------------------
		IF ISNULL(@PRCo, 0) = 0
		BEGIN
			SELECT @ErrorMsg = 'Missing PR Company!', @Return_Value = 1
			GOTO vspExit
		END

		IF ISNULL(@DednCode, 0) = 0
		BEGIN
			SELECT @ErrorMsg = 'Missing PR Deduction Code!', @Return_Value = 1
			GOTO vspExit
		END

		---------------------------------------------------------
		-- CHECK FOR THE DEDN CODE AS A PRE-TAX IN BASIS CODES --
		---------------------------------------------------------
		IF EXISTS (SELECT	TOP 1 1 
				   FROM		dbo.bPRDB
				   WHERE	PRCo = @PRCo AND
							EDLType = 'D' AND
							EDLCode = @DednCode)
		BEGIN
			SELECT @ErrorMsg = 'Code is in use as a Pre-Tax deduction basis code.', @Return_Value = 1
			GOTO vspExit
		END
	END

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
GRANT EXECUTE ON  [dbo].[vspPRPreTaxCheckboxVal] TO [public]
GO
