SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[vspAPAUATOPayerTaxYearVal]
/************************************************************
* CREATED BY:	GF 03/18/2013 AP ATO Processing Enhancement
* MODIFIED By:		
*								
*								
*
* USAGE:
* Validate Tax Year entered for APAUATOEFileGenerate.  Must be a valid Tax Year in APAUPayerTaxPaymentATO.
*
* INPUT PARAMETERS
* @APCo       AP Co
* @TaxYear    Year to validate
*
* OUTPUT PARAMETERS
* @AmendedDate Tax Year last amended date for default
* @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
************************************************************/
(@APCo bCompany = NULL, 
 @TaxYear SMALLINT = NULL,
 @AmendedDate bDate = NULL OUTPUT,
 @msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT

SELECT @rcode = 0

IF @TaxYear IS NULL
	BEGIN
	SET @msg = 'Missing Tax Year!'
	RETURN 1
	END

IF @APCo IS NULL
	BEGIN
	SET @msg = 'Missing AP Company!'
	RETURN 1
	END

IF NOT EXISTS (SELECT 1 FROM dbo.APAUPayerTaxPaymentATO WHERE APCo = @APCo and TaxYear = @TaxYear)
	BEGIN
	SET @msg = 'Tax Year is not set up in ATO Processing!'
	RETURN 1
	END
   
---- get last amended date if there is one
SELECT @AmendedDate = MAX(AmendedDate)
FROM dbo.APAUPayeeTaxPaymentATO
WHERE APCo = @APCo
	AND TaxYear = @TaxYear


RETURN 0


GO
GRANT EXECUTE ON  [dbo].[vspAPAUATOPayerTaxYearVal] TO [public]
GO
