SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsHQMT]
   /***********************************************************
    * CREATED BY:   RBT 09/25/03 for issue #13558
    * MODIFIED BY: 
    *			  CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
    *				AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
    *
    * Usage:
    *	Used by Imports to create values for needed or missing
    *      data based upon Viewpoint default rules.
    *
    * Input params:
    *	@ImportId	     Import Identifier
    *	@ImportTemplate	 Import Template
    *
    * Output params:
    *	@msg		error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/
   
    (@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), 
   @Form varchar(20), @rectype varchar(30), @msg varchar(120) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @desc varchar(120), @status int, 
   		@defaultvalue varchar(30), @CursorOpen int	
   
   --Identifiers
   declare @MatlGroupID int, @StdUMID int, @PurchaseUMID int, @SalesUMID int, @CostID int, @CostECMID int,
   		@PriceID int, @PriceECMID int, @PayDiscTypeID int, @PayDiscRateID int, @StockedID int, @TaxableID int,
   		@ActiveID int, @TypeID int
   --Values
   declare @MatlGroup bGroup, @StdUM bUM, @PurchaseUM bUM, @SalesUM bUM
   --Viewpoint Default?
   declare @ynPurchaseUM bYN, @ynSalesUM bYN
   
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
			 @OverwriteMatlGroup 	 	 bYN
			, @OverwriteCost 	 		 bYN
			, @OverwriteCostECM 	 	 bYN
			, @OverwritePrice 	 		 bYN
			, @OverwritePriceECM 	 	 bYN
			, @OverwritePayDiscType 	 bYN
			, @OverwritePayDiscRate 	 bYN
			, @OverwriteStocked 	 	 bYN
			, @OverwriteTaxable 	 	 bYN
			, @OverwriteActive 	 		 bYN
			, @OverwriteType 	 		 bYN
			, @OverwriteStdUM 	 		 bYN
			, @OverwritePurchaseUM 	 	 bYN
			, @OverwriteSalesUM 	 	 bYN			
			,	@IsMatlGroupEmpty 		 bYN
			,	@IsMaterialEmpty 		 bYN
			,	@IsCategoryEmpty 		 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsStdUMEmpty 			 bYN
			,	@IsCostEmpty 			 bYN
			,	@IsCostECMEmpty 		 bYN
			,	@IsPriceEmpty 			 bYN
			,	@IsPriceECMEmpty 		 bYN
			,	@IsPayDiscTypeEmpty 	 bYN
			,	@IsNotesEmpty 			 bYN
			,	@IsPayDiscRateEmpty 	 bYN
			,	@IsPurchaseUMEmpty 		 bYN
			,	@IsSalesUMEmpty 		 bYN
			,	@IsMetricUMEmpty 		 bYN
			,	@IsWeightConvEmpty 		 bYN
			,	@IsStockedEmpty 		 bYN
			,	@IsTaxableEmpty 		 bYN
			,	@IsMatlPhaseEmpty 		 bYN
			,	@IsMatlJCCostTypeEmpty 	 bYN
			,	@IsHaulPhaseEmpty 		 bYN
			,	@IsHaulJCCostTypeEmpty 	 bYN
			,	@IsHaulCodeEmpty 		 bYN
			,	@IsActiveEmpty 			 bYN
			,	@IsTypeEmpty 			 bYN
			,	@IsPriceServiceIdEmpty 	 bYN			

		SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
		SELECT @OverwriteCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Cost', @rectype);
		SELECT @OverwriteCostECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostECM', @rectype);
		SELECT @OverwritePrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Price', @rectype);
		SELECT @OverwritePriceECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PriceECM', @rectype);
		SELECT @OverwritePayDiscType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayDiscType', @rectype);
		SELECT @OverwritePayDiscRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayDiscRate', @rectype);
		SELECT @OverwriteStocked = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Stocked', @rectype);
		SELECT @OverwriteTaxable = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Taxable', @rectype);
		SELECT @OverwriteActive = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Active', @rectype);
		SELECT @OverwriteType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Type', @rectype);
	    SELECT @OverwriteStdUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StdUM', @rectype);
		SELECT @OverwritePurchaseUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PurchaseUM', @rectype);
		SELECT @OverwriteSalesUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SalesUM', @rectype);
   
   select @MatlGroup = MatlGroup from bHQCO with (nolock) where HQCo = @Company
   
   --MatlGroup
   select @MatlGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MatlGroup'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = @MatlGroup
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MatlGroupID
   end
   
   --Cost
   select @CostID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Cost'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCost, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = '0'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CostID
   end
   
   --CostECM
   select @CostECMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CostECM'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCostECM, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'E'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CostECMID
   end
   
   --Price
   select @PriceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Price'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwritePrice, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = '0'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PriceID
   end
   
   --PriceECM
   select @PriceECMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PriceECM'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePriceECM, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'E'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PriceECMID
   end
   
   --PayDiscType
   select @PayDiscTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PayDiscType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePayDiscType, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'N'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PayDiscTypeID
   end
   
   --PayDiscRate
   select @PayDiscRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PayDiscRate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePayDiscRate, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = '0'
     where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PayDiscRateID
   end
   
   --Stocked
   select @StockedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Stocked'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteStocked, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'N'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @StockedID
   end
   
   --Taxable
   select @TaxableID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Taxable'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteTaxable, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'N'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @TaxableID
   end
   
   --Active
   select @ActiveID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Active'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActive, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'Y'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActiveID
   end
   
   --Type
   select @TypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Type'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteType, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'S'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @TypeID
   end
   
   -------------------------------
      --MatlGroup
   select @MatlGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MatlGroup'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = @MatlGroup
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MatlGroupID
   	AND IMWE.UploadVal IS NULL
   end
   
   --Cost
   select @CostID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Cost'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCost, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = '0'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CostID
   	AND IMWE.UploadVal IS NULL
   end
   
   --CostECM
   select @CostECMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CostECM'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCostECM, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'E'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CostECMID
   	AND IMWE.UploadVal IS NULL
   end
   
   --Price
   select @PriceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Price'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwritePrice, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = '0'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PriceID
   	AND IMWE.UploadVal IS NULL
   end
   
   --PriceECM
   select @PriceECMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PriceECM'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePriceECM, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'E'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PriceECMID
   	AND IMWE.UploadVal IS NULL
   end
   
   --PayDiscType
   select @PayDiscTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PayDiscType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePayDiscType, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'N'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PayDiscTypeID
   	AND IMWE.UploadVal IS NULL
   end
   
   --PayDiscRate
   select @PayDiscRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PayDiscRate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePayDiscRate, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = '0'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PayDiscRateID
   	AND IMWE.UploadVal IS NULL
   end
   
   --Stocked
   select @StockedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Stocked'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteStocked, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'N'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @StockedID
   	AND IMWE.UploadVal IS NULL
   end
   
   --Taxable
   select @TaxableID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Taxable'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteTaxable, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'N'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @TaxableID
   	AND IMWE.UploadVal IS NULL
   end
   
   --Active
   select @ActiveID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Active'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActive, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'Y'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActiveID
   	AND IMWE.UploadVal IS NULL
   end
   
   --Type
   select @TypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Type'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteType, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'S'
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @TypeID
   	AND IMWE.UploadVal IS NULL
   end
   
   
   --Get StdUM for Purchase UM and Sales UM defaults
   select @StdUMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'StdUM'
   
   select @ynPurchaseUM = 'N'
   select @PurchaseUMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PurchaseUM', @rectype, 'Y')
   if @PurchaseUMID <> 0 select @ynPurchaseUM = 'Y'
   
   select @ynSalesUM = 'N'
   select @SalesUMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SalesUM', @rectype, 'Y')
   if @SalesUMID <> 0 select @ynSalesUM = 'Y'
   
   
   DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD FOR
   SELECT IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
   FROM IMWE with (nolock)
   INNER join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
   WHERE IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
   ORDER BY IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   -- set open cursor flag
   select @CursorOpen = 1
   
   -- #142350 removing @importid varchar(10), @seq int, @Identifier int,
	DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int,
			@complete int
		   
   declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
           @columnlist varchar(255), @records int, @oldrecseq int
   
   declare @UploadDate bDate, @Amount bDollar, 
   		@Co bCompany, @Mth bMonth, @BatchSeq int, @CMAcct bCMAcct, @CMTransType bCMTransType,
   		@CMRef bCMRef, @CMRefSeq tinyint, @AcctDate smalldatetime, @Payee varchar(20), 
   		@Description bDesc, @GLAcct bGLAcct
   
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
   
   	If @Column = 'StdUM' select @StdUM = @Uploadval
   
	IF @Column='MatlGroup' 
		IF @Uploadval IS NULL
			SET @IsMatlGroupEmpty = 'Y'
		ELSE
			SET @IsMatlGroupEmpty = 'N'
	IF @Column='Material' 
		IF @Uploadval IS NULL
			SET @IsMaterialEmpty = 'Y'
		ELSE
			SET @IsMaterialEmpty = 'N'
	IF @Column='Category' 
		IF @Uploadval IS NULL
			SET @IsCategoryEmpty = 'Y'
		ELSE
			SET @IsCategoryEmpty = 'N'
	IF @Column='Description' 
		IF @Uploadval IS NULL
			SET @IsDescriptionEmpty = 'Y'
		ELSE
			SET @IsDescriptionEmpty = 'N'
	IF @Column='StdUM' 
		IF @Uploadval IS NULL
			SET @IsStdUMEmpty = 'Y'
		ELSE
			SET @IsStdUMEmpty = 'N'
	IF @Column='Cost' 
		IF @Uploadval IS NULL
			SET @IsCostEmpty = 'Y'
		ELSE
			SET @IsCostEmpty = 'N'
	IF @Column='CostECM' 
		IF @Uploadval IS NULL
			SET @IsCostECMEmpty = 'Y'
		ELSE
			SET @IsCostECMEmpty = 'N'
	IF @Column='Price' 
		IF @Uploadval IS NULL
			SET @IsPriceEmpty = 'Y'
		ELSE
			SET @IsPriceEmpty = 'N'
	IF @Column='PriceECM' 
		IF @Uploadval IS NULL
			SET @IsPriceECMEmpty = 'Y'
		ELSE
			SET @IsPriceECMEmpty = 'N'
	IF @Column='PayDiscType' 
		IF @Uploadval IS NULL
			SET @IsPayDiscTypeEmpty = 'Y'
		ELSE
			SET @IsPayDiscTypeEmpty = 'N'
	IF @Column='Notes' 
		IF @Uploadval IS NULL
			SET @IsNotesEmpty = 'Y'
		ELSE
			SET @IsNotesEmpty = 'N'
	IF @Column='PayDiscRate' 
		IF @Uploadval IS NULL
			SET @IsPayDiscRateEmpty = 'Y'
		ELSE
			SET @IsPayDiscRateEmpty = 'N'
	IF @Column='PurchaseUM' 
		IF @Uploadval IS NULL
			SET @IsPurchaseUMEmpty = 'Y'
		ELSE
			SET @IsPurchaseUMEmpty = 'N'
	IF @Column='SalesUM' 
		IF @Uploadval IS NULL
			SET @IsSalesUMEmpty = 'Y'
		ELSE
			SET @IsSalesUMEmpty = 'N'
	IF @Column='MetricUM' 
		IF @Uploadval IS NULL
			SET @IsMetricUMEmpty = 'Y'
		ELSE
			SET @IsMetricUMEmpty = 'N'
	IF @Column='WeightConv' 
		IF @Uploadval IS NULL
			SET @IsWeightConvEmpty = 'Y'
		ELSE
			SET @IsWeightConvEmpty = 'N'
	IF @Column='Stocked' 
		IF @Uploadval IS NULL
			SET @IsStockedEmpty = 'Y'
		ELSE
			SET @IsStockedEmpty = 'N'
	IF @Column='Taxable' 
		IF @Uploadval IS NULL
			SET @IsTaxableEmpty = 'Y'
		ELSE
			SET @IsTaxableEmpty = 'N'
	IF @Column='MatlPhase' 
		IF @Uploadval IS NULL
			SET @IsMatlPhaseEmpty = 'Y'
		ELSE
			SET @IsMatlPhaseEmpty = 'N'
	IF @Column='MatlJCCostType' 
		IF @Uploadval IS NULL
			SET @IsMatlJCCostTypeEmpty = 'Y'
		ELSE
			SET @IsMatlJCCostTypeEmpty = 'N'
	IF @Column='HaulPhase' 
		IF @Uploadval IS NULL
			SET @IsHaulPhaseEmpty = 'Y'
		ELSE
			SET @IsHaulPhaseEmpty = 'N'
	IF @Column='HaulJCCostType' 
		IF @Uploadval IS NULL
			SET @IsHaulJCCostTypeEmpty = 'Y'
		ELSE
			SET @IsHaulJCCostTypeEmpty = 'N'
	IF @Column='HaulCode' 
		IF @Uploadval IS NULL
			SET @IsHaulCodeEmpty = 'Y'
		ELSE
			SET @IsHaulCodeEmpty = 'N'
	IF @Column='Active' 
		IF @Uploadval IS NULL
			SET @IsActiveEmpty = 'Y'
		ELSE
			SET @IsActiveEmpty = 'N'
	IF @Column='Type' 
		IF @Uploadval IS NULL
			SET @IsTypeEmpty = 'Y'
		ELSE
			SET @IsTypeEmpty = 'N'
	IF @Column='PriceServiceId' 
		IF @Uploadval IS NULL
			SET @IsPriceServiceIdEmpty = 'Y'
		ELSE
			SET @IsPriceServiceIdEmpty = 'N'   
   
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
   	if @ynPurchaseUM = 'Y' AND (ISNULL(@OverwritePurchaseUM, 'Y') = 'Y' OR ISNULL(@IsPurchaseUMEmpty, 'Y') = 'Y')
   	begin
   		UPDATE IMWE
   		SET IMWE.UploadVal = @StdUM
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		     and IMWE.Identifier = @PurchaseUMID and IMWE.RecordType = @rectype
   	end
   
   	if @ynSalesUM = 'Y' AND (ISNULL(@OverwriteSalesUM, 'Y') = 'Y' OR ISNULL(@IsSalesUMEmpty, 'Y') = 'Y')
   	begin
   		UPDATE IMWE
   		SET IMWE.UploadVal = @StdUM
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		     and IMWE.Identifier = @SalesUMID and IMWE.RecordType = @rectype
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
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsHQMT]'
   
       return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsHQMT] TO [public]
GO
