SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPRDeptVal]
   /***********************************************************
    * CREATED BY: EN 10/5/07 created based on bspPRDeptVal for issue 121327 to return YN flag indicating
	*						 if dept code is in use in bPRTH
    * MODIFIED By : 
    *
    * USAGE:
    * validates PR Department PRDP
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   PRCo   PR Co to validate agains 
    *   Dept   PR Department to validate
    * OUTPUT PARAMETERS
	*	@deptinprth	equals Y if there are any entries in PRTH containing this department
    *   @msg      error message if error occurs otherwise Description of Department
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @dept bDept = null, @deptinprth bYN output, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @deptinprth = 'N'
   
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
   
	--issue 121327 check PRTH for existence of dept code
	if (select count(*) from bPRTH (nolock) where PRCo = @prco and PRDept = @dept) > 0
		select @deptinprth = 'Y'


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRDeptVal] TO [public]
GO
