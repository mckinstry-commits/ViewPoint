SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRStateVal    Script Date: 8/28/99 9:33:35 AM ******/
   CREATE  proc [dbo].[bspPRStateVal]
   /***********************************************************
    * CREATED BY: kb 11/17/97
    * MODIFIED By : kb 11/17/97
    *				EN 10/9/02 - issue 18877 change double quotes to single
	*				EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
    *
    * USAGE:
    * validates PR State from PRSI
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   PRCo   PR Co to validate agains 
    *   State  PR State to validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of EarnCode
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @state varchar(4) = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @state is null
   	begin
   	select @msg = 'Missing PR State!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = State
   	from PRSI
   	where PRCo = @prco and State= @state 
   if @@rowcount = 0
   	begin
   	select @msg = 'PR State not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRStateVal] TO [public]
GO
