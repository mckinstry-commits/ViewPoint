SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************
* Created By:  DAN SO 09/24/2009 - Issue #129350
* Modified By: GF 03/31/2010 - #129350 more levels
*
*
* USAGE:   Head of finding Surcharge Rates
*
* Surcharge Rate Hierarchy: The Location Group and Surcharge Code are the 2 required fields
* with the search criteria. Initially the hierarchy used for quotes will then be applied
* to the surcharge rate table when no quote override is found.
*
* SURCHARGE BASIS IS NOT USED WHEN LOOKING FOR A RATE.
*
*
* INPUT PARAMETERS
* @msco				Company
* @SurchargeCode	Surcharge Code
* @matlgroup
* @material
* @category
* @locgroup
* @fromloc
* @trucktype
* @um
* @quote
* @zone
* @saledate
* @basis			NOT USED
*
* OUTPUT PARAMETERS
* @Rate		Surcharge Rate
* @minamt	minimum amount
* @msg    On error
*
* RETURN VALUE
*   0         Success
*   1         Failure
*
**************************************/
--CREATE PROC [dbo].[vspMSSurchargeRateGet]
CREATE PROC [dbo].[vspMSSurchargeRateGet]
(@msco bCompany = NULL, @SurchargeCode smallint = NULL, @matlgroup bGroup = NULL,
 @material bMatl = NULL, @category varchar(10) = NULL, @locgroup bGroup = NULL,
 @fromloc bLoc = NULL, @trucktype varchar(10) = NULL, @um bUM = NULL,
 @quote varchar(10) = NULL, @zone varchar(10) = NULL, @saledate bDate = NULL,
 @basis tinyint = NULL, @rate bUnitCost = null output, @minamt bDollar = null output,
 @msg varchar(255) output)
   
AS
SET NOCOUNT ON

DECLARE	@rcode				int,
		@validcnt			int

		
----------------------------------
-- VALIDATE INCOMING PARAMETERS --
----------------------------------
IF @msco IS NULL
	BEGIN
		SELECT @msg = 'Missing MS Company', @rcode = 1
		GOTO vspexit
	END

IF @SurchargeCode IS NULL
	BEGIN
		SELECT @msg = 'Missing Surcharge Code', @rcode = 1
		GOTO vspexit
	END

IF @locgroup IS NULL
	BEGIN
		SELECT @msg = 'Missing IN Location Group', @rcode = 1
		GOTO vspexit
	END
		
---------------------  
-- PRIME VARIABLES --
---------------------
SET @rcode = 0
SET @rate = 0
SET @minamt = 0


