SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMUSetupVal    Script Date: 8/28/99 9:32:47 AM ******/
   CREATE  proc [dbo].[bspHQMUSetupVal]
   /*************************************
   * MODIFIED BY: KF 2/19/97
   * validates HQMT Purchase/Sales UM vs HQMU.UM
   *
   * Pass:
   *	HQMT.MatlGroup
   *	HQMT.Material
   *	HQMT.PurchaseUM or HQMT.SalesUM
   *
   * Success returns:
   *	0 
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@matlgroup tinyint = null, @matl bMatl = null, @um bUM = null, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	declare @hqmucount int
   	declare @hqmtcount int
   	
   	
   if @um is null
   	begin
   	select @msg = 'Missing Unit of Measure', @rcode = 1
   	goto bspexit
   	end
   
   select @hqmucount = count(*) from HQMU where MatlGroup = @matlgroup and Material = @matl and UM = @um
   	if @hqmucount=0
   		begin
   		select @hqmtcount = count(*) from HQMT 
   
   		where MatlGroup=@matlgroup and Material = @matl and StdUM=@um
   			if @hqmtcount=0
   			begin
   				select @msg = 'UM not setup in Material Units of Measure', @rcode = 1
   			end
   		end
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQMUSetupVal] TO [public]
GO
