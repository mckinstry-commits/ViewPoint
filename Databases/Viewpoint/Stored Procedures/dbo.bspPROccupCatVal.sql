SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPROccupCatVal    Script Date: 8/28/99 9:33:32 AM ******/
   CREATE  proc [dbo].[bspPROccupCatVal]
   /***********************************************************
    * CREATED BY: kb 11/24/97
    * MODIFIED By : kb 11/24/97
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR Occupational Category PROC
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   @prco      PR Co to validate against
    *   @occupcat  PR Occupational Category to validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of EarnCode
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @occupcat varchar(10) = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @occupcat is null
   	begin
   	select @msg = 'Missing PR Occupational Category!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from PROP
   	where PRCo = @prco and OccupCat=@occupcat 
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Occupational Category not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPROccupCatVal] TO [public]
GO
