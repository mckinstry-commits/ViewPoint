SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************/
CREATE proc [dbo].[bspMSTicQuoteHaulCodeGet]
   /*************************************
    * Created By:  GF 07/03/2000
    * Modified By: GF 01/15/2001
    *
    * USAGE:   Called from other MSTicEntry SP to get a
    * default haul code from a quote.
    *
    * INPUT PARAMETERS
    *  MS Company, MatlGroup, Material, Category, LocGroup, FromLoc, UM, Quote, TruckType
    *
    * OUTPUT PARAMETERS
    *  Haul Code
    *  @msg      error message if error occurs
    * RETURN VALUE
    *   0         Success
    *   1         Failure
    *
    **************************************/
   (@msco bCompany = null, @matlgroup bGroup = null, @material bMatl = null,
    @category varchar(10) = null, @locgroup bGroup = null, @fromloc bLoc = null,
    @um bUM = null, @quote varchar(10) = null, @trucktype varchar(10) = null,
    @haulcode bHaulCode output, @msg varchar(255) output)
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
   
   if @um is null
   	begin
   	select @msg = 'Missing Unit of measure', @rcode = 1
   	goto bspexit
   	end
   
   -- look for haul code
   if @quote is not null
   BEGIN
       -- only search levels 7-12 if from location is not null
       if @fromloc is not null
       BEGIN
           if @material is not null
           BEGIN
               -- level 12
               select @haulcode=HaulCode
               from bMSHX with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and UM=@um
               if @@rowcount <> 0 goto bspexit
               -- level 11
               select @haulcode=HaulCode
               from bMSHX with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and UM=@um
               if @@rowcount <> 0 goto bspexit
           END
   
           if @category is not null
           BEGIN
               -- level 10
               select @haulcode=HaulCode
               from bMSHX with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and UM=@um
               if @@rowcount <> 0 goto bspexit
               -- level 9
               select @haulcode=HaulCode
               from bMSHX with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and UM=@um
               if @@rowcount <> 0 goto bspexit
           END
   
           -- level 8
           select @haulcode=HaulCode
           from bMSHX with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and MatlGroup=@matlgroup and Category is null and Material is null
           and TruckType=@trucktype and UM=@um
           if @@rowcount <> 0 goto bspexit
           -- level 7
           select @haulcode=HaulCode
           from bMSHX with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and MatlGroup=@matlgroup and Category is null and Material is null
           and TruckType is null and UM=@um
           if @@rowcount <> 0 goto bspexit
       END
   
       if @material is not null
       BEGIN
           -- level 6
           select @haulcode=HaulCode
           from bMSHX with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and UM=@um
           if @@rowcount <> 0 goto bspexit
           -- level 5
           select @haulcode=HaulCode
           from bMSHX with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
   		and TruckType is null and UM=@um
           if @@rowcount <> 0 goto bspexit
       END
   
       if @category is not null
       BEGIN
           -- level 4
           select @haulcode=HaulCode
           from bMSHX with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and UM=@um
           if @@rowcount <> 0 goto bspexit
           -- level 3
           select @haulcode=HaulCode
           from bMSHX with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType is null and UM=@um
           if @@rowcount <> 0 goto bspexit
       END
   
       -- level 2
       select @haulcode=HaulCode
       from bMSHX with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
       and MatlGroup=@matlgroup and Category is null and Material is null
       and TruckType=@trucktype and UM=@um
       if @@rowcount <> 0 goto bspexit
       -- level 1
       select @haulcode=HaulCode
       from bMSHX with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
       and MatlGroup=@matlgroup and Category is null and Material is null
       and TruckType is null and UM=@um
   END




bspexit:
	if @rcode <> 0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicQuoteHaulCodeGet] TO [public]
GO
