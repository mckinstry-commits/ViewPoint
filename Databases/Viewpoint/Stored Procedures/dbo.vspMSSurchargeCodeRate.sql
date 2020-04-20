SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************
* Created By:	DAN SO 11/03/2009 - Issue: #129350 
* Modified By:	GF 03/31/2010 - #129350 more levels no basis
*
* USAGE: Get SurchargeCode rate
*
* Surcharge Rate Hierarchy: The Location Group and Surcharge Code are the 2 required fields
* with the search criteria. Initially the hierarchy used for quotes will then be applied
* to the surcharge rate table when no quote override is found.
*
* SURCHARGE BASIS IS NOT USED WHEN LOOKING FOR A RATE.
*
*
* INPUT PARAMETERS:
*	@msco			MS Company
*	@SurchargeCode	MS Surcharge Code
*	@locgroup		IN Location Group
*	@fromloc		IN Location
*	@matlgroup		Material Group
*	@category		Material Category
*	@material		Material
*	@trucktype		MS Truck Type
*	@um				HQ UM
*	@zone			MS Zone
*   @saledate		MS Sale Date
*
* OUTPUT PARAMETERS:
*	@rate		SurchargeCode rate
*   @minamt		Minimum Amount associated with found SurchargeCode
*	@msg		Informational
*	@rcode		0 - Successful - no rate found
*				1 - Error
*				3 - Successful - rate found
*
*****************************************************/
--CREATE PROC [dbo].[vspMSSurchargeCodeRate]
CREATE PROC [dbo].[vspMSSurchargeCodeRate]
(@msco bCompany = null, @SurchargeCode smallint = null, @locgroup bGroup = null, 
 @fromloc bLoc = null, @matlgroup bGroup = null, @category varchar(10) = null, 
 @material bMatl = null, @trucktype varchar(10) = null, @um bUM = null,
 @zone varchar(10) = null, @SaleDate bDate = null, @rate bUnitCost = null output,
 @minamt bDollar = null output, @msg varchar(255) output)
AS
SET NOCOUNT ON

DECLARE @rcode int,
		@EffectiveDate bDate
	

---------------------
-- PRIME VARIABLES --
---------------------
SET @rcode = 0
SET @rate = 0
SET @minamt = 0

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
		
IF @matlgroup IS NULL
	BEGIN
		SELECT @msg = 'Missing Material Group', @rcode = 1
		GOTO vspexit
	END

---- verify that surcharge code exists and get the effective date
select @EffectiveDate = EffectiveDate
from dbo.bMSSurchargeCodes with (nolock)
where MSCo=@msco and SurchargeCode = @SurchargeCode
if @@rowcount = 0
	begin
	select @msg = 'Invalid Surcharge Code', @rcode = 1
	goto vspexit
	end
	
---- set a dummy effective date if we do not have one
if isnull(@EffectiveDate,'') = '' set @EffectiveDate = '01/01/1980'

------------------------------------------------
-- GET SURCHARGE BASIS FROMbMSSurchargeCodes --
------------------------------------------------
--SELECT @basis = SurchargeBasis
--  FROM bMSSurchargeCodes WITH (NOLOCK)
-- WHERE MSCo = @msco 
--   AND SurchargeCode = @SurchargeCode
   
--IF @basis IS NULL
--	BEGIN
--		SET @msg = 'Could not find Surcharge Basis'
--		SET @rcode = 1
--		goto vspexit
--	END


-------------------------------------------
-- LOOK FOR RATE in MSSurchargeCodeRates --
-------------------------------------------

