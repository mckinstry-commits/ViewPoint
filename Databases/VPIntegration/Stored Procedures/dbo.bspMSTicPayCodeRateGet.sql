SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************/
CREATE   proc [dbo].[bspMSTicPayCodeRateGet]
/*************************************
 * Created By:  GF 07/03/2000
 * Modified By: GF 01/15/2001
 *			    GG 01/16/01 - return 0 if rate not found
 *				GF 02/08/2001 - problem with finding rate if no zone
 *				GF 03/13/2002 - Some levels not exiting if rate found (12-5)
 *				GF 04/03/2004 - #24231 - added additional levels for vendor w/no truck type
 *				GF 06/16/2004 - #24849 - more levels for loc, vendor w/no truck type
 *				GF 07/16/2007 - issue #120883 - more levels for quote, not truck type, vendor
 *				Dan So 05/22/2008 - Issue #28688 - Return Minimum Pay Amount
 *				GF 10/15/2008 - issue #130533 not finding pay rate for quote when vendor and not truck type related to #120883
*
 *  
 *
 * USAGE:   Called from other MSTicEntry SP to get a default pay code rate.
 *
 *
 * INPUT PARAMETERS
 *  MS Company, PayCode, MatlGroup, Material, Category, LocGroup, FromLoc,
 *  Quote, TruckType, VendorGroup, Vendor, Truck, UM, Zone, PayBasis
 *
 * OUTPUT PARAMETERS
 *  @rate		Pay Code Rate
 *  @payminamt	Pay Minimum Amount
 *  @msg        error message if error occurs
 *
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 *
 **************************************/
