SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSPriceFindMatlVal]
   /*************************************
   * Created By:   GF 12/19/2000
   * Modified By:
   *
   * validates Material to HQMT.Material from MSPriceFind
   *
   * Pass:
   *   MS Company, FromLoc, MatlGroup, Material
   *
   * Success returns:
   *   Sales Unit of Measure
   *   PayDiscType
   *	0 and Description from bHQMT
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @fromloc bLoc = null, @matlgroup bGroup = null,
    @material bMatl = null, @salesum bUM output, @paydisctype char(1) output,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int
   select @rcode = 0
   
   if @msco is null
       begin
       select @msg = 'Missing MS Company!', @rcode = 1
       goto bspexit
       end
   
   if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @material is null
       begin
       select @msg = 'Missing Material!', @rcode = 1
       goto bspexit
       end
   
   select @msg=Description, @salesum=SalesUM, @paydisctype=PayDiscType
   from bHQMT where MatlGroup=@matlgroup and Material=@material
   if @@rowcount = 0
       begin
       select @msg = 'Invalid Material!', @rcode = 1
       goto bspexit
       end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPriceFindMatlVal] TO [public]
GO
