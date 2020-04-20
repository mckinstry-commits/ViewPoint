SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRAUPAYGPurgeTaxYearVal    Script Date: 8/28/99 9:35:43 AM ******/
CREATE  procedure [dbo].[vspPRAUPAYGPurgeTaxYearVal]
/************************************************************
* CREATED BY: 	 CHS 04/7/2011 
* MODIFIED By:
*								
*								
*
* USAGE:
* If validate that year
* entered is a valid year and that it exists in vPRAUEmployer
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
*GRANT EXECUTE ON vspPRAUPAYGPurgeTaxYearVal TO public;
************************************************************/
@PRCo bCompany, @TaxYear VARCHAR(4), @errmsg VARCHAR(255) OUTPUT
   AS
   SET NOCOUNT ON
   
   DECLARE @rcode INT
   
   SELECT @rcode = 0
   
   /* Verify that year has 4 digits and is numeric */
   IF NOT (@TaxYear >= '1000' and @TaxYear <= '9999')
   	BEGIN
   	SELECT @errmsg = 'Invalid year.', @rcode = 1
   	GOTO bspexit
   	END
   
   IF NOT EXISTS 
		(
			SELECT 1 FROM dbo.PRAUEmployer
			WHERE PRCo=@PRCo
		)
	BEGIN
		SELECT @errmsg = 'No detail exists for this tax year.', @rcode = 1
   		GOTO bspexit
	END
   
   
   
   bspexit:
   	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRAUPAYGPurgeTaxYearVal] TO [public]
GO
