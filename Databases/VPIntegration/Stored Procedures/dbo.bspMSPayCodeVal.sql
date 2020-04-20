SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSPayCodeVal]
   /*************************************
   * Created By:   GF 03/06/2000
   * Modified By:
   *
   * validates MS Pay Code
   *
   * Pass:
   *	MS Company and MS Pay Code to be validated
   *
   * Success returns:
   *	0 and Description from bMSPC
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @paycode bPayCode = null, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if @paycode is null
   	begin
   	select @msg = 'Missing MS Pay Code', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bMSPC where MSCo=@msco and PayCode = @paycode
       if @@rowcount = 0
           begin
   		select @msg = 'Not a valid MS Pay Code', @rcode = 1
           goto bspexit
   		end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPayCodeVal] TO [public]
GO