----------------------------------------------------
-- LOOK FOR RATE BY QUOTE IN MSSurchargeOverrides --
----------------------------------------------------
if @quote is not null
	BEGIN
		
	-- test to see if an override is set up for the Surcharge code, if not then can skip the quote checks --
	select @validcnt = count(*) from dbo.bMSSurchargeOverrides with (nolock) 
	where MSCo=@msco and Quote=@quote and SurchargeCode=@SurchargeCode
	if @validcnt = 0 goto MSSurchargeCodeRates_Check

	---- only search levels 7-12 if from location is not null
	if @fromloc is not null
		BEGIN
	
		if @material is not null
			BEGIN
			---- level 24 ----
			select @rate=SurchargeRate, @minamt = MinAmt
			from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
			and MatlGroup=@matlgroup and Category=@category and Material=@material
			and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode
			IF @@rowcount <> 0 
				BEGIN
					SET @msg = 'vspMSSurchargeRateGet: 24'
					SET @rcode = 3
					goto vspexit
				END
			
			---- level 23 ----
			select @rate=SurchargeRate, @minamt = MinAmt
			from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
			and MatlGroup=@matlgroup and Category=@category and Material=@material
			and TruckType= @trucktype and UM is null and SurchargeCode=@SurchargeCode
			IF @@rowcount <> 0 
				BEGIN
					SET @msg = 'vspMSSurchargeRateGet: 23'
					SET @rcode = 3
					goto vspexit
				END
			
			---- level 22 ----
			select @rate=SurchargeRate, @minamt = MinAmt
			from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
			and MatlGroup=@matlgroup and Category=@category and Material=@material
			and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode
			IF @@rowcount <> 0 
				BEGIN
					SET @msg = 'vspMSSurchargeRateGet: 22'
					SET @rcode = 3
					goto vspexit
				END
			
			---- level 21 ----
			select @rate=SurchargeRate, @minamt = MinAmt
			from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
			and MatlGroup=@matlgroup and Category=@category and Material=@material
			and TruckType is null and UM is null and SurchargeCode=@SurchargeCode
			IF @@rowcount <> 0 
				BEGIN
					SET @msg = 'vspMSSurchargeRateGet: 21'
					SET @rcode = 3
					goto vspexit
				END
			END -- if @material is not null

		if @category is not null
			BEGIN
			-- level 20 --
			select @rate=SurchargeRate, @minamt = MinAmt
			from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
			and MatlGroup=@matlgroup and Category=@category and Material is null
			and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode
			IF @@rowcount <> 0 
				BEGIN
					SET @msg = 'vspMSSurchargeRateGet: 20'
					SET @rcode = 3
					goto vspexit
				END
			
			-- level 19 --
			select @rate=SurchargeRate, @minamt = MinAmt
			from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
			and MatlGroup=@matlgroup and Category=@category and Material is null
			and TruckType=@trucktype and UM is null and SurchargeCode=@SurchargeCode
			IF @@rowcount <> 0 
				BEGIN
					SET @msg = 'vspMSSurchargeRateGet: 19'
					SET @rcode = 3
					goto vspexit
				END

			-- level 18 --
			select @rate=SurchargeRate, @minamt = MinAmt
			from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
			and MatlGroup=@matlgroup and Category=@category and Material is null
			and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode
			IF @@rowcount <> 0 
				BEGIN
					SET @msg = 'vspMSSurchargeRateGet: 18'
					SET @rcode = 3
					goto vspexit
				END
			
			-- level 17 --
			select @rate=SurchargeRate, @minamt = MinAmt
			from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
			and MatlGroup=@matlgroup and Category=@category and Material is null
			and TruckType is null and UM is null and SurchargeCode=@SurchargeCode
			IF @@rowcount <> 0 
				BEGIN
					SET @msg = 'vspMSSurchargeRateGet: 17'
					SET @rcode = 3
					goto vspexit
				END
			END -- if @category is not null

		---- level 16 ----
		select @rate=SurchargeRate, @minamt = MinAmt
		from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
		and MatlGroup=@matlgroup and Category is null and Material is null
		and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode
		IF @@rowcount <> 0 
			BEGIN
				SET @msg = 'vspMSSurchargeRateGet: 16'
				SET @rcode = 3
				goto vspexit
			END
		
		---- level 15 ----
		select @rate=SurchargeRate, @minamt = MinAmt
		from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
		and MatlGroup=@matlgroup and Category is null and Material is null
		and TruckType=@trucktype and UM is null and SurchargeCode=@SurchargeCode
		IF @@rowcount <> 0 
			BEGIN
				SET @msg = 'vspMSSurchargeRateGet: 15'
				SET @rcode = 3
				goto vspexit
			END
			
		---- level 14 ----
		select @rate=SurchargeRate, @minamt = MinAmt
		from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
		and MatlGroup=@matlgroup and Category is null and Material is null
		and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode
		IF @@rowcount <> 0 
			BEGIN
				SET @msg = 'vspMSSurchargeRateGet: 14'
				SET @rcode = 3
				goto vspexit
			END
		
		---- level 13 ----
		select @rate=SurchargeRate, @minamt = MinAmt
		from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
		and MatlGroup=@matlgroup and Category is null and Material is null
		and TruckType is null and UM is null and SurchargeCode=@SurchargeCode
		IF @@rowcount <> 0 
			BEGIN
				SET @msg = 'vspMSSurchargeRateGet: 13'
				SET @rcode = 3
				goto vspexit
			END
		END -- if @fromloc is not null
		
	if @material is not null
		BEGIN
		---- level 12 ----
		select @rate=SurchargeRate, @minamt = MinAmt
		from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
		and MatlGroup=@matlgroup and Category=@category and Material=@material
		and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode
		IF @@rowcount <> 0 
			BEGIN
				SET @msg = 'vspMSSurchargeRateGet: 12'
				SET @rcode = 3
				goto vspexit
			END
		
		---- level 11 --
		select @rate=SurchargeRate, @minamt = MinAmt
		from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
		and MatlGroup=@matlgroup and Category=@category and Material=@material
		and TruckType=@trucktype and UM is null and SurchargeCode=@SurchargeCode
		IF @@rowcount <> 0 
			BEGIN
				SET @msg = 'vspMSSurchargeRateGet: 11'
				SET @rcode = 3
				goto vspexit
			END
			
		---- level 10 ----
		select @rate=SurchargeRate, @minamt = MinAmt
		from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
		and MatlGroup=@matlgroup and Category=@category and Material=@material
		and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode
		IF @@rowcount <> 0 
			BEGIN
				SET @msg = 'vspMSSurchargeRateGet: 10'
				SET @rcode = 3
				goto vspexit
			END
		
		---- level 9 --
		select @rate=SurchargeRate, @minamt = MinAmt
		from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
		and MatlGroup=@matlgroup and Category=@category and Material=@material
		and TruckType is null and UM is null and SurchargeCode=@SurchargeCode
		IF @@rowcount <> 0 
			BEGIN
				SET @msg = 'vspMSSurchargeRateGet:  9'
				SET @rcode = 3
				goto vspexit
			END	
		END -- if @material is not null

	if @category is not null
		BEGIN
		---- level 8 ----
		select @rate=SurchargeRate, @minamt = MinAmt
		from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
		and MatlGroup=@matlgroup and Category=@category and Material is null
		and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode
		IF @@rowcount <> 0 
			BEGIN
				SET @msg = 'vspMSSurchargeRateGet: 8'
				SET @rcode = 3
				goto vspexit
			END
		
		---- level 7 ----
		select @rate=SurchargeRate, @minamt = MinAmt
		from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
		and MatlGroup=@matlgroup and Category=@category and Material is null
		and TruckType=@trucktype and UM is null and SurchargeCode=@SurchargeCode
		IF @@rowcount <> 0 
			BEGIN
				SET @msg = 'vspMSSurchargeRateGet: 7'
				SET @rcode = 3
				goto vspexit
			END

		---- level 6 ----
		select @rate=SurchargeRate, @minamt = MinAmt
		from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
		and MatlGroup=@matlgroup and Category=@category and Material is null
		and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode
		IF @@rowcount <> 0 
			BEGIN
				SET @msg = 'vspMSSurchargeRateGet: 6'
				SET @rcode = 3
				goto vspexit
			END
		
		---- level 5 ----
		select @rate=SurchargeRate, @minamt = MinAmt
		from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
		and MatlGroup=@matlgroup and Category=@category and Material is null
		and TruckType is null and UM is null and SurchargeCode=@SurchargeCode
		IF @@rowcount <> 0 
			BEGIN
				SET @msg = 'vspMSSurchargeRateGet: 5'
				SET @rcode = 3
				goto vspexit
			END
		END -- if @category is not null


	-- level 4 --
	select @rate=SurchargeRate, @minamt = MinAmt
	from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup
	and FromLoc is null and Category is null and Material is null
	and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeRateGet: 4'
			SET @rcode = 3
			goto vspexit
		END
		
	---- level 3 ----
	select @rate=SurchargeRate, @minamt = MinAmt
	from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup
	and FromLoc is null and Category is null and Material is null
	and TruckType=@trucktype and UM is null and SurchargeCode=@SurchargeCode
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeRateGet: 3'
			SET @rcode = 3
			goto vspexit
		END
		
	---- level 2 ----
	select @rate=SurchargeRate, @minamt = MinAmt
	from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup
	and FromLoc is null and Category is null and Material is null
	and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeRateGet: 2'
			SET @rcode = 3
			goto vspexit
		END

	---- level 1 ----
	select @rate=SurchargeRate, @minamt = MinAmt
	from dbo.bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup
	and FromLoc is null and Category is null and Material is null
	and TruckType is null and UM is null and SurchargeCode=@SurchargeCode
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeRateGet: 1'
			SET @rcode = 3
			goto vspexit
		END
	END -- if @quote is not null


