SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRAUItemVal    Script Date: 8/28/99 9:33:18 AM ******/
create  PROC [dbo].[vspPRAUItemVal]
/***********************************************************/
-- CREATED BY: EN 1/10/2011
-- MODIFIED BY: 
--
-- USAGE:
-- Validates Australia PAYG Item Code against data in vPRAUItems which is a 
-- maintained by Viewpoint behind-the-scenes.  Table vPRAUItems dictates the 
-- available Items, the tab they are to be used on, and the order in which they
-- will appear in the PRAustraliaPAYG grid tabs and F4 lookups.  
-- This procedure determines if the Item Code is being used on the correct tab
-- and returns the Item Code Description if the Item Code is found to be valid.
--
-- INPUT PARAMETERS
--   @TaxYear	Tax Year
--   @Tab		Can be 'ATO', 'Super', or 'Misc'
--   @ItemCode	Code to validate
--
-- OUTPUT PARAMETERS
--   @Message	Error message if error occurs otherwise returns Item Description from vPRAUItems
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
-- TEST HARNESS
--
--	DECLARE	@ReturnCode int,
--			@Message varchar(60)
--
--	EXEC	@ReturnCode = [dbo].[vspPRAUItemVal]
--			@TaxYear = 2010,
--			@Tab = 'ATO',
--			@ItemCode = 'EF',
--			@Message = @Message OUTPUT
--
--	SELECT	@ReturnCode as 'Return Code', @Message as '@Message'
--
/******************************************************************/
(
@TaxYear char(4) = null,
@Tab char(5) = null, 
@ItemCode char(4) = null,
@Message varchar(60) output
)

AS
SET NOCOUNT ON

IF @TaxYear IS NULL
BEGIN
	SELECT @Message = 'Missing Tax Year!'
	RETURN 1
END

IF @Tab IS NULL
BEGIN
	SELECT @Message = 'Missing Tab Code!'
	RETURN 1
END

IF @ItemCode IS NULL
BEGIN
	SELECT @Message = 'Missing Item Code!'
	RETURN 1
END

--need to also check tax year range
SELECT @Message = ItemDescription 
FROM dbo.PRAUItems 
WHERE ItemCode = @ItemCode  
	  AND Tab = @Tab 
	  AND @TaxYear BETWEEN BeginTaxYear AND ISNULL(EndTaxYear, @TaxYear)

IF @@ROWCOUNT = 0
BEGIN
	SELECT @Message = 'Item is either invalid for this tab or for this tax year!'
	RETURN 1
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspPRAUItemVal] TO [public]
GO
