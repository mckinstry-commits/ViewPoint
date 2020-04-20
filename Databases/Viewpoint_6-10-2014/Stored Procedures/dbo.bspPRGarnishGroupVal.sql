SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRGarnishGroupVal    Script Date: 8/28/99 9:33:21 AM ******/
   CREATE  proc [dbo].[bspPRGarnishGroupVal]
   /***********************************************************
    * CREATED BY: kb 11/25/97
    * MODIFIED By : kb 11/25/97
    *				EN 10/8/02 - issue 18877 change double quotes to single
	*				EN 12/14/07 - #120867 return @codeinuse flag
    *
    * USAGE:
    * validates PR Garnishment Group from PRGG
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   @prco   PR Co to validate against
    *   @group PR Group to validate
	*	@codeinuse	=Y if Garn Group code is in use in bPRDL or bPREH
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of PR Garnishment Group
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @group bGroup = null, @codeinuse bYN output, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @codeinuse = 'N'
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @group is null
   	begin
   	select @msg = 'Missing PR Garnish Group!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from PRGG
   	where PRCo = @prco and GarnGroup=@group 
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Garnish Group not on file!', @rcode = 1
   	goto bspexit
   	end
   
	--check for garnishment group in use in bPRDL or bPREH
	--check bPRDL
	if exists(select GarnGroup from dbo.bPRDL (nolock) where PRCo = @prco and GarnGroup = @group)
	begin
		select @codeinuse = 'Y'
		goto bspexit
	end
	--check bPREH
	if exists(select CSGarnGroup from dbo.bPREH (nolock) where PRCo = @prco and CSGarnGroup = @group)
	begin
		select @codeinuse = 'Y'
		goto bspexit
	end		

   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRGarnishGroupVal] TO [public]
GO