(@msco bCompany = null, @paycode bPayCode = null, @matlgroup bGroup = null,
 @material bMatl = null, @category varchar(10) = null, @locgroup bGroup = null,
 @fromloc bLoc = null, @quote varchar(10) = null, @trucktype varchar(10) = null,
 @vendorgroup bGroup = null, @vendor bVendor = null, @truck varchar(10) = null,
 @um bUM = null, @zone varchar(10) = null, @basis tinyint = null,
 @rate bUnitCost output, @payminamt bDollar = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int

select @rcode = 0, @rate = 0

if @msco is null
       begin
       select @msg = 'Missing MS Company', @rcode = 1
       goto bspexit
       end

if @basis is null
       begin
       select @msg = 'Missing Pay Basis', @rcode = 1
       goto bspexit
       end

---- look for a quote override pay code rate in MSPX
if @quote is not null and @um is not null
   BEGIN
       -- test to see if an override is set up for the pay code, if not then can skip the quote checks
       select @validcnt = count(*) from bMSPX with (nolock) 
       where MSCo=@msco and Quote=@quote and PayCode=@paycode and Override='Y'
       if @validcnt = 0 goto MSPR_check
       -- only search levels 13-24 if from location is not null
       if @fromloc is not null
       BEGIN
   
           if @material is not null
           BEGIN
               -- level 24
               select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM=@um and PayCode=@paycode and Override='Y'
               if @@rowcount <> 0 goto bspexit
               -- level 23
               select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and PayCode=@paycode and Override='Y'
               if @@rowcount <> 0 goto bspexit
               -- level 22
               select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and Vendor is null and Truck is null
			   and UM=@um and PayCode=@paycode and Override='Y'
               if @@rowcount <> 0 goto bspexit
				---- level 21.9
				select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
				where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
				and MatlGroup=@matlgroup and Category=@category and Material=@material
				and TruckType is null and Vendor=@vendor and Truck=@truck
				and UM=@um and PayCode=@paycode and Override='Y'
				if @@rowcount <> 0 goto bspexit
				---- level 21.8
				select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
				where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
				and MatlGroup=@matlgroup and Category=@category and Material=@material
				and TruckType is null and Vendor=@vendor and Truck is null
				and UM=@um and PayCode=@paycode and Override='Y'
				if @@rowcount <> 0 goto bspexit
               -- level 21
               select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor is null and Truck is null
               and UM=@um and PayCode=@paycode and Override='Y'
               if @@rowcount <> 0 goto bspexit
           END
   
           if @category is not null
           BEGIN
               -- level 20
               select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM=@um and PayCode=@paycode and Override='Y'
               if @@rowcount <> 0 goto bspexit
               -- level 19
               select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and PayCode=@paycode and Override='Y'
               if @@rowcount <> 0 goto bspexit
               -- level 18
               select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and Vendor is null and Truck is null
               and UM=@um and PayCode=@paycode and Override='Y'
               if @@rowcount <> 0 goto bspexit
				---- level 17.9
				select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
				where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
				and MatlGroup=@matlgroup and Category=@category and Material is null
				and TruckType is null and Vendor=@vendor and Truck=@truck
				and UM=@um AND PayCode=@paycode and Override='Y'
				if @@rowcount <> 0 goto bspexit
				---- level 17.8
				select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
				where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
				and MatlGroup=@matlgroup and Category=@category and Material is null
				and TruckType is null and Vendor=@vendor and Truck is null
				and UM=@um and PayCode=@paycode and Override='Y'
				if @@rowcount <> 0 goto bspexit
               -- level 17
               select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
               where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and Vendor is null and Truck is null
               and UM=@um and PayCode=@paycode and Override='Y'
               if @@rowcount <> 0 goto bspexit
           END
   
           -- level 16
           select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck
           and UM=@um and PayCode=@paycode and Override='Y'
           if @@rowcount <> 0 goto bspexit
           -- level 15
           select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null
           and UM=@um and PayCode=@paycode and Override='Y'
           if @@rowcount <> 0 goto bspexit
   			---- level 14.5 issue #24849
   			select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
   			where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
   			and Category is null and Material is null and TruckType is null
   			and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null
   			and UM=@um and PayCode=@paycode and Override='Y'
   			if @@rowcount <> 0 goto bspexit
           -- level 14
           select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and Vendor is null and Truck is null and UM=@um and PayCode=@paycode and Override='Y'
           if @@rowcount <> 0 goto bspexit
			---- level 13.9
			select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
			where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
			and Category is null and Material is null and TruckType is null
			and Vendor=@vendor and Truck=@truck and UM=@um and PayCode=@paycode and Override='Y'
			if @@rowcount <> 0 goto bspexit
			---- level 13.8
			select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
			where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
			and Category is null and Material is null and TruckType is null
			and Vendor=@vendor and Truck is null and UM=@um and PayCode=@paycode and Override='Y'
			if @@rowcount <> 0 goto bspexit
           -- level 13
           select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and Vendor is null and Truck is null and UM=@um and PayCode=@paycode and Override='Y'
           if @@rowcount <> 0 goto bspexit
       END
   
       if @material is not null
       BEGIN
           -- level 12
           select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um and PayCode=@paycode and Override='Y'
           if @@rowcount <> 0 goto bspexit
           -- level 11
           select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM=@um and PayCode=@paycode and Override='Y'
           if @@rowcount <> 0 goto bspexit
           -- level 10
           select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
      		and TruckType=@trucktype and Vendor is null and Truck is null
           and UM=@um and PayCode=@paycode and Override='Y'
           if @@rowcount <> 0 goto bspexit
           -- level 9
           select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType is null and Vendor is null and Truck is null and UM=@um and PayCode=@paycode and Override='Y'
           if @@rowcount <> 0 goto bspexit
       END
   
       if @category is not null
       BEGIN
           -- level 8
           select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um and PayCode=@paycode and Override='Y'
           if @@rowcount <> 0 goto bspexit
           -- level 7
           select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM=@um and PayCode=@paycode and Override='Y'
           if @@rowcount <> 0 goto bspexit
           -- level 6
           select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and Vendor is null and Truck is null
           and UM=@um and PayCode=@paycode and Override='Y'
           if @@rowcount <> 0 goto bspexit
           -- level 5
           select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType is null and Vendor is null and Truck is null and UM=@um and PayCode=@paycode and Override='Y'
           if @@rowcount <> 0 goto bspexit
       END
   
       -- level 4
       select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
       where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM=@um and PayCode=@paycode and Override='Y'
       if @@rowcount <> 0 goto bspexit
		-- level 3
		select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
		where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
		and Category is null and Material is null and TruckType=@trucktype
		and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null
		and UM=@um and PayCode=@paycode and Override='Y'
		if @@rowcount <> 0 goto bspexit
		-- level 2.5 vendor no truck type
		select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock)
		where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
		and Category is null and Material is null and TruckType is null
		and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null
		and UM=@um and PayCode=@paycode and Override='Y'
       -- level 2
       select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
       where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and Vendor is null and Truck is null and UM=@um and PayCode=@paycode and Override='Y'
       if @@rowcount <> 0 goto bspexit
       -- level 1
       select @rate=PayRate, @payminamt = PayMinAmt from bMSPX with (nolock) 
       where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and Vendor is null and Truck is null and UM=@um and PayCode=@paycode and Override='Y'
       if @@rowcount <> 0 goto bspexit
   END
  

 
