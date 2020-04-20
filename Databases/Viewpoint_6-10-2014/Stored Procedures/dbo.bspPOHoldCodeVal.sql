SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPOHoldCodeVal]
   /***********************************************************
    * CREATED BY: MV 01/13/03
    * MODIFIED By : 
    *
    * USAGE:
    *  Validates HQ Hold Code in POEntry. Returns an error
    *	if the holdcode is the retainage holdcode in bAPCO.
    *
    * INPUTS:
    *   @holdcode      Hold Code to validate
    *
    * OUTPUT:
    *   @msg           Hold Code description or error message
    *
    * RETURN VALUE
    *   0              success
    *   1              failure
    *****************************************************/
       (@co int, @holdcode bHoldCode = null, @msg varchar(60) output)
   
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @holdcode is null
   	begin
   	select @msg = 'Missing Hold code', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   from bHQHC
   where HoldCode = @holdcode
   if @@rowcount = 0
   	begin
   	select @msg = 'Hold Code not on file!', @rcode = 1
   	goto bspexit
   	end
   
   select 1 from bAPCO where @co=APCo and @holdcode=RetHoldCode
   if @@rowcount > 0
    begin
   	select @msg = 'Hold Code is a Retainage Hold Code!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOHoldCodeVal] TO [public]
GO
