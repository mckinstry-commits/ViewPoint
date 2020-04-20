SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPayPdControlAFCheck    Script Date: 8/28/99 9:33:20 AM ******/
   CREATE  proc [dbo].[bspPRPayPdControlAFCheck]
   /***********************************************************
    * CREATED BY: EN 5/29/2009
    * MODIFIED By : 
    *
    * USAGE:
    * Called by PR Pay Pd Control form.  
	* Checks bPRAF to determine if active freqs are set up for a PR Ending Date.
	* Returns Y/N value @displayfreqwarning ... returns 'Y' if no freqs found, else 'N'.
    *
    * INPUT PARAMETERS
    *   @prco	PR Co to validate against 
    *   @prgroup	PR Group to use in validation
    *   @enddate	PR Ending Date
    *		
    * OUTPUT PARAMETERS
    *   @displayfreqwarning	if error occurs, value default is 'N' if PREndDate does not exist in bPRPC
	*	@msg	null
    *
    * RETURN VALUE
    *   0		success
    *   1          Failure
    *****************************************************/ 
   
   (@prco bCompany, @prgroup bGroup, @enddate bDate, @displayfreqwarning bYN output, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int, @status tinyint
   
   select @rcode = 0
   
   select @displayfreqwarning = 'Y'

   --frequency warning is not needed if Pay Period does not exist in bPRPC so set it to 'N'
   if not exists(select * from PRPC where PRCo=@prco and PRGroup=@prgroup and PREndDate=@enddate)
		select @displayfreqwarning = 'N'

   --no frequency warning if active frequencies exist in bPRAF
   if exists(select * from PRAF where PRCo=@prco and PRGroup=@prgroup and PREndDate=@enddate)
		select @displayfreqwarning = 'N'
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPayPdControlAFCheck] TO [public]
GO