MSPR_check: 
---- look for pay rate using unit basis in MSPR
---- Basis: 1-unit based, 4-units per mile, 5-units per hour
if @basis in (1,4,5)
   BEGIN
       -- only search levels 25-48 if from location is not null
       if @fromloc is not null
       BEGIN
   
           if @material is not null
           BEGIN
               -- level 48
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 47
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM=@um and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 46
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 45
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and Zone is null
               if @@rowcount <> 0 goto bspexit
			   -- level 44.9
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 44.8
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 44
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor is null and Truck is null
               and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 43
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and Vendor is null and Truck is null
               and UM=@um and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 42
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor is null and Truck is null and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 41
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor is null and Truck is null and UM=@um and Zone is null
               if @@rowcount <> 0 goto bspexit
           END

           if @category is not null
           BEGIN
               -- level 40
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 39
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM=@um and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 38
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
   				and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 37
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and Zone is null
               if @@rowcount <> 0 goto bspexit
			   -- level 36.9
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 36.8
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 36
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and Vendor is null and Truck is null and UM=@um
               and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 35
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and Vendor is null and Truck is null and UM=@um
               and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 34
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and Vendor is null and Truck is null and UM=@um
               and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 33
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and Vendor is null and Truck is null and UM=@um
               and Zone is null
               if @@rowcount <> 0 goto bspexit
           END
   
           -- level 32
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 31
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 30
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 29
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 28
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and Vendor is null and Truck is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 27
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and Vendor is null and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
   	-- -- -- level 26.5 issue #24849 - location, vendor, w/no truck type
   	select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
   	where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
   	and Category is null and Material is null and TruckType is null
   	and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone=@zone
   	if @@rowcount <> 0 goto bspexit
   	-- -- -- level 26.4 issue #24849 - location, vendor, w/no truck type
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 26
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and Vendor is null and Truck is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 25
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and Vendor is null and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
       END
   
       if @material is not null
       BEGIN
           -- level 24
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 23
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 22
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 21
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 20
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and Vendor is null and Truck is null
           and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 19
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and Vendor is null and Truck is null
           and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 18
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType is null and Vendor is null and Truck is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 17
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType is null and Vendor is null and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
       END
   
	if @category is not null
		BEGIN
           -- level 16
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 15
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 14
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 13
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 12
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and Vendor is null and Truck is null and UM=@um
           and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 11
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and Vendor is null and Truck is null and UM=@um
           and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 10
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType is null and Vendor is null and Truck is null and UM=@um
           and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 9
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType is null and Vendor is null and Truck is null and UM=@um
           and Zone is null
           if @@rowcount <> 0 goto bspexit
       END
   
       -- level 8
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM=@um and Zone=@zone
       if @@rowcount <> 0 goto bspexit
       -- level 7
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM=@um and Zone is null
      if @@rowcount <> 0 goto bspexit
       -- level 6
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone=@zone
       if @@rowcount <> 0 goto bspexit
       -- level 5
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone is null
   	if @@rowcount <> 0 goto bspexit
   	-- level 4.5 vendor no truck type w/zone
   	select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone=@zone
   	if @@rowcount <> 0 goto bspexit
   	-- level 4.5 vendor no truck type w/no zone
   	select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone is null
   	if @@rowcount <> 0 goto bspexit
       -- level 4
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and Vendor is null and Truck is null and UM=@um and Zone=@zone
       if @@rowcount <> 0 goto bspexit
       -- level 3
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and Vendor is null and Truck is null and UM=@um and Zone is null
       if @@rowcount <> 0 goto bspexit
       -- level 2
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and Vendor is null and Truck is null and UM=@um and Zone=@zone
       if @@rowcount <> 0 goto bspexit
       -- level 1
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and Vendor is null and Truck is null and UM=@um and Zone is null
       --if @@rowcount = 0 select @rcode = 1
       goto bspexit
   END
   
   
