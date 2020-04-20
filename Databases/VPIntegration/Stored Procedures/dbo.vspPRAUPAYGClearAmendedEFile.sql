SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspPRAUPAYGClearAmendedEFile]
/********************************************************/
-- CREATED BY: 	EN 4/20/2011
-- MODIFIED BY:  
--
-- USAGE:
--	Set the AmendedEFile (Y/N) flag in vPRAUEmployees to 'N'
--	for all employees for the specified PRCo/TaxYear.
--
-- INPUT PARAMETERS:
--	@PRCo		PR Company
--	@TaxYear	Tax Year to affect in vPRAUEmployees
--
-- OUTPUT PARAMETERS:
--	@Message	error message if failure, message specifying # of records cleared if success
--
-- RETURN VALUE:
-- 	0 	    success
--	1 		failure
--
-- TEST HARNESS
--
-- DECLARE	@ReturnCode int,
--			@Message varchar(60)

-- EXEC		@ReturnCode = [dbo].[vspPRAUPAYGClearAmendedEFile]
--			@PRCo = 204,
--			@TaxYear = '2010',
--			@Message = @Message OUTPUT

-- SELECT	@ReturnCode as 'Return Code', @Message as '@Messag
--
/**********************************************************/
(
@PRCo bCompany, 
@TaxYear char(4), 
@Message VARCHAR(4000) = NULL OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON

	-- Check Parameters
	IF @PRCo IS NULL
	BEGIN
		SET @Message = 'Missing PR Company!'
		RETURN 1
	END

	IF @TaxYear IS NULL
	BEGIN
		SET @Message = 'Missing Tax Year!'
		RETURN 1
	END

	BEGIN TRY
		UPDATE dbo.PRAUEmployees
		SET AmendedEFile = 'N'
		WHERE PRCo = @PRCo AND TaxYear = @TaxYear AND AmendedEFile = 'Y'

		SELECT @Message = 'Cleared ' + CONVERT(varchar,@@ROWCOUNT) + ' checkboxes.'
	END TRY
	BEGIN CATCH
		-- Rollback Transaction, if error is caught
		SET @Message = ERROR_MESSAGE()
		RAISERROR (@Message, 15, 1)
		RETURN 1
	END CATCH

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspPRAUPAYGClearAmendedEFile] TO [public]
GO
