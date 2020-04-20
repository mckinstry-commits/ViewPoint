SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSPRUniqueVal]
   /*************************************
   * Created By:   GF 03/03/2000
   * Modified By:  GF 10/10/2000
   *
   * validates MSCo,PayCode,LocGroup,FromLoc,MatlGroup,Material,TruckType,
   *           VendorGroup,Vendor,Truck,UM,Zone to MSPR for uniqueness.
   *
   * Pass:
   *   MSCo,PayCode,LocGroup,FromLoc,MatlGroup,Category,Material,TruckType,
   *   VendorGroup,Vendor,Truck,UM,Zone,Seq
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @paycode bPayCode = null, @locgroup bGroup = null, @fromloc bLoc = null,
    @matlgroup bGroup = null, @category varchar(10) = null, @material bMatl = null, @trucktype varchar(10) = null,
    @vendorgroup bGroup = null, @vendor bVendor = null, @truck bTruck = null, @um bUM = null, @zone varchar(10) = null,
    @seq int = null, @msg varchar(255) output)
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
   
   if @paycode is null
       begin
       select @msg = 'Missing Pay Code!', @rcode=1
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
   
   if @vendorgroup is null
       begin
       select @msg = 'Missing Vendor Group!', @rcode=1
       goto bspexit
       end
   
   if @seq is null
       begin
       select @validcnt = Count(*) from bMSPR
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup
       and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
       and Material=@material and TruckType=@trucktype and VendorGroup=@vendorgroup
       and Vendor=@vendor and Truck=@truck and UM=@um and Zone=@zone
       if @validcnt >0
          begin
          select @msg = 'Duplicate record, cannot insert!', @rcode=1
          goto bspexit
          end
       end
   else
       begin
       select @validcnt = Count(*) from bMSPR
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup
       and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
       and Material=@material and TruckType=@trucktype and VendorGroup=@vendorgroup
       and Vendor=@vendor and Truck=@truck and UM=@um and Zone=@zone and Seq<>@seq
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
GRANT EXECUTE ON  [dbo].[bspMSPRUniqueVal] TO [public]
GO
