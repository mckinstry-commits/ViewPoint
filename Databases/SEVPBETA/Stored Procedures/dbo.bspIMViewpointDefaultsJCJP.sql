SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsJCJP]
 /***********************************************************
  * CREATED BY:   DANF 9/20/05 
  * MODIFIED BY:  
  *				  CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
  *					AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
  *
  * Usage:
  *	Used by Imports to create values for needed or missing
  *      data based upon Viewpoint default rules.
  *small
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
 declare @PhaseGroupID int, @ProjMinPctID int, @JCCoID int, @ActiveYNID int, @ContractID int
 
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
			  @OverwriteJCCo 	 		 bYN
			, @OverwriteProjMinPct 	 	 bYN
			, @OverwriteActiveYN 	 	 bYN
			, @OverwritePhaseGroup 	 	 bYN
			, @OverwriteContract 	 	 bYN
			,	@IsJCCoEmpty 		 bYN
			,	@IsJobEmpty 		 bYN
			,	@IsPhaseGroupEmpty 	 bYN
			,	@IsPhaseEmpty 		 bYN
			,	@IsDescriptionEmpty  bYN
			,	@IsContractEmpty 	 bYN
			,	@IsItemEmpty 		 bYN
			,	@IsProjMinPctEmpty 	 bYN
			,	@IsActiveYNEmpty 	 bYN
			,	@IsNotesEmpty 		 bYN

	SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
	SELECT @OverwriteProjMinPct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ProjMinPct', @rectype);
	SELECT @OverwriteActiveYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActiveYN', @rectype);
	SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
	SELECT @OverwriteContract = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Contract', @rectype);	
 
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
 


 select @ProjMinPctID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
 inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
 Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ProjMinPct'
 if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteProjMinPct, 'Y') = 'Y') 
 begin
 	Update IMWE
 	SET IMWE.UploadVal = '0'
 	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
 	IMWE.ImportId=@ImportId and IMWE.Identifier = @ProjMinPctID
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

-----------------------------

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
 
 select @ProjMinPctID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
 inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
 Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ProjMinPct'
 if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteProjMinPct, 'Y') = 'N') 
 begin
 	Update IMWE
 	SET IMWE.UploadVal = '0'
 	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
 	IMWE.ImportId=@ImportId and IMWE.Identifier = @ProjMinPctID
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
 set  @PhaseGroupID = 0

 select @PhaseGroupID = DDUD.Identifier From IMTD with (nolock)
 inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
 Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PhaseGroup' and IMTD.DefaultValue = '[Bidtek]'

 select @ContractID = DDUD.Identifier From IMTD with (nolock)
 inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
 Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Contract'

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
 --#142350 - removing @importid varchar(10), @seq int, @Identifier int,
	DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int,
			@complete int
 
 declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
         @columnlist varchar(255), @records int, @oldrecseq int

 declare @JCCo bCompany, @Job bJob, @Phase bPhase, @Description bDesc, @Contract bContract,
		@Item bContractItem
 
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
     If @Column = 'PhaseGroup' select @PhaseGroup = @Uploadval
	 If @Column = 'Job' select @Job = @Uploadval
     If @Column = 'Phase' select @Phase = @Uploadval
     If @Column = 'Description' select @Description = @Uploadval
     If @Column = 'Contract' select @Contract = @Uploadval
     If @Column = 'Item' select @Item = @Uploadval

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
		IF @Column='Description' 
			IF @Uploadval IS NULL
				SET @IsDescriptionEmpty = 'Y'
			ELSE
				SET @IsDescriptionEmpty = 'N'
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
		IF @Column='ProjMinPct' 
			IF @Uploadval IS NULL
				SET @IsProjMinPctEmpty = 'Y'
			ELSE
				SET @IsProjMinPctEmpty = 'N'
		IF @Column='ActiveYN' 
			IF @Uploadval IS NULL
				SET @IsActiveYNEmpty = 'Y'
			ELSE
				SET @IsActiveYNEmpty = 'N'
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

	 if @PhaseGroupID <> 0 AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')
	 begin
 		exec bspJCPhaseGrpGet @JCCo, @PhaseGroup output, @msg output
	 
		 UPDATE IMWE
		 SET IMWE.UploadVal = @PhaseGroup
		 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   	        and IMWE.Identifier=@PhaseGroupID and IMWE.RecordType=@rectype
	 end

	 if @ContractID <> 0 AND (ISNULL(@OverwriteContract, 'Y') = 'Y' OR ISNULL(@IsContractEmpty, 'Y') = 'Y')
	 begin
		select @Contract =''
		select @Contract = Contract
		from JCJM with (nolock)
		where JCCo = @JCCo and Job = @Job
		

		 UPDATE IMWE
		 SET IMWE.UploadVal = @Contract
		 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   	        and IMWE.Identifier=@ContractID and IMWE.RecordType=@rectype

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
 
     select @msg = isnull(@desc,'Clear') + char(13) + char(13) + '[bspIMViewpointDefaultsJCPM]'
 
     return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsJCJP] TO [public]
GO
