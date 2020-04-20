SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsPOVM]
   /***********************************************************
    * CREATED BY:   RBT 05/09/05 for issue #28486
    * MODIFIED BY:  
	*				CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
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
    ************************************************************/
   
    (@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), 
   	@Form varchar(20), @rectype varchar(30), @msg varchar(120) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @desc varchar(120), @status int, @defaultvalue varchar(30), @CursorOpen int, @recode int	
   
   --Identifiers
   declare @VendorGroupID int, @CostOptID int, @VendMatIdID int, @DescriptionID int, @MatlGroupID int, @UMID int, 
   @UnitCostID int, @CostECMID int, @BookPriceID int, @PriceECMID int, @PriceDiscID int
   
   
   --Values
   declare @Vendor bVendor, @VendMatId varchar(30), @Description bDesc, @MatlGroup bGroup, @UM bUM, @CostOpt tinyint,
   @UnitCost bUnitCost, @CostECM bECM, @BookPrice bUnitCost, @PriceECM bECM, @DefVendGrp bGroup,
   @Material bMatl, @DefUM bUM, @DefUnitCost bUnitCost, @DefCostECM bECM, @DefPrice bUnitCost, @DefPriceECM bECM
   
   
   --Flags for dependent defaults
   declare @ynVendMatId bYN, @ynDescription bYN, @ynMatlGroup bYN, @ynUM bYN, 
   @ynUnitCost bYN, @ynCostECM bYN, @ynBookPrice bYN, @ynPriceECM bYN
   
   
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
			  @OverwriteVendorGroup 	 bYN
			, @OverwriteCostOpt 	 	 bYN
			, @OverwriteVendMatId 	 	 bYN
			, @OverwriteDescription 	 bYN
			, @OverwriteMatlGroup 	 	 bYN
			, @OverwriteUM 	 			 bYN
			, @OverwriteUnitCost 	 	 bYN
			, @OverwriteCostECM 	 	 bYN
			, @OverwriteBookPrice 	 	 bYN
			, @OverwritePriceECM 	 	 bYN
			,	@IsVendorGroupEmpty 	bYN
			,	@IsVendorEmpty 		 	bYN
			,	@IsMatlGroupEmpty 	 	bYN
			,	@IsMaterialEmpty 	 	bYN
			,	@IsUMEmpty 			 	bYN
			,	@IsVendMatIdEmpty 	 	bYN
			,	@IsDescriptionEmpty  	bYN
			,	@IsCostOptEmpty 	 	bYN
			,	@IsUnitCostEmpty 	 	bYN
			,	@IsCostECMEmpty 	 	bYN
			,	@IsPriceDiscEmpty 	 	bYN
			,	@IsBookPriceEmpty 	 	bYN
			,	@IsPriceECMEmpty 	 	bYN
			,	@IsNotesEmpty 		 	bYN

	SELECT @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype);
	SELECT @OverwriteCostOpt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostOpt', @rectype);
    SELECT @OverwriteVendMatId = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendMatId', @rectype);
	SELECT @OverwriteDescription = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Description', @rectype);
	SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
	SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UM', @rectype);
	SELECT @OverwriteUnitCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnitCost', @rectype);
	SELECT @OverwriteCostECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostECM', @rectype);
	SELECT @OverwriteBookPrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BookPrice', @rectype);
	SELECT @OverwritePriceECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PriceECM', @rectype);

   
   --get database default values	
   
   --set common defaults
   exec @recode = bspAPVendorGrpGet @Company, @DefVendGrp output, @msg output
   
   select @VendorGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'VendorGroup'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @DefVendGrp
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @VendorGroupID
   end
   
   select @CostOptID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CostOpt'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCostOpt, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '1'
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CostOptID
   end
   
   -------------------------
      select @VendorGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'VendorGroup'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @DefVendGrp
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @VendorGroupID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @CostOptID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CostOpt'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCostOpt, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '1'
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CostOptID
   	AND IMWE.UploadVal IS NULL
   end
   
   
   --Get Identifiers for dependent defaults.
   select @ynVendMatId = 'N'
   select @VendMatIdID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendMatId', @rectype, 'Y')
   if @VendMatIdID <> 0 select @ynVendMatId = 'Y'
   
   select @ynDescription = 'N'
   select @DescriptionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Description', @rectype, 'Y')
   if @DescriptionID <> 0 select @ynDescription = 'Y'
   
   select @ynMatlGroup = 'N'
   select @MatlGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MatlGroup', @rectype, 'Y')
   if @MatlGroupID <> 0 select @ynMatlGroup = 'Y'
   
   select @ynUM = 'N'
   select @UMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UM', @rectype, 'Y')
   if @UMID <> 0 select @ynUM = 'Y'
   
   select @ynUnitCost = 'N'
   select @UnitCostID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnitCost', @rectype, 'Y')
   if @UnitCostID <> 0 select @ynUnitCost = 'Y'
   
   select @ynCostECM = 'N'
   select @CostECMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CostECM', @rectype, 'Y')
   if @CostECMID <> 0 select @ynCostECM = 'Y'
   
   select @ynBookPrice = 'N'
   select @BookPriceID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BookPrice', @rectype, 'Y')
   if @BookPriceID <> 0 select @ynBookPrice = 'Y'
   
   select @ynPriceECM = 'N'
   select @PriceECMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PriceECM', @rectype, 'Y')
   if @PriceECMID <> 0 select @ynPriceECM = 'Y'
   
   select @PriceDiscID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PriceDisc', @rectype, 'N')
   
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
	-- #142350 - removing @importid varchar(10), @seq int, @Identifier int
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
   
   	If @Column = 'Vendor' select @Vendor = @Uploadval
   	If @Column = 'VendMatId' select @VendMatId = @Uploadval
   	If @Column = 'Description' select @Description = @Uploadval
   	If @Column = 'MatlGroup' select @MatlGroup = @Uploadval
   	If @Column = 'Material' select @Material = @Uploadval
   	If @Column = 'UM' select @UM = @Uploadval
   	If @Column = 'CostOpt' select @CostOpt = @Uploadval
   	If @Column = 'UnitCost' select @UnitCost = @Uploadval
   	If @Column = 'CostECM' select @CostECM = @Uploadval
   	If @Column = 'BookPrice' select @BookPrice = @Uploadval
   	If @Column = 'PriceECM' select @PriceECM = @Uploadval

		IF @Column='VendorGroup' 
			IF @Uploadval IS NULL
				SET @IsVendorGroupEmpty = 'Y'
			ELSE
				SET @IsVendorGroupEmpty = 'N'
		IF @Column='Vendor' 
			IF @Uploadval IS NULL
				SET @IsVendorEmpty = 'Y'
			ELSE
				SET @IsVendorEmpty = 'N'
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
		IF @Column='UM' 
			IF @Uploadval IS NULL
				SET @IsUMEmpty = 'Y'
			ELSE
				SET @IsUMEmpty = 'N'
		IF @Column='VendMatId' 
			IF @Uploadval IS NULL
				SET @IsVendMatIdEmpty = 'Y'
			ELSE
				SET @IsVendMatIdEmpty = 'N'
		IF @Column='Description' 
			IF @Uploadval IS NULL
				SET @IsDescriptionEmpty = 'Y'
			ELSE
				SET @IsDescriptionEmpty = 'N'
		IF @Column='CostOpt' 
			IF @Uploadval IS NULL
				SET @IsCostOptEmpty = 'Y'
			ELSE
				SET @IsCostOptEmpty = 'N'
		IF @Column='UnitCost' 
			IF @Uploadval IS NULL
				SET @IsUnitCostEmpty = 'Y'
			ELSE
				SET @IsUnitCostEmpty = 'N'
		IF @Column='CostECM' 
			IF @Uploadval IS NULL
				SET @IsCostECMEmpty = 'Y'
			ELSE
				SET @IsCostECMEmpty = 'N'
		IF @Column='PriceDisc' 
			IF @Uploadval IS NULL
				SET @IsPriceDiscEmpty = 'Y'
			ELSE
				SET @IsPriceDiscEmpty = 'N'
		IF @Column='BookPrice' 
			IF @Uploadval IS NULL
				SET @IsBookPriceEmpty = 'Y'
			ELSE
				SET @IsBookPriceEmpty = 'N'
		IF @Column='PriceECM' 
			IF @Uploadval IS NULL
				SET @IsPriceECMEmpty = 'Y'
			ELSE
				SET @IsPriceECMEmpty = 'N'
		IF @Column='Notes' 
			IF @Uploadval IS NULL
				SET @IsNotesEmpty = 'Y'
			ELSE
				SET @IsNotesEmpty = 'N'
   
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
   
   	if @ynUM = 'Y' AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')
   	begin
   		exec @recode = bspHQMatlVal @MatlGroup, @Material, @DefUM output, @msg output
   
   		select @UM = @DefUM
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @UM
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@UMID and IMWE.RecordType=@rectype
   
   	end
   
   	if @MatlGroup is not null and @Material is not null and @UM is not null AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR ISNULL(@IsMatlGroupEmpty, 'Y') = 'Y')
   	begin
   		select @DefUnitCost = Cost, @DefCostECM = CostECM, @DefPrice = Price, @DefPriceECM = PriceECM
    		from bHQMT
    		where MatlGroup = @MatlGroup and Material = @Material and StdUM = @UM
   		if @@rowcount = 0 
   	 	begin
       	   	select @DefUnitCost = Cost, @DefCostECM = CostECM, @DefPrice = Price, @DefPriceECM = PriceECM
    			from bHQMU
       		where MatlGroup = @MatlGroup and Material = @Material and UM = @UM
   	   	end 
    	end
   
   	if @ynUnitCost = 'Y' AND (ISNULL(@OverwriteUnitCost, 'Y') = 'Y' OR ISNULL(@IsUnitCostEmpty, 'Y') = 'Y')
   	begin
   		if @CostOpt = 2
   			select @UnitCost = @DefUnitCost
   		else	
   			select @UnitCost = null
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @UnitCost
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@UnitCostID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynCostECM = 'Y'  AND (ISNULL(@OverwriteCostECM, 'Y') = 'Y' OR ISNULL(@IsCostECMEmpty, 'Y') = 'Y')
   	begin
   		if @CostOpt = 2
   			select @CostECM = @DefCostECM
   		else
			select @CostECM = null
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @CostECM
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@CostECMID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynBookPrice = 'Y'  AND (ISNULL(@OverwriteBookPrice, 'Y') = 'Y' OR ISNULL(@IsBookPriceEmpty, 'Y') = 'Y')
   	begin
   		if @CostOpt = 4
   			select @BookPrice = @DefPrice
   		else
   			select @BookPrice = null
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @BookPrice
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@BookPriceID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynPriceECM = 'Y'  AND (ISNULL(@OverwritePriceECM, 'Y') = 'Y' OR ISNULL(@IsPriceECMEmpty, 'Y') = 'Y')
   	begin
   		if @CostOpt = 4
   			select @PriceECM = @DefPriceECM
   		else
   			select @PriceECM = null
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @PriceECM
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@PriceECMID and IMWE.RecordType=@rectype
   
   	end
   
   	--set PriceDisc to null for UnitCost types
   	if @CostOpt = 1 or @CostOpt = 2
   	begin
   		UPDATE IMWE
   		SET IMWE.UploadVal = null
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@PriceDiscID and IMWE.RecordType=@rectype
   	end
   
   	select @Vendor = null
   	select @VendMatId = null
   	select @Description = null
   	select @MatlGroup = null
   	select @Material = null
   	select @UM = null
   	select @CostOpt = null
   	select @UnitCost = null
   	select @CostECM = null
   	select @BookPrice = null
   	select @PriceECM = null
   
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
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsPOVM]'
   
       return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsPOVM] TO [public]
GO
