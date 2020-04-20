SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspPRAUEmployerMasterTaxYearVal]
/************************************************************
* CREATED BY: 	 EN	04/08/2011
* MODIFIED By :		
*								
*								
*
* USAGE:
* Validate Tax Year entered for PRAATOEFileGenerate.  Must be a valid Tax Year in PRAUEmployerMaster.
*
* INPUT PARAMETERS
*   @PRCo       PR Co
*   @TaxYear    Year to validate
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
************************************************************/
(@PRCo bCompany, 
 @TaxYear VARCHAR(4),
 @msg VARCHAR(255) OUTPUT)

AS
SET NOCOUNT ON

DECLARE @rcode INT

SELECT @rcode = 0

IF @TaxYear IS NULL
BEGIN
	SELECT @msg = 'Missing Company number!'
	RETURN 1
END

IF @PRCo IS NULL
BEGIN
	SELECT @msg = 'Missing PR Company!'
	RETURN 1
END

IF NOT EXISTS (SELECT * FROM PRAUEmployerMaster WHERE PRCo = @PRCo and TaxYear = @TaxYear)
BEGIN
	SELECT @msg = 'Tax Year is not set up in ATO Processing!'
	RETURN 1
END
   
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspPRAUEmployerMasterTaxYearVal] TO [public]
GO
