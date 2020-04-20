SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsINCW]
   /***********************************************************
    * CREATED BY:   RBT 03/17/05 for issue #27380
    * MODIFIED BY:  
    *			  CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
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
   declare @INCoID int, @ReadyID int, @UnitCostID int, @ECMID int, @UMID int, @MaterialID int, @UserNameID int,
   @MatlGroupID int
   
   --Values
   declare @UnitCost bUnitCost, @ECM bECM, @UM bUM, @INCo bCompany, 
   @UserName bVPUserName, @Loc bLoc, @MatlGroup bGroup, @Material bMatl, 
   @PhyCnt bUnits, @CntDate bDate, @CntBy varchar(20), @Description bDesc,
   @DefUnitCost bUnitCost, @DefECM bECM, @DefUM bUM
   
   --Flags for dependent defaults
   declare @ynUnitCost bYN, @ynECM bYN, @ynUM bYN, @ynUserName bYN, @ynMatlGroup bYN
   
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
   
    select @CursorOpen = 0, @rcode = 0
   
   -- Check ImportTemplate detail for columns to set Bidtek Defaults
   if not exists(select top 1 1 From IMTD with (nolock)
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
   and IMTD.RecordType = @rectype)
   goto bspexit
   
   DECLARE 
			  @OverwriteINCo 	 	 bYN
			, @OverwriteReady 	 	 bYN
			, @OverwriteUserName 	 bYN
			, @OverwriteUnitCost 	 bYN
			, @OverwriteECM 	 	 bYN
			, @OverwriteUM 	 		 bYN
			, @OverwriteMatlGroup 	 bYN
			,	@IsINCoEmpty 		 bYN
			,	@IsLocEmpty 		 bYN
			,	@IsMatlGroupEmpty 	 bYN
			,	@IsMaterialEmpty 	 bYN
			,	@IsPhyCntEmpty 		 bYN
			,	@IsCntDateEmpty 	 bYN
			,	@IsCntByEmpty 		 bYN
			,	@IsUserNameEmpty 	 bYN
			,	@IsUnitCostEmpty 	 bYN
			,	@IsECMEmpty 		 bYN
			,	@IsUMEmpty 			 bYN
			,	@IsReadyEmpty 		 bYN
			,	@IsDescriptionEmpty  bYN			
			
		SELECT @OverwriteINCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'INCo', @rectype);
		SELECT @OverwriteReady = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Ready', @rectype);
	    SELECT @OverwriteUserName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UserName', @rectype);
		SELECT @OverwriteUnitCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnitCost', @rectype);
		SELECT @OverwriteECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ECM', @rectype);
		SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UM', @rectype);
		SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
   
   --get database default values	
   
   --set common defaults
   select @INCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'INCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteINCo, 'Y') = 'Y')
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @INCoID
   end
   
   select @ReadyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Ready'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReady, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ReadyID
   end
   
   --------------------
   
      select @INCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'INCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteINCo, 'Y') = 'N')
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @INCoID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @ReadyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Ready'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReady, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.RecordType = @rectype and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ReadyID
   	AND IMWE.UploadVal IS NULL
   end
   
   --Get Identifiers for dependent defaults.
   select @ynUserName = 'N'
   select @UserNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UserName', @rectype, 'Y')
   if @UserNameID <> 0 select @ynUserName = 'Y'
   
   select @ynUnitCost = 'N'
   select @UnitCostID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnitCost', @rectype, 'Y')
   if @UnitCostID <> 0 select @ynUnitCost = 'Y'
   
   select @ynECM = 'N'
   select @ECMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ECM', @rectype, 'Y')
   if @ECMID <> 0 select @ynECM = 'Y'
   
   select @ynUM = 'N'
   select @UMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UM', @rectype, 'Y')
   if @UMID <> 0 select @ynUM = 'Y'
   
   select @ynMatlGroup = 'N'
   select @MatlGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MatlGroup', @rectype, 'Y')
   if @MatlGroupID <> 0 select @ynMatlGroup = 'Y'
   
   select @MaterialID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Material', @rectype, 'N')
   
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
   
   	If @Column = 'INCo' and isnumeric(@Uploadval) = 1 select @INCo = @Uploadval
   	If @Column = 'UserName' select @UserName = @Uploadval
   	If @Column = 'Loc' select @Loc = @Uploadval
   	If @Column = 'MatlGroup' select @MatlGroup = @Uploadval
   	If @Column = 'Material' select @Material = @Uploadval
   	If @Column = 'UnitCost' select @UnitCost = @Uploadval
   	If @Column = 'ECM' select @ECM = @Uploadval
   	If @Column = 'UM' select @UM = @Uploadval
   	If @Column = 'PhyCnt' select @PhyCnt = @Uploadval
   	If @Column = 'CntDate' select @CntDate = @Uploadval
   	If @Column = 'CntBy' select @CntBy = @Uploadval
   	If @Column = 'Description' select @Description = @Uploadval

	IF @Column='INCo' 
		IF @Uploadval IS NULL
			SET @IsINCoEmpty = 'Y'
		ELSE
			SET @IsINCoEmpty = 'N'
	IF @Column='Loc' 
		IF @Uploadval IS NULL
			SET @IsLocEmpty = 'Y'
		ELSE
			SET @IsLocEmpty = 'N'
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
	IF @Column='PhyCnt' 
		IF @Uploadval IS NULL
			SET @IsPhyCntEmpty = 'Y'
		ELSE
			SET @IsPhyCntEmpty = 'N'
	IF @Column='CntDate' 
		IF @Uploadval IS NULL
			SET @IsCntDateEmpty = 'Y'
		ELSE
			SET @IsCntDateEmpty = 'N'
	IF @Column='CntBy' 
		IF @Uploadval IS NULL
			SET @IsCntByEmpty = 'Y'
		ELSE
			SET @IsCntByEmpty = 'N'
	IF @Column='UserName' 
		IF @Uploadval IS NULL
			SET @IsUserNameEmpty = 'Y'
		ELSE
			SET @IsUserNameEmpty = 'N'
	IF @Column='UnitCost' 
		IF @Uploadval IS NULL
			SET @IsUnitCostEmpty = 'Y'
		ELSE
			SET @IsUnitCostEmpty = 'N'
	IF @Column='ECM' 
		IF @Uploadval IS NULL
			SET @IsECMEmpty = 'Y'
		ELSE
			SET @IsECMEmpty = 'N'
	IF @Column='UM' 
		IF @Uploadval IS NULL
			SET @IsUMEmpty = 'Y'
		ELSE
			SET @IsUMEmpty = 'N'
	IF @Column='Ready' 
		IF @Uploadval IS NULL
			SET @IsReadyEmpty = 'Y'
		ELSE
			SET @IsReadyEmpty = 'N'
	IF @Column='Description' 
		IF @Uploadval IS NULL
			SET @IsDescriptionEmpty = 'Y'
		ELSE
			SET @IsDescriptionEmpty = 'N'
   
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
   
   	if @ynMatlGroup = 'Y' AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR ISNULL(@IsMatlGroupEmpty, 'Y') = 'Y')
   	begin
   		select @MatlGroup = null, @msg = null
   
   		exec @recode = bspHQMatlGrpGet @INCo, @MatlGroup output, @msg output
   
   		if @recode <> 0 
   		begin
   			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
   			 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@MatlGroupID)			
   	
   			select @rcode = 1
   			select @desc = @msg
   		end
   		else
   		begin
   			UPDATE IMWE
   			SET IMWE.UploadVal = @MatlGroup
   			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   			and IMWE.Identifier=@MatlGroupID and IMWE.RecordType=@rectype
   		end
   	end
   
   	if (@ynUnitCost = 'Y' or @ynECM = 'Y' or @ynUM = 'Y')
   	begin
   		--call bspINLocMatlVal
   		select @DefUM = null, @DefUnitCost = null, @DefECM = null, @msg = null
   
   		exec @recode = bspINLocMatlVal @INCo, @Loc, @Material, @MatlGroup, 'Y', 'N', @DefUM output, null,
   				null, null, @DefUnitCost output, @DefECM output, null, null, null, null, null, null, @msg output
   
   		if @recode <> 0 
   		begin
   			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
   			 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@MaterialID)			
   	
   			select @rcode = 1
   			select @desc = @msg
   		end
   		else
   		begin
   			if @ynUnitCost = 'Y'  AND (ISNULL(@OverwriteUnitCost, 'Y') = 'Y' OR ISNULL(@IsUnitCostEmpty, 'Y') = 'Y')
   			begin
   				select @UnitCost = @DefUnitCost
   		
   				UPDATE IMWE
   				SET IMWE.UploadVal = @UnitCost
   				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   				and IMWE.Identifier=@UnitCostID and IMWE.RecordType=@rectype
   		
   			end
   		
   			if @ynECM = 'Y'  AND (ISNULL(@OverwriteECM, 'Y') = 'Y' OR ISNULL(@IsECMEmpty, 'Y') = 'Y')
   			begin
   				select @ECM = @DefECM
   		
   				UPDATE IMWE
   				SET IMWE.UploadVal = @ECM
   				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   				and IMWE.Identifier=@ECMID and IMWE.RecordType=@rectype
   		
   			end
   		
   			if @ynUM = 'Y'  AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')
   			begin
   				select @UM = @DefUM
   		
   				UPDATE IMWE
   				SET IMWE.UploadVal = @UM
   				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   				and IMWE.Identifier=@UMID and IMWE.RecordType=@rectype
   		
   			end
   		end
   	end
   
   
   	if @ynUserName = 'Y' AND (ISNULL(@OverwriteUserName, 'Y') = 'Y' OR ISNULL(@IsUserNameEmpty, 'Y') = 'Y')
   	begin
   		select @UserName = SUSER_SNAME()
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @UserName
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@UserNameID and IMWE.RecordType=@rectype
   
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
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsINCW]'
   
       return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsINCW] TO [public]
GO
