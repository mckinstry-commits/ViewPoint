SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************/
CREATE proc [dbo].[bspMSTicTruckVal]
/*************************************
 * Created By:   GF 06/30/2000
 * Modified By:  GG 01/24/01 - initialize output parameters as null
 *				 GF 08/08/2003 - issue #22101 - change input parameter for vendor from
 *   							bVendor to varchar(10). Will then allow for nulls.
 *				 GP 04/29/2008 - #127970 added output parameter @returnvendor to default into
 *								Haul Vendor on MSTicEntry, added error messages to
 *								return default Vendor.
 *				Dan So 10/03/2008 - #130079 - Modified code to return correct Driver IF @vendor IS NOT NULL
 *				Dan So 10/27/2008 - #130789 - Re-default haul vendor when truck number change and unique.
 *				Dan So 05/22/2009 - #133679 - Correct the way unique truck and vendor work
 *
 * validates MS Vendor Truck for MSTicEntry
 *
 * INPUT PARAMETERS:
 *   @vendorgroup        Vendor Group
 *   @vendor             Vendor #
 *   @truck              Truck #
 *	 @FormMode			 Mode of the calling form
 *
 * OUTPUT PARAMETERS:
 *   @driver             Default Operator
 *   @tare               Default Tare weight
 *   @weightum           Truck weight U/M
 *   @trucktype          Default Truck Type
 *   @paycode            Default Pay Code
 *	 @returnvendor		 Default Haul Vendor
 *	 @UpdateVendor		 Flag used to notify form is Haul Vendor should be updated
 *   @msg                Truck description or error message
 *
 * RETURN CODE:
 *	0     success
 *   1     error
 **************************************/
(@vendorgroup bGroup = null, @vendor bVendor = null, @truck bTruck = null, @FormMode VARCHAR(10) = NULL,
 @driver bDesc = null output, @tare bUnits = null output, @weightum bUM = null output,
 @trucktype varchar(10) = null output, @paycode bPayCode = null output, 
 @returnvendor bVendor = null output, @UpdateVendor CHAR(1) = NULL output, 
 @msg varchar(255) = null output)

AS
SET NOCOUNT ON

	DECLARE @RowCnt int,
			@rcode int

	------------------
	-- PRIME VALUES --
	------------------
	SET	@RowCnt = 0
	SET @UpdateVendor = 'N'
	SET @rcode = 0

	-------------------------------
	-- CHECK INCOMING PARAMETERS --
	-------------------------------
	if @vendorgroup is null
		begin
			select @msg = 'Missing Vendor Group', @rcode = 1
			goto bspexit
		end

	if @truck is null
		begin
			select @msg = 'Missing Vendor Truck', @rcode = 1
			goto bspexit
		end


	--------------------
	-- ISSUE: #133679 --
	--------------------

	-------------------------
	-- GET POSSIBLE VENDOR --
	-------------------------
	-- IF MORE THAN 1 RECORD - DESC -> REMOVES THE NEED FOR TOP 1 --  
	-- SIMPLE SELECT WILL GIVE YOU THE LAST OCCURRENCE OF MULTIPLE RECORDS RETURNED --
	  SELECT @returnvendor = Vendor
	    FROM MSVT WITH (NOLOCK) 
	   WHERE VendorGroup = @vendorgroup 
	     AND Truck = @truck 
	     AND (@vendor is NULL OR Vendor = @vendor)
	ORDER BY Vendor DESC 

	SET @RowCnt = @@RowCount

	   
	--------------------------------------
	-- DOES AT LEAST ONE RECORD EXISTS? --
	--------------------------------------
	IF @vendor IS NULL
		BEGIN
			SET @msg = CASE @RowCnt 
							WHEN 0 THEN  'No Trucks Exist in Vendor Group' 
							ELSE 'FLAG' END
		END

	----------------------------------------
	-- CHECK FOR VALID VENDOR/TRUCK COMBO --
	---------------------------------------- 
	IF @vendor IS NOT NULL
		BEGIN
			IF @RowCnt = 0 
				BEGIN

					SET @msg = 'Not a Valid Vendor Truck'

					-- ONLY REPLACE VENDOR IN CHANGE MODE --
					IF UPPER(@FormMode) = 'CHANGE' 
						BEGIN
							-- A VALID TRUCK/VENDOR COMBO DOES NOT EXIST -- CHECK FOR A UNIQUE TRUCK
							SELECT @returnvendor = Vendor 
							  FROM MSVT WITH (NOLOCK) 
							 WHERE VendorGroup = @vendorgroup 
							   AND Truck = @truck

							-- 0 = NOT VALID VENDOR TRUCK
							-- 1 = VALID VENDOR TRUCK AND UNIQUE
							-- ELSE = VALID TRUCK BUT NOT UNIQUE - RETURN A CONSISTENT ERROR MESSAGE
							SET @msg = CASE @@RowCount
											WHEN 1 THEN 'FLAG' 
											ELSE 'Not a Valid Vendor Truck' END  		
						END						    
				END
		END


	-----------------------
	-- SET FLAG OR ERROR --
	-----------------------
	IF @msg IS NOT NULL
		IF @msg = 'FLAG'
			BEGIN
				SET @UpdateVendor = 'Y'
			END
		ELSE 
			BEGIN
				SET @rcode = 1
				GOTO bspexit
			END


	---------------------
	-- GET INFORMATION --
	---------------------
	-- DO NOT NEED TOP 1 =-> 1:1 ratio --
	SELECT @msg = Description, @driver = Driver, 
		   @tare = TareWght, @weightum = WghtUM,
		   @trucktype = TruckType, @paycode = PayCode
	  FROM MSVT WITH (NOLOCK) 
	 WHERE Truck = @truck 
	   AND VendorGroup = @vendorgroup 
	   AND Vendor = @returnvendor


bspexit:
	IF @rcode <> 0 SET @msg = ISNULL(@msg,'')
	RETURN @rcode



-- ************* --
-- ORIGINAL CODE --
-- ************* --

--------
--------	-- GET A RETURN CODE --
--------	SELECT	@returnvendor=Vendor
--------	  FROM  MSVT WITH (NOLOCK) 
--------	 WHERE  Truck = @truck 
--------	   AND  VendorGroup = @vendorgroup 
--------
--------	SET @RowCnt = @@rowcount
--------	
--------
--------	-- CHECK HOW MANY TRUCK/VENDOR COMBINATIONS WERE RETURNED --
--------	IF @RowCnt = 0
--------		BEGIN
--------			SET @msg = 'Not a valid Vendor Truck'
--------			SET @rcode = 1
--------			GOTO bspexit	
--------		END 
--------	ELSE
--------		BEGIN
--------			IF @RowCnt = 1
--------				BEGIN
--------					-- UNIQUE TRUCK WITHIN VENDOR GROUP --
--------					SET @UpdateVendor = 'Y'
--------					SET @vendor = NULL
--------				END
--------		END
--------
--------	---------------------
--------	-- GET INFORMATION --
--------	---------------------
--------	SELECT	@returnvendor = Vendor, @msg = Description, @driver = Driver, 
--------			@tare = TareWght, @weightum = WghtUM, @trucktype = TruckType, 
--------			@paycode = PayCode
--------	  FROM  MSVT WITH (NOLOCK) 
--------	 WHERE  Truck = @truck 
--------	   AND  VendorGroup = @vendorgroup 
--------	   AND  Vendor = ISNULL(@vendor, @returnvendor) 

--------bspexit:
--------	IF @rcode <> 0 SET @msg = ISNULL(@msg,'')
--------	RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[bspMSTicTruckVal] TO [public]
GO
