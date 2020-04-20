SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSTPCatMatlVal]
   /*************************************
   * Created By:   GF 03/03/2000
   * Modified By:
   *
   * validates Category and Material to HQMT.Material from MSTP
   *
   * Pass:
   *   MS Company
   *   MS From Location
   *	HQ MatlGroup
   *   HQ Category
   *	HQ Material
   *
   * Success returns:
   *   Standard Unit of Measure
   *   Standard Unit Price
   *   Standard Price ECM
   *   Sales Unit of Measure
   *   Sales Unit Price
   *   Sales Price ECM
   *   IN Unit Price - from INMT, INMU, or none
   *   IN ECM - from INMT, INMU, or none
   *	0 and Description from bHQMT
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @fromloc bLoc = null, @matlgroup bGroup = null,
    @category varchar(10) = null, @material bMatl = null, @stdum bUM output,
    @stdunitprice bUnitCost output, @stdecm bECM output, @salesum bUM output,
    @salesunitprice bUnitCost output, @salesecm bECM output, @unitprice bUnitCost = 0 output,
    @ecm bECM = null output, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @validcnt int, @hqmtcat varchar(10), @inunitprice bUnitCost, @inecm bECM
   select @rcode = 0, @stdunitprice=0, @salesunitprice=0, @inunitprice = 0
   
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
   
   if @category is null
       begin
       select @msg = 'Missing Material Category!', @rcode = 1
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
          @stdunitprice=Isnull(Price,0), @stdecm=PriceECM
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
   
   select @salesunitprice=isnull(Price,0), @salesecm=PriceECM
       from bHQMU where MatlGroup=@matlgroup and Material=@material and UM=@salesum
   
   if @fromloc is null goto bspexit
   
   select @inunitprice=isnull(Price,0), @inecm=PriceECM
       from bINMU where MatlGroup=@matlgroup and INCo=@msco and Material=@material and Loc=@fromloc and UM=@salesum
       if @@rowcount=0
          begin
            select @inunitprice=isnull(StdPrice,0), @inecm=PriceECM
            from bINMT where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
          end
   
   if @inunitprice<>0
       begin
       select @unitprice=@inunitprice, @ecm=@inecm
       end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTPCatMatlVal] TO [public]
GO
