SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE  procedure [dbo].[vspEMRevTempCopy]
/*******************************************************************************
    * Created By:	GP 05/15/2008 - Issue #127494
    * Modified By:
	*
	* INPUT:	@emco
	*			@oldrevtemplate - old template name
	*			@newrevtemlpate - new template name
	*			@catrates - category rates checkbox value
	*			@equiprates - equipment rates checkbox value
	*			@newtempdesc - new template description
	*
	* OUTPUT:	@msg
	*
	* RETURN VALUE:		0 - Success
	*					1 - Failure
	*
	* TABLES:	bEMTH - Revenue Templates
	*			bEMTC - Category Rates
	*			bEMTE - Equipment Rates
	*			bEMTD - Revenue Breakdown Codes (for Category Rates)
	*			bEMTF - Revenue Breakdown Codes (for Equipment Rates)
    *
    * This stored procedure will copy EM Revenue Templates and if selected, Category Rates/Equipment Rates
	* to a new record in bEMTH, bEMTC, bEMTE, bEMTD, and bEMTF. It does standard validation and makes use 
	* of TRY CATCH for most error handling.
    * 
 ********************************************************************************/
(@emco bCompany, 
 @oldrevtemplate varchar(10), @newrevtemplate varchar(10), @catrates bYN, @equiprates bYN, @newtempdesc bDesc, 
 @msg varchar(255) output)

as
SET nocount on

DECLARE @rcode int, 
		@toprow int, 
		@rowid int,
		@BkdwnCodeDefault varchar(10)

-- Parameters for bEMTH (Revenue Templates)
DECLARE @typeflag char(1), 
		@notes varchar(255)

-- Parameters for bEMTC (Category Rates)
DECLARE @ccategory bCat, 
		@crevcode bRevCode, 
		@cemgroup bGroup, 
		@calloworideflag char(1), 
		@crate bDollar, 
		@cdiscfromstdrate bPct

-- Parameters for bEMTE (Equipment Rates)
DECLARE @eequipment bEquip, 
		@erevcode bRevCode, 
		@eemgroup bGroup, 
		@ealloworideflag char(1), 
		@erate bDollar, 
		@ediscfromstdrate bPct

-- Parameters for bEMTD (Category Breakdown Codes)
DECLARE @demgroup bGroup,
		@dcategory bCat, 
		@drevcode bRevCode, 
		@drevbdowncode varchar(10), 
		@ddescription bDesc, 
		@drate bDollar

-- Parameters for bEMTF (Equipment Breakdown Codes)
DECLARE @femgroup bGroup,
		@fequipment bEquip, 
		@frevcode bRevCode, 
		@frevbdowncode varchar(10), 
		@fdescription bDesc, 
		@frate bDollar

-----------------------------------------------------
-- SET UP 'IN MEMORY' TABLE TO HOLD CATEGORY RATES --
-----------------------------------------------------
DECLARE @CatTable TABLE 
			(RowID				int	IDENTITY,
			 EMCo				bCompany,
			 RevTemplate		varchar(10),
			 Category			bCat, 
			 RevCode			bRevCode, 
			 EMGroup			bGroup, 
			 AllowOrideFlag		char(1) null, 
			 Rate				bDollar, 
			 DiscFromStdRate	bPct)

------------------------------------------------------
-- SET UP 'IN MEMORY' TABLE TO HOLD EQUIPMENT RATES --
------------------------------------------------------
DECLARE @EquipTable TABLE 
			(RowID				int	IDENTITY,
			 EMCo				bCompany,
			 RevTemplate		varchar(10),
			 Equipment			bEquip, 
			 RevCode			bRevCode, 
			 EMGroup			bGroup, 
			 AllowOrideFlag		char(1) null, 
			 Rate				bDollar, 
			 DiscFromStdRate	bPct)
	
----------------------------------------------------------
-- SET UP 'IN MEMORY' TABLE TO HOLD CAT BREAKDOWN CODES --
----------------------------------------------------------
DECLARE @CatbdownTable TABLE 
			(RowID				int	IDENTITY,
			 EMCo				bCompany,
			 EMGroup			bGroup,
			 RevTemplate		varchar(10),
			 Category			bCat, 
			 RevCode			bRevCode, 
			 RevBdownCode		varchar(10), 
			 Description		bDesc null, 
			 Rate				bDollar)

