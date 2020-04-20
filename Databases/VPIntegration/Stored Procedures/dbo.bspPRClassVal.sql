SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPRClassVal]
   /************************************************************************************************
    * CREATED BY: bc 11/2/99
    * MODIFIED By : EN 10/7/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR Class in PRCC.  Not to be used in leu of PRCraftClassVal.
    *
    * INPUT PARAMETERS
    *   @prco   PR Co to validate agains t
    *   @class  PR Class to validate against
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ************************************************************************************************/
   
   	(@prco bCompany = 0, @class bClass = null, @msg varchar(90) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @class is null
   	begin
   	select @msg = 'Missing PR Class!', @rcode = 1
   	goto bspexit
   	end
   
   if not exists (select * from PRCC where PRCo=@prco and Class=@class)
   	begin
   	select @msg = 'Class not on file for PR Co ' + convert(varchar(3),@prco), @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRClassVal] TO [public]
GO
