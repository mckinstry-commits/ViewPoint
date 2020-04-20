SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSTPMatlUMVal]
   /*************************************
   * Created By:   GF 03/02/2000
   * Modified By:
   *
   * validates Unit of measure to HQUM.UM, HQMT.STDUM,
   * HQMU.UM. Returns unit price and ecm from HQMT,
   * HQMU, INMT, or INMU.
   *
   * Pass:
   *   MS Company
   *   MS From Location
   *	HQ MatlGroup
   *	HQ Material
   *   HQ UM
   *
   * Success returns:
   *   Unit Price and ECM
   *	0 and Description from bHQUM
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @fromloc bLoc = null, @matlgroup bGroup = null,
    @material bMatl = null, @um bUM = null, @unitprice bUnitCost output,
    @ecm bECM output, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @validcnt int, @stdum bUM, @instdum bUM, @inunitprice bUnitCost, @inecm bECM
   
   select @rcode = 0, @unitprice = 0, @inunitprice = 0
   
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
   
   if @um is null
       begin
       select @msg = 'Missing Unit of measure!', @rcode=1
       goto bspexit
       end
   
   select @msg=Description from bHQUM where UM=@um
       if @@rowcount=0
           begin
           select @msg = 'Invalid Unit of measure!', @rcode = 1
           goto bspexit
           end
   
   if @material is null GOTO bspexit
   
   select @unitprice=isnull(Price,0), @ecm=PriceECM
       from bHQMU where MatlGroup=@matlgroup and Material=@material and UM=@um
       if @@rowcount=0
          begin
            select @stdum=StdUM, @unitprice=isnull(Price,0), @ecm=PriceECM
            from bHQMT where MatlGroup=@matlgroup and Material=@material
            if @@rowcount=0
               begin
               select @msg = 'Invalid material!', @rcode=1
               goto bspexit
               end
            if @stdum<>@um
               begin
               select @msg = 'Invalid unit of measure, not standard or in HQMU!', @rcode=1
               goto bspexit
               end
          end
   
   
   if @fromloc is null goto bspexit
   
   select @inunitprice=isnull(Price,0), @inecm=PriceECM
       from bINMU where MatlGroup=@matlgroup and INCo=@msco and Material=@material
               and Loc=@fromloc and UM=@um
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
GRANT EXECUTE ON  [dbo].[bspMSTPMatlUMVal] TO [public]
GO