------------------------------------------------------------
-- SET UP 'IN MEMORY' TABLE TO HOLD EQUIP BREAKDOWN CODES --
------------------------------------------------------------
DECLARE @EquipbdownTable TABLE 
			(RowID				int	IDENTITY,
			 EMCo				bCompany,
			 EMGroup			bGroup,
			 RevTemplate		varchar(10),
			 Equipment			bEquip, 
			 RevCode			bRevCode, 
			 RevBdownCode		varchar(10), 
			 Description		bDesc null, 
			 Rate				bDollar)

	SET @rcode = 0

	----------------
	-- VALIDATION --
	----------------

	------ valid Company
	IF @emco is null
	BEGIN
		SELECT @msg = 'Missing Company!', @rcode = 1
		GOTO vspexit
	END

	------ valid Revenue Template
	IF @newrevtemplate is null or @oldrevtemplate is null
	BEGIN
		SELECT @msg = 'Missing Revenue Template!', @rcode = 1
		GOTO vspexit
	END

	------ make sure To Revenue Template name does not exist already
	SELECT RevTemplate FROM bEMTH WHERE EMCo = @emco and RevTemplate = @newrevtemplate
	IF @@rowcount <> 0
   	BEGIN
   		SELECT @msg = 'Revenue Template already exists! To Revenue Template must be a new template.', @rcode = 1
   		GOTO vspexit
   	END


