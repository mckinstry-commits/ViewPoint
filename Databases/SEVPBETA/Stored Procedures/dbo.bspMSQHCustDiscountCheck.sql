SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspMSQHCustDiscountCheck]
   /***********************************************************
    * Created By:  GF 10/03/2000
    * Modified By:
    *
    * USAGE:
    * Checks if MS Quote Customer Discount overrides exists.
    *
    * INPUT PARAMETERS
    *  MSCo    MS Company
    *  Quote   Quote to check
    *
    * RETURN VALUE
    *   0         No Records exists
    *   1         Records exists
    *****************************************************/
   (@msco bCompany = 0, @quote varchar(10), @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int
   
   select @rcode=0
   
   -- check MSDX - Quote Discount Overrides
   select @validcnt = count(*) from bMSDX with (nolock) where MSCo=@msco and Quote=@quote
   if @validcnt > 0
      begin
      select @msg = 'Quote Discount Overrides exists', @rcode = 1
      goto bspexit
      end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQHCustDiscountCheck] TO [public]
GO
