SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsINMB]
   /***********************************************************
    * CREATED BY:   RBT 09/08/04 for issue #22564
    * MODIFIED BY:  
    *				CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
    *				CC  05/29/09 - Issue #133516 - Correct defaulting of Company
    *				GF 09/14/2010 - issue #141031 change to use vfDateOnlyMonth
    *				AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
	*				GF 04/11/2013 TFS-46929 142183 fix problem with auto number MO
	*
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
   
   select @rcode = 0
   
   --Identifiers
   declare @CoID int, @MthID int, @BatchTransTypeID int, @StatusID int, @JCCoID int, @MOID int
   
   --Values
   declare @Co bCompany, @MO varchar(10)
   
   --Flags for dependent defaults
   declare @ynMO bYN
   
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
			  @OverwriteMth 	 		bYN
			, @OverwriteBatchTransType 	bYN
			, @OverwriteStatus 	 		bYN
			, @OverwriteJCCo 	 		bYN
			, @OverwriteMO 	 			bYN
			, @OverwriteCo				bYN
			,	@IsCoEmpty 				 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsBatchTransTypeEmpty 	 bYN
			,	@IsMOEmpty 				 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsJCCoEmpty 			 bYN
			,	@IsJobEmpty 			 bYN
			,	@IsOrderDateEmpty 		 bYN
			,	@IsOrderedByEmpty 		 bYN
			,	@IsStatusEmpty 			 bYN
			,	@IsNotesEmpty 			 bYN			

	SELECT @OverwriteMth = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Mth', @rectype);
	SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
	SELECT @OverwriteStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Status', @rectype);
	SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);   
    SELECT @OverwriteMO = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MO', @rectype);
    SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
    
   --get database default values	
   
   --set common defaults
   select @CoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @Company
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CoID and IMWE.RecordType = @rectype
   end
   
   select @MthID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Mth'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMth, 'Y') = 'Y') 
   begin
   	Update IMWE
   	----#141031
   	SET IMWE.UploadVal = CONVERT(VARCHAR(10), dbo.vfDateOnlyMonth(), 101)
   	----SET IMWE.UploadVal = right('0' + convert(varchar(2), month(getxdate())),2) + '/01/' + convert(varchar(4), year(getxdate()))
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MthID and IMWE.RecordType = @rectype
   end
   
   select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'A'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID and IMWE.RecordType = @rectype
   end
   
   select @StatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Status'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteStatus, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @StatusID and IMWE.RecordType = @rectype
   end
   
   select @JCCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @Company
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @JCCoID and IMWE.RecordType = @rectype
   end
   
   ------------------------------

   select @CoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @Company
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CoID and IMWE.RecordType = @rectype
   end
      
      select @MthID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Mth'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMth, 'Y')= 'N')
   begin
   	Update IMWE
   	----#141031
   	SET IMWE.UploadVal = CONVERT(VARCHAR(10), dbo.vfDateOnlyMonth(), 101)
   	----SET IMWE.UploadVal = right('0' + convert(varchar(2), month(getxdate())),2) + '/01/' + convert(varchar(4), year(getxdate()))
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MthID and IMWE.RecordType = @rectype
   	AND IMWE.UploadVal IS NULL
   end
   
   select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y')= 'N')
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'A'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID and IMWE.RecordType = @rectype
   	AND IMWE.UploadVal IS NULL
   end
   
   select @StatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Status'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteStatus, 'Y')= 'N')
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @StatusID and IMWE.RecordType = @rectype
   	AND IMWE.UploadVal IS NULL
   end
   
   select @JCCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCCo, 'Y')= 'N')
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @Company
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @JCCoID and IMWE.RecordType = @rectype
   	AND IMWE.UploadVal IS NULL
   end
   
   
   --Get Identifiers for dependent defaults.
   select @ynMO = 'N'
   select @MOID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MO', @rectype, 'Y')
   if @MOID <> 0 select @ynMO = 'Y'
   
   
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
	--#142350 - removing @importid varchar(10), @seq int, @Identifier int,
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
   
       If @Column = 'Co' select @Co = @Uploadval
   	--If @Column = 'MO' select @MO = @Uploadval
	IF @Column='Co' 
		IF @Uploadval IS NULL
			SET @IsCoEmpty = 'Y'
		ELSE
			SET @IsCoEmpty = 'N'
	IF @Column='Mth' 
		IF @Uploadval IS NULL
			SET @IsMthEmpty = 'Y'
		ELSE
			SET @IsMthEmpty = 'N'
	IF @Column='BatchId' 
		IF @Uploadval IS NULL
			SET @IsBatchIdEmpty = 'Y'
		ELSE
			SET @IsBatchIdEmpty = 'N'
	IF @Column='BatchSeq' 
		IF @Uploadval IS NULL
			SET @IsBatchSeqEmpty = 'Y'
		ELSE
			SET @IsBatchSeqEmpty = 'N'
	IF @Column='BatchTransType' 
		IF @Uploadval IS NULL
			SET @IsBatchTransTypeEmpty = 'Y'
		ELSE
			SET @IsBatchTransTypeEmpty = 'N'
	IF @Column='MO' 
		IF @Uploadval IS NULL
			SET @IsMOEmpty = 'Y'
		ELSE
			SET @IsMOEmpty = 'N'
	IF @Column='Description' 
		IF @Uploadval IS NULL
			SET @IsDescriptionEmpty = 'Y'
		ELSE
			SET @IsDescriptionEmpty = 'N'
	IF @Column='JCCo' 
		IF @Uploadval IS NULL
			SET @IsJCCoEmpty = 'Y'
		ELSE
			SET @IsJCCoEmpty = 'N'
	IF @Column='Job' 
		IF @Uploadval IS NULL
			SET @IsJobEmpty = 'Y'
		ELSE
			SET @IsJobEmpty = 'N'
	IF @Column='OrderDate' 
		IF @Uploadval IS NULL
			SET @IsOrderDateEmpty = 'Y'
		ELSE
			SET @IsOrderDateEmpty = 'N'
	IF @Column='OrderedBy' 
		IF @Uploadval IS NULL
			SET @IsOrderedByEmpty = 'Y'
		ELSE
			SET @IsOrderedByEmpty = 'N'
	IF @Column='Status' 
		IF @Uploadval IS NULL
			SET @IsStatusEmpty = 'Y'
		ELSE
			SET @IsStatusEmpty = 'N'
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
   	if @ynMO = 'Y' AND (ISNULL(@OverwriteMO, 'Y') = 'Y' OR ISNULL(@IsMOEmpty, 'Y') = 'Y')
   	begin
   		select @MO = null
   
   		exec @recode = bspINMONextMO @Co, @MO output
		----TFS-46929
		select @MO = convert(varchar(10),convert(int, isNull(@MO,'0')))
   		----select @MO = convert(varchar(10),convert(int, isNull(@MO,'0')) + @currrecseq - 1)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @MO
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@MOID and IMWE.RecordType=@rectype
   
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
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsINMB]'
   
       return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsINMB] TO [public]
GO
