SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsJCPC]
   /***********************************************************
    * CREATED BY:   RBT 9/19/05 for issue #28897
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
   declare @PhaseGroupID int, @BillFlagID int, @ItemUnitFlagID int, @PhaseUnitFlagID int
   
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
			  @OverwritePhaseGroup 	 	 bYN
			, @OverwriteBillFlag 	 	 bYN
			, @OverwriteItemUnitFlag 	 bYN
			, @OverwritePhaseUnitFlag 	 bYN
			,	@IsPhaseGroupEmpty 		 bYN
			,	@IsPhaseEmpty 			 bYN
			,	@IsCostTypeEmpty 		 bYN
			,	@IsUMEmpty 				 bYN
			,	@IsBillFlagEmpty 		 bYN
			,	@IsItemUnitFlagEmpty 	 bYN
			,	@IsPhaseUnitFlagEmpty 	 bYN

	SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
	SELECT @OverwriteBillFlag = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BillFlag', @rectype);
	SELECT @OverwriteItemUnitFlag = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ItemUnitFlag', @rectype);
	SELECT @OverwritePhaseUnitFlag = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseUnitFlag', @rectype);
   
   --get database default values	
   
   --set common defaults
   select @PhaseGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PhaseGroup'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y') 
   begin
   	exec bspJCPhaseGrpGet @Company, @PhaseGroup output, @msg output
   
       UPDATE IMWE
       SET IMWE.UploadVal = @PhaseGroup
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PhaseGroupID
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
   
   ------------------------
      select @PhaseGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PhaseGroup'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'N') 
   begin
   	exec bspJCPhaseGrpGet @Company, @PhaseGroup output, @msg output
   
       UPDATE IMWE
       SET IMWE.UploadVal = @PhaseGroup
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PhaseGroupID
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
   
   --Get Identifiers for dependent defaults.
   
   --NO DEPENDENT DEFAULTS, SKIP THE LOOP
   goto bspexit
   
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
   --#142350 - removing	@importid varchar(10), @seq int, @Identifier int,
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
   
       --If @Column = 'JCCo' select @JCCo = @Uploadval
		IF @Column='PhaseGroup' 
			IF @Uploadval IS NULL
				SET @IsPhaseGroupEmpty = 'Y'
			ELSE
				SET @IsPhaseGroupEmpty = 'N'
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
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsJCPC]'
   
       return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsJCPC] TO [public]
GO
