SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRLocalVal    Script Date: 8/28/99 9:33:26 AM ******/
   CREATE  proc [dbo].[bspPRLocalVal]
   /***********************************************************
    * CREATED BY: kb 11/17/97
    * MODIFIED By : kb 11/17/97
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR Localfrom PRLI
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   PRCo   PR Co to validate agains 
    *   Local  PR Local to validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of EarnCode
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @local bLocalCode = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @local is null
   	begin
   	select @msg = 'Missing PR Local!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from PRLI
   	where PRCo = @prco and LocalCode=@local 
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Local not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRLocalVal] TO [public]
GO
