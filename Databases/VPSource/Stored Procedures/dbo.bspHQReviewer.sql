SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQReviewer    Script Date: 8/28/99 9:34:54 AM ******/
   CREATE   procedure [dbo].[bspHQReviewer]
   /*************************************
   * validates HQ Reviewer
   *
   * Pass:
   *	HQ Reviewer to be validated
   *
   * Success returns:
   *	0 and Description from bHQRV
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@reviewer varchar(10) = null, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @reviewer is null
   	begin
   	select @msg = 'Missing Reviewer', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Name from bHQRV with (nolock) where Reviewer= @reviewer
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Reviewer code.', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQReviewer] TO [public]
GO
