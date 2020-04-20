SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfMSPayCodeRate]
(@msco bCompany = null, @paycode bPayCode = null, @locgroup bGroup = null, @fromloc bLoc = null,
 @matlgroup bGroup = null, @category varchar(10) = null, @material bMatl = null,
 @trucktype varchar(10) = null, @vendorgroup bGroup = null, @vendor bVendor = null,
 @truck bTruck = null, @um bUM = null)
returns bUnitCost
/***********************************************************
* Created By:	GF 12/21/2005
* Modified By:	
*
* retrive haul rate
*
* Pass:
* @msco				MS Company
* @paycode			MS Pay Code
* @locgroup			IN Location Group
* @fromloc			IN Location
* @matlgroup		Material Group
* @category			Material Category
* @material			Material
* @trucktype		MS Truck Type
* @vendorgroup		Vendor Group
* @vendor			Vendor
* @truck			MS Vendor Truck
* @um				HQ UM
*
* OUTPUT PARAMETERS:
* Pay Rate
*
*****************************************************/
as
begin

declare @rcode int, @retcode int, @quote varchar(10), @zone varchar(10),
		@rate bUnitCost, @minamt bDollar, @basis tinyint, @tmpmsg varchar(255)

select @rcode = 0, @quote = null, @zone = null, @rate = 0, @minamt = 0

-- -- -- exit function if missing key values
if @msco is null goto exitfunction
if isnull(@paycode,'') = '' goto exitfunction
if @locgroup is null goto exitfunction
if @matlgroup is null goto exitfunction
if @vendorgroup is null goto exitfunction


-- -- -- get haul basis from MSHC
select @basis = PayBasis
from bMSPC with (nolock) where MSCo=@msco and PayCode=@paycode
if @@rowcount = 0 goto exitfunction


