SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRRoutineVal    Script Date: 8/28/99 9:33:35 AM ******/
   CREATE  proc [dbo].[bspPRRoutineVal]
   /***********************************************************
    * CREATED BY: kb 11/25/97
    * MODIFIED By : kb 11/25/97
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR Routine PRRM
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   PRCo    PR Co to validate agains 
    *   Routine PR Routine to validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Routine
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @routine varchar(10) = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @routine is null
   	begin
   	select @msg = 'Missing PR Routine!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from PRRM
   	where PRCo = @prco and Routine=@routine
    
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Routine not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRoutineVal] TO [public]
GO
