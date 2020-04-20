SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************
* Created By:	DAN SO 11/03/2009 - Issue: #129350 - Copied from vspMSSurchargeCodeRate
* Modified By:	
*
* Calls vspMSSurchargeCodeRate to retrieve the Surcharge Rate
******* Tried to call vspMSSurchargeCodeRate here, but you can only call
******* other functions and extended stored procedures within a function.
******* So any logic changes in vspMSSurchargeCodeRate need to be copied here.
*
* Pass:
* @msco				MS Company
* @SurchargeCode	MS Surcharge Code
* @locgroup			IN Location Group
* @fromloc			IN Location
* @matlgroup		Material Group
* @category			Material Category
* @material			Material
* @trucktype		MS Truck Type
* @um				HQ UM
* @zone				MS Zone
*
* OUTPUT PARAMETERS:
* Surcharge Rate
*
*****************************************************/
--CREATE FUNCTION [dbo].[vfMSSurchargeCodeRate]
CREATE FUNCTION [dbo].[vfMSSurchargeCodeRate]
	(@msco bCompany = null, @SurchargeCode bHaulCode = null, 
	 @locgroup bGroup = null, @fromloc bLoc = null, @matlgroup bGroup = null, 
	 @category varchar(10) = null, @material bMatl = null, @trucktype varchar(10) = null, 
	 @um bUM = null, @zone varchar(10) = null)
RETURNS bUnitCost

AS

