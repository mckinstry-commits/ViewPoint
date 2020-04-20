SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQInsCodeVal    Script Date: 8/28/99 9:34:51 AM ******/
   CREATE  proc [dbo].[bspHQInsCodeVal]
   /*************************************
   * validates HQ Insurance Codes
   *
   * Pass:
   *	HQ Insurance Code
   *
   * Success returns:
   *	0 and Insureance Code Description from bHQLT
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@inscode bInsCode = null, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @inscode is null
   	begin
   	select @msg = 'Missing Insurance Code!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg = Description from bHQIC where InsCode = @inscode
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Insurance Code!', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQInsCodeVal] TO [public]
GO
