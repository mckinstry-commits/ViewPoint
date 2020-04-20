SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsPREA]
   /***********************************************************
    * CREATED BY:   RBT 07/16/04 for issue #24985
    * MODIFIED BY:  DANF 06/11/07 - Issue 124799 Initialized amounts to zero if null.
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
   
   declare @rcode int, @desc varchar(120), @status int, @defaultvalue varchar(30), @CursorOpen int	
   
   --Identifiers
   declare @PRCoID int, @AuditYNID int, @SubjectAmtID int, @EligibleAmtID int, 
			@cHoursID int, @cAmountID int, @cSubjectAmtID int, @cEligibleAmtID int

   
   --Values
   
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
			  @OverwritePRCo 	 	 bYN
			, @OverwriteAuditYN 	 bYN
			, @OverwriteSubjectAmt 	 bYN
			, @OverwriteEligibleAmt  bYN
			,	@IsPRCoEmpty 		 bYN
			,	@IsEmployeeEmpty 	 bYN
			,	@IsMthEmpty 		 bYN
			,	@IsEDLTypeEmpty 	 bYN
			,	@IsEDLCodeEmpty 	 bYN
			,	@IsHoursEmpty 		 bYN
			,	@IsAmountEmpty 		 bYN
			,	@IsSubjectAmtEmpty 	 bYN
			,	@IsEligibleAmtEmpty  bYN
			,	@IsAuditYNEmpty 	 bYN			

	SELECT @OverwritePRCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRCo', @rectype);
	SELECT @OverwriteAuditYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AuditYN', @rectype);
	SELECT @OverwriteSubjectAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SubjectAmt', @rectype);
	SELECT @OverwriteEligibleAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EligibleAmt', @rectype);
   
  
   
   --get database default values	
   
   --set common defaults
   select @PRCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PRCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePRCo, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PRCoID
   end
   
   select @AuditYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AuditYN'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAuditYN, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'Y'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @AuditYNID
   end
   
   select @SubjectAmtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SubjectAmt'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSubjectAmt, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @SubjectAmtID
   end
   
   select @EligibleAmtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EligibleAmt'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteEligibleAmt, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @EligibleAmtID
   end
   
-------------------------
      select @PRCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PRCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePRCo, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PRCoID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @AuditYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AuditYN'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAuditYN, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'Y'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @AuditYNID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @SubjectAmtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SubjectAmt'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSubjectAmt, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @SubjectAmtID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @EligibleAmtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EligibleAmt'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteEligibleAmt, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @EligibleAmtID
   	AND IMWE.UploadVal IS NULL
   end
   
   
  select @cHoursID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Hours', @rectype, 'N')
  select @cAmountID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Amount', @rectype, 'N')
  select @cSubjectAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SubjectAmt', @rectype, 'N')
  select @cEligibleAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EligibleAmt', @rectype, 'N')
   
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
	-- #142350 - removing  @importid varchar(10), @seq int, @Identifier int,   
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
		IF @Column='PRCo' 
			IF @Uploadval IS NULL
				SET @IsPRCoEmpty = 'Y'
			ELSE
				SET @IsPRCoEmpty = 'N'
		IF @Column='Employee' 
			IF @Uploadval IS NULL
				SET @IsEmployeeEmpty = 'Y'
			ELSE
				SET @IsEmployeeEmpty = 'N'
		IF @Column='Mth' 
			IF @Uploadval IS NULL
				SET @IsMthEmpty = 'Y'
			ELSE
				SET @IsMthEmpty = 'N'
		IF @Column='EDLType' 
			IF @Uploadval IS NULL
				SET @IsEDLTypeEmpty = 'Y'
			ELSE
				SET @IsEDLTypeEmpty = 'N'
		IF @Column='EDLCode' 
			IF @Uploadval IS NULL
				SET @IsEDLCodeEmpty = 'Y'
			ELSE
				SET @IsEDLCodeEmpty = 'N'
		IF @Column='Hours' 
			IF @Uploadval IS NULL
				SET @IsHoursEmpty = 'Y'
			ELSE
				SET @IsHoursEmpty = 'N'
		IF @Column='Amount' 
			IF @Uploadval IS NULL
				SET @IsAmountEmpty = 'Y'
			ELSE
				SET @IsAmountEmpty = 'N'
		IF @Column='SubjectAmt' 
			IF @Uploadval IS NULL
				SET @IsSubjectAmtEmpty = 'Y'
			ELSE
				SET @IsSubjectAmtEmpty = 'N'
		IF @Column='EligibleAmt' 
			IF @Uploadval IS NULL
				SET @IsEligibleAmtEmpty = 'Y'
			ELSE
				SET @IsEligibleAmtEmpty = 'N'
		IF @Column='AuditYN' 
			IF @Uploadval IS NULL
				SET @IsAuditYNEmpty = 'Y'
			ELSE
				SET @IsAuditYNEmpty = 'N'   
				
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
   
		--Set columns Hours, Amount, SubjectAmt, EligibleAmt to zero if null.
      UPDATE IMWE
      SET IMWE.UploadVal = 0
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and isnull(IMWE.UploadVal,'') = ''and
      (IMWE.Identifier = @cHoursID or IMWE.Identifier = @cAmountID or IMWE.Identifier = @cSubjectAmtID or IMWE.Identifier = @cEligibleAmtID)


   bspexit:
   
   	if @CursorOpen = 1
   	begin
   		close WorkEditCursor
   		deallocate WorkEditCursor	
   	end
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsPREA]'
   
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsPREA] TO [public]
GO