BEGIN TRY
	BEGIN TRANSACTION

	----------------------------------------------------------------
	-- bEMTH REVENUE TEMPLATE INSERT:							  --
	-- Select all VALUES for existing Revenue Template record and --
	-- insert new record INTO bEMTH								  --
	----------------------------------------------------------------
	IF @newtempdesc = ''
	BEGIN
		SELECT @newtempdesc = Description
		FROM bEMTH
		WHERE EMCo = @emco and RevTemplate = @oldrevtemplate
	END

	SELECT @typeflag = TypeFlag, @notes = Notes
	FROM bEMTH
	WHERE EMCo = @emco and RevTemplate = @oldrevtemplate

	INSERT bEMTH(EMCo, RevTemplate, Description, TypeFlag, Notes, CopyFlag)
	VALUES (@emco, @newrevtemplate, @newtempdesc, @typeflag, @notes, 'Y')


	----------------------------------------
	-- LOAD CATEGORY RATE DATA INTO TABLE --
	----------------------------------------
	INSERT INTO	@CatTable
	SELECT EMCo, RevTemplate, Category, RevCode, EMGroup, AllowOrideFlag, Rate, DiscFromStdRate
	FROM bEMTC
	WHERE EMCo = @emco and RevTemplate = @oldrevtemplate

	SELECT @toprow = COUNT(*) FROM @CatTable
	SET @rowid = 1

	-- Step through selected records and insert new records INTO bEMTC
	IF @catrates = 'Y'
	BEGIN
		IF @toprow <> 0
		BEGIN
			WHILE @rowid <= @toprow
			BEGIN
				SELECT @ccategory = Category, @crevcode = RevCode, @cemgroup = EMGroup, 
					@calloworideflag = AllowOrideFlag, @crate = Rate, @cdiscfromstdrate = DiscFromStdRate
				FROM @CatTable
				WHERE RowID = @rowid

				INSERT bEMTC(EMCo, RevTemplate, Category, RevCode, EMGroup, AllowOrideFlag, Rate, DiscFromStdRate)
				VALUES (@emco, @newrevtemplate, @ccategory, @crevcode, @cemgroup, @calloworideflag, @crate, @cdiscfromstdrate)

				SELECT @rowid = @rowid + 1
			END
		END
	END

	-----------------------------------------
	-- LOAD EQUIPMENT RATE DATA INTO TABLE --
	-----------------------------------------
	INSERT INTO	@EquipTable
	SELECT EMCo, RevTemplate, Equipment, RevCode, EMGroup, AllowOrideFlag, Rate, DiscFromStdRate
	FROM bEMTE
	WHERE EMCo = @emco and RevTemplate = @oldrevtemplate

	SELECT @toprow = COUNT(*) FROM @EquipTable
	SET @rowid = 1

	-- Step through selected records and insert new records INTO bEMTE
	IF @equiprates = 'Y'
	BEGIN
		IF @toprow <> 0
		BEGIN
			WHILE @rowid <= @toprow
			BEGIN
				SELECT @eequipment = Equipment, @erevcode = RevCode, @eemgroup = EMGroup, 
					@ealloworideflag = AllowOrideFlag, @erate = Rate, @ediscfromstdrate = DiscFromStdRate
				FROM @EquipTable
				WHERE RowID = @rowid

				INSERT bEMTE(EMCo, RevTemplate, Equipment, RevCode, EMGroup, AllowOrideFlag, Rate, DiscFromStdRate)
				VALUES (@emco, @newrevtemplate, @eequipment, @erevcode, @eemgroup, 
						@ealloworideflag, @erate, @ediscfromstdrate)

				SELECT @rowid = @rowid + 1
			END
		END
	END

	---------------------------------------------
	-- LOAD CAT BREAKDOWN CODE DATA INTO TABLE --
	---------------------------------------------
	INSERT INTO @CatbdownTable
	SELECT EMCo, EMGroup, RevTemplate, Category, RevCode, RevBdownCode, Description, Rate
	FROM bEMTD
	WHERE EMCo = @emco and RevTemplate = @oldrevtemplate

	SELECT @toprow = COUNT(*) FROM @CatbdownTable
	SET @rowid = 1

	-- Step through selected records and insert new records INTO bEMTD
	IF @catrates = 'Y'
	BEGIN
		IF @toprow <> 0
		BEGIN
			WHILE @rowid <= @toprow
			BEGIN
				SELECT @demgroup = EMGroup, @dcategory = Category, @drevcode = RevCode, 
					@drevbdowncode = RevBdownCode, @ddescription = Description, @drate = Rate
				FROM @CatbdownTable
				WHERE RowID = @rowid

				-- Insert bEMTD record only if duplicate record doesn't exist
				IF NOT EXISTS(SELECT TOP 1 1 FROM bEMTD WHERE EMCo = @emco and EMGroup = @demgroup  
					and RevTemplate = @newrevtemplate and Category = @dcategory and RevCode = @drevcode 
					and RevBdownCode = @drevbdowncode)
				BEGIN
					INSERT bEMTD(EMCo, EMGroup, RevTemplate, Category, RevCode, RevBdownCode, Description, Rate)
					VALUES (@emco, @demgroup, @newrevtemplate, @dcategory, @drevcode, @drevbdowncode, 
						@ddescription, @drate)
				END

				SELECT @rowid = @rowid + 1
			END
		END
	END

	-----------------------------------------------
	-- LOAD EQUIP BREAKDOWN CODE DATA INTO TABLE --
	-----------------------------------------------
	INSERT INTO @EquipbdownTable
	SELECT EMCo, EMGroup, RevTemplate, Equipment, RevCode, RevBdownCode, Description, Rate
	FROM bEMTF
	WHERE EMCo = @emco and RevTemplate = @oldrevtemplate

	SELECT @toprow = COUNT(*) FROM @EquipbdownTable
	SET @rowid = 1

	-- Step through selected records and insert new records INTO bEMTF
	IF @equiprates = 'Y'
	BEGIN
		IF @toprow <> 0
		BEGIN
			WHILE @rowid <= @toprow
			BEGIN
				SELECT @femgroup = EMGroup, @fequipment = Equipment, @frevcode = RevCode, 
					@frevbdowncode = RevBdownCode, @fdescription = Description, @frate = Rate
				FROM @EquipbdownTable
				WHERE RowID = @rowid

				-- Insert bEMTF record only if duplicate record doesn't exist
				IF NOT EXISTS(SELECT TOP 1 1 FROM bEMTF WHERE EMCo = @emco and EMGroup = @femgroup  
					and RevTemplate = @newrevtemplate and Equipment = @fequipment and RevCode = @frevcode 
					and RevBdownCode = @frevbdowncode)
				BEGIN
					INSERT bEMTF(EMCo, EMGroup, RevTemplate, Equipment, RevCode, RevBdownCode, Description, Rate)
					VALUES (@emco, @femgroup, @newrevtemplate, @fequipment, @frevcode, @frevbdowncode, 
						@fdescription, @frate)
				END

				SELECT @rowid = @rowid + 1
			END
		END
	END
		
	---- Reset CopyFlag back to 'N' after values have been inserted into bEMTC & bEMTE,
	---- the CopyFlag was used to bypass the default record inserted in each of these tables
	---- insert trigger.
	UPDATE bEMTH
	SET CopyFlag = 'N'
	WHERE EMCo = @emco and RevTemplate = @newrevtemplate

	COMMIT TRANSACTION
END TRY

BEGIN CATCH
	
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRANSACTION
	END

	SELECT @msg = 'Revenue template copy failed. ' + char(13) + char(10) + ERROR_MESSAGE()
	SET @rcode = 1
	RETURN @rcode
	
END CATCH

vspexit:
	IF @rcode<>0 SELECT @msg = isnull(@msg,'')
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMRevTempCopy] TO [public]
GO
