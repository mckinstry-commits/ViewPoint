SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[vspAPTaxableTaxYearVal]
/****************************************************************************
* CREATED BY:	GF 03/12/2013 TFS-00000 AP Taxable Payment Reporting Enhancement
* MODIFIED BY:
*
*
* USAGE:
* Validates the Tax Year from the AP Taxable Payment Reporting form and returns 
* ATO tax year information if set up in AP Payer/Payee ATO tables.
*
*
* INPUT PARAMETERS:
* @APCo					AP Company
* @TaxYear				AP Reporting Tax Year
*
*
* OUTPUT PARAMETERS:
* @TaxYearClosed			Tax Year Closed Flag
*
*
*
* RETURN VALUE:
* 	0 	    Success		no error returned to form, always 0
*
*****************************************************************************/
(@APCo bCompany = NULL
 ,@TaxYear SMALLINT = NULL
 ,@TaxYearClosed VARCHAR(1) = 'N' OUTPUT
 ,@Msg VARCHAR(255) OUTPUT
 )
AS
SET NOCOUNT ON

DECLARE @rcode INT

SET @rcode = 0
SET @TaxYearClosed = 'N'

---- check if tax year is closed
IF EXISTS(SELECT 1 FROM dbo.vAPAUPayerTaxPaymentATO WHERE APCo = @APCo AND TaxYear = @TaxYear
					AND TaxYearClosed = 'Y')
	BEGIN
	SET @TaxYearClosed = 'Y'
	END







vspexit:
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspAPTaxableTaxYearVal] TO [public]
GO
