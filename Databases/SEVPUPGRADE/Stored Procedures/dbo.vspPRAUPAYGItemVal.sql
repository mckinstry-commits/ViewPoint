SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRAUPAYGItemVal    Script Date: 8/28/99 9:33:18 AM ******/
CREATE  PROC [dbo].[vspPRAUPAYGItemVal]
/***********************************************************/
-- CREATED BY: EN 5/21/2013
-- MODIFIED BY: 
--
-- USAGE:
-- Validates the Item # to make sure it is valid for the expected tab.
--
-- INPUT PARAMETERS
--   @TaxYear	Tax Year
--	 @ItemCode	ItemCode
--	 @Tab		'ATO' or 'Misc' or 'Super'
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

-- EXEC		@ReturnCode = [dbo].[vspPRAUPAYGItemVal]
--			@TaxYear = '2014',
--			@ItemCode = 1,
--			@Tab = 'ATO',
--			@Message = @Message OUTPUT

-- SELECT	@ReturnCode as 'Return Code', @Message as 'Error Message'
--
/******************************************************************/
(
 @TaxYear char(4) = null,
 @ItemCode char(4) = null,
 @Tab char(5) = null,
 @ErrorMsg varchar(255) output
)

AS

BEGIN TRY

	SET NOCOUNT ON
  
	DECLARE @Return_Value tinyint

	SET @Return_Value = 0
	
	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @TaxYear IS NULL
	BEGIN
		SET @Return_Value = 1
		SET @ErrorMsg = 'Missing Tax Year!'
		GOTO vspExit
	END
	
	IF @ItemCode IS NULL
	BEGIN
		SET @Return_Value = 1
		SET @ErrorMsg = 'Missing Item Code!'
		GOTO vspExit
	END
	
	IF @Tab IS NULL
	BEGIN
		SET @Return_Value = 1
		SET @ErrorMsg = 'Missing Tab Value!'
		GOTO vspExit
	END

	-- determine if item code is valid
	IF NOT EXISTS	(SELECT 1 FROM dbo.vPRAUItems
					 WHERE @TaxYear BETWEEN BeginTaxYear AND ISNULL(EndTaxYear, @TaxYear) AND
						   ItemCode = @ItemCode AND
						   Tab = @Tab)
	BEGIN
		--partial summaries exist but none with this end date ... return error
		SET @Return_Value = 1
		SET @ErrorMsg = 'Invalid Item Code!'
		GOTO vspExit
	END

	--need to also check tax year range
	SELECT @ErrorMsg = ItemDescription 
	FROM dbo.PRAUItems 
	WHERE ItemCode = @ItemCode  
		  AND Tab = @Tab 
		  AND @TaxYear BETWEEN BeginTaxYear AND ISNULL(EndTaxYear, @TaxYear)

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrorMsg = 'Item is either invalid for this tab or for this tax year!'
		RETURN 1
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
GRANT EXECUTE ON  [dbo].[vspPRAUPAYGItemVal] TO [public]
GO
