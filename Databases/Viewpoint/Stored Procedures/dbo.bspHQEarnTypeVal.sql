SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQEarnTypeVal    Script Date: 8/28/99 9:34:50 AM ******/
   CREATE  proc [dbo].[bspHQEarnTypeVal]
   /*************************************
   * validates HQ Earn Type
   *
   * Pass:
   *	HQ Earn Type to be validated
   *
   * Success returns:
   *	0 and Group Description from bHQET
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@et bEarnType = null, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @et is null
   	begin
   	select @msg = 'Missing HQ Earn Type', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bHQET where EarnType = @et
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid HQ Earn Type', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQEarnTypeVal] TO [public]
GO
