SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCrewValForTimeCards    Script Date: 8/28/99 9:33:16 AM ******/
   CREATE    proc [dbo].[bspPRCrewValForTimeCards]
   /***********************************************************
    * CREATED BY: EN 3/01/04
    * MODIFIED By :
    *
    * USAGE:
    * validates PR Crew from PRCR returning crew shift value for use in PRTimeCards
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   PRCo   PR Co to validate agains 
    *   Crew   PR Crew to validate
    * OUTPUT PARAMETERS
    *	 @shift	   crew shift
    *   @msg      error message if error occurs otherwise Description of Crew
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @crew varchar(10) = null, @shift tinyint output, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @crew is null
   	begin
   	select @msg = 'Missing PR Crew!', @rcode = 1
   	goto bspexit
   	end
   
   select @shift = Shift, @msg = Description
   	from dbo.PRCR with (nolock)
   	where PRCo = @prco and Crew=@crew 
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Crew not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCrewValForTimeCards] TO [public]
GO
