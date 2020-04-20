SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsJCCI]
/***********************************************************
* CREATED BY:	RBT 06/21/2004	- issue #24373
* MODIFIED BY:	CC	02/18/2009	- issue #24531 - Use default only if set to overwrite or value is null
*				CHS 10/08/2009	- issue #135844
*				AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
*
* Usage:
*	Used by Imports to create values for needed or missing
*      data based upon Viewpoint default rules.
*
* Input params:
*	@ImportId	 Import Identifier
*	@ImportTemplate	 Import Template
*
* Output params:
*	@msg		error message
*
* Return code:
*	0 = success, 1 = failure
*
* Defaulted Columns:
*	JCCo, SICode, StartMonth, Department, TaxCode, TaxGroup, Description, SIRegion,
*	UM, RetainPCT, MarkupRate, OrigContractUnits, OrigUnitPrice, BillType, OrigContractAmt,
*	BillDescription, InitSubs, RetainPCT.
************************************************************/
   
    (@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), 
   	@Form varchar(20), @rectype varchar(30), @msg varchar(120) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @desc varchar(120), @status int, @defaultvalue varchar(30), @CursorOpen int	
   
   --Identifiers
   --#142350 - removing  @RetainPCTID int,
   declare @JCCoID int, @SICodeID int, @StartMonthID int, @DepartmentID int, 
   @TaxCodeID int, @TaxGroupID int, @DescriptionID int, @SIRegionID int, @UMID int, 
   @MarkUpRateID int, @OrigContractUnitsID int, @OrigUnitPriceID int, @BillTypeID int, 
   @OrigContractAmtID int, @BillDescriptionID int, @InitSubsID int, @RetainPctID int, @InitAsZeroID int	--	#135844
   
   --Values
   declare @JCCo bCompany, @Contract bContract, @Department bDept, @TaxCode bTaxCode, 
   @TaxGroup bGroup, @RetainPct bPct, @SIRegion varchar(6), @BillType bBillType, @StartMonth bMonth,
   @OrigUnitPrice bUnitCost, @SICode varchar(16), @SIMetric bYN, @DefUM bUM, @UM bUM,
   @Description bItemDesc, @BillDescription bItemDesc, @Item bContractItem, @OrigContractUnits bUnits,
   @OrigContractAmt bDollar
   
   --Default Values
   declare @DefDepartment bDept, @DefTaxCode bTaxCode, @DefTaxGroup bGroup, @DefRetainPct bPct,
   @DefSIRegion varchar(6), @DefBillType bBillType, @DefStartMonth bMonth, @DefOrigUnitPrice bUnitCost
   
   --Flags for dependent defaults
   declare @ynDepartment bYN, @ynTaxCode bYN, @ynTaxGroup bYN, @ynRetainPct bYN, @ynSIRegion bYN,
   @ynBillType bYN, @ynStartMonth bYN, @ynUM bYN, @ynOrigUnitPrice bYN, @ynBillDescription bYN,
   @ynSICode bYN, @ynDescription bYN, @ynOrigContractAmt bYN
   
   /* check required input params */
   
   if @ImportId is null
     begin
     select @desc = 'Missing ImportId.', @rcode = 1
     goto bspexit
     end
   if @ImportTemplate is null
     begin
     select @desc = 'Missing ImportTemplate.', @rcode = 1
     goto bspexit
     end
   
   if @Form is null
     begin
     select @desc = 'Missing Form.', @rcode = 1
     goto bspexit
    end
   
    select @CursorOpen = 0
   
   -- Check ImportTemplate detail for columns to set Bidtek Defaults
   if not exists(select top 1 1 From IMTD with (nolock)
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
   and IMTD.RecordType = @rectype)
   goto bspexit
   
   DECLARE 
			  @OverwriteJCCo 	 			bYN
			, @OverwriteOrigContractUnits 	bYN
			, @OverwriteInitSubs 	 		bYN
			, @OverwriteInitAsZero 	 		bYN	--	#135844
			, @OverwriteMarkUpRate 	 		bYN
			, @OverwriteDepartment 	 	 	bYN
			, @OverwriteTaxCode 	 	 	bYN
			, @OverwriteTaxGroup 	 	 	bYN
			, @OverwriteRetainPCT 	 	 	bYN
			, @OverwriteSIRegion 	 	 	bYN
			, @OverwriteBillType 	 	 	bYN
			, @OverwriteStartMonth 	 	 	bYN
			, @OverwriteUM 	 			 	bYN
			, @OverwriteDescription 	 	bYN
			, @OverwriteBillDescription  	bYN
			, @OverwriteSICode 	 		 	bYN
			, @OverwriteOrigUnitPrice 	 	bYN
			, @OverwriteOrigContractAmt  	bYN
			,	@IsJCCoEmpty 				 bYN
			,	@IsContractEmpty 			 bYN
			,	@IsItemEmpty 				 bYN
			,	@IsSICodeEmpty 				 bYN
			,	@IsStartMonthEmpty 			 bYN
			,	@IsDepartmentEmpty 			 bYN
			,	@IsTaxCodeEmpty 			 bYN
			,	@IsTaxGroupEmpty 			 bYN
			,	@IsDescriptionEmpty 		 bYN
			,	@IsSIRegionEmpty 			 bYN
			,	@IsUMEmpty 					 bYN
			,	@IsRetainPCTEmpty 			 bYN
			,	@IsMarkUpRateEmpty 			 bYN
			,	@IsNotesEmpty 				 bYN
			,	@IsOrigContractUnitsEmpty 	 bYN
			,	@IsOrigUnitPriceEmpty 		 bYN
			,	@IsBillTypeEmpty 			 bYN
			,	@IsBillGroupEmpty 			 bYN
			,	@IsOrigContractAmtEmpty 	 bYN
			,	@IsBillDescriptionEmpty 	 bYN
			,	@IsInitSubsEmpty 			 bYN


	SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
	SELECT @OverwriteOrigContractUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OrigContractUnits', @rectype);
	SELECT @OverwriteInitSubs = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InitSubs', @rectype);
	SELECT @OverwriteMarkUpRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MarkUpRate', @rectype);
	SELECT @OverwriteDepartment = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Department', @rectype);
	SELECT @OverwriteTaxCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxCode', @rectype);
	SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype);
	SELECT @OverwriteRetainPCT = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RetainPCT', @rectype);
	SELECT @OverwriteSIRegion = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SIRegion', @rectype);
	SELECT @OverwriteBillType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BillType', @rectype);
	SELECT @OverwriteStartMonth = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StartMonth', @rectype);
	SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UM', @rectype);
	SELECT @OverwriteDescription = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Description', @rectype);
	SELECT @OverwriteBillDescription = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BillDescription', @rectype);
	SELECT @OverwriteSICode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SICode', @rectype);
	SELECT @OverwriteOrigUnitPrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OrigUnitPrice', @rectype);
	SELECT @OverwriteOrigContractAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OrigContractAmt', @rectype);
	SELECT @OverwriteInitAsZero = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InitAsZero', @rectype);	--	#135844
   
   
   --get database default values	
   
   --set common defaults
   
   select @JCCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y')
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @Company
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @JCCoID
   end
   
   select @OrigContractUnitsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OrigContractUnits'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOrigContractUnits, 'Y') = 'Y')
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @OrigContractUnitsID
   end
   
   select @InitSubsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InitSubs'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteInitSubs, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'Y'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @InitSubsID
   end

