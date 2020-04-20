SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspMSQuoteChangeCheck]
   /*************************************
   * Created By:   GF 03/30/2000
   * Modified By:
   *
   * checks MSQD for sold units.
   *
   * Pass:
   *   MSCo,Quote
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @quote varchar(10) = null, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0
   
   /*
   if @msco is null
       begin
       select @msg = 'Missing MS Company!', @rcode=0
       goto bspexit
       end
   
   if @quote is null
       begin
       select @msg = 'Missing Quote!', @rcode=0
       goto bspexit
       end
   */
   
   -- check bMSQD for sold units
   select @validcnt = count(*) from bMSQD with (nolock) where MSCo=@msco and Quote=@quote and SoldUnits<>0
   if @validcnt <> 0
       begin
       select @msg = 'Sold units have been posted', @rcode=1
       goto bspexit
       end
   else
       begin
       select @msg = 'Sold units have not been posted', @rcode=0
       goto bspexit
       end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQuoteChangeCheck] TO [public]
GO
