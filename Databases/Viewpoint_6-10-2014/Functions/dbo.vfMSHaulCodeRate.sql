SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   function [dbo].[vfMSHaulCodeRate]
(@msco bCompany = null, @haulcode bHaulCode = null, @locgroup bGroup = null, @fromloc bLoc = null,
 @matlgroup bGroup = null, @category varchar(10) = null, @material bMatl = null,
 @trucktype varchar(10) = null, @um bUM = null)
returns bUnitCost
/***********************************************************
* Created By:	GF 12/21/2005
* Modified By:	
*
* retrive haul rate
*
* Pass:
* @msco				MS Company
* @haulcode			MS Haul Code
* @locgroup			IN Location Group
* @fromloc			IN Location
* @matlgroup		Material Group
* @category			Material Category
* @material			Material
* @trucktype		MS Truck Type
* @um				HQ UM
*
* OUTPUT PARAMETERS:
* Haul Rate
*
*****************************************************/
as
begin

declare @rcode int, @retcode int, @quote varchar(10), @zone varchar(10),
		@rate bUnitCost, @minamt bDollar, @basis tinyint, @tmpmsg varchar(255)

select @rcode = 0, @quote = null, @zone = null, @rate = 0, @minamt = 0

-- -- -- exit function if missing key values
if @msco is null goto exitfunction
if isnull(@haulcode,'') = '' goto exitfunction
if isnull(@locgroup,'') = '' goto exitfunction
if @matlgroup is null goto exitfunction

-- -- -- get haul basis from MSHC
select @basis = HaulBasis
from bMSHC with (nolock) where MSCo=@msco and HaulCode=@haulcode
if @@rowcount = 0 goto exitfunction

   MSHR_check:
   -- look for rate and minimum amount in MSHR by haul basis
   -- Basis: 1-unit based, 4-units per mile, 5-units per hour
   if @basis in (1,4,5)
   BEGIN
       -- only search levels 13-24 if from location is not null
       if @fromloc is not null
       BEGIN
   
           if @material is not null
           BEGIN
               -- level 24
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType=@trucktype and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 23
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType=@trucktype and UM=@um and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 22
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType is null and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 21
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType is null and UM=@um and Zone is null
               if @@rowcount <> 0 goto exitfunction
           END
   
           if @category is not null
           BEGIN
               -- level 20
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 19
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType=@trucktype and UM=@um and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 18
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType is null and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 17
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType is null and UM=@um and Zone is null
               if @@rowcount <> 0 goto exitfunction
           END
   
           -- level 16
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 15
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType=@trucktype and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 14
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 13
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
       END
   
       if @material is not null
       BEGIN
           -- level 12
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType=@trucktype and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 11
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType=@trucktype and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 10
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 9
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
       END
   
       if @category is not null
       BEGIN
           -- level 8
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 7
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType=@trucktype and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 6
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 5
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto exitfunction
       END
   
       -- level 4
       select @rate=HaulRate
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType=@trucktype and UM=@um and Zone=@zone
       if @@rowcount <> 0 goto exitfunction
       -- level 3
       select @rate=HaulRate
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType=@trucktype and UM=@um and Zone is null
       if @@rowcount <> 0 goto exitfunction
       -- level 2
       select @rate=HaulRate
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType is null and UM=@um and Zone=@zone
       if @@rowcount <> 0 goto exitfunction
       -- level 1
       select @rate=HaulRate
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType is null and UM=@um and Zone is null
       goto exitfunction
   END
   
   -- Basis: 2-per hour, 3-Load based
   if @basis in (2,3)
   BEGIN
       -- only search levels 13-24 if from location is not null
       if @fromloc is not null
       BEGIN
   
           if @material is not null
           BEGIN
               -- level 24
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType=@trucktype and UM is null and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 23
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType=@trucktype and UM is null and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 22
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType is null and UM is null and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 21
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType is null and UM is null and Zone is null
               if @@rowcount <> 0 goto exitfunction
           END
   
           if @category is not null
           BEGIN
               -- level 20
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType=@trucktype and UM is null and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 19
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType=@trucktype and UM is null and Zone is null
               if @@rowcount <> 0 goto exitfunction
               -- level 18
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType is null and UM is null and Zone=@zone
               if @@rowcount <> 0 goto exitfunction
               -- level 17
               select @rate=HaulRate
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType is null and UM is null and Zone is null
               if @@rowcount <> 0 goto exitfunction
           END
   
           -- level 16
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType=@trucktype and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 15
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType=@trucktype and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 14
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 13
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType is null and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
       END
   
       if @material is not null
       BEGIN
           -- level 12
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType=@trucktype and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 11
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType=@trucktype and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 10
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 9
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType is null and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
       END
   
       if @category is not null
       BEGIN
           -- level 8
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType=@trucktype and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 7
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType=@trucktype and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
           -- level 6
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto exitfunction
           -- level 5
           select @rate=HaulRate
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType is null and UM is null and Zone is null
           if @@rowcount <> 0 goto exitfunction
       END
   
       -- level 4
       select @rate=HaulRate
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType=@trucktype and UM is null and Zone=@zone
       if @@rowcount <> 0 goto exitfunction
       -- level 3
       select @rate=HaulRate
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType=@trucktype and UM is null and Zone is null
       if @@rowcount <> 0 goto exitfunction
       -- level 2
       select @rate=HaulRate
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType is null and UM is null and Zone=@zone
       if @@rowcount <> 0 goto exitfunction
       -- level 1
       select @rate=HaulRate
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType is null and UM is null and Zone is null
       goto exitfunction
   END









exitfunction:
	return @rate
end

GO
GRANT EXECUTE ON  [dbo].[vfMSHaulCodeRate] TO [public]
GO
