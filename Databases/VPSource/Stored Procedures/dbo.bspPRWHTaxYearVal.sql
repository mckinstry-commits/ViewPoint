SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRWHTaxYearVal    Script Date: 8/28/99 9:35:43 AM ******/
   CREATE  procedure [dbo].[bspPRWHTaxYearVal]
   /************************************************************
    * CREATED BY: 	 EN 11/22/98
    * MODIFIED By : EN 11/22/98
    *					EN 10/9/02 - issue 18877 change double quotes to single
	*				mh 10/26/06 - We were passing in an empty string to tell the proc to 
	*								just validate the TaxYear.  6.x code will not allow us
	*								to pass in an empty string as a parameter.  Changed to "X"
    *
    * USAGE:
    * If option to initialize W2 run is being used, validate that year
    * entered is not already set up in PRWH for the company, or ...
    * If option to re-create W2 run is being used or no option is selected,
    * validate that year entered is set up in PRWH for the company, or ...
    * If no option is selected, just validate the year.
    *
    * INPUT PARAMETERS
    *   @PRCo       PR Co
    *   @Opt	 'I' to Initialize W2 run, 'R' to Re-create, 'X' to just validate year
    *   @TaxYear    Year to validate
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    ************************************************************/
   	@PRCo bCompany, @Opt char(1), @TaxYear varchar(4), @errmsg varchar(255) output
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   /* Verify that year has 4 digits and is numeric */
   if not (@TaxYear >= '1000' and @TaxYear <= '9999')
   	begin
   	select @errmsg = 'Invalid year.', @rcode = 1
   	goto bspexit
   	end
   
   /* if initializing W2 run, year must not be set up in PRWH */
   if @Opt = 'I'
   	if exists(select * from bPRWH where PRCo = @PRCo and TaxYear = @TaxYear)
   	 	begin
   	 	select @errmsg = 'Year has already been initialized.', @rcode = 1
   	 	goto bspexit
   	 	end
   	
   /* if re-creating W2 run, year must be set up in PRWH */
   if @Opt = 'R'
   	if not exists(select * from bPRWH where PRCo = @PRCo and TaxYear = @TaxYear)
   	 	begin
   	 	select @errmsg = 'Year has not been previously initialized.', @rcode = 1
   	 	goto bspexit
   	 	end
   	
   /* just validate that year is set up in PRWH */
   if @Opt = 'X'
   	if not exists(select * from bPRWH where PRCo = @PRCo and TaxYear = @TaxYear)
   	 	begin
   	 	select @errmsg = 'Year must first be initialized.', @rcode = 1
   	 	goto bspexit
   	 	end	
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRWHTaxYearVal] TO [public]
GO
