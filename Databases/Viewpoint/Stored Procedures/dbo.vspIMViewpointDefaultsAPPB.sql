SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspIMViewpointDefaultsAPPB]
/***********************************************************
* CREATED BY: MV 08/07/09 - Issue: #134927
* MODIFIED BY: GF 09/15/2010 - issue #141031 changed to use vfDateOnly and vfDateOnlyMonth
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
		@Co				bCompany,  @Mth				varchar(10),@BatchId		bBatchID,	@BatchSeq		int,
		@CMCo			bCompany,  @CMAcct			bCMAcct,	@PayMethod		CHAR(1),	@ChkType		CHAR(1),
		@CMRef			bCMRef,	   @CMRefSeq		int,		@EFTSeq			int,		@PaidDate		bDate,
		@VendorGroup	bGroup,	   @Vendor			bVendor,	@Amount			bDollar,	@VoidYN			bYN,
		@OverflowYN		bYN,	   @SeparatePayYN	bYN,		@PayOverrideYN	bYN,		@AmtToPay		bDollar,			

		-- ID --
		@CoID			int,	@MthID			int,		@BatchIdID		int,	@BatchSeqID		int,
		@CMCoID			int,	@CMAcctID		int,		@PayMethodID	int,	@ChkTypeID		int,
		@CMRefID		int,	@CMRefSeqID		int,		@EFTSeqID		int,	@PaidDateID		int,
		@VendorGroupID	int,	@VendorID		int,		@AmountID		int,	@VoidYNID		int,
		@OverflowYNID	int,	@SeparatePayYNID int,		@PayOverrideYNID int,	@RetainageID	int,
		@AmtToPayID		int,

		-- Value Exists --
		@ynCo			bYN,	@ynMth			bYN,	@ynBatchId		bYN,	@ynBatchSeq		bYN,
		@ynCMCo			bYN,	@ynCMAcct		bYN,	@ynPayMethod	bYN,	@ynChkType		bYN,
		@ynCMRef		bYN,	@ynCMRefSeq		bYN,	@ynEFTSeq		bYN,	@ynPaidDate		bYN,
		@ynVendorGroup	bYN,	@ynVendor		bYN,	@ynAmount		bYN,	@ynVoidYN		bYN,
		@ynOverflowYN	bYN,	@ynSeparatePayYN bYN,	@ynPayOverrideYN bYN,
		
		-- Overwrite --
		@owCo			bYN,	@owMth			bYN,	@owBatchId		bYN,	@owBatchSeq		bYN,
		@owCMCo			bYN,	@owCMAcct		bYN,	@owPayMethod	bYN,	@owChkType		bYN,
		@owCMRef		bYN,	@owCMRefSeq		bYN,	@owEFTSeq		bYN,	@owPaidDate		bYN,
		@owVendorGroup	bYN,	@owVendor		bYN,	@owAmount		bYN,	@owVoidYN		bYN,
		@owOverflowYN	bYN,	@owSeparatePayYN bYN,	@owPayOverrideYN bYN,

		-- IsEmpty --
		@IsEmptyCo			bYN,	@IsEmptyMth			bYN,	@IsEmptyBatchId		bYN,	@IsEmptyBatchSeq	bYN,
		@IsEmptyCMCo		bYN,	@IsEmptyCMAcct		bYN,	@IsEmptyPayMethod	bYN,	@IsEmptyChkType		bYN,
		@IsEmptyCMRef		bYN,	@IsEmptyCMRefSeq	bYN,	@IsEmptyEFTSeq		bYN,	@IsEmptyPaidDate	bYN,
		@IsEmptyVendorGroup	bYN,	@IsEmptyVendor		bYN,	@IsEmptyAmount		bYN,	@IsEmptyVoidYN		bYN,
		@IsEmptyOverflowYN	bYN,	@IsEmptySeparatePayYN bYN,	@IsEmptyPayOverrideYN bYN,	@IsEmptyAmtToPay	bYN,	

		-- Cusor Variables --
		@curRecSeq	int,		  @curTableName	VARCHAR(20),  @curCol		VARCHAR(30), @curUploadVal	VARCHAR(60),
		@curIdent	int,		  @curImportID	VARCHAR(10),  @curSeq		int,		 @curIdentifier	int,
		@curCurSeq	int,		  @curAllowNull	int,		  @curError		int,		 @curSQL		VARCHAR(255),
		@curValList VARCHAR(255), @curColList	VARCHAR(255), @curComplete  int,		 @curCounter	int, 
		@curRecord	int,		  @curOldRecSeq int,		  @curOpen		int		


	---------------------
	-- INITIALIZE VARIABLES --
	---------------------
	SET @rcode = 0
	SET @curOpen = 0
	SET @ImportCompleted = 'N'

	SELECT	@ynCo			= 'N',	@ynMth			= 'N',	@ynBatchId		= 'N',	@ynBatchSeq		= 'N',
			@ynCMCo			= 'N',	@ynCMAcct		= 'N',	@ynPayMethod	= 'N',	@ynChkType		= 'N',
			@ynCMRef		= 'N',	@ynCMRefSeq		= 'N',	@ynEFTSeq		= 'N',	@ynPaidDate		= 'N',
			@ynVendorGroup	= 'N',	@ynVendor		= 'N',	@ynAmount		= 'N',	@ynVoidYN		= 'N'

	

	SELECT 	@IsEmptyCo			= 'N',	@IsEmptyMth				= 'N',	@IsEmptyBatchId			= 'N',	@IsEmptyBatchSeq	= 'N',
			@IsEmptyCMCo		= 'N',	@IsEmptyCMAcct			= 'N',	@IsEmptyPayMethod		= 'N',	@IsEmptyChkType		= 'N',
			@IsEmptyCMRef		= 'N',	@IsEmptyCMRefSeq		= 'N',	@IsEmptyEFTSeq			= 'N',	@IsEmptyPaidDate	= 'N',
			@IsEmptyVendorGroup	= 'N',	@IsEmptyVendor			= 'N',	@IsEmptyAmount			= 'N',	@IsEmptyVoidYN		= 'N',
			@IsEmptyOverflowYN	= 'N',	@IsEmptySeparatePayYN	= 'N',	@IsEmptyPayOverrideYN	= 'N',	@IsEmptyAmtToPay	= 'N'

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
	-- CHECK IF ANY DEFAULTS EXIST --
	----------------------------------
	SELECT TOP 1 1
	  FROM IMTD (nolock)	
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
--	SET	@owCo				= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype)
--	SET	@owCMCo				= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CMCo', @rectype)
--	SET	@owCMAcct			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CMAcct', @rectype)
--	SET	@owPayMethod		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayMethod', @rectype)
--	SET	@owChkType			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ChkType', @rectype)
--	SET	@owVendorGroup		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype)
--	SET @owPaidDate			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PaidDate', @rectype)
--	SET	@owVoidYN			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VoidYN', @rectype)


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

	/* There are some columns that can be updated to ALL imported records as a set.  The value is NOT
	   unique to the individual imported record. */
	select @CoID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', @rectype, 'Y')		
	select @MthID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Mth', @rectype, 'Y')	
	select @CMCoID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CMCo', @rectype, 'Y')	
	select @PayMethodID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayMethod', @rectype, 'Y')		
	select @VendorGroupID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'Y')	

	-------------
    -- COMPANY --
	-------------
	select @Co= @Company 
	IF @CoID is not null
     		BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = @Co
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @CoID 
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			 END

	----------------------
    -- MTH --
	----------------------
	----#141031
	SET @Mth = CONVERT(VARCHAR(10), dbo.vfDateOnlyMonth(), 101)
	----select @Mth = convert(varchar(2), month(getxdate())) + '/1/' + convert(varchar(4),year(getxdate()))
	IF @MthID is not null
     		BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = @Mth
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @MthID 
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			 END

	----------------------
    -- CMCO --
	----------------------
	select @CMCo=CMCo from APCO where APCo=@Co
	IF @CMCoID is not null
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = @CMCo
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @CMCoID
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			END
	
	---------------
	-- PAY METHOD --
	---------------
	IF @PayMethodID is not null
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'C'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @PayMethodID
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL OR IMWE.UploadVal = ''
			END
               
	-----------------
	-- VENDOR GROUP --
	-----------------
	select @VendorGroup = VendorGroup from HQCO where HQCo=@Company
	IF @VendorGroupID is not null
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = @VendorGroup
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @VendorGroupID
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			END


	------------------------------------------------
	-- GET COLUMN IDENTIFIERS FOR THOSE COLUMNS   --
	-- THAT WILL BE DEFAULTED					  --	 
	------------------------------------------------  
	SET @CMAcctID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CMAcct', @rectype, 'Y');	
	SET @VoidYNID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VoidYN', @rectype, 'Y');
	SET @ChkTypeID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ChkType', @rectype, 'Y');
	SET @CMRefSeqID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CMRefSeq', @rectype, 'Y');
	SET @AmountID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Amount', @rectype, 'Y');
	SET @OverflowYNID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Overflow', @rectype, 'Y');
	SET @SeparatePayYNID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SeparatePayYN', @rectype, 'Y');
	SET @PayOverrideYNID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayOverrideYN', @rectype, 'Y');

	------------------------------------------------
	-- GET COLUMN IDENTIFIERS FOR THOSE COLUMNS   --
	-- THAT WONT BE DEFAULTED					  --	 
	------------------------------------------------  
	SET @CMRefID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CMRef', @rectype, 'N');	
	SET @VendorID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Vendor', @rectype, 'N');
	SET	@AmtToPayID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AmtToPay', @rectype, 'N')
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

					IF @curCol = 'Mth' 
						IF @curUploadVal IS NULL SET @IsEmptyMth = 'Y'

					IF @curCol = 'CMCo' 
						IF @curUploadVal IS NULL SET @IsEmptyCMCo = 'Y'
					
					IF @curCol = 'CMAcct' 
						IF @curUploadVal IS NULL SET @IsEmptyCMAcct = 'Y'

					IF @curCol = 'PayMethod' 
						IF @curUploadVal IS NULL SET @IsEmptyPayMethod = 'Y'

					IF @curCol = 'ChkType' 
						IF @curUploadVal IS NULL SET @IsEmptyChkType = 'Y'

					IF @curCol = 'CMRef' 
						IF @curUploadVal IS NULL SET @IsEmptyCMRefSeq = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @CMRefSeq = CONVERT(int, @curUploadVal)

					IF @curCol = 'CMRefSeq' 
						IF @curUploadVal IS NULL SET @IsEmptyCMRefSeq = 'Y'

					IF @curCol = 'VendorGroup' 
						IF @curUploadVal IS NULL SET @IsEmptyVendorGroup = 'Y'

					IF @curCol = 'Vendor' 
						IF @curUploadVal IS NULL SET @IsEmptyVendor = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @Vendor = CONVERT(int, @curUploadVal)

					IF @curCol = 'PaidDate' 
						IF @curUploadVal IS NULL SET @IsEmptyPaidDate = 'Y'
						ELSE IF ISDATE(@curUploadVal) = 1 SET @PaidDate = CONVERT(smalldatetime, @curUploadVal)

					IF @curCol = 'Amount' 
						IF @curUploadVal IS NULL SET @IsEmptyAmount = 'Y'

					IF @curCol = 'VoidYN' 
						IF @curUploadVal IS NULL SET @IsEmptyVoidYN = 'Y'

					IF @curCol = 'Overflow' 
						IF @curUploadVal IS NULL SET @IsEmptyOverflowYN = 'Y'

					IF @curCol = 'SeparatePayYN' 
						IF @curUploadVal IS NULL SET @IsEmptySeparatePayYN = 'Y'

					IF @curCol = 'PayOverrideYN' 
						IF @curUploadVal IS NULL SET @IsEmptyPayOverrideYN = 'Y'
					
					IF @curCol = 'AmtToPay' 
						IF @curUploadVal IS NULL SET @IsEmptyAmount = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @AmtToPay = CONVERT(float, @curUploadVal)
					

					-- GET NEXT RECORD --
					FETCH NEXT FROM curWorkEdit INTO @curRecSeq, @curIdent, @curTableName, @curCol, @curUploadVal

				END --IF @curRecSeq = @curCurSeq
			ELSE 
				BEGIN 
					-----------------------------------------------------
					-- A DIFFERENT IMPORT RECORDSEQ HAS BEEN DETECTED. -- 
					-- SET DEFAULT VALUES OF PREVIOUS RECORD.		   --
					-----------------------------------------------------

					-- COMPANY --
					IF @CoID <> 0 AND (@owCo = 'Y' OR @IsEmptyCo = 'Y')
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = @Co
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @CoID 
							   AND IMWE.RecordType = @rectype
						END
					
					-- MTH --
					IF @MthID <> 0 AND (@owMth = 'Y' OR @IsEmptyMth = 'Y')
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = @Mth
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @MthID 
							   AND IMWE.RecordType = @rectype
						END		

					-- CMCO --
					IF @CMCoID <> 0 AND (@owCMCo = 'Y' OR @IsEmptyCMCo = 'Y')
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = @CMCo
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @CMCoID 
							   AND IMWE.RecordType = @rectype
						END		

					-- VENDORGROUP --
					IF @VendorGroupID <> 0 AND (@owVendorGroup = 'Y' OR @IsEmptyVendorGroup = 'Y')
						BEGIN
							SELECT @VendorGroup = VendorGroup
							  FROM HQCO WITH (NOLOCK)
							WHERE HQCo = @Co

							UPDATE IMWE
							   SET IMWE.UploadVal = @VendorGroup
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @VendorGroupID 
							   AND IMWE.RecordType = @rectype
						END	
					
					-- CMACCT --
					IF @CMAcctID <> 0 AND (@owCMAcct = 'Y' OR @IsEmptyCMAcct = 'Y')
						BEGIN
							SELECT @CMAcct = CMAcct
							  FROM APVM WITH (NOLOCK)
							WHERE VendorGroup=@VendorGroup and Vendor=@Vendor
							IF @CMAcct is null 
							BEGIN
							SELECT @CMAcct = CMAcct
							  FROM APCO WITH (NOLOCK)
							WHERE APCo= @Co
							END

							UPDATE IMWE
							   SET IMWE.UploadVal = @CMAcct
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @CMAcctID 
							   AND IMWE.RecordType = @rectype
						END	

					-- PAYMETHOD --
					IF @PayMethodID <> 0 AND (@owPayMethod = 'Y' OR @IsEmptyPayMethod = 'Y')
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = 'C'
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @PayMethodID 
							   AND IMWE.RecordType = @rectype
						END

					-- CHKTYPE --
					IF @ChkTypeID <> 0 AND (@owChkType = 'Y' OR @IsEmptyChkType = 'Y')
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = 'I'
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @ChkTypeID 
							   AND IMWE.RecordType = @rectype
						END	

					-- CMREFSEQ --
					IF @CMRefSeqID <> 0 AND (@owCMRefSeq = 'Y' OR @IsEmptyCMRefSeq = 'Y')
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = 0
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @CMRefSeqID 
							   AND IMWE.RecordType = @rectype
						END	

					-- PAIDDATE --
					IF @PaidDateID <> 0 AND (@owPaidDate = 'Y' OR @IsEmptyPaidDate = 'Y')
						BEGIN
							UPDATE IMWE
							----#141031
							   SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @PaidDateID 
							   AND IMWE.RecordType = @rectype
						END	

					-- AMOUNT --
					IF @AmountID <> 0 AND (@owAmount = 'Y' OR @IsEmptyAmount = 'Y')
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = 00.00
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @AmountID 
							   AND IMWE.RecordType = @rectype
						END		

					-- VOIDYN --
					IF @VoidYNID <> 0 AND @IsEmptyVoidYN = 'Y'
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = 'N'
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @VoidYNID 
							   AND IMWE.RecordType = @rectype
						END	
					
					-- OVERFLOW --
					IF @OverflowYNID <> 0 AND @IsEmptyOverflowYN = 'Y'
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = 'N'
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @OverflowYNID 
							   AND IMWE.RecordType = @rectype
						END	
					
					-- SEPARATEPAYYN --
					IF @SeparatePayYNID <> 0 AND @IsEmptySeparatePayYN = 'Y'
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = 'N'
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @SeparatePayYNID 
							   AND IMWE.RecordType = @rectype
						END	

					-- PAYOVERRIDEYN --
					IF @PayOverrideYNID <> 0 AND  @IsEmptyPayOverrideYN = 'Y'
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = 'N'
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @PayOverrideYNID 
							   AND IMWE.RecordType = @rectype
						END	

					
					-- AMOUNT TO PAY --
					IF @AmtToPayID <> 0 AND @IsEmptyAmtToPay = 'Y'
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = 00.00
							 WHERE IMWE.ImportTemplate = @ImportTemplate 
							   AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @AmtToPayID 
							   AND IMWE.RecordType = @rectype
						END

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
    SET @msg = ISNULL(@desc, 'Header ') + char(13) + char(13) + 'vspIMViewpointDefaultsAPPB'
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsAPPB] TO [public]
GO
