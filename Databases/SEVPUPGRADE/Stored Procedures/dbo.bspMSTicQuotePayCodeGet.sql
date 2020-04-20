SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
CREATE  proc [dbo].[bspMSTicQuotePayCodeGet]
/*************************************
 * Created By:   GF 07/03/2000
 * Modified By:	GF 07/16/2007 - issue #120883 additional levels for quote,no trucktype, vendor
 *
 *
 * USAGE:   Called from other MSTicEntry SP to get a
 * default pay code from a quote.
 *
 *
 * INPUT PARAMETERS
 *  MS Company, MatlGroup, Material, Category, LocGroup, FromLoc, UM,
 *  Quote, VendorGroup, Vendor, Truck, TruckType
 *
 * OUTPUT PARAMETERS
 *  Pay Code
 *  @msg      error message if error occurs
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 *
 **************************************/
(@msco bCompany = null, @matlgroup bGroup = null, @material bMatl = null,
 @category varchar(10) = null, @locgroup bGroup = null, @fromloc bLoc = null,
 @um bUM = null, @quote varchar(10) = null, @vendorgroup bGroup = null,
 @vendor bVendor = null, @truck varchar(10) = null, @trucktype varchar(10) = null,
 @paycode bPayCode output, @msg varchar(255) output)

as
set nocount on

declare @rcode int, @validcnt int

select @rcode = 0

if @msco is null
       begin
       select @msg = 'Missing MS Company', @rcode = 1
       goto bspexit
       end

if @locgroup is null
   	begin
   	select @msg = 'Missing From Location Group', @rcode = 1
   	goto bspexit
   	end

if @matlgroup is null
       begin
       select @msg = 'Missing Material Group', @rcode = 1
       goto bspexit
       end

if @um is null
   	begin
   	select @msg = 'Missing Unit of measure', @rcode = 1
   	goto bspexit
   	end

---- look for a quote pay code in MSPX
if @quote is not null
   BEGIN
       -- only search levels 13-24 if from location is not null
       if @fromloc is not null
       BEGIN
   
           if @material is not null
           BEGIN
               -- level 24
               select @paycode=PayCode from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM=@um
               if @@rowcount <> 0 goto bspexit
               -- level 23
               select @paycode=PayCode from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um
               if @@rowcount <> 0 goto bspexit
               -- level 22
               select @paycode=PayCode from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and Vendor is null and Truck is null and UM=@um
               if @@rowcount <> 0 goto bspexit
               -- level 21
               select @paycode=PayCode from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor is null and Truck is null and UM=@um
               if @@rowcount <> 0 goto bspexit
				---- level 20.9
               select @paycode=PayCode from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor=@vendor and Truck=@truck and UM=@um
               if @@rowcount <> 0 goto bspexit
				---- level 20.8
               select @paycode=PayCode from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor=@vendor and Truck is null and UM=@um
               if @@rowcount <> 0 goto bspexit
           END
   
           if @category is not null
           BEGIN
               -- level 20
               select @paycode=PayCode from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM=@um
               if @@rowcount <> 0 goto bspexit
               -- level 19
               select @paycode=PayCode from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um
               if @@rowcount <> 0 goto bspexit
               -- level 18
               select @paycode=PayCode from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and Vendor is null and Truck is null and UM=@um
               if @@rowcount <> 0 goto bspexit
               -- level 17
               select @paycode=PayCode from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and Vendor is null and Truck is null and UM=@um
               if @@rowcount <> 0 goto bspexit
				---- level 16.9
               select @paycode=PayCode from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and Vendor=@vendor and Truck=@truck and UM=@um
               if @@rowcount <> 0 goto bspexit
				---- level 16.8
               select @paycode=PayCode from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and Vendor=@vendor and Truck is null and UM=@um
               if @@rowcount <> 0 goto bspexit
           END
   
           -- level 16
           select @paycode=PayCode from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM=@um
           if @@rowcount <> 0 goto bspexit
           -- level 15
           select @paycode=PayCode from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um
           if @@rowcount <> 0 goto bspexit
           -- level 14
           select @paycode=PayCode from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and Vendor is null and Truck is null and UM=@um
           if @@rowcount <> 0 goto bspexit
           -- level 13
           select @paycode=PayCode from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and Vendor is null and Truck is null and UM=@um
           if @@rowcount <> 0 goto bspexit
			---- level 12.9
			select @paycode=PayCode from bMSPX with (nolock) 
			where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
			and Category is null and Material is null and TruckType is null
			and Vendor=@vendor and Truck=@truck and UM=@um
			if @@rowcount <> 0 goto bspexit
			---- level 12.8
			select @paycode=PayCode from bMSPX with (nolock) 
			where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
			and Category is null and Material is null and TruckType is null
			and Vendor=@vendor and Truck is null and UM=@um
			if @@rowcount <> 0 goto bspexit
       END
   
       if @material is not null
       BEGIN
           -- level 12
           select @paycode=PayCode from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um
           -- level 11
           select @paycode=PayCode from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM=@um
           -- level 10
           select @paycode=PayCode from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and Vendor is null and Truck is null and UM=@um
           -- level 9
           select @paycode=PayCode from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType is null and Vendor is null and Truck is null and UM=@um
       END
   
       if @category is not null
       BEGIN
           -- level 8
           select @paycode=PayCode from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um
           -- level 7
           select @paycode=PayCode from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM=@um
           -- level 6
           select @paycode=PayCode from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and Vendor is null and Truck is null and UM=@um
           -- level 5
           select @paycode=PayCode from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType is null and Vendor is null and Truck is null and UM=@um
       END
   
       -- level 4
       select @paycode=PayCode from bMSPX with (nolock) 
       where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM=@um
       if @@rowcount <> 0 goto bspexit
       -- level 3
       select @paycode=PayCode from bMSPX with (nolock) 
       where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um
       if @@rowcount <> 0 goto bspexit
       -- level 2
       select @paycode=PayCode from bMSPX with (nolock) 
       where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and Vendor is null and Truck is null and UM=@um
       if @@rowcount <> 0 goto bspexit
       -- level 1
       select @paycode=PayCode from bMSPX with (nolock) 
       where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and Vendor is null and Truck is null and UM=@um
       if @@rowcount <> 0 goto bspexit
   END




bspexit:
	if @rcode <> 0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicQuotePayCodeGet] TO [public]
GO
