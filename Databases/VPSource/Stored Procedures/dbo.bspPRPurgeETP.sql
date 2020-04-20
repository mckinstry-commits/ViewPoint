SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPurgeETP    Script Date: 8/28/99 9:35:39 AM ******/
CREATE procedure [dbo].[bspPRPurgeETP]
/***********************************************************
* CREATED BY:	CHS	#142027 - 3/31/2011
* Modified: 
*			
* USAGE:
* Purges Header, & ETP Employee Amounts for a given tax year and Company from the 
* tables PRAUEmployeeETPAmounts, & vPRAUEmployerETP
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
*GRANT EXECUTE ON bspPRPurgeETP TO public;
*****************************************************/
(@PRCo bCompany, 
	@TaxYear char(4),
	@Msg varchar(255) output)
	
	AS

	SET NOCOUNT ON

	DECLARE @rcode int
	SELECT @rcode = 1, @Msg = 'Purge of Employment Termination Payment data unsuccessful.'
	
	DELETE FROM PRAUEmployeeETPAmounts WHERE PRCo=@PRCo and TaxYear = @TaxYear
	DELETE FROM PRAUEmployerETP WHERE PRCo=@PRCo and TaxYear = @TaxYear		
   
   	SELECT @rcode = 0, @Msg =  'Successfully purged Employment Termination Payment data for Company ' + CAST(@PRCo as VARCHAR(60)) + ' and Tax Year ' + @TaxYear + '. '
   	
   
	bspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPurgeETP] TO [public]
GO
