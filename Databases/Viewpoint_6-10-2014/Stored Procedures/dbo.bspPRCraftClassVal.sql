SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCraftClassVal    Script Date: 8/28/99 9:33:15 AM ******/
   CREATE  proc [dbo].[bspPRCraftClassVal]
   /************************************************************************************************
    * CREATED BY: kb 11/21/97
    * MODIFIED By : kb 11/21/97
    *				EN 10/7/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR Craft/Class combination from PRCC
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   @prco   PR Co to validate agains t
    *   @craft  PR Craft to validate against
    *   @class  PR Class to validate against
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ************************************************************************************************/ 
   
   	(@prco bCompany = 0, @craft bCraft = null, @class bClass = null, @msg varchar(90) output)
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
   
   if @class is null
   	begin
   	select @msg = 'Missing PR Class!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg=Description from PRCC where PRCo=@prco and Craft=@craft and Class=@class
   if @@rowcount = 0
   	begin
   	select @msg = 'Craft/Class combination not on file!', @rcode = 1 	goto bspexit
   	end
   
   bspexit:
   	
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCraftClassVal] TO [public]
GO