---- IF FROM LOCATION EXISTS: 48-25 ----
if @fromloc is not null
	BEGIN
		
	-- level 48 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material=@material and TruckType=@trucktype and UM=@um and Zone=@zone
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A48'
			SET @rcode = 3
			goto vspexit
		END
		
	-- level 47 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material=@material and TruckType=@trucktype and UM=@um and Zone is null
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A47'
			SET @rcode = 3
			goto vspexit
		END

	-- level 46 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material=@material and TruckType=@trucktype and UM is null and Zone=@zone
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A46'
			SET @rcode = 3
			goto vspexit
		END
		
	-- level 45 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material=@material and TruckType=@trucktype and UM is null and Zone is null
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A45'
			SET @rcode = 3
			goto vspexit
		END

	-- level 44 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material=@material and TruckType is null and UM=@um and Zone=@zone
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A44'
			SET @rcode = 3
			goto vspexit
		END
		
	-- level 43 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material=@material and TruckType is null and UM=@um and Zone is null
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A43'
			SET @rcode = 3
			goto vspexit
		END

	-- level 42 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material=@material and TruckType is null and UM is null and Zone=@zone
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A42'
			SET @rcode = 3
			goto vspexit
		END
		
	-- level 41 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material=@material and TruckType is null and UM is null and Zone is null
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A41'
			SET @rcode = 3
			goto vspexit
		END

	-- level 40 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A40'
			SET @rcode = 3
			goto vspexit
		END
		
	-- level 39 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material is null and TruckType=@trucktype and UM=@um and Zone is null
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A39'
			SET @rcode = 3
			goto vspexit
		END

	-- level 38 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material is null and TruckType=@trucktype and UM is null and Zone=@zone
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A38'
			SET @rcode = 3
			goto vspexit
		END
		
	-- level 37 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material is null and TruckType=@trucktype and UM is null and Zone is null
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A37'
			SET @rcode = 3
			goto vspexit
		END

	-- level 36 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material is null and TruckType is null and UM=@um and Zone=@zone
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A36'
			SET @rcode = 3
			goto vspexit
		END
		
	-- level 35 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material is null and TruckType is null and UM=@um and Zone is null
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A35'
			SET @rcode = 3
			goto vspexit
		END

	-- level 34 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material is null and TruckType is null and UM is null and Zone=@zone
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A34'
			SET @rcode = 3
			goto vspexit
		END
		
	-- level 33 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
	and Material is null and TruckType is null and UM is null and Zone is null
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A33'
			SET @rcode = 3
			goto vspexit
		END

	-- level 32 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and Category is null
	and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A32'
			SET @rcode = 3
			goto vspexit
		END
		
	-- level 31 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and Category is null
	and Material is null and TruckType=@trucktype and UM=@um and Zone is null
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A31'
			SET @rcode = 3
			goto vspexit
		END

	-- level 30 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and Category is null
	and Material is null and TruckType=@trucktype and UM is null and Zone=@zone
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A30'
			SET @rcode = 3
			goto vspexit
		END
		
	-- level 29 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and Category is null
	and Material is null and TruckType=@trucktype and UM is null and Zone is null
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A29'
			SET @rcode = 3
			goto vspexit
		END

	-- level 28 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and Category is null
	and Material is null and TruckType is null and UM=@um and Zone=@zone
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A28'
			SET @rcode = 3
			goto vspexit
		END
		
	-- level 27 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and Category is null
	and Material is null and TruckType is null and UM=@um and Zone is null
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A27'
			SET @rcode = 3
			goto vspexit
		END

	-- level 26 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and Category is null
	and Material is null and TruckType is null and UM is null and Zone=@zone
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A26'
			SET @rcode = 3
			goto vspexit
		END
		
	-- level 25 --
	select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
		   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
	from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
	and LocGroup=@locgroup and FromLoc=@fromloc and Category is null
	and Material is null and TruckType is null and UM is null and Zone is null
	IF @@rowcount <> 0 
		BEGIN
			SET @msg = 'vspMSSurchargeCodeRate: A25'
			SET @rcode = 3
			goto vspexit
		END
		
	END ---- END FROM LOCATION



---- check levels 1-24 FROM LOCATION IS NULL
-- level 24 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material=@material and TruckType=@trucktype and UM=@um and Zone=@zone
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A24'
		SET @rcode = 3
		goto vspexit
	END
	
-- level 23 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material=@material and TruckType=@trucktype and UM=@um and Zone is null
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A23'
		SET @rcode = 3
		goto vspexit
	END

-- level 22 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material=@material and TruckType=@trucktype and UM is null and Zone=@zone
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A22'
		SET @rcode = 3
		goto vspexit
	END
	