---- Basis: 2-hourly based, 3-load based, 6-percent of haul
if @basis in (2,3,6)
	BEGIN
	---- only search levels 25-48 if from location is not null
	if @fromloc is not null
		BEGIN
   
		if @material is not null
			BEGIN
               -- level 48
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM is null and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 47
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM is null and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 46
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM is null and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 45
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM is null and Zone is null
               if @@rowcount <> 0 goto bspexit
			   -- level 44.9
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM is null and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 44.8
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM is null and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 44
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
   			and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and Vendor is null and Truck is null
               and UM is null and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 43
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and Vendor is null and Truck is null
   			and UM is null and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 42
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor is null and Truck is null and UM is null and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 41
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor is null and Truck is null and UM is null and Zone is null
               if @@rowcount <> 0 goto bspexit
           END
   
           if @category is not null
           BEGIN
               -- level 40
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM is null and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 39
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM is null and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 38
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM is null and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 37
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM is null and Zone is null
               if @@rowcount <> 0 goto bspexit
			   -- level 36.9
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM is null and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 36.8
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM is null and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 36
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and Vendor is null and Truck is null and UM is null
               and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 35
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and Vendor is null and Truck is null and UM is null
               and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 34
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and Vendor is null and Truck is null and UM is null
               and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 33
               select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and Vendor is null and Truck is null and UM is null
               and Zone is null
               if @@rowcount <> 0 goto bspexit
           END
   
           -- level 32
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 31
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 30
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 29
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 28
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and Vendor is null and Truck is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 27
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and Vendor is null and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
   	-- -- -- level 26.5 issue #24849 - location, vendor, w/no truck type
   	select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
   	where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
   	and Category is null and Material is null and TruckType is null
   	and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM is null and Zone=@zone
   	if @@rowcount <> 0 goto bspexit
   	-- -- -- level 26.4 issue #24849 - location, vendor, w/no truck type
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 26
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and Vendor is null and Truck is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 25
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and Vendor is null and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
       END
   
       if @material is not null
       BEGIN
           -- level 24
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM is null and Zone=@zone
   
           if @@rowcount <> 0 goto bspexit
           -- level 23
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 22
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 21
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 20
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and Vendor is null and Truck is null
           and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 19
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and Vendor is null and Truck is null
           and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 18
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType is null and Vendor is null and Truck is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 17
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType is null and Vendor is null and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
       END
   
       if @category is not null
       BEGIN
           -- level 16
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 15
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 14
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 13
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 12
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and Vendor is null and Truck is null and UM is null
           and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 11
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and Vendor is null and Truck is null and UM is null
           and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 10
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType is null and Vendor is null and Truck is null and UM is null
           and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 9
           select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType is null and Vendor is null and Truck is null and UM is null
           and Zone is null
           if @@rowcount <> 0 goto bspexit
       END
   
       -- level 8
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM is null and Zone=@zone
       if @@rowcount <> 0 goto bspexit
       -- level 7
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM is null and Zone is null
       if @@rowcount <> 0 goto bspexit
       -- level 6
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM is null and Zone=@zone
       if @@rowcount <> 0 goto bspexit
       -- level 5
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM is null and Zone is null
       if @@rowcount <> 0 goto bspexit
   	-- level 4.5 vendor no truck type w/zone
   	select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone=@zone
   	if @@rowcount <> 0 goto bspexit
   	-- level 4.5 vendor no truck type w/no zone
   	select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone is null
   	if @@rowcount <> 0 goto bspexit
       -- level 4
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and Vendor is null and Truck is null and UM is null and Zone=@zone
       if @@rowcount <> 0 goto bspexit
       -- level 3
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
   	and Vendor is null and Truck is null and UM is null and Zone is null
       if @@rowcount <> 0 goto bspexit
       -- level 2
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and Vendor is null and Truck is null and UM is null and Zone=@zone
       if @@rowcount <> 0 goto bspexit
       -- level 1
       select @rate=PayRate, @payminamt = MinAmt from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and Vendor is null and Truck is null and UM is null and Zone is null
       goto bspexit
   END





bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicPayCodeRateGet] TO [public]
GO
