SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPurgeW2s    Script Date: 8/28/99 9:35:39 AM ******/
CREATE procedure [dbo].[bspPRPurgeBAS]
/***********************************************************
* CREATED BY:	CHS	#142027 - 3/22/2011
* Modified: 
*			
* USAGE:
* Purges Header Header, BAS Tax Codes, & BAS Amounts for a given tax year and Company from the 
* tables vPRAUEmployerBASAmounts, vPRAUEmployerBASGSTTaxCodes, & vPRAUEmployerBAS
*
* INPUT PARAMETERS
*   @PRCo		PR Company
*   @TaxYear	Tax Year to purge
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*GRANT EXECUTE ON bspPRPurgeFBTs TO public;
*****************************************************/
(@PRCo bCompany, 
	@TaxYear char(4),
	@Msg varchar(255) output)
	
	AS

	SET NOCOUNT ON

	DECLARE @rcode int
	SELECT @rcode = 1, @Msg = 'Purge of Business Activity Statement data unsuccessful.'

	DELETE FROM vPRAUEmployerBASAmounts WHERE PRCo=@PRCo and TaxYear = @TaxYear
	
	DELETE FROM vPRAUEmployerBASGSTTaxCodes WHERE PRCo=@PRCo and TaxYear = @TaxYear
	
	DELETE FROM vPRAUEmployerBAS WHERE PRCo=@PRCo and TaxYear = @TaxYear
   
   	SELECT @rcode = 0, @Msg =  'Successfully purged Business Activity Statement data for Company  ' + CAST(@PRCo as VARCHAR(60)) + ' and Tax Year  ' + @TaxYear + '. '
   
	bspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPurgeBAS] TO [public]
GO
