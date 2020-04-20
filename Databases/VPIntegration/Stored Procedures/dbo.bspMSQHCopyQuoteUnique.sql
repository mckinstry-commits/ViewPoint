SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSQHCopyQuoteUnique]
   /*************************************
   * Created By:   GF 05/08/2000
   * Modified By:
   *
   * validates MS Quote is unique for copy
   *
   * Pass:
   *	MS Company and MS Quote
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
   
   if @msco is null
   	begin
   	select @msg = 'Missing MS Company', @rcode = 1
   	goto bspexit
   	end
   
   if @quote is null
   	begin
   	select @msg = 'Missing MS Quote', @rcode = 1
   	goto bspexit
   	end
   
   select @validcnt=count(*) from bMSQH where MSCo=@msco and Quote=@quote
       if @validcnt > 0
           begin
   		select @msg = 'This quote is already set up!', @rcode = 1
           goto bspexit
   		end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQHCopyQuoteUnique] TO [public]
GO
