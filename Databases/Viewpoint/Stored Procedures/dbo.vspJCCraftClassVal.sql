SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCraftClassVal    Script Date: 8/28/99 9:33:15 AM ******/
CREATE  proc [dbo].[vspJCCraftClassVal]
/************************************************************************************************
* CREATED BY:		CHS 03/24/2009
* MODIFIED By : 
*
* USAGE:
* validates PR Craft/Class combination from PRCC
* an error is returned if any of the following occurs
*
* INPUT PARAMETERS
*   @prco   PR Co to validate against
*   @craft  PR Craft to validate against
*   @class  PR Class to validate against
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
*   @desc     Description of Ded/Earnings/Liab Code
* RETURN VALUE
*   0         success
*   1         Failure
************************************************************************************************/ 

(@prco bCompany = 0, 
	@craft bCraft = null, 
	@class bClass = null, 
	@desc varchar(60) = null output, 
	@msg varchar(90) output)

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
   
   select @msg=Description, @desc=Description from PRCC where PRCo=@prco and Craft=@craft and Class=@class
   if @@rowcount = 0
   	begin
   	select @msg = 'Craft/Class combination not on file!', @rcode = 1 	goto bspexit
   	end
   
   bspexit:
   	
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCraftClassVal] TO [public]
GO
