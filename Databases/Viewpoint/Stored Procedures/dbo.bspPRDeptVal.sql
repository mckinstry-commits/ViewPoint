SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRDeptVal    Script Date: 8/28/99 9:33:17 AM ******/
   CREATE  proc [dbo].[bspPRDeptVal]
   /***********************************************************
    * CREATED BY: kb 11/18/97
    * MODIFIED By : kb 11/18/97
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR Department PRDP
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   PRCo   PR Co to validate agains 
    *   Dept   PR Department to validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Department
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @dept bDept = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @dept is null
   	begin
   	select @msg = 'Missing PR Department!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from PRDP
   	where PRCo = @prco and PRDept=@dept 
   if @@rowcount = 0 	begin
   	select @msg = 'PR Department not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDeptVal] TO [public]
GO
