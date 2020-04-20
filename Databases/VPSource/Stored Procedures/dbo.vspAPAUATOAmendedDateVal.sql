SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[vspAPAUATOAmendedDateVal]
/************************************************************
* CREATED BY:	GF 04/08/2013 AP ATO Processing Enhancement
* MODIFIED By:		
*								
*								
*
* USAGE:
* Validate Amended date for the Tax Year entered in APAUATOEFileGenerate.
* There must be at least one creditor/payee with the amended date.
*
* INPUT PARAMETERS
* @APCo			AP Co
* @TaxYear		Year to validate
* @AmendedDate	AmendedDate
*
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
************************************************************/
(@APCo bCompany = NULL, 
 @TaxYear SMALLINT = NULL,
 @AmendedDate bDate = NULL,
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

IF @AmendedDate IS NULL
	BEGIN
	SET @msg = 'Missing Amended Date!'
	RETURN 1
	END


IF NOT EXISTS (SELECT 1 FROM dbo.APAUPayeeTaxPaymentATO WHERE APCo = @APCo
					AND TaxYear = @TaxYear
					AND AmendedDate = @AmendedDate)
	BEGIN
	SET @msg = 'No creditors have the amended date assigned!'
	RETURN 1
	END
   

RETURN 0


GO
GRANT EXECUTE ON  [dbo].[vspAPAUATOAmendedDateVal] TO [public]
GO
