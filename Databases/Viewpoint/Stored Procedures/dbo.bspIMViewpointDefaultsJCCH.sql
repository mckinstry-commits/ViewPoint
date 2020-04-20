SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsJCCH]
  /***********************************************************
   * CREATED BY:   DANF 9/19/05 
   * MODIFIED BY:  
   *		CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
   *		AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
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
  
  declare @rcode int, @desc varchar(120), @status int, @defaultvalue varchar(30), @CursorOpen int	
  
  --Identifiers
  declare @JCCoID int, @PhaseGroupID int, @BillFlagID int, @ItemUnitFlagID int, @PhaseUnitFlagID int, @ActiveYNID int, @BuyOutYNID int
  
  --Values
  declare @PhaseGroup bGroup
  
  --Flags for dependent defaults
  
  
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
 			  @OverwriteBillFlag 	 	 bYN
			, @OverwriteItemUnitFlag 	 bYN
			, @OverwritePhaseUnitFlag 	 bYN
			, @OverwriteBuyOutYN 	 	 bYN
			, @OverwriteActiveYN 	 	 bYN
			, @OverwriteJCCo 	 		 bYN
			, @OverwritePhaseGroup 	 	 bYN
			,	@IsJCCoEmpty 			 bYN
			,	@IsPhaseGroupEmpty 		 bYN
			,	@IsJobEmpty 			 bYN
			,	@IsPhaseEmpty 			 bYN
			,	@IsCostTypeEmpty 		 bYN
			,	@IsUMEmpty 				 bYN
			,	@IsBillFlagEmpty 		 bYN
			,	@IsItemUnitFlagEmpty 	 bYN
			,	@IsPhaseUnitFlagEmpty 	 bYN
			,	@IsBuyOutYNEmpty 		 bYN
			,	@IsActiveYNEmpty 		 bYN
			,	@IsOrigHoursEmpty 		 bYN
			,	@IsOrigUnitsEmpty 		 bYN
			,	@IsOrigCostEmpty 		 bYN			
			
	SELECT @OverwriteBillFlag = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BillFlag', @rectype);
	SELECT @OverwriteItemUnitFlag = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ItemUnitFlag', @rectype);
	SELECT @OverwritePhaseUnitFlag = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseUnitFlag', @rectype);
	SELECT @OverwriteBuyOutYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BuyOutYN', @rectype);
	SELECT @OverwriteActiveYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActiveYN', @rectype);
    SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
	SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
  
  --get database default values	
  
  --set common defaults
 
  select @JCCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = @Company
  	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @JCCoID
  end
 
  select @BillFlagID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BillFlag'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBillFlag, 'Y') = 'Y') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = 'C'
  	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @BillFlagID
  end
  
  select @ItemUnitFlagID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ItemUnitFlag'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteItemUnitFlag, 'Y') = 'Y') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = 'N'
  	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @ItemUnitFlagID
  end
  
  select @PhaseUnitFlagID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PhaseUnitFlag'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePhaseUnitFlag, 'Y') = 'Y') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = 'N'
  	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @PhaseUnitFlagID
  end
  
  select @BuyOutYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BuyOutYN'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBuyOutYN, 'Y') = 'Y') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = 'N'
  	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @BuyOutYNID
  end
 
   select @ActiveYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActiveYN'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActiveYN, 'Y') = 'Y') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = 'Y'
  	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActiveYNID
  end
  
  ------------------
  
    select @JCCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCCo, 'Y') = 'N') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = @Company
  	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @JCCoID
  	AND IMWE.UploadVal IS NULL
  end
 
  select @BillFlagID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BillFlag'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBillFlag, 'Y') = 'N') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = 'C'
  	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @BillFlagID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @ItemUnitFlagID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ItemUnitFlag'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteItemUnitFlag, 'Y') = 'N') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = 'N'
  	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @ItemUnitFlagID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @PhaseUnitFlagID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PhaseUnitFlag'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePhaseUnitFlag, 'Y') = 'N') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = 'N'
  	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @PhaseUnitFlagID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @BuyOutYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BuyOutYN'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBuyOutYN, 'Y') = 'N') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = 'N'
  	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @BuyOutYNID
  	AND IMWE.UploadVal IS NULL
  end
 
   select @ActiveYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActiveYN'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActiveYN, 'Y') = 'N') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = 'Y'
  	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActiveYNID
  	AND IMWE.UploadVal IS NULL
  end
  
  --Get Identifiers for dependent defaults.
  
  select @PhaseGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PhaseGroup' and IMTD.DefaultValue = '[Bidtek]'
 
  --NO DEPENDENT DEFAULTS, SKIP THE LOOP
  
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
	--#142350 - removing    @importid varchar(10), @seq int, @Identifier int,
	DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int,
			@complete int
  
  declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
          @columnlist varchar(255), @records int, @oldrecseq int, @JCCo bCompany
  
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
  
      If @Column = 'JCCo' and isnumeric(@Uploadval) =1 select @JCCo = @Uploadval
      
		IF @Column='JCCo' 
			IF @Uploadval IS NULL
				SET @IsJCCoEmpty = 'Y'
			ELSE
				SET @IsJCCoEmpty = 'N'
		IF @Column='PhaseGroup' 
			IF @Uploadval IS NULL
				SET @IsPhaseGroupEmpty = 'Y'
			ELSE
				SET @IsPhaseGroupEmpty = 'N'
		IF @Column='Job' 
			IF @Uploadval IS NULL
				SET @IsJobEmpty = 'Y'
			ELSE
				SET @IsJobEmpty = 'N'
		IF @Column='Phase' 
			IF @Uploadval IS NULL
				SET @IsPhaseEmpty = 'Y'
			ELSE
				SET @IsPhaseEmpty = 'N'
		IF @Column='CostType' 
			IF @Uploadval IS NULL
				SET @IsCostTypeEmpty = 'Y'
			ELSE
				SET @IsCostTypeEmpty = 'N'
		IF @Column='UM' 
			IF @Uploadval IS NULL
				SET @IsUMEmpty = 'Y'
			ELSE
				SET @IsUMEmpty = 'N'
		IF @Column='BillFlag' 
			IF @Uploadval IS NULL
				SET @IsBillFlagEmpty = 'Y'
			ELSE
				SET @IsBillFlagEmpty = 'N'
		IF @Column='ItemUnitFlag' 
			IF @Uploadval IS NULL
				SET @IsItemUnitFlagEmpty = 'Y'
			ELSE
				SET @IsItemUnitFlagEmpty = 'N'
		IF @Column='PhaseUnitFlag' 
			IF @Uploadval IS NULL
				SET @IsPhaseUnitFlagEmpty = 'Y'
			ELSE
				SET @IsPhaseUnitFlagEmpty = 'N'
		IF @Column='BuyOutYN' 
			IF @Uploadval IS NULL
				SET @IsBuyOutYNEmpty = 'Y'
			ELSE
				SET @IsBuyOutYNEmpty = 'N'
		IF @Column='ActiveYN' 
			IF @Uploadval IS NULL
				SET @IsActiveYNEmpty = 'Y'
			ELSE
				SET @IsActiveYNEmpty = 'N'
		IF @Column='OrigHours' 
			IF @Uploadval IS NULL
				SET @IsOrigHoursEmpty = 'Y'
			ELSE
				SET @IsOrigHoursEmpty = 'N'
		IF @Column='OrigUnits' 
			IF @Uploadval IS NULL
				SET @IsOrigUnitsEmpty = 'Y'
			ELSE
				SET @IsOrigUnitsEmpty = 'N'
		IF @Column='OrigCost' 
			IF @Uploadval IS NULL
				SET @IsOrigCostEmpty = 'Y'
			ELSE
				SET @IsOrigCostEmpty = 'N'
		
		  
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
 
 	 if @PhaseGroupID <> 0  AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')
 	 begin
  		exec bspJCPhaseGrpGet @JCCo, @PhaseGroup output, @msg output
 	 
 		 UPDATE IMWE
 		 SET IMWE.UploadVal = @PhaseGroup
		 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   	        and IMWE.Identifier=@PhaseGroupID and IMWE.RecordType=@rectype
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
  
      select @msg = isnull(@desc,'Clear') + char(13) + char(13) + '[bspIMViewpointDefaultsJCPC]'
  
      return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsJCCH] TO [public]
GO
