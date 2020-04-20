SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSQHByTypeVal]
   /*************************************
   * Created By:   GF 05/11/2000
   * Modified By:
   *
   * validates MS Quote by quote type
   *
   * Pass:
   *	MS Company, QuoteType, and Quote to be validated
   *
   * Success returns:
   *	0 and Description from bMSQH
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @quotetype varchar(1) = null, @quote varchar(10) = null,
    @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if @quotetype is null
   	begin
   	select @msg = 'Missing Quote Type', @rcode = 1
   	goto bspexit
   	end
   
   if @quote is null
   	begin
   	select @msg = 'Missing Quote', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bMSQH where MSCo=@msco and QuoteType=@quotetype and Quote=@quote
       if @@rowcount = 0
           begin
   		select @msg = 'Not a valid MS Quote', @rcode = 1
           goto bspexit
   		end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQHByTypeVal] TO [public]
GO