--	#135844
   select @InitAsZeroID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InitAsZero'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteInitAsZero, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @InitAsZeroID
   end

   select @MarkUpRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MarkUpRate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMarkUpRate, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MarkUpRateID
   end
   
-----------
   select @JCCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCCo, 'Y') = 'N')
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @Company
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @JCCoID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @OrigContractUnitsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OrigContractUnits'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOrigContractUnits, 'Y') = 'N')
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @OrigContractUnitsID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @InitSubsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InitSubs'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteInitSubs, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'Y'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @InitSubsID
   	AND IMWE.UploadVal IS NULL
   end

--	#135844
   select @InitAsZeroID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InitAsZero'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteInitAsZero, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @InitAsZeroID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @MarkUpRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MarkUpRate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMarkUpRate, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MarkUpRateID
   	AND IMWE.UploadVal IS NULL
   end   
   
   --Get Identifiers for dependent defaults.
   select @ynDepartment = 'N'
   select @DepartmentID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Department', @rectype, 'Y')
   if @DepartmentID <> 0 select @ynDepartment = 'Y'
   
   select @ynTaxCode = 'N'
   select @TaxCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxCode', @rectype, 'Y')
   if @TaxCodeID <> 0 select @ynTaxCode = 'Y'
   
   select @ynTaxGroup = 'N'
   select @TaxGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxGroup', @rectype, 'Y')
   if @TaxGroupID <> 0 select @ynTaxGroup = 'Y'
   
   select @ynRetainPct = 'N'
   select @RetainPctID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RetainPCT', @rectype, 'Y')
   if @RetainPctID <> 0 select @ynRetainPct = 'Y'
   
   select @ynSIRegion = 'N'
   select @SIRegionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SIRegion', @rectype, 'Y')
   if @SIRegionID <> 0 select @ynSIRegion = 'Y'
   
   select @ynBillType = 'N'
   select @BillTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BillType', @rectype, 'Y')
   if @BillTypeID <> 0 select @ynBillType = 'Y'
   
   select @ynStartMonth = 'N'
   select @StartMonthID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StartMonth', @rectype, 'Y')
   if @StartMonthID <> 0 select @ynStartMonth = 'Y'
   
   select @ynUM = 'N'
   select @UMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UM', @rectype, 'Y')
   if @UMID <> 0 select @ynUM = 'Y'
   
   select @ynDescription = 'N'
   select @DescriptionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Description', @rectype, 'Y')
   if @DescriptionID <> 0 select @ynDescription = 'Y'
   
   select @ynBillDescription = 'N'
   select @BillDescriptionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BillDescription', @rectype, 'Y')
   if @BillDescriptionID <> 0 select @ynBillDescription = 'Y'
   
   select @ynSICode = 'N'
   select @SICodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SICode', @rectype, 'Y')
   if @SICodeID <> 0 select @ynSICode = 'Y'
   
   select @ynOrigUnitPrice = 'N'
   select @OrigUnitPriceID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OrigUnitPrice', @rectype, 'Y')
   if @OrigUnitPriceID <> 0 select @ynOrigUnitPrice = 'Y'
   
   --Get OrigUnitPriceID
   select @OrigUnitPriceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OrigUnitPrice'
   
   select @ynOrigContractAmt = 'N'
   select @OrigContractAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OrigContractAmt', @rectype, 'Y')
   if @OrigContractAmtID <> 0 select @ynOrigContractAmt = 'Y'
   
   
   --Start Processing
   DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD FOR
   SELECT IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
   FROM IMWE with (nolock)
   INNER join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
   WHERE IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
   ORDER BY IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   -- set open cursor flag
   select @CursorOpen = 1
	-- #142350 - removing @importid varchar(10), @seq int, @Identifier int,
	DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int,
			@complete int
   
   declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
           @columnlist varchar(255), @records int, @oldrecseq int
   
   select @complete = 0
   
   fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   select @complete = @@fetch_status
   select @currrecseq = @Recseq
   
   -- while cursor is not empty
   while @complete = 0
   begin
     -- if rec sequence = current rec sequence flag
     if @Recseq = @currrecseq
     begin
   
    If @Column = 'JCCo' select @JCCo = @Uploadval
   	If @Column = 'Contract' select @Contract = @Uploadval
   	If @Column = 'SICode' select @SICode = @Uploadval
   	If @Column = 'SIRegion' select @SIRegion = @Uploadval
   	If @Column = 'Description' select @Description = @Uploadval
   	If @Column = 'Item' select @Item = @Uploadval
   	If @Column = 'OrigContractUnits' select @OrigContractUnits = @Uploadval
   	If @Column = 'OrigUnitPrice' select @OrigUnitPrice = @Uploadval
   	If @Column = 'UM' select @UM = @Uploadval

	IF @Column='JCCo' 
		IF @Uploadval IS NULL
			SET @IsJCCoEmpty = 'Y'
		ELSE
			SET @IsJCCoEmpty = 'N'
	IF @Column='Contract' 
		IF @Uploadval IS NULL
			SET @IsContractEmpty = 'Y'
		ELSE
			SET @IsContractEmpty = 'N'
	IF @Column='Item' 
		IF @Uploadval IS NULL
			SET @IsItemEmpty = 'Y'
		ELSE
			SET @IsItemEmpty = 'N'
	IF @Column='SICode' 
		IF @Uploadval IS NULL
			SET @IsSICodeEmpty = 'Y'
		ELSE
			SET @IsSICodeEmpty = 'N'
	IF @Column='StartMonth' 
		IF @Uploadval IS NULL
			SET @IsStartMonthEmpty = 'Y'
		ELSE
			SET @IsStartMonthEmpty = 'N'
	IF @Column='Department' 
		IF @Uploadval IS NULL
			SET @IsDepartmentEmpty = 'Y'
		ELSE
			SET @IsDepartmentEmpty = 'N'
	IF @Column='TaxCode' 
		IF @Uploadval IS NULL
			SET @IsTaxCodeEmpty = 'Y'
		ELSE
			SET @IsTaxCodeEmpty = 'N'
	IF @Column='TaxGroup' 
		IF @Uploadval IS NULL
			SET @IsTaxGroupEmpty = 'Y'
		ELSE
			SET @IsTaxGroupEmpty = 'N'
	IF @Column='Description' 
		IF @Uploadval IS NULL
			SET @IsDescriptionEmpty = 'Y'
		ELSE
			SET @IsDescriptionEmpty = 'N'
	IF @Column='SIRegion' 
		IF @Uploadval IS NULL
			SET @IsSIRegionEmpty = 'Y'
		ELSE
			SET @IsSIRegionEmpty = 'N'
	IF @Column='UM' 
		IF @Uploadval IS NULL
			SET @IsUMEmpty = 'Y'
		ELSE
			SET @IsUMEmpty = 'N'
	IF @Column='RetainPCT' 
		IF @Uploadval IS NULL
			SET @IsRetainPCTEmpty = 'Y'
		ELSE
			SET @IsRetainPCTEmpty = 'N'
	IF @Column='MarkUpRate' 
		IF @Uploadval IS NULL
			SET @IsMarkUpRateEmpty = 'Y'
		ELSE
			SET @IsMarkUpRateEmpty = 'N'
	IF @Column='Notes' 
		IF @Uploadval IS NULL
			SET @IsNotesEmpty = 'Y'
		ELSE
			SET @IsNotesEmpty = 'N'
	IF @Column='OrigContractUnits' 
		IF @Uploadval IS NULL
			SET @IsOrigContractUnitsEmpty = 'Y'
		ELSE
			SET @IsOrigContractUnitsEmpty = 'N'
	IF @Column='OrigUnitPrice' 
		IF @Uploadval IS NULL
			SET @IsOrigUnitPriceEmpty = 'Y'
		ELSE
			SET @IsOrigUnitPriceEmpty = 'N'
	IF @Column='BillType' 
		IF @Uploadval IS NULL
			SET @IsBillTypeEmpty = 'Y'
		ELSE
			SET @IsBillTypeEmpty = 'N'
	IF @Column='BillGroup' 
		IF @Uploadval IS NULL
			SET @IsBillGroupEmpty = 'Y'
		ELSE
			SET @IsBillGroupEmpty = 'N'
	IF @Column='OrigContractAmt' 
		IF @Uploadval IS NULL
			SET @IsOrigContractAmtEmpty = 'Y'
		ELSE
			SET @IsOrigContractAmtEmpty = 'N'
	IF @Column='BillDescription' 
		IF @Uploadval IS NULL
			SET @IsBillDescriptionEmpty = 'Y'
		ELSE
			SET @IsBillDescriptionEmpty = 'N'
	IF @Column='InitSubs' 
		IF @Uploadval IS NULL
			SET @IsInitSubsEmpty = 'Y'
		ELSE
			SET @IsInitSubsEmpty = 'N'

	IF @Column='InitAsZero' 
		IF @Uploadval IS NULL
			SET @IsInitSubsEmpty = 'Y'
		ELSE
			SET @IsInitSubsEmpty = 'N'

   
       select @oldrecseq = @Recseq
   
       --fetch next record
       fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
   	-- if this is the last record, set the sequence to -1 to process last record.
   	if @@fetch_status <> 0 
   	   select @Recseq = -1
   
     end
     else
     begin
   	-- set values that depend on other columns
   
   	--Get header values to use as defaults.
   	select @DefDepartment = Department, @DefTaxCode = TaxCode, @DefTaxGroup = TaxGroup,
   	@DefRetainPct = RetainagePCT, @DefSIRegion = SIRegion, @DefBillType = DefaultBillType, 
   	@DefStartMonth = StartMonth, @SIMetric = SIMetric
   	from JCCM with (nolock) where JCCo = @JCCo and Contract = @Contract
   
   	if @ynDepartment = 'Y'  AND (ISNULL(@OverwriteDepartment, 'Y') = 'Y' OR ISNULL(@IsDepartmentEmpty, 'Y') = 'Y')
   	begin
   		select @Department = @DefDepartment
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @Department
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@DepartmentID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynTaxCode = 'Y' AND (ISNULL(@OverwriteTaxCode, 'Y') = 'Y' OR ISNULL(@IsTaxCodeEmpty, 'Y') = 'Y')
   	begin
   		select @TaxCode = @DefTaxCode
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @TaxCode
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@TaxCodeID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynTaxGroup = 'Y' AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y' OR ISNULL(@IsTaxGroupEmpty, 'Y') = 'Y')
   	begin
   		select @TaxGroup = @DefTaxGroup
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @TaxGroup
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@TaxGroupID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynRetainPct = 'Y' AND (ISNULL(@OverwriteRetainPCT, 'Y') = 'Y' OR ISNULL(@IsRetainPCTEmpty, 'Y') = 'Y')
   	begin
   		select @RetainPct = @DefRetainPct
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @RetainPct
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@RetainPctID and IMWE.RecordType=@rectype
   
   	end
   
    	if @ynBillType = 'Y' AND (ISNULL(@OverwriteBillType, 'Y') = 'Y' OR ISNULL(@IsBillTypeEmpty, 'Y') = 'Y')
   	begin
   		select @BillType = @DefBillType
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @BillType
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@BillTypeID and IMWE.RecordType=@rectype
   
   	end
    
    	if @ynStartMonth = 'Y' AND (ISNULL(@OverwriteStartMonth, 'Y') = 'Y' OR ISNULL(@IsStartMonthEmpty, 'Y') = 'Y')
   	begin
   		select @StartMonth = @DefStartMonth
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @StartMonth
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@StartMonthID and IMWE.RecordType=@rectype
   
   	end
    
    	if @ynSIRegion = 'Y'  AND (ISNULL(@OverwriteSIRegion, 'Y') = 'Y' OR ISNULL(@IsSIRegionEmpty, 'Y') = 'Y')
   	begin
   		select @SIRegion = @DefSIRegion
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @SIRegion
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@SIRegionID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynSICode = 'Y' AND (ISNULL(@OverwriteSICode, 'Y') = 'Y' OR ISNULL(@IsSICodeEmpty, 'Y') = 'Y')
   	begin
   		select @SICode = SICode from JCSI with (nolock) where SIRegion = @SIRegion and SICode = ltrim(rtrim(@Item))
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @SICode
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@SICodeID and IMWE.RecordType=@rectype
   
   	end
   
   	--Get UM and UnitPrice defaults
   	select @DefUM = null, @DefOrigUnitPrice = null
   	exec bspJCCIDefaultUMGet @SIRegion, @SICode, @SIMetric, @DefUM output, @DefOrigUnitPrice output, @msg output
   
    	if @ynUM = 'Y' AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')
   	begin
   		if isnull(@SICode,'') <> ''
   		begin
   			select @UM = isnull(@DefUM,'LS')
   
   			UPDATE IMWE
   			SET IMWE.UploadVal = @UM
   			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   			and IMWE.Identifier=@UMID and IMWE.RecordType=@rectype
   		end
   		else if isnull(@UM,'') = ''
   		begin
   			select @UM = 'LS'
   
   			UPDATE IMWE
   			SET IMWE.UploadVal = @UM
   			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   			and IMWE.Identifier=@UMID and IMWE.RecordType=@rectype
   		end	
   	end
   
   	if @ynOrigUnitPrice = 'Y' and @DefOrigUnitPrice is not null AND (ISNULL(@OverwriteOrigUnitPrice, 'Y') = 'Y' OR ISNULL(@IsOrigUnitPriceEmpty, 'Y') = 'Y')
   	begin
   		select @OrigUnitPrice = @DefOrigUnitPrice
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @OrigUnitPrice
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@OrigUnitPriceID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynDescription = 'Y'  AND (ISNULL(@OverwriteDescription, 'Y') = 'Y' OR ISNULL(@IsDescriptionEmpty, 'Y') = 'Y')
   	begin
   		select @Description = 'Item ' + ltrim(rtrim(convert(varchar(40), @Item)))
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @Description
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@DescriptionID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynBillDescription = 'Y' AND (ISNULL(@OverwriteBillDescription, 'Y') = 'Y' OR ISNULL(@IsBillDescriptionEmpty, 'Y') = 'Y')
   	begin
   		select @BillDescription = @Description
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @BillDescription
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@BillDescriptionID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynOrigContractAmt = 'Y' AND (ISNULL(@OverwriteOrigContractAmt, 'Y') = 'Y' OR ISNULL(@IsOrigContractAmtEmpty, 'Y') = 'Y')
   	begin
   		select @OrigContractAmt = isnull(@OrigUnitPrice,0) * isnull(@OrigContractUnits,0)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @OrigContractAmt
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@OrigContractAmtID and IMWE.RecordType=@rectype
   
   	end
   
   	--CLEANUP SECTION
   
   	--Make sure units are zero if UM is "Lump Sum".
   	if @UM = 'LS'
   	begin
   		select @OrigContractUnits = 0
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @OrigContractUnits
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@OrigContractUnitsID and IMWE.RecordType=@rectype
   
   		select @OrigUnitPrice = 0
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @OrigUnitPrice
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@OrigUnitPriceID and IMWE.RecordType=@rectype
   
   	end
   
   	-- set Current Req Seq to next @Recseq unless we are processing last record.
   	if @Recseq = -1
   		select @complete = 1	-- exit the loop
   	else
   		select @currrecseq = @Recseq
   
     end
   end
   
   bspexit:
   
   	if @CursorOpen = 1
   	begin
   		close WorkEditCursor
   		deallocate WorkEditCursor	
   	end
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsJCCI]'
   
       return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsJCCI] TO [public]
GO
