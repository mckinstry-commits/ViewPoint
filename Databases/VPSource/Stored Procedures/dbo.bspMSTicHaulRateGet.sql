SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************/
CREATE  proc [dbo].[bspMSTicHaulRateGet]
   /*************************************
    * Created By:  GF 07/03/2000
    * Modified By: GF 10/10/2000
    *				GF 03/19/2004 - issue #24038 - haul rate by phase or valid part phase levels added.
    *								also changed to use bMSHO - haul overrides instead of bMSHX.
    *
    *
    * USAGE:   Called from other MSTicEntry SP to get haul rate
    *          and minimum amount.
    *
    *
    * INPUT PARAMETERS
    *  MS Company, HaulCode, MatlGroup, Material, Category, LocGroup, FromLoc,
    *  TruckType, UM, Quote, Zone, HaulBasis, ToJCCo, PhaseGroup, Phase
    *
    * OUTPUT PARAMETERS
    *  Haul Rate
    *  Minimum Amount
    *  @msg      error message if error occurs
    * RETURN VALUE
    *   0         Success
    *   1         Failure
    *
    **************************************/
   (@msco bCompany = null, @haulcode bHaulCode = null, @matlgroup bGroup = null,
    @material bMatl = null, @category varchar(10) = null, @locgroup bGroup = null,
    @fromloc bLoc = null, @trucktype varchar(10) = null, @um bUM = null,
    @quote varchar(10) = null, @zone varchar(10) = null, @basis tinyint = null,
    @tojcco bCompany = null, @phasegroup bGroup = null, @phase bPhase = null,
    @rate bUnitCost output, @minamt bDollar output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int, @pphase bPhase, @validphasechars int
   
   select @rcode = 0, @rate = 0, @minamt = 0
   
   if @basis is null select @basis=1
   
   if @msco is null
       begin
       select @msg = 'Missing MS Company', @rcode = 1
       goto bspexit
       end
   
   if @haulcode is null
   	begin
   	select @msg = 'Missing Haul Code', @rcode = 1
   	goto bspexit
   	end
   
   if @locgroup is null
       begin
       select @msg = 'Missing IN Location Group', @rcode = 1
       goto bspexit
       end
   
   -- validate JC Company -  get valid portion of phase code
   if @tojcco is not null
   	begin
   	select @validphasechars = ValidPhaseChars from JCCO with (nolock) where JCCo = @tojcco
   	if @@rowcount = 0 set @validphasechars = len(@phase)
   	end
   
   -- format valid portion of Phase
   if isnull(@phase,'') <> ''
   	begin
   	if @validphasechars > 0
   		set @pphase = substring(@phase,1,@validphasechars) + '%'
   	else
   		set @pphase = @phase
   	end
   else
   	set @pphase = null
   
   
   -- look for rate and minimum amount by quote in MSHO
   if @quote is not null
   BEGIN
       -- test to see if an override is set up for the haul code, if not then can skip the quote checks
       select @validcnt = count(*) from bMSHO with (nolock) 
       where MSCo=@msco and Quote=@quote and HaulCode=@haulcode
       if @validcnt = 0 goto MSHR_check
   
   	-- look for MSHO using phase group and phase if Job Sale
   	if @tojcco is not null and @phase is not null
   		begin
   		-- exact match for phase
   		select @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   		and Material=@material and TruckType=@trucktype and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0 goto bspexit
   		-- look for MSHO using valid part phase 
   		select Top 1 @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   		and Material=@material and TruckType=@trucktype and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   				 UM, HaulCode, PhaseGroup, Phase, HaulRate, MinAmt
   		if @@rowcount <> 0 goto bspexit
   
   		-- exact match for phase and no truck type
   		select @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   		and Material=@material and TruckType is null and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0 goto bspexit
   		-- look for MSHO using valid part phase 
   		select Top 1 @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   		and Material=@material and TruckType is null and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   				 UM, HaulCode, PhaseGroup, Phase, HaulRate, MinAmt
   		if @@rowcount <> 0 goto bspexit
   
   		-- exact match for phase and no material
   		select @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   		and Material is null and TruckType=@trucktype and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0 goto bspexit
   		-- look for MSHO using valid part phase 
   		select Top 1 @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   		and Material is null and TruckType=@trucktype and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   				 UM, HaulCode, PhaseGroup, Phase, HaulRate, MinAmt
   		if @@rowcount <> 0 goto bspexit
   
   		-- exact match for phase and no material and no truck type
   		select @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   		and Material is null and TruckType is null and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0 goto bspexit
   		-- look for MSHO using valid part phase 
   		select Top 1 @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   		and Material is null and TruckType is null and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   				 UM, HaulCode, PhaseGroup, Phase, HaulRate, MinAmt
   		if @@rowcount <> 0 goto bspexit
   
   		-- exact match for phase and no category and no material
   		select @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null 
   		and Material is null and TruckType=@trucktype and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0 goto bspexit
   		-- look for MSHO using valid part phase 
   		select Top 1 @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
   		and Material is null and TruckType=@trucktype and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   				 UM, HaulCode, PhaseGroup, Phase, HaulRate, MinAmt
   		if @@rowcount <> 0 goto bspexit
   
   		-- exact match for phase and no category and no material and no trucktype
   		select @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null 
   		and Material is null and TruckType is null and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0 goto bspexit
   		-- look for MSHO using valid part phase 
   		select Top 1 @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
   		and Material is null and TruckType is null and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   				 UM, HaulCode, PhaseGroup, Phase, HaulRate, MinAmt
   		if @@rowcount <> 0 goto bspexit
   
   
   		-- exact match for phase no from location
   		select @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   		and Material=@material and TruckType=@trucktype and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0 goto bspexit
   		-- look for MSHO using valid part phase 
   		select Top 1 @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   		and Material=@material and TruckType=@trucktype and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   				 UM, HaulCode, PhaseGroup, Phase, HaulRate, MinAmt
   		if @@rowcount <> 0 goto bspexit
   
   		-- exact match for phase and no truck type no from location
   		select @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   		and Material=@material and TruckType is null and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0 goto bspexit
   		-- look for MSHO using valid part phase 
   		select Top 1 @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   		and Material=@material and TruckType is null and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   				 UM, HaulCode, PhaseGroup, Phase, HaulRate, MinAmt
   		if @@rowcount <> 0 goto bspexit
   
   		-- exact match for phase and no material no from location
   		select @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   		and Material is null and TruckType=@trucktype and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0 goto bspexit
   		-- look for MSHO using valid part phase 
   		select Top 1 @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   		and Material is null and TruckType=@trucktype and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   				 UM, HaulCode, PhaseGroup, Phase, HaulRate, MinAmt
   		if @@rowcount <> 0 goto bspexit
   
   		-- exact match for phase and no material and no truck type and no from location
   		select @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   		and Material is null and TruckType is null and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0 goto bspexit
   		-- look for MSHO using valid part phase 
   		select Top 1 @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   		and Material is null and TruckType is null and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   				 UM, HaulCode, PhaseGroup, Phase, HaulRate, MinAmt
   		if @@rowcount <> 0 goto bspexit
   
   		-- exact match for phase and no category and no material and no from location
   		select @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc is null and MatlGroup=@matlgroup and Category is null 
   		and Material is null and TruckType=@trucktype and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0 goto bspexit
   		-- look for MSHO using valid part phase 
   		select Top 1 @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc is null and MatlGroup=@matlgroup and Category is null
   		and Material is null and TruckType=@trucktype and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   				 UM, HaulCode, PhaseGroup, Phase, HaulRate, MinAmt
   		if @@rowcount <> 0 goto bspexit
   
   		-- exact match for phase and no category and no material and no trucktype and no from location
   		select @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc is null and MatlGroup=@matlgroup and Category is null 
   		and Material is null and TruckType is null and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0 goto bspexit
   		-- look for MSHO using valid part phase 
   		select Top 1 @rate=HaulRate, @minamt=MinAmt
   		from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   		and FromLoc is null and MatlGroup=@matlgroup and Category is null
   		and Material is null and TruckType is null and UM=@um and HaulCode=@haulcode 
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   				 UM, HaulCode, PhaseGroup, Phase, HaulRate, MinAmt
   		if @@rowcount <> 0 goto bspexit
   		end
   
       -- only search levels 7-12 if from location is not null
       if @fromloc is not null
       BEGIN
           if @material is not null
           BEGIN
               -- level 12
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType=@trucktype and UM=@um and HaulCode=@haulcode and Phase is null
               if @@rowcount <> 0 goto bspexit
               -- level 11
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material
               and TruckType is null and UM=@um and HaulCode=@haulcode and Phase is null
               if @@rowcount <> 0 goto bspexit
           END
   
           if @category is not null
           BEGIN
               -- level 10
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType=@trucktype and UM=@um and HaulCode=@haulcode and Phase is null
               if @@rowcount <> 0 goto bspexit
               -- level 9
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material is null
               and TruckType is null and UM=@um and HaulCode=@haulcode and Phase is null
               if @@rowcount <> 0 goto bspexit
           END
   
           -- level 8
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and MatlGroup=@matlgroup and Category is null and Material is null
           and TruckType=@trucktype and UM=@um and HaulCode=@haulcode and Phase is null
           if @@rowcount <> 0 goto bspexit
           -- level 7
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and MatlGroup=@matlgroup and Category is null and Material is null
           and TruckType is null and UM=@um and HaulCode=@haulcode and Phase is null
           if @@rowcount <> 0 goto bspexit
       END
   
       if @material is not null
       BEGIN
           -- level 6
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and UM=@um and HaulCode=@haulcode and Phase is null
           if @@rowcount <> 0 goto bspexit
           -- level 5
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType is null and UM=@um and HaulCode=@haulcode and Phase is null
           if @@rowcount <> 0 goto bspexit
       END
   
       if @category is not null
       BEGIN
           -- level 4
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType=@trucktype and UM=@um and HaulCode=@haulcode and Phase is null
           if @@rowcount <> 0 goto bspexit
           -- level 3
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material is null
           and TruckType is null and UM=@um and HaulCode=@haulcode and Phase is null
           if @@rowcount <> 0 goto bspexit
       END
   
       -- level 2
       select @rate=HaulRate, @minamt=MinAmt
       from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
       and MatlGroup=@matlgroup and Category is null and Material is null
       and TruckType=@trucktype and UM=@um and HaulCode=@haulcode and Phase is null
       if @@rowcount <> 0 goto bspexit
       -- level 1
       select @rate=HaulRate, @minamt=MinAmt
       from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
       and MatlGroup=@matlgroup and Category is null and Material is null
       and TruckType is null and UM=@um and HaulCode=@haulcode and Phase is null
       if @@rowcount <> 0 goto bspexit
   END
   
   
   
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
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType=@trucktype and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 23
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType=@trucktype and UM=@um and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 22
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType is null and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 21
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType is null and UM=@um and Zone is null
               if @@rowcount <> 0 goto bspexit
           END
   
           if @category is not null
           BEGIN
               -- level 20
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
          and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 19
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType=@trucktype and UM=@um and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 18
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType is null and UM=@um and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 17
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType is null and UM=@um and Zone is null
               if @@rowcount <> 0 goto bspexit
           END
   
           -- level 16
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 15
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType=@trucktype and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 14
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 13
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
       END
   
       if @material is not null
       BEGIN
           -- level 12
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType=@trucktype and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 11
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType=@trucktype and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 10
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 9
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
       END
   
       if @category is not null
       BEGIN
           -- level 8
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 7
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType=@trucktype and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 6
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType is null and UM=@um and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 5
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType is null and UM=@um and Zone is null
           if @@rowcount <> 0 goto bspexit
       END
   
       -- level 4
       select @rate=HaulRate, @minamt=MinAmt
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType=@trucktype and UM=@um and Zone=@zone
       if @@rowcount <> 0 goto bspexit
       -- level 3
       select @rate=HaulRate, @minamt=MinAmt
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType=@trucktype and UM=@um and Zone is null
       if @@rowcount <> 0 goto bspexit
       -- level 2
       select @rate=HaulRate, @minamt=MinAmt
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType is null and UM=@um and Zone=@zone
       if @@rowcount <> 0 goto bspexit
       -- level 1
       select @rate=HaulRate, @minamt=MinAmt
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType is null and UM=@um and Zone is null
       goto bspexit
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
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType=@trucktype and UM is null and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 23
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType=@trucktype and UM is null and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 22
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType is null and UM is null and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 21
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material=@material and TruckType is null and UM is null and Zone is null
               if @@rowcount <> 0 goto bspexit
           END
   
           if @category is not null
           BEGIN
               -- level 20
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType=@trucktype and UM is null and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 19
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType=@trucktype and UM is null and Zone is null
               if @@rowcount <> 0 goto bspexit
               -- level 18
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType is null and UM is null and Zone=@zone
               if @@rowcount <> 0 goto bspexit
               -- level 17
               select @rate=HaulRate, @minamt=MinAmt
               from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
               and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
               and Material is null and TruckType is null and UM is null and Zone is null
               if @@rowcount <> 0 goto bspexit
           END
   
           -- level 16
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType=@trucktype and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 15
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType=@trucktype and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 14
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 13
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
           and Material is null and TruckType is null and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
       END
   
       if @material is not null
       BEGIN
           -- level 12
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType=@trucktype and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 11
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType=@trucktype and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 10
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 9
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material=@material and TruckType is null and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
       END
   
       if @category is not null
       BEGIN
           -- level 8
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType=@trucktype and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 7
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType=@trucktype and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
           -- level 6
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType is null and UM is null and Zone=@zone
           if @@rowcount <> 0 goto bspexit
           -- level 5
           select @rate=HaulRate, @minamt=MinAmt
           from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
           and FromLoc is null and MatlGroup=@matlgroup and Category=@category
           and Material is null and TruckType is null and UM is null and Zone is null
           if @@rowcount <> 0 goto bspexit
       END
   
       -- level 4
       select @rate=HaulRate, @minamt=MinAmt
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType=@trucktype and UM is null and Zone=@zone
       if @@rowcount <> 0 goto bspexit
       -- level 3
       select @rate=HaulRate, @minamt=MinAmt
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType=@trucktype and UM is null and Zone is null
       if @@rowcount <> 0 goto bspexit
       -- level 2
       select @rate=HaulRate, @minamt=MinAmt
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType is null and UM is null and Zone=@zone
       if @@rowcount <> 0 goto bspexit
       -- level 1
       select @rate=HaulRate, @minamt=MinAmt
       from bMSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode and LocGroup=@locgroup
       and FromLoc is null and Category is null and Material is null
       and TruckType is null and UM is null and Zone is null
       goto bspexit
   END



bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicHaulRateGet] TO [public]
GO
