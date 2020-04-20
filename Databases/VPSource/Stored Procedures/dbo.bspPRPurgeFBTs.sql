SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[bspPRPurgeFBTs]
/***********************************************************
* CREATED BY:	CHS	#142027
* Modified: 
*			
* USAGE:
* Purges FBT Header, FBT Info, & FBT Amounts for a given tax year and Company from the 
* tables vPRAUEmployerFBT, vPRAUEmployerFBTItems, & vPRAUEmployerFBTCodes
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
	SELECT @rcode = 1, @Msg = 'Purge of Fringe Benefit Tax data unsuccessful.' 

	DELETE FROM vPRAUEmployerFBTCodes WHERE PRCo=@PRCo and TaxYear = @TaxYear
	
	DELETE FROM vPRAUEmployerFBTItems WHERE PRCo=@PRCo and TaxYear = @TaxYear
	
	DELETE FROM vPRAUEmployerFBT WHERE PRCo=@PRCo and TaxYear = @TaxYear
		
   	SELECT @rcode = 0, @Msg =  'Successfully purged Fringe Benefit Tax data for Company  ' + CAST(@PRCo as VARCHAR(60)) + ' and Tax Year  ' + @TaxYear + '. '
   
	bspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPurgeFBTs] TO [public]
GO
