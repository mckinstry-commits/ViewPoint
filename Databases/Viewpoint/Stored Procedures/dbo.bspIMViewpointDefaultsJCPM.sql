SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsJCPM]
/***********************************************************
* CREATED BY:   RBT 09/19/2005 - issue #28897
* MODIFIED BY:  CC	02/18/2009 - Issue #24531 - Use default only if set to overwrite or value is null
*				CHS	09/25/2009 - issue #126548
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
   declare @PhaseGroupID int, @ProjMinPctID int, @DescID int
   
   --Values
   --   #142350 renaming @Desc
   declare @PhaseGroup bGroup, @Phase bPhase, @DescJCPM bItemDesc

	set @rcode = 0
   
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
			  @OverwritePhaseGroup	bYN
			, @OverwriteProjMinPct	bYN
			, @OverwriteDesc		bYN
			, @IsPhaseGroupEmpty	bYN
			, @IsPhaseEmpty			bYN
			, @IsDescriptionEmpty	bYN
			, @IsProjMinPctEmpty	bYN
			, @IsNotesEmpty			bYN

   --get database default values	
   
   --set common defaults
	SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
	SELECT @OverwriteProjMinPct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ProjMinPct', @rectype);

	SELECT @OverwriteDesc = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Description', @rectype)
	SELECT @DescID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Description', @rectype, 'Y');


	SELECT @PhaseGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGroup', @rectype, 'Y');

	if @PhaseGroupID <> 0 and (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y') 
		begin
		exec bspJCPhaseGrpGet @Company, @PhaseGroup output, @msg output

		   UPDATE IMWE
		   SET IMWE.UploadVal = @PhaseGroup
		   where IMWE.ImportTemplate=@ImportTemplate and 
		IMWE.ImportId=@ImportId and IMWE.Identifier = @PhaseGroupID
		end
   
	SELECT @ProjMinPctID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ProjMinPct', @rectype, 'Y');

	if @ProjMinPctID <> 0 and (ISNULL(@OverwriteProjMinPct, 'Y') = 'Y') 
		begin
		Update IMWE
		SET IMWE.UploadVal = '0'
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
		IMWE.ImportId=@ImportId and IMWE.Identifier = @ProjMinPctID
		end
   
   -------------------
   
	SELECT @PhaseGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGroup', @rectype, 'Y');

	if @PhaseGroupID <> 0 and (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y') 
		begin
		exec bspJCPhaseGrpGet @Company, @PhaseGroup output, @msg output

		   UPDATE IMWE
		   SET IMWE.UploadVal = @PhaseGroup
		   where IMWE.ImportTemplate=@ImportTemplate and 
		IMWE.ImportId=@ImportId and IMWE.Identifier = @PhaseGroupID
		AND IMWE.UploadVal IS NULL
		end
	   
	SELECT @ProjMinPctID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ProjMinPct', @rectype, 'Y');

	if @ProjMinPctID <> 0 and (ISNULL(@OverwriteProjMinPct, 'Y') = 'Y') 
		begin
		Update IMWE
		SET IMWE.UploadVal = '0'
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
		IMWE.ImportId=@ImportId and IMWE.Identifier = @ProjMinPctID
		AND IMWE.UploadVal IS NULL
		end
   
  
   
   --Get Identifiers for dependent defaults.
   
   
   --Start Processing
   DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD for

   SELECT IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
	   FROM IMWE with (nolock)
	   INNER join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
	   WHERE IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
	   ORDER BY IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   -- set open cursor flag
   select @CursorOpen = 1
   --#142350 -removing   @importid varchar(10), @seq int, @Identifier int,
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
   
		IF @Column='PhaseGroup' 
			IF @Uploadval IS NULL
				SET @IsPhaseGroupEmpty = 'Y'
			ELSE
				SET @IsPhaseGroupEmpty = 'N'
				
		IF @Column='Phase' 
			IF @Uploadval IS NULL
				SET @IsPhaseEmpty = 'Y'
			ELSE
				BEGIN
					SET @IsPhaseEmpty = 'N'
					SET @Phase =  @Uploadval
				END

		IF @Column='Description' 
			IF @Uploadval IS NULL
				SET @IsDescriptionEmpty = 'Y'
			ELSE
				SET @IsDescriptionEmpty = 'N'

		IF @Column='ProjMinPct' 
			IF @Uploadval IS NULL
				SET @IsProjMinPctEmpty = 'Y'
			ELSE
				SET @IsProjMinPctEmpty = 'N'

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

			-- Description --
			IF @DescID <> 0 AND (@OverwriteDesc = 'Y' OR @IsDescriptionEmpty = 'Y')
			BEGIN
				SELECT @DescJCPM = Description
					FROM bJCPM
					WHERE PhaseGroup = @PhaseGroup
					AND Phase = @Phase


				UPDATE IMWE
				SET IMWE.UploadVal = @DescJCPM
					WHERE IMWE.ImportTemplate = @ImportTemplate 
						AND IMWE.ImportId = @ImportId 
						AND IMWE.RecordSeq = @oldrecseq 
						AND IMWE.Identifier = @DescID 
						AND IMWE.RecordType = @rectype
			END
   
   
   		-- set Current Req Seq to next @Recseq unless we are processing last record.
   		if @Recseq = -1
   			select @complete = 1	-- exit the loop
   		else
   			select @currrecseq = @Recseq
   
		end
		
   end	-- while @complete = 0


   
   bspexit:
   
   	if @CursorOpen = 1
   	begin
   		close WorkEditCursor
   		deallocate WorkEditCursor	
   	end
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsJCPM]'
   
       return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsJCPM] TO [public]
GO
