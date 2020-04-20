SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspMSCatMatlVal]
   /*************************************
   * Created By:   GF 03/03/2000
   * Modified By:
   *
   * validates Category and Material to HQMT.Material
   *
   * Pass:
   *	HQ MatlGroup
   *   HQ Category
   *	HQ Material
   *
   * Success returns:
   *   Payment Discount Type
   *   Standard Unit of Measure
   *   Standard Payment Discount
   *   Sales Unit of Measure
   *   Sales Payment Discount
   *   Haul Code
   *	0 and Description from bHQMT
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@matlgroup bGroup = null, @category varchar(10) = null, @material bMatl = null,
    @paydisctype char(1) output, @stdum bUM = Null output, @standdiscrate bUnitCost output,
    @salesum bUM = Null output, @salesdiscrate bUnitCost output, @haulcode bHaulCode output,
    @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @validcnt int, @hqmtcat varchar(10), @disctype char(1)
   select @rcode = 0, @standdiscrate=0, @salesdiscrate=0, @paydisctype='N', @haulcode=null
   
   if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @category is null
       begin
       select @msg = 'Missing Material Category!', @rcode = 1
       goto bspexit
       end
   
   if @material = ''
   	begin
   	select @msg = 'Missing Material!', @rcode = 1
   	goto bspexit
   	end
   
   if @material is null goto bspexit
   
   select @validcnt = Count(*) from bHQMC where MatlGroup=@matlgroup and Category=@category
       if @validcnt = 0
           begin
           select @msg = 'Invalid Material Category!', @rcode=1
           goto bspexit
           end
   
   select @hqmtcat=Category, @msg=Description, @stdum=StdUM, @salesum=SalesUM,
          @paydisctype=PayDiscType, @standdiscrate=isnull(PayDiscRate,0),
          @haulcode=HaulCode
       from bHQMT where MatlGroup=@matlgroup and Material=@material
   	if @@rowcount = 0
   		begin
   		select @msg = 'Invalid Material!', @rcode = 1
   		goto bspexit
           end
       if @hqmtcat<>@category
           begin
           select @msg = 'Material not set up for this Material Category!', @rcode=1
           goto bspexit
           end
   
   
   select @salesdiscrate=isnull(PayDiscRate,0)
   from bHQMU where MatlGroup=@matlgroup and Material=@material and UM=@salesum
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSCatMatlVal] TO [public]
GO
