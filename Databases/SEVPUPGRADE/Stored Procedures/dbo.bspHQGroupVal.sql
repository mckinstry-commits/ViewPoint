SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQGroupVal    Script Date: 8/28/99 9:34:50 AM ******/
   CREATE  proc [dbo].[bspHQGroupVal]
   /*************************************
   * validates HQ VendorGroup, MatlGroup, PhaseGroup, or CustGroup
   *
   * Pass:
   *	HQ Group to be validated
   *
   * Success returns:
   *	0 and Group Description from bHQGP
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@grp bGroup = null, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @grp is null
   	begin
   	select @msg = 'Missing HQ Group', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bHQGP where Grp = @grp
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid HQ Group', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQGroupVal] TO [public]
GO
