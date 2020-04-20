SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCraftVal    Script Date: 8/28/99 9:33:15 AM ******/
   CREATE  proc [dbo].[bspPRCraftVal]
   /***********************************************************
    * CREATED BY: kb 11/19/97
    * MODIFIED By : kb 11/19/97
    *				EN 10/7/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR Craft from PRCM
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   PRCo   PR Co to validate agains t
    *   Craft  PR Craft to validate against
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ******************************************************************/ 
   
   	(@prco bCompany = 0, @craft bCraft = null, @msg varchar(90) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @craft is null
   	begin
   	select @msg = 'Missing PR Craft!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg=Description from PRCM where PRCo=@prco and Craft=@craft
   if @@rowcount = 0
   	begin
   	select @msg = 'Craft not on file!', @rcode = 1 	goto bspexit
   	end
   
   bspexit:
   	
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCraftVal] TO [public]
GO
