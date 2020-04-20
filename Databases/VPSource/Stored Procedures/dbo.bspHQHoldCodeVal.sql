SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQHoldCodeVal    Script Date: 8/28/99 9:34:50 AM ******/
   
   CREATE  proc [dbo].[bspHQHoldCodeVal]
   /***********************************************************
    * CREATED BY: KF 3/5/97
    * MODIFIED By : KF 3/5/97
    *				MV 04/12/06 - APCompany 6X recode - change err msg
    *
    * USAGE:
    *  Validates HQ Hold Code
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
       (@holdcode bHoldCode = null, @msg varchar(60) output)
   
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
   	select @msg = 'Hold Code not on file.', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQHoldCodeVal] TO [public]
GO
