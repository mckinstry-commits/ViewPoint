SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRAUPAYGItemSetup    Script Date: 8/28/99 9:33:18 AM ******/
CREATE  PROC [dbo].[vspPRAUPAYGItemSetup]
/***********************************************************/
-- CREATED BY: LS 2/17/2011
-- MODIFIED BY: 
--
-- USAGE:
-- Gathers the PAYG Setup information for the ATO Items, Superannuation Extra Items, and
-- the Miscellaneous Items.  It initializes the PAYG Setup by using the ATO Category 
-- assigned to each EDL Code. 
--
-- INPUT PARAMETERS
--   @PRCo		PR Company
--   @TaxYear	Tax Year
--
-- OUTPUT PARAMETERS
--   @Message	Error message if error occurs	
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
-- TEST HARNESS
--
-- DECLARE	@ReturnCode int,
--			@Message varchar(60)

-- EXEC		@ReturnCode = [dbo].[vspPRAUPAYGItemSetup]
--			@PRCo = 204,
--			@TaxYear = '2010',
--			@Message = @Message OUTPUT

-- SELECT	@ReturnCode as 'Return Code', @Message as '@Messag
--
/******************************************************************/
(
@PRCo bCompany = null,
@TaxYear char(4) = null, 
@Message varchar(4000) output
)
AS
BEGIN
	SET NOCOUNT ON

	-- Check Parameters
	IF @PRCo IS NULL
	BEGIN
		SELECT @Message = 'Missing PR Company!'
		RETURN 1
	END

	IF @TaxYear IS NULL
	BEGIN
		SELECT @Message = 'Missing Tax Year!'
		RETURN 1
	END

	BEGIN TRY
		BEGIN TRAN
		-- Clear Current PAYG Setup
		DELETE FROM dbo.vPRAUEmployerATOItems WHERE PRCo = @PRCo AND TaxYear = @TaxYear
		DELETE FROM dbo.vPRAUEmployerSuperItems WHERE PRCo = @PRCo AND TaxYear = @TaxYear
		DELETE FROM dbo.vPRAUEmployerMiscItems WHERE PRCo = @PRCo AND TaxYear = @TaxYear

		-- Setup ATO Items (both Earnings, and Deductions / Liabilities)
		INSERT INTO dbo.vPRAUEmployerATOItems (PRCo, TaxYear, ItemCode, EDLType, EDLCode)
		SELECT dl.PRCo, @TaxYear AS TaxYear, i.ItemCode, dl.DLType AS EDLType, dl.DLCode AS EDLCode FROM dbo.bPRDL dl
			JOIN dbo.vPRAUItemsATOCategories a ON a.ATOCategory = dl.ATOCategory
			JOIN dbo.vPRAUItems i ON i.ItemCode = a.ItemCode
			WHERE @TaxYear BETWEEN i.BeginTaxYear AND ISNULL(i.EndTaxYear, @TaxYear) 
				AND i.Tab = 'ATO'
				AND dl.PRCo = @PRCo
		UNION
		SELECT e.PRCo, @TaxYear AS TaxYear, i.ItemCode, 'E' AS EDLType, e.EarnCode AS EDLCode FROM dbo.bPREC e
			JOIN dbo.vPRAUItemsATOCategories a ON a.ATOCategory = e.ATOCategory
			JOIN dbo.vPRAUItems i ON i.ItemCode = a.ItemCode
			WHERE @TaxYear BETWEEN i.BeginTaxYear AND ISNULL(i.EndTaxYear, @TaxYear) 
				AND i.Tab = 'ATO'
				AND e.PRCo = @PRCo
				
		-- Setup Superannuation Items (only DL Types)
		INSERT INTO dbo.vPRAUEmployerSuperItems (PRCo, TaxYear, ItemCode, DLType, DLCode)
		SELECT dl.PRCo, @TaxYear, i.ItemCode, dl.DLType, dl.DLCode FROM dbo.bPRDL dl
			JOIN dbo.vPRAUItemsATOCategories a ON a.ATOCategory = dl.ATOCategory
			JOIN dbo.vPRAUItems i ON i.ItemCode = a.ItemCode
			WHERE @TaxYear BETWEEN i.BeginTaxYear AND ISNULL(i.EndTaxYear, @TaxYear) 
				AND i.Tab = 'Super'
				AND dl.PRCo = @PRCo

		-- Setup Miscellaneous Items (both Earnings, and Deductions / Liabilities)
		INSERT INTO dbo.vPRAUEmployerMiscItems (PRCo, TaxYear, ItemCode, EDLType, EDLCode)
		SELECT dl.PRCo, @TaxYear AS TaxYear, i.ItemCode, dl.DLType AS EDLType, dl.DLCode AS EDLCode FROM dbo.bPRDL dl
			JOIN dbo.vPRAUItemsATOCategories a ON a.ATOCategory = dl.ATOCategory
			JOIN dbo.vPRAUItems i ON i.ItemCode = a.ItemCode
			WHERE @TaxYear BETWEEN i.BeginTaxYear AND ISNULL(i.EndTaxYear, @TaxYear) 
				AND i.Tab = 'Misc'
				AND dl.PRCo = @PRCo
		UNION
		SELECT e.PRCo, @TaxYear AS TaxYear, i.ItemCode, 'E' AS EDLType, e.EarnCode AS EDLCode FROM dbo.bPREC e
			JOIN dbo.vPRAUItemsATOCategories a ON a.ATOCategory = e.ATOCategory
			JOIN dbo.vPRAUItems i ON i.ItemCode = a.ItemCode
			WHERE @TaxYear BETWEEN i.BeginTaxYear AND ISNULL(i.EndTaxYear, @TaxYear) 
				AND i.Tab = 'Misc'
				AND e.PRCo = @PRCo

		-- Success, Commit the changes
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		-- Rollback Transaction, if error is caught
		SET @Message = ERROR_MESSAGE()
		IF @@TRANCOUNT > 0 BEGIN ROLLBACK TRAN END
		RAISERROR (@Message, 15, 1)
	END CATCH

END


GO
GRANT EXECUTE ON  [dbo].[vspPRAUPAYGItemSetup] TO [public]
GO
