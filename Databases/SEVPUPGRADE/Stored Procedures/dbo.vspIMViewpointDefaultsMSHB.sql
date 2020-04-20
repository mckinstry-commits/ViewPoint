SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspIMViewpointDefaultsMSHB]
/***********************************************************
* CREATED BY: Dan So 05/04/09 - Issue: #126811
* MODIFIED BY: 
*	
*
* Usage:
*	Used by Imports to create values for needed or missing
*      data based upon Bidtek default rules.
*
* Input params:
*	@ImportId	Import Identifier
*	@ImportTemplate	Import ImportTemplate
*
* Output params:
*	@msg		error message
*
* Return code:
*	0 = success, 1 = failure
************************************************************/
    
(@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), 
 @Form varchar(20), @rectype varchar(30), @msg varchar(120) output)

AS

	SET NOCOUNT ON

	DECLARE
		@rcode int, @Temprcode int, @desc varchar(120), @ImportCompleted bYN,

		-- Variables --
		@Co				bCompany,  @Mth				bMonth,		 @BatchId		bBatchID, @BatchSeq		int,
		@BatchTransType	CHAR(1),   @FreightBill		VARCHAR(10), @SaleDate		bDate,	  @HaulerType	CHAR(1),
		@EMCo			bCompany,  @EMGroup			bGroup,		 @Equipment		bEquip,   @PRCo			bCompany,
		@Employee		bEmployee, @HaulVendor		bVendor,	 @VendorGroup	bGroup,   @Truck		bTruck,
		@Driver			bDesc,	   @HaulTrans		bTrans,

		-- ID --
		@CoID				int, @MthID				int, @BatchIdID			int, @BatchSeqID		int,
		@BatchTransTypeID	int, @FreightBillID		int, @SaleDateID		int, @HaulerTypeID		int,
		@EMCoID				int, @EMGroupID			int, @EquipmentID		int, @PRCoID			int,
		@EmployeeID			int, @HaulVendorID		int, @VendorGroupID		int, @TruckID			int,
		@DriverID			int, @HaulTransID		int,	

		-- Clear Data ID --
		@cdCoID				int, @cdMthID			int, @cdBatchIdID		int, @cdBatchSeqID		int,
		@cdBatchTransTypeID	int, @cdFreightBillID	int, @cdSaleDateID		int, @cdHaulerTypeID	int,
		@cdEMCoID			int, @cdEMGroupID		int, @cdEquipmentID		int, @cdPRCoID			int,
		@cdEmployeeID		int, @cdHaulVendorID	int, @cdVendorGroupID	int, @cdTruckID			int,
		@cdDriverID			int, @cdHaulTransID		int,

		-- Value Exists --
		@ynCo				bYN, @ynMth				bYN, @ynBatchId			bYN, @ynBatchSeq	bYN,
		@ynBatchTransType	bYN, @ynFreightBill		bYN, @ynSaleDate		bYN, @ynHaulerType	bYN,
		@ynEMCo				bYN, @ynEMGroup			bYN, @ynEquipment		bYN, @ynPRCo		bYN,
		@ynEmployee			bYN, @ynHaulVendor		bYN, @ynVendorGroup		bYN, @ynTruck		bYN,
		@ynDriver			bYN, @ynHaulTrans		bYN,		
		
		-- Overwrite --
		@owCo				bYN, @owMth				bYN, @owBatchId			bYN, @owBatchSeq	bYN,
		@owBatchTransType	bYN, @owFreightBill		bYN, @owSaleDate		bYN, @owHaulerType	bYN,
		@owEMCo				bYN, @owEMGroup			bYN, @owEquipment		bYN, @owPRCo		bYN,
		@owEmployee			bYN, @owHaulVendor		bYN, @owVendorGroup		bYN, @owTruck		bYN,
		@owDriver			bYN, @owHaulTrans		bYN,

		-- IsEmpty --
		@IsEmptyCo				bYN, @IsEmptyMth			bYN, @IsEmptyBatchId		bYN, @IsEmptyBatchSeq	bYN,
		@IsEmptyBatchTransType	bYN, @IsEmptyHaulTrans		bYN, @IsEmptyFreightBill	bYN, @IsEmptySaleDate	bYN,
		@IsEmptyHaulerType		bYN, @IsEmptyVendorGroup	bYN, @IsEmptyHaulVendor		bYN, @IsEmptyTruck		bYN,
		@IsEmptyDriver			bYN, @IsEmptyEMCo			bYN, @IsEmptyEquipment		bYN, @IsEmptyEMGroup	bYN,
		@IsEmptyPRCo			bYN, @IsEmptyEmployee		bYN,

		-- Cusor Variables --
		@curRecSeq	int,		  @curTableName	VARCHAR(20),  @curCol		VARCHAR(30), @curUploadVal	VARCHAR(60),
		@curIdent	int,		  @curImportID	VARCHAR(10),  @curSeq		int,		 @curIdentifier	int,
		@curCurSeq	int,		  @curAllowNull	int,		  @curError		int,		 @curSQL		VARCHAR(255),
		@curValList VARCHAR(255), @curColList	VARCHAR(255), @curComplete  int,		 @curCounter	int, 
		@curRecord	int,		  @curOldRecSeq int,		  @curOpen		int		


	---------------------
	-- PRIME VARIABLES --
	---------------------
	SET @rcode = 0
	SET @curOpen = 0
	SET @ImportCompleted = 'N'

	SELECT	@ynCo				= 'N', @ynMth			= 'N', @ynBatchId		= 'N', @ynBatchSeq		= 'N', 
			@ynBatchTransType	= 'N', @ynFreightBill	= 'N', @ynSaleDate		= 'N', @ynHaulerType	= 'N', 
			@ynEMCo				= 'N', @ynEMGroup		= 'N', @ynEquipment		= 'N', @ynPRCo			= 'N', 
			@ynEmployee			= 'N', @ynHaulVendor	= 'N', @ynVendorGroup	= 'N', @ynTruck			= 'N', 
			@ynDriver			= 'N', @ynHaulTrans		= 'N'

	SELECT 	@IsEmptyCo				= 'N', @IsEmptyMth			= 'N', @IsEmptyBatchId		= 'N', @IsEmptyBatchSeq	= 'N', 
			@IsEmptyBatchTransType	= 'N', @IsEmptyHaulTrans	= 'N', @IsEmptyFreightBill	= 'N', @IsEmptySaleDate	= 'N', 
			@IsEmptyHaulerType		= 'N', @IsEmptyVendorGroup	= 'N', @IsEmptyHaulVendor	= 'N', @IsEmptyTruck	= 'N', 
			@IsEmptyDriver			= 'N', @IsEmptyEMCo			= 'N', @IsEmptyEquipment	= 'N', @IsEmptyEMGroup	= 'N', 
			@IsEmptyPRCo			= 'N', @IsEmptyEmployee		= 'N'

    -------------------------
    -- REQUIRED PARAMETERS --
	-------------------------
	IF @ImportId IS NULL
		BEGIN
			SET @desc = 'Missing ImportId.' 
			SET @rcode = 1
			GOTO vspExit
		END

    IF @ImportTemplate IS NULL
		BEGIN
			SET @desc = 'Missing ImportTemplate.'
			SET @rcode = 1
			GOTO vspExit
		END
    
    IF @Form IS NULL
		BEGIN
			SET @desc = 'Missing Form.'
			SET @rcode = 1
			GOTO vspExit
		END

	----------------------------------
	-- CHECK FOR ANY DEFAULTS EXIST --
	----------------------------------
	SELECT TOP 1 1
	  FROM IMTD	
	 WHERE IMTD.ImportTemplate = @ImportTemplate 
	   AND IMTD.DefaultValue = '[Bidtek]'
	   AND IMTD.RecordType = @rectype

	IF @@ROWCOUNT = 0
		BEGIN
			SET @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.'
			GOTO vspExit
		END

	------------------
	-- OVERWRITE YN --
	------------------		
	SET @owCo				= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype)
	SET @owBatchTransType	= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype)
	SET @owFreightBill		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FreightBill', @rectype)
	SET @owSaleDate			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SaleDate', @rectype)
	SET @owHaulerType		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulerType', @rectype)
	SET @owEMCo				= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMCo', @rectype)
	SET @owEMGroup			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMGroup', @rectype)
	SET @owEquipment		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Equipment', @rectype)
	SET @owPRCo				= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRCo', @rectype)
	SET @owEmployee			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Employee', @rectype)
	SET @owHaulVendor		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulVendor', @rectype)
	SET @owVendorGroup		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype)
	SET @owTruck			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Truck', @rectype)
	SET @owDriver			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Driver', @rectype)
	SET @owHaulTrans		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulTrans', @rectype)


	-- ************************************************************************************ --
	--																						--
	--			RECORDS ALREADY EXIST IN THE IMWE TABLE FROM THE IMPORTED TEXTFILE			--
	--																						--
	--			All records with the same RecordSeq represent a single import record		--
	--																						--
	-- ************************************************************************************ --

	------------------
	-- SET DEFAULTS -- VALUES DEFAULTED ON NEW RECORD --
	------------------
    -- COMPANY --
	-------------
	SET @CoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', @rectype, 'Y')

	IF ISNULL(@CoID, 0)<> 0 
		IF (ISNULL(@owCo, 'Y') = 'Y')
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = @Company
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @CoID 
				   AND IMWE.RecordType = @rectype
			 END
		ELSE
     		BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = @Company
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @CoID 
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			 END

	----------------------
    -- BATCH TRANS TYPE --
	----------------------
	SET @BatchTransTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BatchTransType', @rectype, 'Y')

	IF ISNULL(@BatchTransTypeID, 0)<> 0 
		IF ISNULL(@owBatchTransType, 'Y') = 'Y'
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'A'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @BatchTransTypeID
				   AND IMWE.RecordType = @rectype
			END
		ELSE
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'A'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @BatchTransTypeID
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			END
        
	---------------
	-- SALE DATE --
	---------------
	SET @SaleDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SaleDate', @rectype, 'Y')

	IF ISNULL(@SaleDateID, 0)<> 0 
		IF ISNULL(@owSaleDate, 'Y') = 'Y'
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = CONVERT(varchar(20), GETDATE(), 101)
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @SaleDateID
				   AND IMWE.RecordType = @rectype
			END
		ELSE
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = CONVERT(varchar(20), GETDATE(), 101)
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @SaleDateID
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			END
               
	-----------------
	-- HAULER TYPE --
	-----------------
	SET @HaulerTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulerType', @rectype, 'Y')

	IF ISNULL(@HaulerTypeID, 0)<> 0 
		IF ISNULL(@owHaulerType, 'Y') = 'Y'
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'E'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @HaulerTypeID
				   AND IMWE.RecordType = @rectype
			END
		ELSE
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'E'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @HaulerTypeID
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			END


	------------------------------------------------
	-- GET COLUMN IDENTIFIERS FOR THOSE COLUMNS   --
	-- THAT MIGHT BE DEFAULTED BUT WHOSE DEFAULTS --
	-- COULD BE UNIQUE FOR EACH IMPORTED RECORD	  --	 
	------------------------------------------------  
	SET @FreightBillID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FreightBill', @rectype, 'Y');	
	SET @EMCoID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EMCo', @rectype, 'Y');
	SET @EMGroupID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EMGroup', @rectype, 'Y');
	SET @EquipmentID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Equipment', @rectype, 'Y');
	SET @PRCoID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PRCo', @rectype, 'Y');
	SET @EmployeeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Employee', @rectype, 'Y');
	SET @HaulVendorID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulVendor', @rectype, 'Y');
	SET @VendorGroupID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'Y');
	SET @TruckID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Truck', @rectype, 'Y');
	SET @DriverID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Driver', @rectype, 'Y');
	SET @HaulTransID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulTrans', @rectype, 'Y');

	-------------------------------------------------
	-- GET COLUMN IDENTIFIERS TO BE USED TO CLEAR  --
	-- DATA AT THE BOTTOM OF THE ROUTINE - THIS IS --
	-- NEEDED JUST IN CASE DATA WAS UPLOADED AND   --
	-- NEEDS TO BE CLEARED IN CERTAIN CASES - I    --
	-- INCLUDED ALL OF THE DETAIL IDs JUST IN CASE --
	-- THEY ARE NEEDED IN THE FUTUREFOR EASE       --
	------------------------------------------------- 
	SET @cdCoID				= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', @rectype, 'N')
	SET @cdBatchTransTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BatchTransType', @rectype, 'N')
	SET @cdSaleDateID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SaleDate', @rectype, 'N')
	SET @cdHaulerTypeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulerType', @rectype, 'N')
	SET @cdFreightBillID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FreightBill', @rectype, 'N');	
	SET @cdEMCoID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EMCo', @rectype, 'N');
	SET @cdEMGroupID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EMGroup', @rectype, 'N');
	SET @cdEquipmentID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Equipment', @rectype, 'N');
	SET @cdPRCoID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PRCo', @rectype, 'N');
	SET @cdEmployeeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Employee', @rectype, 'N');
	SET @cdHaulVendorID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulVendor', @rectype, 'N');
	SET @cdVendorGroupID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'N');
	SET @cdTruckID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Truck', @rectype, 'N');
	SET @cdDriverID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Driver', @rectype, 'N');
	SET @cdHaulTransID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulTrans', @rectype, 'N');

	------------------------------------------
	-- BEGIN THE DEFAULT GENERATING PROCESS --
	-- FOR THOSE COLUMNS WHOSE DEFAULT IS	--
	-- UNIQUE FOR EACH IMPORTED RECORD		--
	------------------------------------------
	DECLARE curWorkEdit CURSOR LOCAL FAST_FORWARD FOR
		SELECT IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
		  FROM IMWE INNER JOIN DDUD 
			ON IMWE.Identifier = DDUD.Identifier 
		   AND DDUD.Form = IMWE.Form
		 WHERE IMWE.ImportId = @ImportId 
		   AND IMWE.ImportTemplate = @ImportTemplate 
		   AND IMWE.Form = @Form 
		   AND IMWE.RecordType = @rectype
	  ORDER BY IMWE.RecordSeq, IMWE.Identifier
    
	-- OPEN CUSOR AND GET FIRST RECORD --
	OPEN curWorkEdit
	SET @curOpen = 1

	FETCH NEXT FROM curWorkEdit INTO @curRecSeq, @curIdent, @curTableName, @curCol, @curUploadVal
    
	SELECT @curCurSeq = @curRecSeq, @curComplete = 0, @curCounter = 1

	-------------------------------------------------------------------------------------------------------------
	-- For each imported record:																			   --
	-- (Each imported record has multiple records in the IMWE table representing columns of the import record) --
	-- Cursor will cycle through each column of an imported record and set the imported value into a variable  --
	-- that could be used during the defaulting process later if desired.  It may not be used at all.		   --
	-------------------------------------------------------------------------------------------------------------	

	-- WHILE CURSOR IS NOT EMPTY --
	WHILE @ImportCompleted = 'N'
		BEGIN

			-- NEW IMPORT SEQ --
			IF @curRecSeq = @curCurSeq AND @@FETCH_STATUS = 0
				BEGIN
					
					------------------------------------------------
					-- GET UPLOADED VALUES FOR THIS IMPORT RECORD --
					------------------------------------------------
					IF @curCol = 'Co' 
						IF @curUploadVal IS NULL SET @IsEmptyCo = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @Co = CONVERT(int, @curUploadVal)

					IF @curCol = 'Mth' 
						IF @curUploadVal IS NULL SET @IsEmptyMth = 'Y'
						ELSE IF ISDATE(@curUploadVal) = 1 SET @Mth = CONVERT(smalldatetime, @curUploadVal)

					IF @curCol = 'BatchTransType' 
						IF @curUploadVal IS NULL SET @IsEmptyBatchTransType = 'Y'
						ELSE SET @BatchTransType = @curUploadVal

					IF @curCol = 'FreightBill' 
						IF @curUploadVal IS NULL SET @IsEmptyFreightBill = 'Y'
						ELSE SET @FreightBill = @curUploadVal

					IF @curCol = 'SaleDate' 
						IF @curUploadVal IS NULL SET @IsEmptySaleDate = 'Y'
						ELSE IF ISDATE(@curUploadVal) = 1 SET @SaleDate = CONVERT(smalldatetime, @curUploadVal)

					IF @curCol = 'HaulerType' 
						IF @curUploadVal IS NULL SET @IsEmptyHaulerType = 'Y'
						ELSE SET @HaulerType = @curUploadVal

					IF @curCol = 'EMCo' 
						IF @curUploadVal IS NULL SET @IsEmptyEMCo = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @EMCo = CONVERT(int, @curUploadVal)

					IF @curCol = 'EMGroup' 
						IF @curUploadVal IS NULL SET @IsEmptyEMGroup = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @EMGroup = CONVERT(int, @curUploadVal)

					IF @curCol = 'Equipment' 
						IF @curUploadVal IS NULL SET @IsEmptyEquipment = 'Y'
						ELSE SET @Equipment = @curUploadVal

					IF @curCol = 'PRCo' 
						IF @curUploadVal IS NULL SET @IsEmptyPRCo = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @PRCo = CONVERT(int, @curUploadVal)

					IF @curCol = 'Employee' 
						IF @curUploadVal IS NULL SET @IsEmptyEmployee = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @Employee = CONVERT(int, @curUploadVal)

					IF @curCol = 'HaulVendor' 
						IF @curUploadVal IS NULL SET @IsEmptyHaulVendor = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @HaulVendor = CONVERT(int, @curUploadVal)

					IF @curCol = 'VendorGroup' 
						IF @curUploadVal IS NULL SET @IsEmptyVendorGroup = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @VendorGroup = CONVERT(int, @curUploadVal)

					IF @curCol = 'Truck' 
						IF @curUploadVal IS NULL SET @IsEmptyTruck = 'Y'
						ELSE SET @Truck = @curUploadVal

					IF @curCol = 'Driver' 
						IF @curUploadVal IS NULL SET @IsEmptyDriver = 'Y'
						ELSE SET @Driver = @curUploadVal

					IF @curCol = 'HaulTrans' 
						IF @curUploadVal IS NULL SET @IsEmptyHaulTrans = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @HaulTrans = CONVERT(int, @curUploadVal)


					-- GET NEXT RECORD --
					FETCH NEXT FROM curWorkEdit INTO @curRecSeq, @curIdent, @curTableName, @curCol, @curUploadVal

				END --IF @curRecSeq = @curCurSeq
			ELSE 
				BEGIN 
					-------------------------------------------
					-- SET DEFAULT VALUES OF PREVIOUS RECORD --
					-------------------------------------------

					-- FREIGHT BILL --
					IF @FreightBillID <> 0 AND (@owFreightBill = 'Y' OR @IsEmptyFreightBill = 'Y')
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = @FreightBill
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @FreightBillID 
							   AND IMWE.RecordType = @rectype
						END
					
					-- SALES DATE --
					IF @SaleDateID <> 0 AND (@owSaleDate = 'Y' OR @IsEmptySaleDate = 'Y')
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = @SaleDate
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @SaleDateID 
							   AND IMWE.RecordType = @rectype
						END				

					-- VendorGroup --
					IF @VendorGroupID <> 0 AND (@owVendorGroup = 'Y' OR @IsEmptyVendorGroup = 'Y')
						BEGIN

							SELECT @VendorGroup = h.VendorGroup
							  FROM bHQCO h WITH (NOLOCK)
							  JOIN bMSCO m with (NOLOCK) 
								ON m.APCo = h.HQCo
							 WHERE m.MSCo = @Co

							UPDATE IMWE
							   SET IMWE.UploadVal = @VendorGroup
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @VendorGroupID 
							   AND IMWE.RecordType = @rectype
						END	
					
					-- HAULER TYPE --
					-- HAULER TYPE: E -> EMCo, Equipment, PRCo, and Employee ARE ACTIVE --
					-- HAULER TYPE: H -> HaulVendor, Truck, and Driver ARE ACTIVE --
					IF @HaulerTypeID <> 0 AND (@owHaulerType = 'Y' OR @IsEmptyHaulerType = 'Y')
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = @HaulerType
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @HaulerTypeID 
							   AND IMWE.RecordType = @rectype
						END 

						IF @HaulerType = 'E' -- EQUIPMENT --
							BEGIN

								-- EMCo --
								IF @EMCoID <> 0 AND (@owEMCo = 'Y' OR @IsEmptyEMCo = 'Y')
									BEGIN
										UPDATE IMWE
										   SET IMWE.UploadVal = @EMCo
										 WHERE IMWE.ImportTemplate = @ImportTemplate 
										   AND IMWE.ImportId = @ImportId 
										   AND IMWE.RecordSeq = @curCurSeq
										   AND IMWE.Identifier = @EMCoID 
										   AND IMWE.RecordType = @rectype
									END

								-- EMGroup -- NULLS -> @msg
								IF @EMGroupID <> 0 AND (@EMCo IS NOT NULL) AND (@owEMGroup = 'Y' OR @IsEmptyEMGroup = 'Y')
									BEGIN
										EXEC @Temprcode = dbo.bspEMGroupGet @EMCo, @EMGroup OUTPUT, NULL
    
										UPDATE IMWE
										   SET IMWE.UploadVal = @EMGroup
										 WHERE IMWE.ImportTemplate = @ImportTemplate 
										   AND IMWE.ImportId = @ImportId 
										   AND IMWE.RecordSeq = @curCurSeq
										   AND IMWE.Identifier = @EMGroupID 
										   AND IMWE.RecordType = @rectype
									END

								-- Equipment --
								IF @EquipmentID <> 0 AND (@owEquipment = 'Y' OR @IsEmptyEquipment = 'Y')
									BEGIN
										UPDATE IMWE
										   SET IMWE.UploadVal = @Equipment
										 WHERE IMWE.ImportTemplate = @ImportTemplate 
										   AND IMWE.ImportId = @ImportId 
										   AND IMWE.RecordSeq = @curCurSeq
										   AND IMWE.Identifier = @EquipmentID 
										   AND IMWE.RecordType = @rectype
									END

								-- PRCo --
								IF @PRCoID <> 0 AND (@owPRCo = 'Y' OR @IsEmptyPRCo = 'Y')
									BEGIN
										UPDATE IMWE
										   SET IMWE.UploadVal = @PRCo
										 WHERE IMWE.ImportTemplate = @ImportTemplate 
										   AND IMWE.ImportId = @ImportId 
										   AND IMWE.RecordSeq = @curCurSeq
										   AND IMWE.Identifier = @PRCoID 
										   AND IMWE.RecordType = @rectype
									END

								-- Employee --
								IF @EmployeeID <> 0 AND (@owEmployee = 'Y' OR @IsEmptyEmployee = 'Y')
									BEGIN
										UPDATE IMWE
										   SET IMWE.UploadVal = @Employee
										 WHERE IMWE.ImportTemplate = @ImportTemplate 
										   AND IMWE.ImportId = @ImportId 
										   AND IMWE.RecordSeq = @curCurSeq
										   AND IMWE.Identifier = @EmployeeID 
										   AND IMWE.RecordType = @rectype
									END

							END --IF @HaulerType = 'E'

						ELSE IF @HaulerType = 'H' -- HAUL --
							BEGIN

								-- HaulVendor --
								IF @HaulVendorID <> 0 AND (@owHaulVendor = 'Y' OR @IsEmptyHaulVendor = 'Y')
									BEGIN
										UPDATE IMWE
										   SET IMWE.UploadVal = @HaulVendor
										 WHERE IMWE.ImportTemplate = @ImportTemplate 
										   AND IMWE.ImportId = @ImportId 
										   AND IMWE.RecordSeq = @curCurSeq
										   AND IMWE.Identifier = @HaulVendorID 
										   AND IMWE.RecordType = @rectype
									END

								-- Truck --
								IF @TruckID <> 0 AND (@owTruck = 'Y' OR @IsEmptyTruck = 'Y')
									BEGIN
										UPDATE IMWE
										   SET IMWE.UploadVal = @Truck
										 WHERE IMWE.ImportTemplate = @ImportTemplate 
										   AND IMWE.ImportId = @ImportId 
										   AND IMWE.RecordSeq = @curCurSeq
										   AND IMWE.Identifier = @TruckID 
										   AND IMWE.RecordType = @rectype
									END

								-- Driver --
								IF @DriverID <> 0 AND (@owDriver = 'Y' OR @IsEmptyDriver = 'Y')
									BEGIN

										-- GET DRIVER NAME --
										EXEC @rcode = dbo.bspMSTicTruckVal @VendorGroup, @HaulVendor, @Truck, 'ADD',
															@Driver output, null, null, null, null, null, null, null

										UPDATE IMWE
										   SET IMWE.UploadVal = @Driver
										 WHERE IMWE.ImportTemplate = @ImportTemplate 
										   AND IMWE.ImportId = @ImportId 
										   AND IMWE.RecordSeq = @curCurSeq
										   AND IMWE.Identifier = @DriverID 
										   AND IMWE.RecordType = @rectype
									END

							END --IF @HaulerType = 'H'


					-- SET CURRENT SEQUENCE --
					SET @curCurSeq = @curRecSeq

					IF @@FETCH_STATUS <> 0 SET @ImportCompleted = 'Y'

				END	--IF @curRecSeq = @curCurSeq	

		END --Cursor Loop


	-- CLEAN UP CURSOR --
	CLOSE curWorkEdit
	DEALLOCATE curWorkEdit
	SET @curOpen = 0
    

--------------------
-- ERROR HANDLING --
--------------------
vspExit:
	
	-- CLEAN UP CURSOR --
	IF @curOpen = 1
		BEGIN
			CLOSE curWorkEdit
			DEALLOCATE curWorkEdit
		END

	-- SET ERROR MESSAGE AND RETURN --
    SET @msg = ISNULL(@desc, 'Header ') + char(13) + char(13) + '[vspIMViewpointDefaultsMSHB]'
    RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsMSHB] TO [public]
GO
