SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatlVal    Script Date: 8/28/99 9:34:53 AM ******/
   CREATE  proc [dbo].[bspHQMatlVal]
   /*************************************
   * validates HQ Material vs HQMT.Material
   *
   * Pass:
   *	HQ MatlGroup
   *	HQ Material
   *
   * Success returns:
   *       Purchase Unit Of measure
   *	0 and Description from bHQMT
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@matlgroup bGroup = null, @material bMatl = null, @purchum bUM=null output, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group', @rcode = 1
   	goto bspexit
   	end
   
   if @material is null
   	begin
   	select @msg = 'Missing Material', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @purchum=PurchaseUM from bHQMT where MatlGroup = @matlgroup and 
   	Material = @material
   	if @@rowcount = 0
   		begin
   
   		select @msg = 'Material not on file.', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQMatlVal] TO [public]
GO
