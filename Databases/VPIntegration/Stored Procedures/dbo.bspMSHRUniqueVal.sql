SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSHRUniqueVal]
   /*************************************
   * Created By:   GF 03/02/2000
   * Modified By:  GF 10/10/2000
   *
   * validates MSCo,HaulCode,LocGroup,FromLoc,MatlGroup,Material,TruckType,UM,Zone
   * to MSHR for uniqueness.
   *
   * Pass:
   *   MSCo,HaulCode,LocGroup,FromLoc,MatlGroup,Category,Material,TruckType,UM,Zone,Seq
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany, @haulcode bHaulCode, @locgroup bGroup = null, @fromloc bLoc = null,
    @matlgroup bGroup, @category varchar(10), @material bMatl, @trucktype varchar(10),
    @um bUM, @zone varchar(10), @seq int = null, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0, @msg=''
   
   -- validate required columns
   if @msco is null
       begin
       select @msg = 'Missing MS Company!', @rcode=1
       goto bspexit
       end
   
   if @haulcode is null
       begin
       select @msg = 'Missing Haul Code!', @rcode=1
       goto bspexit
       end
   
   if @locgroup is null
       begin
       select @msg = 'Missing Location Group!', @rcode=1
       goto bspexit
       end
   
   if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group!', @rcode=1
   	goto bspexit
   	end
   
   if @seq is null
       begin
       select @validcnt = Count(*) from bMSHR
       where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
       and Material=@material and TruckType=@trucktype and UM=@um and Zone=@zone
       if @validcnt >0
          begin
          select @msg = 'Duplicate record, cannot insert!', @rcode=1
          goto bspexit
          end
       end
   else
       begin
       select @validcnt = Count(*) from bMSHR
       where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
       and Material=@material and TruckType=@trucktype and UM=@um and Zone=@zone
       and Seq<>@seq
       if @validcnt >0
          begin
          select @msg = 'Duplicate record, cannot insert!', @rcode=1
          goto bspexit
          end
       end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHRUniqueVal] TO [public]
GO
