SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspIMViewpointDefaultsAPTB]
/***********************************************************
* CREATED BY: MV 08/10/09 - Issue: #130949
* MODIFIED BY: GF 06/30/2010 - issue #135813 expanded subcontract to 30 characters
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
		@rcode int, @recode int, @Temprcode int, @desc varchar(120), @ImportCompleted bYN,
		@TempExpMth bDate, @TempAPTrans bTrans,@TempAPRef varchar(15), @TempInvDate bDate,
		@TempGross bDollar, @TempDiscTaken bDollar, @TempBalance bDollar, @TempPrevDisc bDollar,
		@TempPrevPaid bDollar,@TempRetainage bDollar,

		-- Header Variables --
		@FormHeader				varchar(20), @HeaderRecKeyID		int,		@HeaderRecType			varchar(10), 
		@HeaderRecSeq			int,		 @HeaderVendorGroup		bGroup,		@HeaderVendorGroupID	int,
		@HeaderVendor			bVendor,	 @HeaderVendorID		int,		@HeaderMth				bDate,
		@HeaderMthID			int,		 @HeaderCoID			int,		@HeaderCo				bCompany,
		@HeaderRetainageFlagID	int,		 		

		-- Detail Variables --
		@FormDetail		varchar(20),
		@DetailRecKeyID	int,
		@Co				bCompany,		@Mth			bMonth,		@BatchId		bBatchID,	 @BatchSeq		int,
		@ExpMth			bDate,			@APTrans		bTrans,		@APRef			varchar(15), @InvDate		bDate,
		@Gross			bDollar,		@DiscTaken		bDollar,	@Balance		bDollar,	 @PrevDisc		bDollar,
		@PrevPaid		bDollar,		@Retainage		bDollar,	@AmtToPay		bDollar,	 @Subcontract	VARCHAR(30),
		@RetainageFlag	bYN,			
		

		-- ID --
		@CoID			int, @MthID				int, @BatchIdID			int, @BatchSeqID	int, 
		@ExpMthID		int, @APTransID			int, @APRefID			int, @InvDateID		int, 
		@GrossID		int, @DiscTakenID		int, @BalanceID			int, @PrevDiscID	int, 
		@PrevPaidID		int, @RetainageID 		int, @RetainageFlagID	int, @AmtToPayID	int,
		@SubcontractID	int,

			
		-- Overwrite --
		@owCo			bYN, @owMth				bYN, @owBatchId			bYN, @owBatchSeq	bYN, 
		@owExpMth		bYN, @owAPTrans			bYN, @owAPRef			bYN, @owInvDate		bYN, 
		@owGross		bYN, @owDiscTaken		bYN, @owBalance			bYN, @owPrevDisc	bYN, 
		@owPrevPaid		bYN, @owRetainage 		bYN, 

		-- IsEmpty --
		@IsEmptyCo			bYN, @IsEmptyMth				bYN, @IsEmptyBatchId		bYN, @IsEmptyBatchSeq	bYN, 
		@IsEmptyExpMth		bYN, @IsEmptyAPTrans			bYN, @IsEmptyAPRef			bYN, @IsEmptyInvDate	bYN, 
		@IsEmptyGross		bYN, @IsEmptyDiscTaken			bYN, @IsEmptyBalance		bYN, @IsEmptyPrevDisc	bYN, 
		@IsEmptyPrevPaid	bYN, @IsEmptyRetainage	 		bYN, @IsEmptyRetainageFlag  bYN, @IsEmptyAmtToPay	bYN,
		@IsEmptySubcontract bYN,

		-- Cusor Variables --
		@curRecSeq	int,		  @curTableName	VARCHAR(20),  @curCol		VARCHAR(30), @curUploadVal	VARCHAR(60),
		@curIdent	int,		  @curImportID	VARCHAR(10),  @curSeq		int,		 @curIdentifier	int,
		@curCurSeq	int,		  @curAllowNull	int,		  @curError		int,		 @curSQL		VARCHAR(255),
		@curValList VARCHAR(255), @curColList	VARCHAR(255), @curComplete  int,		 @curCounter	int, 
		@curRecord	int,		  @curOldRecSeq int,		  @curOpen		int,		 @curRecKey		int


	---------------------
	-- PRIME VARIABLES --
	---------------------
	SET @rcode = 0
	SET @curOpen = 0
	SET @ImportCompleted = 'N'
	SET @FormHeader = 'APPayEdit'
	SET @FormDetail = 'APPayEditDetail'
	SEt @HeaderRecType = 'APPB'


	
	SELECT 	
		@IsEmptyCo			= 'N', @IsEmptyMth				= 'N', @IsEmptyBatchId			= 'N', @IsEmptyBatchSeq		= 'N', 
		@IsEmptyExpMth		= 'N', @IsEmptyAPTrans			= 'N', @IsEmptyAPRef			= 'N', @IsEmptyInvDate		= 'N', 
		@IsEmptyGross		= 'N', @IsEmptyDiscTaken		= 'N', @IsEmptyBalance			= 'N', @IsEmptyPrevDisc		= 'N', 
		@IsEmptyPrevPaid	= 'N', @IsEmptyRetainage 		= 'N', @IsEmptyRetainageFlag	= 'N', @IsEmptyAmtToPay		= 'N',
		@IsEmptySubcontract	= 'N'
   

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
	  FROM IMTD	
	 WHERE IMTD.ImportTemplate=@ImportTemplate 
	   AND IMTD.DefaultValue = '[Bidtek]'
	   AND IMTD.RecordType = @rectype

	IF @@ROWCOUNT = 0
		BEGIN
			SET @desc = 'No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.'
			GOTO vspExit
		END

	----------------------------
	-- GET RECORD IDENTIFIERS --
	----------------------------
	-- DETAIL --
	SELECT @DetailRecKeyID = a.Identifier
      FROM IMTD a join DDUD b 
		ON a.Identifier = b.Identifier
     WHERE a.ImportTemplate = @ImportTemplate 
	   AND b.ColumnName = 'RecKey'
       AND a.RecordType = @rectype 
	   AND b.Form = @FormDetail


	------------------
	-- OVERWRITE YN --
	------------------		
	SET @owAPRef = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'APRef', @rectype) 

	-- ************************************************************************************ --
	--																						--
	--			RECORDS ALREADY EXIST IN THE IMWE TABLE FROM THE IMPORTED TEXTFILE			--
	--																						--
	--			All records with the same RecordSeq represent a single import record		--
	--																						--
	-- ************************************************************************************ --

	------------------------------------------------
	-- GET COLUMN IDENTIFIERS FOR THOSE COLUMNS   --
	-- THAT WILL BE DEFAULTED					  --	 
	------------------------------------------------  
	-- HEADER --
	SET @HeaderVendorGroupID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'VendorGroup', @HeaderRecType, 'N')
	SET @HeaderVendorID				= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Vendor', @HeaderRecType, 'N')
	SET @HeaderMthID				= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Mth', @HeaderRecType, 'N')
	SET @HeaderCoID					= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Co', @HeaderRecType, 'N')

	SET @CoID				= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', @rectype, 'Y')
	SET @MthID				= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Mth', @rectype, 'Y')
	SET @ExpMthID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ExpMth', @rectype, 'Y')
	SET @APTransID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'APTrans', @rectype, 'Y')
	SET @InvDateID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'InvDate', @rectype, 'Y')
	SET @DiscTakenID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DiscTaken', @rectype, 'Y')
	SET @BalanceID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Balance', @rectype, 'Y')
	SET @PrevDiscID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PrevDisc', @rectype, 'Y')
	SET @PrevPaidID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PrevPaid', @rectype, 'Y')
	SET @RetainageID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Retainage', @rectype, 'Y')
	SET @GrossID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Gross', @rectype, 'Y')

	------------------------------------------------
	-- GET COLUMN IDENTIFIERS FOR THOSE COLUMNS   --
	-- THAT WILL NOT BE DEFAULTED				  --	 
	------------------------------------------------ 
	SET @APRefID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'APRef', @rectype, 'N')
	SET @AmtToPayID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AmtToPay', @rectype, 'N')
	SET @SubcontractID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Subcontract', @rectype, 'N')
	SET @RetainageFlagID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RetainageFlag', @rectype, 'N')

	-- DETAIL -- 
	SET @owAPRef			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'APRef', @rectype)
 

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
			IF @curCurSeq = @curRecSeq AND @@FETCH_STATUS = 0
				BEGIN
				
					------------------------------------------------
					-- GET UPLOADED VALUES FOR THIS IMPORT RECORD --
					------------------------------------------------
					IF @curCol = 'Co' 
						BEGIN
						IF @curUploadVal IS NULL SET @IsEmptyCo = 'Y'
						END
					IF @curCol = 'Mth'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptyMth = 'Y'
						END
					IF @curCol = 'ExpMth'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptyExpMth = 'Y'
						END
					IF @curCol = 'APTrans'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptyAPTrans = 'Y'
						END
					IF @curCol = 'APRef'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptyAPRef = 'Y'
						ELSE SET @APRef = @curUploadVal
						END
					IF @curCol = 'InvDate' 
						BEGIN
						IF @curUploadVal IS NULL SET @IsEmptyInvDate = 'Y'
						END
					IF @curCol = 'Gross'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptyGross = 'Y'
						END
					IF @curCol = 'Retainage'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptyRetainage = 'Y'
						END
					IF @curCol = 'PrevPaid'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptyPrevPaid = 'Y'
						END
					IF @curCol = 'PrevDisc'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptyPrevDisc = 'Y'
						END
					IF @curCol = 'Balance'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptyBalance = 'Y'
						END
					IF @curCol = 'DiscTaken'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptyDiscTaken = 'Y'
						END
					IF @curCol = 'RetainageFlag'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptyRetainageFlag = 'Y'
						ELSE SET @RetainageFlag =@curUploadVal
						END
					IF @curCol = 'AmtToPay'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptyAmtToPay = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @AmtToPay = CONVERT(float, @curUploadVal)
						END
					IF @curCol = 'Subcontract'
						BEGIN 
						IF @curUploadVal IS NULL SET @IsEmptySubcontract = 'Y'
						ELSE SET @Subcontract =@curUploadVal
						END

					-- GET NEXT RECORD --
					FETCH NEXT FROM curWorkEdit INTO @curRecSeq, @curIdent, @curTableName, @curCol, @curUploadVal

				END --IF @curRecSeq = @curCurSeq
			ELSE 
				BEGIN 

					-------------------------------
					-- SET UP TO GET HEADER DATA --
					-------------------------------
        			SELECT @curRecKey = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @DetailRecKeyID 
					   AND IMWE.RecordType = @rectype 
        			   AND IMWE.RecordSeq = @curCurSeq --@curRecSeq
      
        			SELECT @HeaderRecSeq = IMWE.RecordSeq
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @DetailRecKeyID 
				       AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.UploadVal = @curRecKey
      
					----------------------------
					-- GET HEADER INFORMATION --
					----------------------------
					-- HeaderVendorGroup --
        			SELECT @HeaderVendorGroup = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @HeaderVendorGroupID 
					   AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.RecordSeq = @HeaderRecSeq


					-- HeaderVendor --
					SELECT @HeaderVendor = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @HeaderVendorID 
					   AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.RecordSeq = @HeaderRecSeq	

					-- HeaderMth --
					SELECT @HeaderMth = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @HeaderMthID 
					   AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.RecordSeq = @HeaderRecSeq	

					-- HeaderCo --
					SELECT @HeaderCo = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @HeaderCoID 
					   AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.RecordSeq = @HeaderRecSeq

					-------------------------
					-- SET DETAIL DEFAULTS --
					-------------------------
					-- Co --
					IF @CoID IS NOT NULL AND @IsEmptyCo = 'Y' --(@owCo = 'Y' OR @IsEmptyCo = 'Y')
						BEGIN
						   UPDATE IMWE
						      SET IMWE.UploadVal = @HeaderCo
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq 
							  AND IMWE.Identifier = @CoID

						END

					-- Mth --
        			IF @MthID IS NOT NULL AND (@owMth = 'Y' OR @IsEmptyMth = 'Y')
         				BEGIN
						   UPDATE IMWE
						      SET IMWE.UploadVal = @HeaderMth
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @MthID
						END

					--Retainage Flag --
					IF @RetainageFlagID <> 0 AND @IsEmptyRetainageFlag = 'Y'
						BEGIN
							-- update Detail RetainageFlag 
							UPDATE IMWE
								SET IMWE.UploadVal = 'N'
							WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
								AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
								AND IMWE.Identifier = @RetainageFlagID
						END

					-- ExpMth --
					IF @ExpMthID IS NOT NULL AND (@owExpMth = 'Y' OR @IsEmptyExpMth = 'Y')
						BEGIN
							--Get ExpMth from bAPTH
							SELECT @TempExpMth = Mth
						     FROM APTH WITH (NOLOCK)
						    WHERE APCo = @HeaderCo 
							 and VendorGroup=@HeaderVendorGroup and Vendor=@HeaderVendor
							 and APRef=@APRef

						   UPDATE IMWE
						      SET IMWE.UploadVal = @TempExpMth
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @ExpMthID
						END					
				
					-- APTrans --
					IF @APTransID <> 0 AND (@owAPTrans = 'Y' OR @IsEmptyAPTrans = 'Y')
						BEGIN
						--Get APTrans from bAPTH
							SELECT @TempAPTrans = APTrans
						     FROM APTH WITH (NOLOCK)
						    WHERE APCo = @HeaderCo  
							 and VendorGroup=@HeaderVendorGroup and Vendor=@HeaderVendor
							 and APRef=@APRef

						   UPDATE IMWE
						      SET IMWE.UploadVal = @TempAPTrans
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @APTransID
						END		

					-- InvDate --
					IF @InvDateID <> 0 AND (@owInvDate = 'Y' OR @IsEmptyInvDate = 'Y')
						BEGIN
						--Get APTrans from bAPTL
							SELECT @TempInvDate = InvDate
						     FROM APTH WITH (NOLOCK)
						    WHERE APCo = @HeaderCo  
							 and VendorGroup=@HeaderVendorGroup and Vendor=@HeaderVendor
							 and APRef=@APRef

						   UPDATE IMWE
						      SET IMWE.UploadVal = @TempInvDate
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @InvDateID
						END	
					
					-- GROSS, RETAINAGE,PREVPAID, PREVDISC,BALANCE AND DISCTAKEN ARE	 --
					-- INITIALLY DEFAULTED TO 0. WHEN bAPDB RECORDS ARE CREATED		     --
					-- DURING THE UPLOAD, THESE AMOUNTS ARE UPDATED TO bAPTB		     --			
					
					IF @GrossID <> 0 AND @IsEmptyRetainage = 'Y'
						BEGIN
						   UPDATE IMWE
						      SET IMWE.UploadVal = 0.0
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @GrossID
						END

					IF @RetainageID <> 0 AND (@owRetainage = 'Y' OR @IsEmptyRetainage = 'Y')
						BEGIN
						   UPDATE IMWE
						      SET IMWE.UploadVal = 0.0
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @RetainageID
						END

					IF @PrevPaidID <> 0 AND (@owPrevPaid = 'Y' OR @IsEmptyPrevPaid = 'Y')
						BEGIN
						   UPDATE IMWE
						      SET IMWE.UploadVal = 0.0
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @PrevPaidID
						END

					IF @PrevDiscID <> 0 AND (@owPrevDisc = 'Y' OR @IsEmptyPrevDisc = 'Y')
						BEGIN
						   UPDATE IMWE
						      SET IMWE.UploadVal = 0.0
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @PrevDiscID
						END

					IF @BalanceID <> 0 AND (@owBalance = 'Y' OR @IsEmptyBalance = 'Y')
						BEGIN
						   UPDATE IMWE
						      SET IMWE.UploadVal = 0.0
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @BalanceID
						END

					IF @DiscTakenID <> 0 AND (@owDiscTaken = 'Y' OR @IsEmptyDiscTaken = 'Y')
						BEGIN
						   UPDATE IMWE
						      SET IMWE.UploadVal = 0.0
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @DiscTakenID
						END

					

					-- SET CURRENT SEQUENCE --
					SET @curCurSeq = @curRecSeq


					-- RESET WORKING VARIBLES --
					SELECT @TempExpMth = NULL,@TempAPTrans = NULL, @TempAPRef = NULL, @TempInvDate = NULL,
					@ExpMth = NULL,@APTrans = NULL,@APRef = NULL, @InvDate = NULL, @Gross = NULL, 
					@DiscTaken = NULL, @Balance = NULL, @PrevDisc = NULL,@PrevPaid = NULL, @Retainage = NULL,
					@IsEmptyRetainageFlag = 'N', @RetainageFlag = NULL 


					-- FLAG STOP LOOP --
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
    SET @msg = ISNULL(@desc, 'Line') + char(13) + char(13) + '[vspIMViewpointDefaultsAPTB]'

    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsAPTB] TO [public]
GO
