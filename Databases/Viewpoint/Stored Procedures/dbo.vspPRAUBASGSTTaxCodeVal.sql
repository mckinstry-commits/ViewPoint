SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROC [dbo].[vspPRAUBASGSTTaxCodeVal]
/***********************************************************/
-- CREATED BY: MV 03/09/11 #138181
-- MODIFIED BY: 
--
-- USAGE:
-- Validates Tax Codes entered for AU BAS GST Items. Tax Code must be checked for "GST".
-- Returns tax code description.
-- Called from PRAUBASProcessGSTTaxCodes. 
--
-- INPUT PARAMETERS
--   @TaxGroup	Tax Group
--	 @TaxCode	Tax Code
--
-- OUTPUT PARAMETERS
--   @Message	Error message if error occurs otherwise returns  Description from bHQTX
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
--
/******************************************************************/
(
@TaxGroup bGroup, @TaxCode bTaxCode, @Message varchar(60) output
)

AS
SET NOCOUNT ON

IF @TaxGroup IS NULL
BEGIN
	SELECT @Message = 'Missing Tax Group!'
	RETURN 1
END

IF @TaxCode IS NULL
BEGIN
	SELECT @Message = 'Missing Tax Code!'
	RETURN 1
END


SELECT @Message = Description 
FROM dbo.bHQTX
WHERE TaxGroup=@TaxGroup AND TaxCode=@TaxCode AND GST='Y'  
IF @@ROWCOUNT = 0
BEGIN
	SELECT @Message = 'Tax Code is not valid for GST Items!'
	RETURN 1
END

RETURN 0



GO
GRANT EXECUTE ON  [dbo].[vspPRAUBASGSTTaxCodeVal] TO [public]
GO
