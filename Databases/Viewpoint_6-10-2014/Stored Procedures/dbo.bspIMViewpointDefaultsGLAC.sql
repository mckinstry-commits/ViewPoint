SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsGLAC]
   /***********************************************************
    * CREATED BY:   RBT 09/12/05 for issue #29592
    * MODIFIED BY:  DANF 12/12/06 - Issue 123301 Fix GL Company default.
    *				CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
    *				CC  05/29/09 - Issue #133516 - Correct defaulting of Company
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
   
   declare @rcode int, @desc varchar(120), @status int, @defaultvalue varchar(30), @CursorOpen int	
   
   --Identifiers
   declare @GLCoID int, @AcctTypeID int, @ActiveID int, @InterfaceDetailID int,
   @CashAccrualID int, @NormBalID int, @SummaryAcctID int, @CashOffAcctID int, @SubTypeID int
   
   --Values
   declare @GLCo bCompany, @CashAccrual varchar(1), @NormBal varchar(1), @SummaryAcct bGLAcct, @GLAcct bGLAcct,
   @GLCOCashAccrual varchar(1), @AcctType varchar(1), @CashOffAcct bGLAcct
   
   --Flags for dependent defaults
   declare @ynCashAccrual bYN, @ynNormBal bYN, @ynSummaryAcct bYN
   
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
			  @OverwriteActive 	 		 bYN
			, @OverwriteInterfaceDetail  bYN
			, @OverwriteSubType 	 	 bYN
			, @OverwriteCashAccrual 	 bYN
			, @OverwriteNormBal 	 	 bYN
			, @OverwriteSummaryAcct 	 bYN
			, @OverwriteCo				 bYN
			,	@IsGLCoEmpty 			 bYN
			,	@IsGLAcctEmpty 			 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsAcctTypeEmpty 		 bYN
			,	@IsNormBalEmpty 		 bYN
			,	@IsSubTypeEmpty 		 bYN
			,	@IsSummaryAcctEmpty 	 bYN
			,	@IsActiveEmpty 			 bYN
			,	@IsInterfaceDetailEmpty  bYN
			,	@IsCrossRefMemAcctEmpty  bYN
			,	@IsNotesEmpty 			 bYN

	SELECT @OverwriteActive = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Active', @rectype);
	SELECT @OverwriteInterfaceDetail = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InterfaceDetail', @rectype);
	SELECT @OverwriteSubType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SubType', @rectype);
    SELECT @OverwriteCashAccrual = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CashAccrual', @rectype);
	SELECT @OverwriteNormBal = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'NormBal', @rectype);
	SELECT @OverwriteSummaryAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SummaryAcct', @rectype);
   	SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
   --get database default values	
   
   --set common defaults
   select @GLCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @GLCoID
   end
   
   select @ActiveID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Active'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActive, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'Y'
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActiveID
   end
   
   select @InterfaceDetailID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InterfaceDetail'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteInterfaceDetail, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @InterfaceDetailID
   end
   
   select @SubTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SubType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSubType, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = null
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @SubTypeID
   end
-------------------

   select @GLCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @GLCoID
   end

   select @ActiveID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Active'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActive, 'Y')= 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'Y'
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActiveID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @InterfaceDetailID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InterfaceDetail'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteInterfaceDetail, 'Y')= 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @InterfaceDetailID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @SubTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SubType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSubType, 'Y')= 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = null
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @SubTypeID
   	AND IMWE.UploadVal IS NULL
   end
   
   
   --Get Identifiers for dependent defaults.
   select @ynCashAccrual = 'N'
   select @CashAccrualID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CashAccrual', @rectype, 'Y')
   if @CashAccrualID <> 0 select @ynCashAccrual = 'Y'
   
   select @ynNormBal = 'N'
   select @NormBalID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'NormBal', @rectype, 'Y')
   if @NormBalID <> 0 select @ynNormBal = 'Y'
   
   select @ynSummaryAcct = 'N'
   select @SummaryAcctID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SummaryAcct', @rectype, 'Y')
   if @SummaryAcctID <> 0 select @ynSummaryAcct = 'Y'
   
   --get other identifiers
   select @CashOffAcctID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CashOffAcct', @rectype, 'N')
   
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

	--#142350 removing   @importid varchar(10), @seq int, @Identifier int,
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
   
       If @Column = 'GLCo' select @GLCo = @Uploadval
   	If @Column = 'GLAcct' select @GLAcct = @Uploadval
   	If @Column = 'CashAccrual' select @CashAccrual = @Uploadval
   	If @Column = 'NormBal' select @NormBal = @Uploadval
   	If @Column = 'SummaryAcct' select @SummaryAcct = @Uploadval
   	If @Column = 'AcctType' select @AcctType = @Uploadval

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
	IF @Column='Description' 
		IF @Uploadval IS NULL
			SET @IsDescriptionEmpty = 'Y'
		ELSE
			SET @IsDescriptionEmpty = 'N'
	IF @Column='AcctType' 
		IF @Uploadval IS NULL
			SET @IsAcctTypeEmpty = 'Y'
		ELSE
			SET @IsAcctTypeEmpty = 'N'
	IF @Column='NormBal' 
		IF @Uploadval IS NULL
			SET @IsNormBalEmpty = 'Y'
		ELSE
			SET @IsNormBalEmpty = 'N'
	IF @Column='SubType' 
		IF @Uploadval IS NULL
			SET @IsSubTypeEmpty = 'Y'
		ELSE
			SET @IsSubTypeEmpty = 'N'
	IF @Column='SummaryAcct' 
		IF @Uploadval IS NULL
			SET @IsSummaryAcctEmpty = 'Y'
		ELSE
			SET @IsSummaryAcctEmpty = 'N'
	IF @Column='Active' 
		IF @Uploadval IS NULL
			SET @IsActiveEmpty = 'Y'
		ELSE
			SET @IsActiveEmpty = 'N'
	IF @Column='InterfaceDetail' 
		IF @Uploadval IS NULL
			SET @IsInterfaceDetailEmpty = 'Y'
		ELSE
			SET @IsInterfaceDetailEmpty = 'N'
	IF @Column='CrossRefMemAcct' 
		IF @Uploadval IS NULL
			SET @IsCrossRefMemAcctEmpty = 'Y'
		ELSE
			SET @IsCrossRefMemAcctEmpty = 'N'
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
   	--get company default value for Cash Accrual
   	select @GLCOCashAccrual = CashAccrual from GLCO with (nolock) where GLCo = @GLCo
   
   	-- set values that depend on other columns
   
   	--CashAccrual default is A, and if GLCO CashAccrual is A then this one must be A.
   	if (@ynCashAccrual = 'Y' or @GLCOCashAccrual = 'A') and @CashAccrualID<>0   AND (ISNULL(@OverwriteCashAccrual, 'Y') = 'Y' OR @CashAccrual IS NULL) 
   	begin
   		select @CashAccrual = 'A'
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @CashAccrual
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@CashAccrualID and IMWE.RecordType=@rectype
   	end
   
   	if @CashAccrual = 'A'
   	begin
   		--clear the Cash Offset Acct if CashAccrual = A
   		select @CashOffAcct = null
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @CashOffAcct
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@CashOffAcctID and IMWE.RecordType=@rectype
   	end
   
   	if @ynNormBal = 'Y' AND (ISNULL(@OverwriteNormBal, 'Y') = 'Y' OR ISNULL(@IsNormBalEmpty, 'Y') = 'Y')
   	begin
   		if @AcctType = 'A' or @AcctType = 'E'
   			select @NormBal = 'D'
   		else
   			select @NormBal = 'C'
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @NormBal
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@NormBalID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynSummaryAcct = 'Y'  AND (ISNULL(@OverwriteSummaryAcct, 'Y') = 'Y' OR ISNULL(@IsSummaryAcctEmpty, 'Y') = 'Y')
   	begin
   		select @SummaryAcct = @GLAcct
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @SummaryAcct
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@SummaryAcctID and IMWE.RecordType=@rectype
   
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
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsGLAC]'
   
       return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsGLAC] TO [public]
GO
