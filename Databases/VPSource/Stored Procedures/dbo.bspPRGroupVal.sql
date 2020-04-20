SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRGroupVal    Script Date: 11/5/2002 1:20:25 PM ******/
   /****** Object:  Stored Procedure dbo.bspPRGroupVal    Script Date: 8/28/99 9:33:21 AM ******/
   CREATE   proc [dbo].[bspPRGroupVal]
   /***********************************************************
    * CREATED BY: kb 11/22/97
    * MODIFIED By : kb 11/22/97
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR Group from PRGR
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   PRCo   PR Co to validate agains 
    *   Group  PR Group to validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of PR Group
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @group bGroup = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @group is null
   	begin
   	select @msg = 'Missing PR Group!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from PRGR
   	where PRCo = @prco and PRGroup=@group 
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Group not on file!', @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRGroupVal] TO [public]
GO
