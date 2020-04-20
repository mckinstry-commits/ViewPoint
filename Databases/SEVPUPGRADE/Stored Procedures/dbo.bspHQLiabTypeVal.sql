SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQLiabTypeVal    Script Date: 8/28/99 9:34:51 AM ******/
   CREATE  proc [dbo].[bspHQLiabTypeVal]
   /*************************************
   * validates HQ Liability Type
   *
   * Pass:
   *	HQ Liability Type to be validated
   *
   * Success returns:
   *	0 and Group Description from bHQLT
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@lt int = null, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @lt is null
   	begin
   	select @msg = 'Missing HQ Liability Type', @rcode = 1
   	goto bspexit
   
   	end
   
   
   select @msg = Description from bHQLT where LiabType = @lt
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid HQ Liability Type', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQLiabTypeVal] TO [public]
GO