-- level 21 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material=@material and TruckType=@trucktype and UM is null and Zone is null
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A21'
		SET @rcode = 3
		goto vspexit
	END

-- level 20 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material=@material and TruckType is null and UM=@um and Zone=@zone
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A20'
		SET @rcode = 3
		goto vspexit
	END
	
-- level 19 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material=@material and TruckType is null and UM=@um and Zone is null
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A19'
		SET @rcode = 3
		goto vspexit
	END

-- level 18 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material=@material and TruckType is null and UM is null and Zone=@zone
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A18'
		SET @rcode = 3
		goto vspexit
	END
	
-- level 17 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material=@material and TruckType is null and UM is null and Zone is null
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A17'
		SET @rcode = 3
		goto vspexit
	END

-- level 16 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A16'
		SET @rcode = 3
		goto vspexit
	END
	
-- level 15 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material is null and TruckType=@trucktype and UM=@um and Zone is null
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A15'
		SET @rcode = 3
		goto vspexit
	END

-- level 14 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material is null and TruckType=@trucktype and UM is null and Zone=@zone
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A14'
		SET @rcode = 3
		goto vspexit
	END
	
-- level 13 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material is null and TruckType=@trucktype and UM is null and Zone is null
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A13'
		SET @rcode = 3
		goto vspexit
	END

-- level 12 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material is null and TruckType is null and UM=@um and Zone=@zone
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A12'
		SET @rcode = 3
		goto vspexit
	END
	
-- level 11 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material is null and TruckType is null and UM=@um and Zone is null
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A11'
		SET @rcode = 3
		goto vspexit
	END

-- level 10 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material is null and TruckType is null and UM is null and Zone=@zone
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A10'
		SET @rcode = 3
		goto vspexit
	END
	
-- level 9 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and MatlGroup=@matlgroup and Category=@category
and Material is null and TruckType is null and UM is null and Zone is null
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A9'
		SET @rcode = 3
		goto vspexit
	END

-- level 8 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and Category is null
and Material is null and TruckType=@trucktype and UM=@um and Zone=@zone
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A8'
		SET @rcode = 3
		goto vspexit
	END
	
-- level 7 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and Category is null
and Material is null and TruckType=@trucktype and UM=@um and Zone is null
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A7'
		SET @rcode = 3
		goto vspexit
	END

-- level 6 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and Category is null
and Material is null and TruckType=@trucktype and UM is null and Zone=@zone
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A6'
		SET @rcode = 3
		goto vspexit
	END
	
-- level 5 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and Category is null
and Material is null and TruckType=@trucktype and UM is null and Zone is null
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A5'
		SET @rcode = 3
		goto vspexit
	END

-- level 4 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and Category is null
and Material is null and TruckType is null and UM=@um and Zone=@zone
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A4'
		SET @rcode = 3
		goto vspexit
	END
	
-- level 3 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and Category is null
and Material is null and TruckType is null and UM=@um and Zone is null
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A3'
		SET @rcode = 3
		goto vspexit
	END

-- level 2 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and Category is null
and Material is null and TruckType is null and UM is null and Zone=@zone
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A2'
		SET @rcode = 3
		goto vspexit
	END
	
-- level 1 --
select @rate = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldSurchargeRate else SurchargeRate end,
	   @minamt = case when isnull(@SaleDate,@EffectiveDate) < @EffectiveDate then OldMinAmt else MinAmt end
from dbo.bMSSurchargeCodeRates with (nolock) where MSCo=@msco and SurchargeCode=@SurchargeCode
and LocGroup=@locgroup and FromLoc is null and Category is null
and Material is null and TruckType is null and UM is null and Zone is null
IF @@rowcount <> 0 
	BEGIN
		SET @msg = 'vspMSSurchargeCodeRate: A1'
		SET @rcode = 3
		goto vspexit
	END






-----------------
-- END ROUTINE --
-----------------


vspexit:
	IF @rcode <> 0 SET @msg = isnull(@msg,'')
	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargeCodeRate] TO [public]
GO