BEGIN

	DECLARE @rate		bUnitCost,
			@minamt		bDollar,
			@basis		tinyint,
			@msg		varchar(255),
			@rcode		int

	---------------------
	-- PRIME VARIABLES --
	---------------------
	SET @rate = 0

	-----------------------------------------
	-- EXIT FUNCTION IF MISSING KEY VALUES --
	-----------------------------------------
	IF @msco IS NULL GOTO ExitFunction
	IF @SurchargeCode IS NULL GOTO ExitFunction
	IF @locgroup IS NULL GOTO ExitFunction
	IF @matlgroup IS NULL GOTO ExitFunction

	------------------------------------------------
	-- GET SURCHARGE BASIS FROM bMSSurchargeCodes --
	------------------------------------------------
	SELECT @basis = SurchargeBasis
	  FROM bMSSurchargeCodes WITH (NOLOCK)
	 WHERE MSCo = @msco 
	   AND SurchargeCode = @SurchargeCode
	   
	IF @basis IS NULL GOTO ExitFunction


	---------------------------
	-- GET RATES BASED ON UM -- 
	---------------------------
	-- 2-Material Units, 4-Haul Units --
	if @basis in (2,4)
	BEGIN

	    -- IF LOCATION EXISTS - SEARCH LEVELS 24-13 --
	    if @fromloc is not null
	    BEGIN

			if @material is not null
			BEGIN
				-- level 24 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material=@material and TruckType=@trucktype and UM=@um and Zone=@zone
   				IF  @@rowcount <> 0 GOTO ExitFunction
 
				-- level 23 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material=@material and TruckType=@trucktype and UM=@um and Zone is null
				IF  @@rowcount <> 0 GOTO ExitFunction
				
				-- level 22 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material=@material and TruckType is null and UM=@um and Zone=@zone
				IF  @@rowcount <> 0 GOTO ExitFunction
				
				-- level 21 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material=@material and TruckType is null and UM=@um and Zone is null
				IF  @@rowcount <> 0 GOTO ExitFunction
				
			END -- if @material is not null

			if @category is not null
			BEGIN
				-- level 20 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
				IF  @@rowcount <> 0 GOTO ExitFunction
				
				-- level 19 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material is null and TruckType=@trucktype and UM=@um and Zone is null
				IF  @@rowcount <> 0 GOTO ExitFunction
				
				-- level 18 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material is null and TruckType is null and UM=@um and Zone=@zone
				IF  @@rowcount <> 0 GOTO ExitFunction
				
				-- level 17 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material is null and TruckType is null and UM=@um and Zone is null
				IF  @@rowcount <> 0 GOTO ExitFunction
				
			END -- if @category is not null

			-- level 16 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
			and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 15 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
			and Material is null and TruckType=@trucktype and UM=@um and Zone is null
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 14 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
			and Material is null and TruckType is null and UM=@um and Zone=@zone
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 13 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
			and Material is null and TruckType is null and UM=@um and Zone is null
			IF  @@rowcount <> 0 GOTO ExitFunction
			
		END -- if @fromloc is not null

		if @material is not null
		BEGIN
			-- level 12 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material=@material and TruckType=@trucktype and UM=@um and Zone=@zone
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 11 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material=@material and TruckType=@trucktype and UM=@um and Zone is null
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 10 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material=@material and TruckType is null and UM=@um and Zone=@zone
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 9 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material=@material and TruckType is null and UM=@um and Zone is null
			IF  @@rowcount <> 0 GOTO ExitFunction
			
		END -- if @material is not null

		if @category is not null
		BEGIN
			-- level 8 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 7 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material is null and TruckType=@trucktype and UM=@um and Zone is null
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 6 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material is null and TruckType is null and UM=@um and Zone=@zone
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 5 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material is null and TruckType is null and UM=@um and Zone is null
			IF  @@rowcount <> 0 GOTO ExitFunction
			
		END -- if @category is not null

		-- level 4 --
		select @rate=SurchargeRate, @minamt=MinAmt
		from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
		and FromLoc is null and Category is null and Material is null
		and TruckType=@trucktype and UM=@um and Zone=@zone
		IF  @@rowcount <> 0 GOTO ExitFunction
		
		-- level 3 --
		select @rate=SurchargeRate, @minamt=MinAmt
		from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
		and FromLoc is null and Category is null and Material is null
		and TruckType=@trucktype and UM=@um and Zone is null
		IF  @@rowcount <> 0 GOTO ExitFunction
		
		-- level 2 --
		select @rate=SurchargeRate, @minamt=MinAmt
		from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
		and FromLoc is null and Category is null and Material is null
		and TruckType is null and UM=@um and Zone=@zone
		IF  @@rowcount <> 0 GOTO ExitFunction
		
		-- level 1 --
		select @rate=SurchargeRate, @minamt=MinAmt
		from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
		and FromLoc is null and Category is null and Material is null
		and TruckType is null and UM=@um and Zone is null
		
		GOTO ExitFunction
		
	END -- if @basis in (2,4)


	----------------------------
	-- GET RATES NOT UM BASED --
	----------------------------
	-- 1-Material Total, 3-Haul Total, 5-Miles, 6-Loads, 7-Fixed Amount --
	if @basis in (1,3,5,6,7)
	BEGIN
	
		-- IF LOCATION EXISTS - SEARCH LEVELS 24-13 --
		if @fromloc is not null
		BEGIN

			if @material is not null
			BEGIN
				-- level 24 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material=@material and TruckType=@trucktype and UM=@um and Zone=@zone
				IF  @@rowcount <> 0 GOTO ExitFunction 
				
				-- level 23 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material=@material and TruckType=@trucktype and UM=@um and Zone is null
				IF  @@rowcount <> 0 GOTO ExitFunction
				
				-- level 22 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material=@material and TruckType is null and UM=@um and Zone=@zone
				IF  @@rowcount <> 0 GOTO ExitFunction
				
				-- level 21 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material=@material and TruckType is null and UM=@um and Zone is null
				IF  @@rowcount <> 0 GOTO ExitFunction
				
			END -- if @material is not null

			if @category is not null
			BEGIN
				-- level 20 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
				IF  @@rowcount <> 0 GOTO ExitFunction
				
				-- level 19 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material is null and TruckType=@trucktype and UM=@um and Zone is null
				IF  @@rowcount <> 0 GOTO ExitFunction
				
				-- level 18 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material is null and TruckType is null and UM=@um and Zone=@zone
				IF  @@rowcount <> 0 GOTO ExitFunction
				
				-- level 17 --
				select @rate=SurchargeRate, @minamt=MinAmt
				from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
				and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
				and Material is null and TruckType is null and UM=@um and Zone is null
				IF  @@rowcount <> 0 GOTO ExitFunction
				
			END -- if @category is not null

			-- level 16 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
			and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 15 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
			and Material is null and TruckType=@trucktype and UM=@um and Zone is null
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 14 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
			and Material is null and TruckType is null and UM=@um and Zone=@zone
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 13 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc=@fromloc and MatlGroup=@matlgroup and Category is null
			and Material is null and TruckType is null and UM=@um and Zone is null
			IF  @@rowcount <> 0 GOTO ExitFunction
			
		END -- if @fromloc is not null

		if @material is not null
		BEGIN
			-- level 12 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material=@material and TruckType=@trucktype and UM=@um and Zone=@zone
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 11 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material=@material and TruckType=@trucktype and UM=@um and Zone is null
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 10 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material=@material and TruckType is null and UM=@um and Zone=@zone
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 9 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material=@material and TruckType is null and UM=@um and Zone is null
			IF  @@rowcount <> 0 GOTO ExitFunction
			
		END -- if @material is not null

		if @category is not null
		BEGIN
			-- level 8 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 7 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material is null and TruckType=@trucktype and UM=@um and Zone is null
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 6 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material is null and TruckType is null and UM=@um and Zone=@zone
			IF  @@rowcount <> 0 GOTO ExitFunction
			
			-- level 5 --
			select @rate=SurchargeRate, @minamt=MinAmt
			from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
			and FromLoc is null and MatlGroup=@matlgroup and Category=@category
			and Material is null and TruckType is null and UM=@um and Zone is null
			IF  @@rowcount <> 0 GOTO ExitFunction
			
		END -- if @category is not null

		-- level 4 --
		select @rate=SurchargeRate, @minamt=MinAmt
		from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
		and FromLoc is null and Category is null and Material is null
		and TruckType=@trucktype and UM=@um and Zone=@zone
		IF  @@rowcount <> 0 GOTO ExitFunction
		
		-- level 3 --
		select @rate=SurchargeRate, @minamt=MinAmt
		from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
		and FromLoc is null and Category is null and Material is null
		and TruckType=@trucktype and UM=@um and Zone is null
		IF  @@rowcount <> 0 GOTO ExitFunction
		
		-- level 2 --
		select @rate=SurchargeRate, @minamt=MinAmt
		from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
		and FromLoc is null and Category is null and Material is null
		and TruckType is null and UM=@um and Zone=@zone
		IF  @@rowcount <> 0 GOTO ExitFunction
		
		-- level 1 --
		select @rate=SurchargeRate, @minamt=MinAmt
		from bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode and LocGroup=@locgroup
		and FromLoc is null and Category is null and Material is null
		and TruckType is null and UM=@um and Zone is null
		
		GOTO ExitFunction
		
	END -- if @basis in (1,3,5,6,7)

	
ExitFunction:
	RETURN @rate
	
	
END

GO
GRANT EXECUTE ON  [dbo].[vfMSSurchargeCodeRate] TO [public]
GO
