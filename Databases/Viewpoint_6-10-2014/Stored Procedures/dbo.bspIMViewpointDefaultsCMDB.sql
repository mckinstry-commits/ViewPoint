SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsCMDB]
   /***********************************************************
    * CREATED BY:   RBT 07/17/03 for issue #17182 - CM Outstanding Entries
    * MODIFIED BY: 
    *				CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
    *				CC  05/29/09 - Issue #133516 - Correct defaulting of Company
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
   
    (@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @rectype varchar(30), @msg varchar(120) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @DefaultIndc varchar(10), @desc varchar(120), @status int, 
   		@defaultvalue varchar(30), @CursorOpen int,
   		@BatchTransTypeID int, @VoidTrans bYN, @VoidID int, @CompanyID int, @GLCo bCompany,
   		@GLCoID int, @ynGLCo bYN, @CMGLAcct bGLAcct, @CMGLAcctID int, @ynCMGLAcct bYN,
   		@ynRefSeq bYN, @CMRefSeqID int, @CMRefID int 
   
   -- Set default indicator text.
   select @DefaultIndc = '[Bidtek]'
   
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
   	Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = @DefaultIndc
   	and IMTD.RecordType = @rectype)
   	goto bspexit
   
   DECLARE 
			  @OverwriteBatchTransType 	 bYN
			, @OverwriteVoid 	 		 bYN
			, @OverwriteGLCo 	 		 bYN
			, @OverwriteCMGLAcct 	 	 bYN
			, @OverwriteCMRefSeq 	 	 bYN
			, @OverwriteCo				 bYN
			,	@IsCoEmpty 				 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsBatchTransTypeEmpty 	 bYN
			,	@IsCMAcctEmpty 			 bYN
			,	@IsCMTransTypeEmpty 	 bYN
			,	@IsCMRefEmpty 			 bYN
			,	@IsCMRefSeqEmpty 		 bYN
			,	@IsActDateEmpty 		 bYN
			,	@IsAmountEmpty 			 bYN
			,	@IsPayeeEmpty 			 bYN
			,	@IsVoidEmpty 			 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsGLCoEmpty 			 bYN
			,	@IsGLAcctEmpty 			 bYN
			,	@IsCMGLAcctEmpty 		 bYN			
   
    SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
	SELECT @OverwriteVoid = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Void', @rectype);
	SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
	SELECT @OverwriteCMGLAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CMGLAcct', @rectype);
	SELECT @OverwriteCMRefSeq = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CMRefSeq', @rectype);
	SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
   
   --Co, set value for all
   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
   if @@rowcount <> 0 and @defaultvalue = @DefaultIndc
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
   end
   
   --BatchTransType, set value for all
   select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
   if @@rowcount <> 0 and @defaultvalue = @DefaultIndc AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'A'
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
   end
   
   --Void, set value for all
   select @VoidID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Void'
   if @@rowcount <> 0 and @defaultvalue = @DefaultIndc  AND (ISNULL(@OverwriteVoid, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'N'
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @VoidID
   end
   
   
   ---------------------

   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
   if @@rowcount <> 0 and @defaultvalue = @DefaultIndc
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
   end
   
   
      --BatchTransType, set value for all
   select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
   if @@rowcount <> 0 and @defaultvalue = @DefaultIndc AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'A'
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
       AND IMWE.UploadVal IS NULL
   end
   
   --Void, set value for all
   select @VoidID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Void'
   if @@rowcount <> 0 and @defaultvalue = @DefaultIndc  AND (ISNULL(@OverwriteVoid, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = 'N'
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @VoidID
       AND IMWE.UploadVal IS NULL
   end
   
   
   
   --GLCo, set flag
   select @ynGLCo = 'N'
   select @GLCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLCo', @rectype, 'Y')
   if @GLCoID <> 0 select @ynGLCo = 'Y'
   
   --CMGLAcct, set flag
   select @ynCMGLAcct = 'N'
   select @CMGLAcctID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CMGLAcct', @rectype, 'Y')
   if @CMGLAcctID <> 0 select @ynCMGLAcct = 'Y'
   
   --CMRefSeq, set flag
   select @ynRefSeq = 'N'
   select @CMRefSeqID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CMRefSeq', @rectype, 'Y')
   if @CMRefSeqID <> 0 
  
   begin
   	select @ynRefSeq = 'Y'
   	
   	--If we are using Viewpoint defaults, set all CMRefSeq fields to null so later calculation works.
   	UPDATE IMWE
   	SET IMWE.UploadVal = null
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
   	     and IMWE.Identifier = @CMRefSeqID
   
   	--Get CMRef Identifier number (whether or not it is a Default field).
   	select @CMRefID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CMRef', @rectype, 'N')
   end
   
   
   DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD FOR
   SELECT IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
   FROM IMWE with (nolock)
   INNER join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
   WHERE IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
   ORDER BY IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   -- set open cursor flag
   select @CursorOpen = 1
	-- #142350 - @importid,@seq
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
   		@CMRef bCMRef, @CMRefSeq tinyint, @ActDate smalldatetime, @Payee varchar(20), 
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
   
       If @Column = 'Co' and isnumeric(@Uploadval) = 1 select @Co = Convert(int, @Uploadval)
   	If @Column = 'Mth' and isdate(@Uploadval) = 1 select @Mth = Convert(smalldatetime, @Uploadval)
   	If @Column = 'CMAcct' and isnumeric(@Uploadval) = 1 select @CMAcct = @Uploadval
   	If @Column = 'CMTransType' and isnumeric(@Uploadval) = 1 select @CMTransType = @Uploadval
   	If @Column = 'CMRef' select @CMRef = @Uploadval
   	If @Column = 'CMRefSeq' and isnumeric(@Uploadval) = 1 select @CMRefSeq = @Uploadval
   	If @Column = 'ActDate' and isdate(@Uploadval) = 1 select @ActDate = @Uploadval
   	If @Column = 'Amount' and isnumeric(@Uploadval) = 1 select @Amount = @Uploadval
   	If @Column = 'Payee' select @Payee = @Uploadval
   	If @Column = 'Description' select @Description = @Uploadval
   	If @Column = 'GLCo' and isnumeric(@Uploadval) = 1 select @GLCo = @Uploadval
   	If @Column = 'GLAcct' select @GLAcct = @Uploadval
   	If @Column = 'CMGLAcct' select @CMGLAcct = @Uploadval

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
	IF @Column='CMAcct' 
		IF @Uploadval IS NULL
			SET @IsCMAcctEmpty = 'Y'
		ELSE
			SET @IsCMAcctEmpty = 'N'
	IF @Column='CMTransType' 
		IF @Uploadval IS NULL
			SET @IsCMTransTypeEmpty = 'Y'
		ELSE
			SET @IsCMTransTypeEmpty = 'N'
	IF @Column='CMRef' 
		IF @Uploadval IS NULL
			SET @IsCMRefEmpty = 'Y'
		ELSE
			SET @IsCMRefEmpty = 'N'
	IF @Column='CMRefSeq' 
		IF @Uploadval IS NULL
			SET @IsCMRefSeqEmpty = 'Y'
		ELSE
			SET @IsCMRefSeqEmpty = 'N'
	IF @Column='ActDate' 
		IF @Uploadval IS NULL
			SET @IsActDateEmpty = 'Y'
		ELSE
			SET @IsActDateEmpty = 'N'
	IF @Column='Amount' 
		IF @Uploadval IS NULL
			SET @IsAmountEmpty = 'Y'
		ELSE
			SET @IsAmountEmpty = 'N'
	IF @Column='Payee' 
		IF @Uploadval IS NULL
			SET @IsPayeeEmpty = 'Y'
		ELSE
			SET @IsPayeeEmpty = 'N'
	IF @Column='Void' 
		IF @Uploadval IS NULL
			SET @IsVoidEmpty = 'Y'
		ELSE
			SET @IsVoidEmpty = 'N'
	IF @Column='Description' 
		IF @Uploadval IS NULL
			SET @IsDescriptionEmpty = 'Y'
		ELSE
			SET @IsDescriptionEmpty = 'N'
	IF @Column='GLCo' 
		IF @Uploadval IS NULL
			SET @IsGLCoEmpty = 'Y'
		ELSE
			SET @IsGLCoEmpty = 'N'
	IF @Column='GLAcct' 
		IF @Uploadval IS NULL
			SET @IsGLAcctEmpty = 'Y'
		ELSE
			SET @IsGLAcctEmpty = 'N'
	IF @Column='CMGLAcct' 
		IF @Uploadval IS NULL
			SET @IsCMGLAcctEmpty = 'Y'
		ELSE
			SET @IsCMGLAcctEmpty = 'N'
   
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
   	if @ynGLCo = 'Y' AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
   	begin	
   		select @GLCo = GLCo from bCMCO with (nolock) where CMCo = @Co
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @GLCo
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		     and IMWE.Identifier = @GLCoID and IMWE.RecordType = @rectype
   	end
   
   	if @ynCMGLAcct = 'Y' AND (ISNULL(@OverwriteCMGLAcct, 'Y') = 'Y' OR ISNULL(@IsCMGLAcctEmpty, 'Y') = 'Y')
   	begin
  		select @CMGLAcct = GLAcct from bCMAC with (nolock) where CMCo = @Co and CMAcct = @CMAcct and GLCo = @GLCo
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @CMGLAcct
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		     and IMWE.Identifier = @CMGLAcctID and IMWE.RecordType = @rectype
   	end
   
   	if @ynRefSeq = 'Y'  AND (ISNULL(@OverwriteCMRefSeq, 'Y') = 'Y' OR ISNULL(@IsCMRefSeqEmpty, 'Y') = 'Y')
   	begin
   		-- calculate sequence number
   		select @CMRefSeq = isnull(max(UploadVal), -1) + 1 from bIMWE with (nolock)
   		where ImportId = @ImportId and ImportTemplate = @ImportTemplate
   		and Identifier = @CMRefSeqID and RecordSeq in 
   		(select RecordSeq from bIMWE with (nolock) where ImportId = @ImportId and 
   		ImportTemplate = @ImportTemplate and Identifier = @CMRefID and UploadVal = @CMRef)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @CMRefSeq
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		     and IMWE.Identifier = @CMRefSeqID and IMWE.RecordType = @rectype
   
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
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspViewpointDefaultsCMDB]'
   
       return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsCMDB] TO [public]
GO