-- -- -- look for pay rate using unit basis in MSPR
MSPR_check:
-- Basis: 1-unit based, 4-units per mile, 5-units per hour
   if @basis in (1,4,5)
   BEGIN
       -- only search levels 25-48 if from location is not null
       if @fromloc is not null
       BEGIN
   
           if @material is not null
           BEGIN
               -- level 48
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 47
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM=@um and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 46
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 45
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 44
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and Vendor is null and Truck is null
               and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 43
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and Vendor is null and Truck is null
               and UM=@um and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 42
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor is null and Truck is null and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 41
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor is null and Truck is null and UM=@um and Zone is null
               if @@rowcount <> 0 goto exitfunction
           END
   
           if @category is not null
           BEGIN
               -- level 40
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 39
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM=@um and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 38
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
   			and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 37
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM=@um and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 36
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and Vendor is null and Truck is null and UM=@um
               and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
 
               -- level 35
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and Vendor is null and Truck is null and UM=@um
               and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 34
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and Vendor is null and Truck is null and UM=@um
               and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 33
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and Vendor is null and Truck is null and UM=@um
               and Zone is null
               if @@rowcount <> 0 goto exitfunction
           END
   
           -- level 32
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 31
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 30
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 29
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 28
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and Vendor is null and Truck is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 27
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and Vendor is null and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
   	-- -- -- level 26.5 issue #24849 - location, vendor, w/no truck type
   	select @rate=PayRate from bMSPR with (nolock) 
   	where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
   	and Category is null and Material is null and TruckType is null
   	and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone=@zone
   	if @@rowcount <> 0 goto exitfunction
   	-- -- -- level 26.4 issue #24849 - location, vendor, w/no truck type
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 26
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and Vendor is null and Truck is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 25
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and Vendor is null and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
       END
   
       if @material is not null
       BEGIN
           -- level 24
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 23
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 22
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 21
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 20
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and Vendor is null and Truck is null
           and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 19
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and Vendor is null and Truck is null
           and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 18
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType is null and Vendor is null and Truck is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 17
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType is null and Vendor is null and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
       END
   
       if @category is not null
   	BEGIN
           -- level 16
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 15
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 14
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 13
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 12
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and Vendor is null and Truck is null and UM=@um
           and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 11
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and Vendor is null and Truck is null and UM=@um
           and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 10
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType is null and Vendor is null and Truck is null and UM=@um
           and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 9
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType is null and Vendor is null and Truck is null and UM=@um
           and Zone is null
           if @@rowcount <> 0 goto exitfunction
       END
   
       -- level 8
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM=@um and Zone=@zone
       if @@rowcount <> 0 goto exitfunction
       -- level 7
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM=@um and Zone is null
      if @@rowcount <> 0 goto exitfunction
       -- level 6
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone=@zone
       if @@rowcount <> 0 goto exitfunction
       -- level 5
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone is null
   	if @@rowcount <> 0 goto exitfunction
   	-- level 4.5 vendor no truck type w/zone
   	select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone=@zone
   	if @@rowcount <> 0 goto exitfunction
   	-- level 4.5 vendor no truck type w/no zone
   	select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone is null
   	if @@rowcount <> 0 goto exitfunction
       -- level 4
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and Vendor is null and Truck is null and UM=@um and Zone=@zone
       if @@rowcount <> 0 goto exitfunction
       -- level 3
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and Vendor is null and Truck is null and UM=@um and Zone is null
       if @@rowcount <> 0 goto exitfunction
       -- level 2
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and Vendor is null and Truck is null and UM=@um and Zone=@zone
       if @@rowcount <> 0 goto exitfunction
       -- level 1
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and Vendor is null and Truck is null and UM=@um and Zone is null
       --if @@rowcount = 0 select @rcode = 1
       goto exitfunction
   END
   
   
   -- Basis: 2-hourly based, 3-load based, 6-percent of haul
   if @basis in (2,3,6)
   BEGIN
       -- only search levels 25-48 if from location is not null
       if @fromloc is not null
       BEGIN
   
           if @material is not null
           BEGIN
               -- level 48
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM is null and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 47
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM is null and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 46
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM is null and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 45
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM is null and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 44
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
   			and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and Vendor is null and Truck is null
               and UM is null and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 43
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and Vendor is null and Truck is null
   			and UM is null and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 42
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor is null and Truck is null and UM is null and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 41
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and Vendor is null and Truck is null and UM is null and Zone is null
               if @@rowcount <> 0 goto exitfunction
           END
   
           if @category is not null
           BEGIN
               -- level 40
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM is null and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 39
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck=@truck and UM is null and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 38
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM is null and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 37
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
               and Truck is null and UM is null and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 36
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and Vendor is null and Truck is null and UM is null
               and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 35
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and Vendor is null and Truck is null and UM is null
               and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 34
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and Vendor is null and Truck is null and UM is null
               and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 33
               select @rate=PayRate from bMSPR with (nolock) 
               where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and Vendor is null and Truck is null and UM is null
               and Zone is null
               if @@rowcount <> 0 goto exitfunction
           END
   
           -- level 32
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 31
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 30
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 29
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 28
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and Vendor is null and Truck is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 27
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType=@trucktype
           and Vendor is null and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
   	-- -- -- level 26.5 issue #24849 - location, vendor, w/no truck type
   	select @rate=PayRate from bMSPR with (nolock) 
   	where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
   	and Category is null and Material is null and TruckType is null
   	and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM is null and Zone=@zone
   	if @@rowcount <> 0 goto exitfunction
   	-- -- -- level 26.4 issue #24849 - location, vendor, w/no truck type
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 26
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and Vendor is null and Truck is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 25
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc=@fromloc
           and Category is null and Material is null and TruckType is null
           and Vendor is null and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
       END
   
       if @material is not null
       BEGIN
           -- level 24
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM is null and Zone=@zone
   
           if @@rowcount <> 0 goto exitfunction
           -- level 23
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 22
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 21
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 20
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and Vendor is null and Truck is null
           and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 19
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and Vendor is null and Truck is null
           and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 18
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType is null and Vendor is null and Truck is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 17
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType is null and Vendor is null and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
       END
   
       if @category is not null
       BEGIN
           -- level 16
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 15
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 14
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 13
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck is null and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 12
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and Vendor is null and Truck is null and UM is null
           and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 11
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and Vendor is null and Truck is null and UM is null
           and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 10
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType is null and Vendor is null and Truck is null and UM is null
           and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 9
           select @rate=PayRate from bMSPR with (nolock) 
           where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType is null and Vendor is null and Truck is null and UM is null
           and Zone is null
           if @@rowcount <> 0 goto exitfunction
       END
   
       -- level 8
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM is null and Zone=@zone
       if @@rowcount <> 0 goto exitfunction
       -- level 7
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck=@truck and UM is null and Zone is null
       if @@rowcount <> 0 goto exitfunction
       -- level 6
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM is null and Zone=@zone
       if @@rowcount <> 0 goto exitfunction
       -- level 5
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM is null and Zone is null
       if @@rowcount <> 0 goto exitfunction
   	-- level 4.5 vendor no truck type w/zone
   	select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone=@zone
   	if @@rowcount <> 0 goto exitfunction
   	-- level 4.5 vendor no truck type w/no zone
   	select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and VendorGroup=@vendorgroup and Vendor=@vendor and Truck is null and UM=@um and Zone is null
   	if @@rowcount <> 0 goto exitfunction
       -- level 4
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
       and Vendor is null and Truck is null and UM is null and Zone=@zone
       if @@rowcount <> 0 goto exitfunction
       -- level 3
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType=@trucktype
   	and Vendor is null and Truck is null and UM is null and Zone is null
       if @@rowcount <> 0 goto exitfunction
       -- level 2
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and Vendor is null and Truck is null and UM is null and Zone=@zone
       if @@rowcount <> 0 goto exitfunction
       -- level 1
       select @rate=PayRate from bMSPR with (nolock) 
       where MSCo=@msco and PayCode=@paycode and LocGroup=@locgroup and FromLoc is null
       and Category is null and Material is null and TruckType is null
       and Vendor is null and Truck is null and UM is null and Zone is null
       goto exitfunction
   END









exitfunction:
	return @rate
end

GO
GRANT EXECUTE ON  [dbo].[vfMSPayCodeRate] TO [public]
GO