-------------------------------
-- GET RATES WITHOUT A QUOTE --
-------------------------------
MSSurchargeCodeRates_Check:	
	
EXEC @rcode = dbo.vspMSSurchargeCodeRate @msco, @SurchargeCode, @locgroup, @fromloc, @matlgroup,
										 @category, @material, @trucktype, @um, @zone, @saledate,
										 @rate output, @minamt output, @msg output

-----------------
-- END ROUTINE --
-----------------




		---- DAN I HAVE REMMED THE PHASE PART OUT SO THAT WE CAN REMOVE FROM TABLE. GF
   		-- look for bMSSurchargeOverrides using phase group and phase if Job Sale --
   	----	if @tojcco is not null and @phase is not null
   	----	BEGIN
   	----		-- exact match for phase --
   	----		select @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   	----		and Material=@material and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase=@phase
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: A'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   			
   	----		-- look for bMSSurchargeOverrides using valid part phase --
   	----		select Top 1 @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   	----		and Material=@material and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase like @pphase
   	----		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   	----				 UM, SurchargeCode, PhaseGroup, Phase, SurchargeRate, MinAmt
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: B'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   
   	----		-- exact match for phase and no truck type --
   	----		select @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   	----		and Material=@material and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase=@phase
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: C'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   			
   	----		-- look for bMSSurchargeOverrides using valid part phase --
   	----		select Top 1 @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   	----		and Material=@material and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase like @pphase
   	----		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   	----				 UM, SurchargeCode, PhaseGroup, Phase, SurchargeRate, MinAmt
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: D'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   
   	----		-- exact match for phase and no material --
   	----		select @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   	----		and Material is null and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase=@phase
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: E'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   			
   	----		-- look for bMSSurchargeOverrides using valid part phase --
   	----		select Top 1 @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   	----		and Material is null and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase like @pphase
   	----		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   	----				 UM, SurchargeCode, PhaseGroup, Phase, SurchargeRate, MinAmt
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: F'
				----	SET @rcode = 3
				----	goto vspexit
				----END
	   
   	----		-- exact match for phase and no material and no truck type --
   	----		select @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   	----		and Material is null and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase=@phase
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: G'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   			
   	----		-- look for bMSSurchargeOverrides using valid part phase --
   	----		select Top 1 @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category 
   	----		and Material is null and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase like @pphase
   	----		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   	----				 UM, SurchargeCode, PhaseGroup, Phase, SurchargeRate, MinAmt
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: H'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   
   	----		-- exact match for phase and no category and no material --
   	----		select @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null 
   	----		and Material is null and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase=@phase
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: I'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   			
   	----		-- look for bMSSurchargeOverrides using valid part phase --
   	----		select Top 1 @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
   	----		and Material is null and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase like @pphase
   	----		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   	----				 UM, SurchargeCode, PhaseGroup, Phase, SurchargeRate, MinAmt
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: J'
				----	SET @rcode = 3
				----	goto vspexit
				----END
	   
   	----		-- exact match for phase and no category and no material and no trucktype --
   	----		select @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null 
   	----		and Material is null and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase=@phase
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: K'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   			
   	----		-- look for bMSSurchargeOverrides using valid part phase --
   	----		select Top 1 @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
   	----		and Material is null and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase like @pphase
   	----		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   	----				 UM, SurchargeCode, PhaseGroup, Phase, SurchargeRate, MinAmt
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: L'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   
   	----		-- exact match for phase no from location --
   	----		select @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   	----		and Material=@material and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase=@phase
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: M'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   			
   	----		-- look for bMSSurchargeOverrides using valid part phase --
   	----		select Top 1 @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   	----		and Material=@material and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase like @pphase
   	----		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   	----				 UM, SurchargeCode, PhaseGroup, Phase, SurchargeRate, MinAmt
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: N'
				----	SET @rcode = 3
				----	goto vspexit
				----END
	   
   	----		-- exact match for phase and no truck type no from location --
   	----		select @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   	----		and Material=@material and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase=@phase
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: O'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   			
   	----		-- look for bMSSurchargeOverrides using valid part phase --
   	----		select Top 1 @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   	----		and Material=@material and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase like @pphase
   	----		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   	----				 UM, SurchargeCode, PhaseGroup, Phase, SurchargeRate, MinAmt
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: P'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   
   	----		-- exact match for phase and no material no from location --
   	----		select @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   	----		and Material is null and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase=@phase
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: Q'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   			
   	----		-- look for bMSSurchargeOverrides using valid part phase --
   	----		select Top 1 @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   	----		and Material is null and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase like @pphase
   	----		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   	----				 UM, SurchargeCode, PhaseGroup, Phase, SurchargeRate, MinAmt
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: R'
				----	SET @rcode = 3
				----	goto vspexit
				----END
	   
   	----		-- exact match for phase and no material and no truck type and no from location --
   	----		select @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   	----		and Material is null and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase=@phase
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: S'
				----	SET @rcode = 3
				----	goto vspexit
				----END

   	----		-- look for bMSSurchargeOverrides using valid part phase --
   	----		select Top 1 @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc is null and MatlGroup=@matlgroup and Category=@category 
   	----		and Material is null and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase like @pphase
   	----		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   	----				 UM, SurchargeCode, PhaseGroup, Phase, SurchargeRate, MinAmt
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: T'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   
   	----		-- exact match for phase and no category and no material and no from location --
   	----		select @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc is null and MatlGroup=@matlgroup and Category is null 
   	----		and Material is null and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase=@phase
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: U'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   			
   	----		-- look for bMSSurchargeOverrides using valid part phase --
   	----		select Top 1 @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc is null and MatlGroup=@matlgroup and Category is null
   	----		and Material is null and TruckType=@trucktype and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase like @pphase
   	----		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   	----				 UM, SurchargeCode, PhaseGroup, Phase, SurchargeRate, MinAmt
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: V'
				----	SET @rcode = 3
				----	goto vspexit
				----END
	   
   	----		-- exact match for phase and no category and no material and no trucktype and no from location --
   	----		select @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc is null and MatlGroup=@matlgroup and Category is null 
   	----		and Material is null and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase=@phase
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: W'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   			
   	----		-- look for bMSSurchargeOverrides using valid part phase --
   	----		select Top 1 @rate=SurchargeRate, @minamt = MinAmt
   	----		from bMSSurchargeOverrides with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup 
   	----		and FromLoc is null and MatlGroup=@matlgroup and Category is null
   	----		and Material is null and TruckType is null and UM=@um and SurchargeCode=@SurchargeCode 
   	----		and PhaseGroup=@phasegroup and Phase like @pphase
   	----		group by MSCo, Quote, LocGroup, FromLoc, MatlGroup, Category, Material, TruckType, 
   	----				 UM, SurchargeCode, PhaseGroup, Phase, SurchargeRate, MinAmt
   	----		IF @@rowcount <> 0 
				----BEGIN
				----	SET @msg = 'vspMSSurchargeRateGet: X'
				----	SET @rcode = 3
				----	goto vspexit
				----END
   			
   	----	END -- if @tojcco is not null and @phase is not null


 
   

vspexit:
	IF @rcode <> 0 SET @msg = ISNULL(@msg,'')
	RETURN @rcode

		


GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargeRateGet] TO [public]
GO
