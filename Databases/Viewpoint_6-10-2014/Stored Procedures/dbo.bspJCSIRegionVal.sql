SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCSIRegionVal    Script Date: 8/28/99 9:33:01 AM ******/
   /****** Object:  Stored Procedure dbo.bspJCSIRegionVal    Script Date: 2/12/97 3:25:08 PM ******/
   CREATE   proc [dbo].[bspJCSIRegionVal]
   /*************************************
   * TV - 23061 added isnulls 
   *
   * validates JC SI Region
   *
   * Pass:
   *	JC Region to be validated
   *
   * Success returns:
   *	0 and Group Description from bJCSI
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@reg char(10) = null, @msg varchar(60) output)
   as 
   set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @reg is null
   	begin
   	select @msg = 'Missing JC SI Region', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = 'Region: ' + isnull(@reg,'') from bJCSI 
     where SIRegion = @reg
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid JC SI Region', @rcode = 1
   		end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCSIRegionVal] TO [public]
GO
