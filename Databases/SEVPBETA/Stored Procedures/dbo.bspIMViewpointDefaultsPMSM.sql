SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsPMSM]
  /***********************************************************
   * CREATED BY:   RBT 09/13/04 for issue #24532
   * MODIFIED BY:  RBT 01/25/06 - issue #120003, fix default for issue (null if zero)
   *				Dan So 09/29/08 - Issue: #129932 - added 'NULL' to paramter list for: exec @recode = bspPMSubmitRevDefaults  
   *				CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
   *				GF 06/28/2009 - issue #124248 architect firm and contact not default from JCJM
   *				AMR 01/24/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
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
	--   #142350 removing @status
DECLARE @rcode int,
		@recode int,
		@desc varchar(120),
		@defaultvalue varchar(30),
		@CursorOpen int	
  
  select @rcode = 0
  
  --Identifiers
  declare @PMCoID int, @VendorGroupID int, @PhaseGroupID int, @PhaseID int, @StatusID int, 
  @ResponsibleFirmID int, @ResponsiblePersonID int, @IssueID int, @SubFirmID int, @SubContactID int, 
  @ArchEngFirmID int, @ArchEngContactID int, @CopiesReqdID int, @SpecNumberID int, @ActivityDateID int, 
  @DescriptionID int, @SubmittalID int, @ProjectID int, @SubmittalTypeID int
  
  --Values
  declare @PMCo bCompany, @VendorGroup bGroup, @PhaseGroup bGroup, @Phase bPhase, @Status bStatus, 
  @ResponsibleFirm bFirm, @ResponsiblePerson bEmployee, @Issue bIssue, @SubFirm bFirm, @SubContact bEmployee, 
  @ArchEngFirm bFirm, @ArchEngContact bEmployee, @CopiesReqd tinyint, @SpecNumber varchar(20), @ActivityDate bDate, 
  @Description bDesc, @Project bProject, @SubmittalType bDocType, @Submittal bDocument,
  @DefDesc bDesc, @DefPhase bPhase, @DefStatus bStatus, @DefRespPerson bEmployee,
  @DefIssue bIssue, @DefSubFirm bFirm, @DefSubContact bEmployee, @DefArchEngContact bEmployee,
  @DefArchEngFirm bFirm, @DefCopiesReqd tinyint, @DefSpecNumber varchar(20), @DefActivityDate bDate,
  @AutoGenSubNo varchar(1), @MaxSubmittal numeric, @format varchar(30), @FSubmittal bDocument
  
  
  --Flags for dependent defaults
  declare @ynVendorGroup bYN, @ynPhaseGroup bYN, @ynPhase bYN, @ynStatus bYN, 
  @ynResponsibleFirm bYN, @ynResponsiblePerson bYN, @ynIssue bYN, @ynSubFirm bYN, @ynSubContact bYN, 
  @ynArchEngFirm bYN, @ynArchEngContact bYN, @ynCopiesReqd bYN, @ynSpecNumber bYN, @ynActivityDate bYN, 
  @ynDescription bYN, @ynSubmittal bYN
  
  
  
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
			  @OverwritePMCo 	 			bYN
			, @OverwriteVendorGroup 	 	bYN
			, @OverwritePhaseGroup 	 		bYN
			, @OverwritePhase 	 			bYN
			, @OverwriteStatus 	 			bYN
			, @OverwriteResponsibleFirm 	bYN
			, @OverwriteResponsiblePerson 	bYN
			, @OverwriteIssue 	 		 	bYN
			, @OverwriteSubFirm 	 	 	bYN
			, @OverwriteSubContact 	 	 	bYN
			, @OverwriteArchEngFirm 	 	bYN
			, @OverwriteArchEngContact 	 	bYN
			, @OverwriteCopiesReqd 	 		bYN
			, @OverwriteSpecNumber 	 		bYN
			, @OverwriteActivityDate 	 	bYN
			, @OverwriteDescription 	 	bYN
			, @OverwriteSubmittal 	 		bYN			 
			,	@IsPMCoEmpty 				 bYN
			,	@IsProjectEmpty 			 bYN
			,	@IsSubmittalTypeEmpty 		 bYN
			,	@IsSubmittalEmpty 			 bYN
			,	@IsRevEmpty 				 bYN
			,	@IsDescriptionEmpty 		 bYN
			,	@IsSpecNumberEmpty 			 bYN
			,	@IsPhaseGroupEmpty 			 bYN
			,	@IsPhaseEmpty 				 bYN
			,	@IsStatusEmpty 				 bYN
			,	@IsVendorGroupEmpty 		 bYN
			,	@IsResponsibleFirmEmpty 	 bYN
			,	@IsResponsiblePersonEmpty 	 bYN
			,	@IsIssueEmpty 				 bYN
			,	@IsSubFirmEmpty 			 bYN
			,	@IsSubContactEmpty 			 bYN
			,	@IsArchEngFirmEmpty 		 bYN
			,	@IsArchEngContactEmpty 		 bYN
			,	@IsDateReqdEmpty 			 bYN
			,	@IsDateRecdEmpty 			 bYN
			,	@IsToArchEngEmpty 			 bYN
			,	@IsDueBackArchEmpty 		 bYN
			,	@IsRecdBackArchEmpty 		 bYN
			,	@IsDateRetdEmpty 			 bYN
			,	@IsActivityDateEmpty 		 bYN
			,	@IsCopiesReqdEmpty 		 	 bYN
			,	@IsCopiesRecdEmpty 		 	 bYN
			,	@IsCopiesSentArchEmpty 	 	 bYN
			,	@IsCopiesRecdArchEmpty 	 	 bYN
			,	@IsCopiesSentEmpty 		 	 bYN
			,	@IsNotesEmpty 				 bYN

	SELECT @OverwritePMCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PMCo', @rectype);
	SELECT @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype);
	SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
	SELECT @OverwritePhase = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Phase', @rectype);
	SELECT @OverwriteStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Status', @rectype);
	SELECT @OverwriteResponsibleFirm = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ResponsibleFirm', @rectype);
	SELECT @OverwriteResponsiblePerson = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ResponsiblePerson', @rectype);
	SELECT @OverwriteIssue = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Issue', @rectype);
	SELECT @OverwriteSubFirm = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SubFirm', @rectype);
	SELECT @OverwriteSubContact = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SubContact', @rectype);
	SELECT @OverwriteArchEngFirm = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ArchEngFirm', @rectype);
	SELECT @OverwriteArchEngContact = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ArchEngContact', @rectype);
	SELECT @OverwriteCopiesReqd = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CopiesReqd', @rectype);
	SELECT @OverwriteSpecNumber = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SpecNumber', @rectype);
	SELECT @OverwriteActivityDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActivityDate', @rectype);
	SELECT @OverwriteDescription = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Description', @rectype);
	SELECT @OverwriteSubmittal = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Submittal', @rectype);
  
  --get database default values	
  
  --set common defaults
  select @PMCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PMCo'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePMCo, 'Y') = 'Y') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = @Company
  	where IMWE.ImportTemplate=@ImportTemplate and
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @PMCoID
  end
  
  --------------
    select @PMCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PMCo'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePMCo, 'Y') = 'N') 
  begin
  	Update IMWE
  	SET IMWE.UploadVal = @Company
  	where IMWE.ImportTemplate=@ImportTemplate and
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @PMCoID
  	AND IMWE.UploadVal IS NULL
  end
  
  
  
  --Get Identifiers for dependent defaults.
  select @ynVendorGroup = 'N'
  select @VendorGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'Y')
  if @VendorGroupID <> 0 select @ynVendorGroup = 'Y'
  
  select @ynPhaseGroup = 'N'
  select @PhaseGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGroup', @rectype, 'Y')
  if @PhaseGroupID <> 0 select @ynPhaseGroup = 'Y'
  
  select @ynPhase = 'N'
  select @PhaseID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Phase', @rectype, 'Y')
  if @PhaseID <> 0 select @ynPhase = 'Y'
  
  select @ynStatus = 'N'
  select @StatusID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Status', @rectype, 'Y')
  if @StatusID <> 0 select @ynStatus = 'Y'
  
  select @ynResponsibleFirm = 'N'
  select @ResponsibleFirmID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ResponsibleFirm', @rectype, 'Y')
  if @ResponsibleFirmID <> 0 select @ynResponsibleFirm = 'Y'
  
  select @ynResponsiblePerson = 'N'
  select @ResponsiblePersonID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ResponsiblePerson', @rectype, 'Y')
  if @ResponsiblePersonID <> 0 select @ynResponsiblePerson = 'Y'
  
  select @ynIssue = 'N'
  select @IssueID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Issue', @rectype, 'Y')
  if @IssueID <> 0 select @ynIssue = 'Y'
  
  select @ynSubFirm = 'N'
  select @SubFirmID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SubFirm', @rectype, 'Y')
  if @SubFirmID <> 0 select @ynSubFirm = 'Y'
  
  select @ynSubContact = 'N'
  select @SubContactID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SubContact', @rectype, 'Y')
  if @SubContactID <> 0 select @ynSubContact = 'Y'
  
  select @ynArchEngFirm = 'N'
  select @ArchEngFirmID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ArchEngFirm', @rectype, 'Y')
  if @ArchEngFirmID <> 0 select @ynArchEngFirm = 'Y'
  
  select @ynArchEngContact = 'N'
  select @ArchEngContactID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ArchEngContact', @rectype, 'Y')
  if @ArchEngContactID <> 0 select @ynArchEngContact = 'Y'
  
  select @ynCopiesReqd = 'N'
  select @CopiesReqdID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CopiesReqd', @rectype, 'Y')
  if @CopiesReqdID <> 0 select @ynCopiesReqd = 'Y'
  
  select @ynSpecNumber = 'N'
  select @SpecNumberID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SpecNumber', @rectype, 'Y')
  if @SpecNumberID <> 0 select @ynSpecNumber = 'Y'
  
  select @ynActivityDate = 'N'
  select @ActivityDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ActivityDate', @rectype, 'Y')
  if @ActivityDateID <> 0 select @ynActivityDate = 'Y'
  
  select @ynDescription = 'N'
  select @DescriptionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Description', @rectype, 'Y')
  if @DescriptionID <> 0 select @ynDescription = 'Y'
  
  select @ynSubmittal = 'N'
  select @SubmittalID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Submittal', @rectype, 'Y')
  if @SubmittalID <> 0 select @ynSubmittal = 'Y'
  
  --Get ID even if not defaulting.
  select @SubmittalID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Submittal', @rectype, 'N')
  select @ProjectID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Project', @rectype, 'N')
  select @SubmittalTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SubmittalType', @rectype, 'N')
  
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
  --#142350 - removing  @importid varchar(10), @seq int, @Identifier int, 
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
  
	----#124248
	if @Uploadval = 'NULL' set @Uploadval = null
  	If @Column = 'PMCo' select @PMCo = @Uploadval
  	If @Column = 'Project' select @Project = @Uploadval
  	If @Column = 'SubmittalType' select @SubmittalType = @Uploadval
  	If @Column = 'Submittal' select @Submittal = @Uploadval
  	If @Column = 'VendorGroup' select @VendorGroup = @Uploadval
  	If @Column = 'PhaseGroup' select @PhaseGroup = @Uploadval
  	If @Column = 'Phase' select @Phase = @Uploadval
  	If @Column = 'Status' select @Status = @Uploadval
  	If @Column = 'ResponsibleFirm' select @ResponsibleFirm = @Uploadval
  	If @Column = 'ResponsiblePerson' select @ResponsiblePerson = @Uploadval
  	If @Column = 'Issue' select @Issue = @Uploadval
  	If @Column = 'SubFirm' select @SubFirm = @Uploadval
  	If @Column = 'SubContact' select @SubContact = @Uploadval
  	If @Column = 'ArchEngFirm' select @ArchEngFirm = @Uploadval
  	If @Column = 'ArchEngContact' select @ArchEngContact = @Uploadval
  	If @Column = 'CopiesReqd' select @CopiesReqd = @Uploadval
  	If @Column = 'SpecNumber' select @SpecNumber = @Uploadval
  	If @Column = 'ActivityDate' select @ActivityDate = @Uploadval
  	If @Column = 'Description' select @Description = @Uploadval

		IF @Column='PMCo' 
			IF @Uploadval IS NULL
				SET @IsPMCoEmpty = 'Y'
			ELSE
				SET @IsPMCoEmpty = 'N'
		IF @Column='Project' 
			IF @Uploadval IS NULL
				SET @IsProjectEmpty = 'Y'
			ELSE
				SET @IsProjectEmpty = 'N'
		IF @Column='SubmittalType' 
			IF @Uploadval IS NULL
				SET @IsSubmittalTypeEmpty = 'Y'
			ELSE
				SET @IsSubmittalTypeEmpty = 'N'
		IF @Column='Submittal' 
			IF @Uploadval IS NULL
				SET @IsSubmittalEmpty = 'Y'
			ELSE
				SET @IsSubmittalEmpty = 'N'
		IF @Column='Rev' 
			IF @Uploadval IS NULL
				SET @IsRevEmpty = 'Y'
			ELSE
				SET @IsRevEmpty = 'N'
		IF @Column='Description' 
			IF @Uploadval IS NULL
				SET @IsDescriptionEmpty = 'Y'
			ELSE
				SET @IsDescriptionEmpty = 'N'
		IF @Column='SpecNumber' 
			IF @Uploadval IS NULL
				SET @IsSpecNumberEmpty = 'Y'
			ELSE
				SET @IsSpecNumberEmpty = 'N'
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
		IF @Column='Status' 
			IF @Uploadval IS NULL
				SET @IsStatusEmpty = 'Y'
			ELSE
				SET @IsStatusEmpty = 'N'
		IF @Column='VendorGroup' 
			IF @Uploadval IS NULL
				SET @IsVendorGroupEmpty = 'Y'
			ELSE
				SET @IsVendorGroupEmpty = 'N'
		IF @Column='ResponsibleFirm' 
			IF @Uploadval IS NULL
				SET @IsResponsibleFirmEmpty = 'Y'
			ELSE
				SET @IsResponsibleFirmEmpty = 'N'
		IF @Column='ResponsiblePerson' 
			IF @Uploadval IS NULL
				SET @IsResponsiblePersonEmpty = 'Y'
			ELSE
				SET @IsResponsiblePersonEmpty = 'N'
		IF @Column='Issue' 
			IF @Uploadval IS NULL
				SET @IsIssueEmpty = 'Y'
			ELSE
				SET @IsIssueEmpty = 'N'
		IF @Column='SubFirm' 
			IF @Uploadval IS NULL
				SET @IsSubFirmEmpty = 'Y'
			ELSE
				SET @IsSubFirmEmpty = 'N'
		IF @Column='SubContact' 
			IF @Uploadval IS NULL
				SET @IsSubContactEmpty = 'Y'
			ELSE
				SET @IsSubContactEmpty = 'N'
		IF @Column='ArchEngFirm' 
			IF @Uploadval IS NULL
				SET @IsArchEngFirmEmpty = 'Y'
			ELSE
				SET @IsArchEngFirmEmpty = 'N'
		IF @Column='ArchEngContact' 
			IF @Uploadval IS NULL
				SET @IsArchEngContactEmpty = 'Y'
			ELSE
				SET @IsArchEngContactEmpty = 'N'
		IF @Column='DateReqd' 
			IF @Uploadval IS NULL
				SET @IsDateReqdEmpty = 'Y'
			ELSE
				SET @IsDateReqdEmpty = 'N'
		IF @Column='DateRecd' 
			IF @Uploadval IS NULL
				SET @IsDateRecdEmpty = 'Y'
			ELSE
				SET @IsDateRecdEmpty = 'N'
		IF @Column='ToArchEng' 
			IF @Uploadval IS NULL
				SET @IsToArchEngEmpty = 'Y'
			ELSE
				SET @IsToArchEngEmpty = 'N'
		IF @Column='DueBackArch' 
			IF @Uploadval IS NULL
				SET @IsDueBackArchEmpty = 'Y'
			ELSE
				SET @IsDueBackArchEmpty = 'N'
		IF @Column='RecdBackArch' 
			IF @Uploadval IS NULL
				SET @IsRecdBackArchEmpty = 'Y'
			ELSE
				SET @IsRecdBackArchEmpty = 'N'
		IF @Column='DateRetd' 
			IF @Uploadval IS NULL
				SET @IsDateRetdEmpty = 'Y'
			ELSE
				SET @IsDateRetdEmpty = 'N'
		IF @Column='ActivityDate' 
			IF @Uploadval IS NULL
				SET @IsActivityDateEmpty = 'Y'
			ELSE
				SET @IsActivityDateEmpty = 'N'
		IF @Column='CopiesReqd' 
			IF @Uploadval IS NULL
				SET @IsCopiesReqdEmpty = 'Y'
			ELSE
				SET @IsCopiesReqdEmpty = 'N'
		IF @Column='CopiesRecd' 
			IF @Uploadval IS NULL
				SET @IsCopiesRecdEmpty = 'Y'
			ELSE
				SET @IsCopiesRecdEmpty = 'N'
		IF @Column='CopiesSentArch' 
			IF @Uploadval IS NULL
				SET @IsCopiesSentArchEmpty = 'Y'
			ELSE
				SET @IsCopiesSentArchEmpty = 'N'
		IF @Column='CopiesRecdArch' 
			IF @Uploadval IS NULL
				SET @IsCopiesRecdArchEmpty = 'Y'
			ELSE
				SET @IsCopiesRecdArchEmpty = 'N'
		IF @Column='CopiesSent' 
			IF @Uploadval IS NULL
				SET @IsCopiesSentEmpty = 'Y'
			ELSE
				SET @IsCopiesSentEmpty = 'N'
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
  
  	if @ynSubmittal = 'Y' AND (ISNULL(@OverwriteSubmittal, 'Y') = 'Y' OR ISNULL(@IsSubmittalEmpty, 'Y') = 'Y')
  	begin
   
  		select @AutoGenSubNo = AutoGenSubNo from JCJM with (nolock) where JCCo = @PMCo and Job = @Project
  
  		--VERY IMPORTANT!
  		select @Submittal = null
  		select @MaxSubmittal = null
  
  		exec @recode = bspPMGetNextSubmittal @PMCo, @Project, @SubmittalType, @Submittal output, @msg output
  		if @recode <> 0 
  		begin
  			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
  			 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@SubmittalID)			
  
  			select @rcode = 1
  			select @desc = @msg
  		end
  
  		--if the submittal type is 'T', then check to see how many previous records have the same PMCo, Project, and Type.
  		if @AutoGenSubNo = 'T'
  		begin
  
  			--query courtesy of DanF.
  			select @MaxSubmittal = max(cast(isnull(Submittal.Submittal,0) as numeric))
  			from bIMWE w with (nolock)
  			left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'Co' from bIMWE with (nolock) 
  			where Identifier=@PMCoID
  			group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
  			as Co on Co.ImportId=w.ImportId and Co.ImportTemplate=w.ImportTemplate and Co.RecordType=w.RecordType and Co.RecordSeq=w.RecordSeq
  			left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'Project' from bIMWE with (nolock) 
  			where Identifier=@ProjectID
  			group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
  			as Project on Project.ImportId=w.ImportId and Project.ImportTemplate=w.ImportTemplate and Project.RecordType=w.RecordType and Project.RecordSeq=w.RecordSeq
  			left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'SubmittalType' from bIMWE with (nolock) 
  			where Identifier=@SubmittalTypeID
  			group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
  			as SubmittalType on SubmittalType.ImportId=w.ImportId and SubmittalType.ImportTemplate=w.ImportTemplate and SubmittalType.RecordType=w.RecordType and SubmittalType.RecordSeq=w.RecordSeq
  			left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'Submittal' from bIMWE with (nolock) 
  			where Identifier=@SubmittalID
  			group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
  			as Submittal on Submittal.ImportId=w.ImportId and Submittal.ImportTemplate=w.ImportTemplate and Submittal.RecordType=w.RecordType and Submittal.RecordSeq=w.RecordSeq
  			left join bJCJM m with (nolock)
  			on Co.Co=m.JCCo and Project.Project=m.Job
  			where w.ImportId = @ImportId and Project.Project = @Project
  			and Co.Co = @PMCo and isnumeric(Submittal.Submittal) = 1 and w.RecordSeq < @currrecseq
  			and SubmittalType.SubmittalType = @SubmittalType 
  			group by w.ImportId,w.ImportTemplate, w.Form, w.RecordSeq, Co.Co, Project.Project,SubmittalType.SubmittalType,Submittal.Submittal,m.AutoGenSubNo
  			
  		end
  		else
  		begin
  		--else check how many previous records there are and increment the Submittal returned by the procedure.
  			select @MaxSubmittal = max(cast(isnull(Submittal.Submittal,0) as numeric))
  			from bIMWE w with (nolock)
  			left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'Co' from bIMWE with (nolock) 
  			where Identifier=@PMCoID
  			group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
  			as Co on Co.ImportId=w.ImportId and Co.ImportTemplate=w.ImportTemplate and Co.RecordType=w.RecordType and Co.RecordSeq=w.RecordSeq
  			left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'Project' from bIMWE with (nolock) 
  			where Identifier=@ProjectID
  			group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
  			as Project on Project.ImportId=w.ImportId and Project.ImportTemplate=w.ImportTemplate and Project.RecordType=w.RecordType and Project.RecordSeq=w.RecordSeq
  			left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'SubmittalType' from bIMWE with (nolock) 
  			where Identifier=@SubmittalTypeID
  			group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
  			as SubmittalType on SubmittalType.ImportId=w.ImportId and SubmittalType.ImportTemplate=w.ImportTemplate and SubmittalType.RecordType=w.RecordType and SubmittalType.RecordSeq=w.RecordSeq
  			left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'Submittal' from bIMWE with (nolock) 
  			where Identifier=@SubmittalID
  			group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
  			as Submittal on Submittal.ImportId=w.ImportId and Submittal.ImportTemplate=w.ImportTemplate and Submittal.RecordType=w.RecordType and Submittal.RecordSeq=w.RecordSeq
  			left join bJCJM m with (nolock)
  			on Co.Co=m.JCCo and Project.Project=m.Job
  			where w.ImportId = @ImportId and Project.Project = @Project
  			and Co.Co = @PMCo and isnumeric(Submittal.Submittal) = 1 and w.RecordSeq < @currrecseq
  			group by w.ImportId,w.ImportTemplate, w.Form, w.RecordSeq, Co.Co, Project.Project,SubmittalType.SubmittalType,Submittal.Submittal,m.AutoGenSubNo
  		
  		end
  
  		if @MaxSubmittal is null
  			select @MaxSubmittal = 0
  
  		if @Submittal is null
  			select @Submittal = 0
  
  		if @MaxSubmittal >= @Submittal
  			select @Submittal = @MaxSubmittal + 1
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @Submittal
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@SubmittalID and IMWE.RecordType=@rectype
  
  		--Check formatting for this field
  		exec @recode = bspIMIMWEDataTypeFormat @ImportId, @ImportTemplate, @rectype, @msg output
  
  	end
  
  	if @ynVendorGroup = 'Y' AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'Y' OR ISNULL(@IsVendorGroupEmpty, 'Y') = 'Y')
  	begin
  		exec @recode = bspAPVendorGrpGet @PMCo, @VendorGroup output, @msg output
  		if @recode <> 0 
  		begin
  			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
  			 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@VendorGroupID)			
  
  			select @rcode = 1
  			select @desc = @msg
  		end
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @VendorGroup
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@VendorGroupID and IMWE.RecordType=@rectype
  
  	end
  
  	if @ynPhaseGroup = 'Y' AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')

  	begin
  		exec @recode = bspJCPhaseGrpGet @PMCo, @PhaseGroup output, @msg output
  
  		if @recode <> 0 
  		begin
  			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
  			 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@PhaseGroupID)			
  
  			select @rcode = 1
  			select @desc = @msg
  		end
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @PhaseGroup
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@PhaseGroupID and IMWE.RecordType=@rectype
  
  	end
  
  	--Set defaults to null.
  	select  @DefDesc = null, @DefPhase = null, @DefStatus = null, @DefRespPerson = null,
  			@DefIssue = null, @DefSubFirm = null, @DefSubContact = null, @DefArchEngContact = null,
  			@DefArchEngFirm = null, @DefCopiesReqd = null, @DefSpecNumber = null, @DefActivityDate = null
  
  	--Multiple default retrieval...
	-- #129932 --
  	exec @recode = bspPMSubmitRevDefaults @PMCo, @Project, @SubmittalType, @Submittal, NULL,
  			@DefDesc output, @DefPhase output, @DefStatus output, @DefRespPerson output,
  			@DefIssue output, @DefSubFirm output, @DefSubContact output, @DefArchEngContact output,
  			@DefArchEngFirm output, @DefCopiesReqd output, @DefSpecNumber output, @DefActivityDate output,
  			@msg output
  			
  --	---- #124248 if no default @DefArchEngFirm and @DefArchEngContact get from JCJM
  --	if isnull(@DefArchEngFirm,'') = ''
  --		begin
		--select @DefArchEngFirm = ArchEngFirm, @DefArchEngContact = ContactCode
		--from JCJM with (nolock) where JCCo=@PMCo and Job=@Project
		--end
		
  /* --I don't think this needs to return an error
  
  	if @recode <> 0
  	begin
  		insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
  		 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,'Retrieving Defaults: ' + @msg,@SubmittalID)			
  
  		select @rcode = 1
  		select @desc = 'Error retrieving defaults: bspPMSubmitRevDefaults.'
  	end
  */
  
  	if @ynDescription = 'Y' AND (ISNULL(@OverwriteDescription, 'Y') = 'Y' OR ISNULL(@IsDescriptionEmpty, 'Y') = 'Y')
  	begin
  		select @Description = @DefDesc
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @Description
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@DescriptionID and IMWE.RecordType=@rectype
  
  	end
  
  	if @ynPhase = 'Y' AND (ISNULL(@OverwritePhase, 'Y') = 'Y' OR ISNULL(@IsPhaseEmpty, 'Y') = 'Y')
  	begin
  		select @Phase = @DefPhase
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @Phase
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@PhaseID and IMWE.RecordType=@rectype
  
  	end
  
  	if @ynStatus = 'Y' AND (ISNULL(@OverwriteStatus, 'Y') = 'Y' OR ISNULL(@IsStatusEmpty, 'Y') = 'Y')
  	begin
  		select @Status = @DefStatus
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @Status
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@StatusID and IMWE.RecordType=@rectype
  
  	end
  
  	if @ynResponsibleFirm = 'Y' AND (ISNULL(@OverwriteResponsibleFirm, 'Y') = 'Y' OR ISNULL(@IsResponsibleFirmEmpty, 'Y') = 'Y')
  	begin
  		exec @recode = bspPMProjectVal @PMCo, @Project, '0,1',null,null,null,null,null,null,null,null, @ResponsibleFirm output, null,null,@msg output
  		if @recode <> 0
  		begin
  			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
  			 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@ResponsibleFirmID)			
  	
  			select @rcode = 1
  			select @desc = @msg
  		end
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @ResponsibleFirm
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@ResponsibleFirmID and IMWE.RecordType=@rectype
  
  	end
  
  	if @ynResponsiblePerson = 'Y' AND (ISNULL(@OverwriteResponsiblePerson, 'Y') = 'Y' OR ISNULL(@IsResponsiblePersonEmpty, 'Y') = 'Y')
  	begin
  		select @ResponsiblePerson = @DefRespPerson
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @ResponsiblePerson
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@ResponsiblePersonID and IMWE.RecordType=@rectype
  
  	end
  
  	if @ynIssue = 'Y' AND (ISNULL(@OverwriteIssue, 'Y') = 'Y' OR ISNULL(@IsIssueEmpty, 'Y') = 'Y')
  	begin
		if @DefIssue = 0 select @DefIssue = null

  		select @Issue = @DefIssue
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @Issue
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@IssueID and IMWE.RecordType=@rectype
  
  	end
  
  	if @ynSubFirm = 'Y' AND (ISNULL(@OverwriteSubFirm, 'Y') = 'Y' OR ISNULL(@IsSubFirmEmpty, 'Y') = 'Y')
  	begin
  		select @SubFirm = @DefSubFirm
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @SubFirm
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@SubFirmID and IMWE.RecordType=@rectype
  
  	end
  
  	if @ynSubContact = 'Y' AND (ISNULL(@OverwriteSubContact, 'Y') = 'Y' OR ISNULL(@IsSubContactEmpty, 'Y') = 'Y')
  	begin
  		select @SubContact = @DefSubContact
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @SubContact
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@SubContactID and IMWE.RecordType=@rectype
  
  	end
	
  	if @ynArchEngFirm = 'Y' AND (ISNULL(@OverwriteArchEngFirm, 'Y') = 'Y' OR ISNULL(@IsArchEngFirmEmpty, 'Y') = 'Y')
  	begin
  		select @ArchEngFirm = @DefArchEngFirm
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @ArchEngFirm
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@ArchEngFirmID and IMWE.RecordType=@rectype
  
  	end
  
  	if @ynArchEngContact = 'Y' AND (ISNULL(@OverwriteArchEngContact, 'Y') = 'Y' OR ISNULL(@IsArchEngContactEmpty, 'Y') = 'Y')
  	begin
  		select @ArchEngContact = @DefArchEngContact
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @ArchEngContact
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@ArchEngContactID and IMWE.RecordType=@rectype
  
  	end
  
  	if @ynCopiesReqd = 'Y'  AND (ISNULL(@OverwriteCopiesReqd, 'Y') = 'Y' OR ISNULL(@IsCopiesReqdEmpty, 'Y') = 'Y')
  	begin
  		select @CopiesReqd = @DefCopiesReqd
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @CopiesReqd
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@CopiesReqdID and IMWE.RecordType=@rectype
  
  	end
  
  	if @ynSpecNumber = 'Y' AND (ISNULL(@OverwriteSpecNumber, 'Y') = 'Y' OR ISNULL(@IsSpecNumberEmpty, 'Y') = 'Y')
  	begin
  		select @SpecNumber = @DefSpecNumber
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @SpecNumber
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@SpecNumberID and IMWE.RecordType=@rectype
  
  	end
  
  	if @ynActivityDate = 'Y' AND (ISNULL(@OverwriteActivityDate, 'Y') = 'Y' OR ISNULL(@IsActivityDateEmpty, 'Y') = 'Y')
  	begin
  		select @ActivityDate = @DefActivityDate
  
  		UPDATE IMWE
  		SET IMWE.UploadVal = @ActivityDate
  		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  		and IMWE.Identifier=@ActivityDateID and IMWE.RecordType=@rectype
  
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
  
      select @msg = isnull(@desc,'Clear') + char(13) + char(13) + '[bspIMViewpointDefaultsPMSM]'
  
      return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsPMSM] TO [public]
GO
