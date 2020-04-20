SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCrewVal    Script Date: 8/28/99 9:33:16 AM ******/
   CREATE   proc [dbo].[bspPRCrewVal]
   /***********************************************************
    * CREATED BY: kb 11/22/97
    * MODIFIED By : kb 11/22/97
    *				EN 10/7/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR Crew from PRCR
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   PRCo   PR Co to validate agains 
    *   Crew   PR Crew to validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Crew
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @crew varchar(10) = null, @msg varchar(60) output)
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
   
   select @msg = Description
   	from PRCR with (nolock)
   	where PRCo = @prco and Crew=@crew 
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Crew not on file!', @rcode = 1
   	goto bspexit
   	end

   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCrewVal] TO [public]
GO
