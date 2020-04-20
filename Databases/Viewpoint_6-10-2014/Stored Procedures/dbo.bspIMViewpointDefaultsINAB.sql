SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsINAB]
    /***********************************************************
     * CREATED BY:   RBT 05/10/04 for issue #23333
     * MODIFIED BY:  RBT 08/25/04 - #25350, Make sure IMWM inserts use Identifier where applicable.
     *				 RBT 08/02/05 - #29451, Add default for TotalCost.
     *				 CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
     *				 CC  05/29/09 - Issue #133516 - Correct defaulting of Company
     *				 GP	 09/16/09 - Issue #135290 - Correct calculation for Total Cost using ECM
     *				 GF 09/14/2010 - issue #141031 change to use function vfDateOnly
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
    
    declare @rcode int, @finalrcode int, @desc varchar(120), @status int, @defaultvalue varchar(30), @CursorOpen int	
    
    --Identifiers
    declare @CoID int, @GLAcctID int, @ActDateID int, @UMID int, @UnitsID int, @UnitCostID int, 
    		@ECMID int, @MatlGroupID int, @GLCoID int, @BatchTypeID int, @BatchTransTypeID int,
    		@MaterialID int, @TotalCostID int
    
    --Values
    declare @ECM bECM, @GLCo bCompany, @GLAcct bGLAcct, @INCo bCompany, @MatlGroup bGroup, 
    		@Material bMatl, @UM bUM, @UnitCost bUnitCost, @Loc bLoc, @DefECM bECM, @DefUnitCost bUnitCost,
    		@DefGLAcct bGLAcct, @DefUM bUM, @Units bUnits, @TotalCost bDollar, @errmsg varchar(120)
    
    --Flags for dependent defaults
    declare @ynECM bYN, @ynGLCo bYN, @ynGLAcct bYN, @ynMatlGroup bYN, @ynUnitCost bYN, @ynUM bYN, @ynTotalCost bYN
    
    /* check required input params */
    
    select @finalrcode = 0
    
    if @ImportId is null
      begin
      select @desc = 'Missing ImportId.', @finalrcode = 1
      goto bspexit
      end
    if @ImportTemplate is null
      begin
      select @desc = 'Missing ImportTemplate.', @finalrcode = 1
      goto bspexit
      end
    
    if @Form is null
      begin
      select @desc = 'Missing Form.', @finalrcode = 1
      goto bspexit
     end
    
     select @CursorOpen = 0
    
    -- Check ImportTemplate detail for columns to set Bidtek Defaults
    if not exists(select top 1 1 From IMTD with (nolock)
    Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
    and IMTD.RecordType = @rectype)
    goto bspexit
    
    DECLARE 
			  @OverwriteBatchTransType 	 bYN
			, @OverwriteActDate 	 	 bYN
			, @OverwriteUnits 	 		 bYN
			, @OverwriteBatchType 	 	 bYN
			, @OverwriteGLCo 	 		 bYN
			, @OverwriteGLAcct 	 		 bYN
			, @OverwriteMatlGroup 	 	 bYN
			, @OverwriteECM 	 		 bYN
			, @OverwriteUnitCost 	 	 bYN
			, @OverwriteUM 	 			 bYN
			, @OverwriteTotalCost 	 	 bYN
			, @OverwriteCo				 bYN
			,	@IsCoEmpty 				 bYN
			,	@IsGLAcctEmpty 			 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsBatchTransTypeEmpty 	 bYN
			,	@IsINTransEmpty 		 bYN
			,	@IsActDateEmpty 		 bYN
			,	@IsLocEmpty 			 bYN
			,	@IsMaterialEmpty 		 bYN
			,	@IsUMEmpty 				 bYN
			,	@IsUnitsEmpty 			 bYN
			,	@IsUnitCostEmpty 		 bYN
			,	@IsECMEmpty 			 bYN
			,	@IsTotalCostEmpty 		 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsMatlGroupEmpty 		 bYN
			,	@IsGLCoEmpty 			 bYN
			,	@IsBatchTypeEmpty 		 bYN			
        
		
		SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
		SELECT @OverwriteActDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActDate', @rectype);
		SELECT @OverwriteUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Units', @rectype);
		SELECT @OverwriteBatchType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchType', @rectype);
	    SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
		SELECT @OverwriteGLAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLAcct', @rectype);
		SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
		SELECT @OverwriteECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ECM', @rectype);
		SELECT @OverwriteUnitCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnitCost', @rectype);
		SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UM', @rectype);
		SELECT @OverwriteTotalCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TotalCost', @rectype);
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
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @CoID
    end
    
    select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'Y') 
    begin
    	Update IMWE
    	SET IMWE.UploadVal = 'A'
    	where IMWE.ImportTemplate=@ImportTemplate and
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
    end
    
    select @ActDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActDate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActDate, 'Y') = 'Y') 
    begin
    	Update IMWE
    	----#141031
    	SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(),101)
    	where IMWE.ImportTemplate=@ImportTemplate and
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActDateID
    end
    
    select @UnitsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Units'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUnits, 'Y') = 'Y')
    begin
    	Update IMWE
    	SET IMWE.UploadVal = '0'
    	where IMWE.ImportTemplate=@ImportTemplate and
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @UnitsID
    end
    
    
    select @BatchTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchType'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchType, 'Y') = 'Y') 
    begin
    	Update IMWE
    	SET IMWE.UploadVal = 'IN Adj'
    	where IMWE.ImportTemplate=@ImportTemplate and
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTypeID
    end
    
    --------------------------

    select @CoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
    begin
    	Update IMWE
    	SET IMWE.UploadVal = @Company
    	where IMWE.ImportTemplate=@ImportTemplate and
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @CoID
    end
    
        select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N') 
    begin
    	Update IMWE
    	SET IMWE.UploadVal = 'A'
    	where IMWE.ImportTemplate=@ImportTemplate and
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @ActDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActDate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActDate, 'Y') = 'N') 
    begin
    	Update IMWE
    	----#141031
    	SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(),101)
    	where IMWE.ImportTemplate=@ImportTemplate and
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActDateID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @UnitsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Units'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUnits, 'Y') = 'N')
    begin
    	Update IMWE
    	SET IMWE.UploadVal = '0'
    	where IMWE.ImportTemplate=@ImportTemplate and
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @UnitsID
    	AND IMWE.UploadVal IS NULL
    end
    
    
    select @BatchTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchType'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchType, 'Y') = 'N') 
    begin
    	Update IMWE
    	SET IMWE.UploadVal = 'IN Adj'
    	where IMWE.ImportTemplate=@ImportTemplate and
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTypeID
    	AND IMWE.UploadVal IS NULL
    end
    
    --Get Identifiers for dependent defaults.
    select @ynGLCo = 'N'
    select @GLCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLCo', @rectype, 'Y')
    if @GLCoID <> 0 select @ynGLCo = 'Y'
    
    select @ynGLAcct = 'N'
    select @GLAcctID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLAcct', @rectype, 'Y')
    if @GLAcctID <> 0 select @ynGLAcct = 'Y'
    
    select @ynMatlGroup = 'N'
    select @MatlGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MatlGroup', @rectype, 'Y')
    if @MatlGroupID <> 0 select @ynMatlGroup = 'Y'
    
    select @ynECM = 'N'
    select @ECMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ECM', @rectype, 'Y')
    if @ECMID <> 0 select @ynECM = 'Y'
    
    select @ynUnitCost = 'N'
    select @UnitCostID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnitCost', @rectype, 'Y')
    if @UnitCostID <> 0 select @ynUnitCost = 'Y'
    
    select @ynUM = 'N'
    select @UMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UM', @rectype, 'Y')
    if @UMID <> 0 select @ynUM = 'Y'
    
    select @ynTotalCost = 'N'
    select @TotalCostID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TotalCost', @rectype, 'Y')
    if @TotalCostID <> 0 select @ynTotalCost = 'Y'
   
    --Added for #25350
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
    
        If @Column = 'Co' select @INCo = @Uploadval
    	 If @Column = 'GLCo' select @GLCo = @Uploadval
    	 If @Column = 'Material' select @Material = @Uploadval
    	 If @Column = 'UM' select @UM = @Uploadval
    	 If @Column = 'Loc' select @Loc = @Uploadval
    	 If @Column = 'MatlGroup' select @MatlGroup = @Uploadval
   	 If @Column = 'Units' and isnumeric(@Uploadval) = 1 select @Units = convert(numeric(12,3), @Uploadval)
   	 If @Column = 'UnitCost' and isnumeric(@Uploadval) = 1 select @UnitCost = convert(numeric(16,5), @Uploadval)
   	 if @Column = 'ECM' select @ECM = @Uploadval --135290

		IF @Column='Co' 
			IF @Uploadval IS NULL
				SET @IsCoEmpty = 'Y'
			ELSE
				SET @IsCoEmpty = 'N'
		IF @Column='GLAcct' 
			IF @Uploadval IS NULL
				SET @IsGLAcctEmpty = 'Y'
			ELSE
				SET @IsGLAcctEmpty = 'N'
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
		IF @Column='INTrans' 
			IF @Uploadval IS NULL
				SET @IsINTransEmpty = 'Y'
			ELSE
				SET @IsINTransEmpty = 'N'
		IF @Column='ActDate' 
			IF @Uploadval IS NULL
				SET @IsActDateEmpty = 'Y'
			ELSE
				SET @IsActDateEmpty = 'N'
		IF @Column='Loc' 
			IF @Uploadval IS NULL
				SET @IsLocEmpty = 'Y'
			ELSE
				SET @IsLocEmpty = 'N'
		IF @Column='Material' 
			IF @Uploadval IS NULL
				SET @IsMaterialEmpty = 'Y'
			ELSE
				SET @IsMaterialEmpty = 'N'
		IF @Column='UM' 
			IF @Uploadval IS NULL
				SET @IsUMEmpty = 'Y'
			ELSE
				SET @IsUMEmpty = 'N'
		IF @Column='Units' 
			IF @Uploadval IS NULL
				SET @IsUnitsEmpty = 'Y'
			ELSE
				SET @IsUnitsEmpty = 'N'
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
		IF @Column='TotalCost' 
			IF @Uploadval IS NULL
				SET @IsTotalCostEmpty = 'Y'
			ELSE
				SET @IsTotalCostEmpty = 'N'
		IF @Column='Description' 
			IF @Uploadval IS NULL
				SET @IsDescriptionEmpty = 'Y'
			ELSE
				SET @IsDescriptionEmpty = 'N'
		IF @Column='MatlGroup' 
			IF @Uploadval IS NULL
				SET @IsMatlGroupEmpty = 'Y'
			ELSE
				SET @IsMatlGroupEmpty = 'N'
		IF @Column='GLCo' 
			IF @Uploadval IS NULL
				SET @IsGLCoEmpty = 'Y'
			ELSE
				SET @IsGLCoEmpty = 'N'
		IF @Column='BatchType' 
			IF @Uploadval IS NULL
				SET @IsBatchTypeEmpty = 'Y'
			ELSE
				SET @IsBatchTypeEmpty = 'N'
    
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
    		select @GLCo = GLCo from bINCO with (nolock) where INCo = @INCo
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @GLCo
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier=@GLCoID and IMWE.RecordType=@rectype
    
    	end
    
    	if @ynMatlGroup = 'Y' and @GLCo is not null AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR ISNULL(@IsMatlGroupEmpty, 'Y') = 'Y')
    	begin
    		select @MatlGroup = MatlGroup from bHQCO with (nolock) where HQCo = @GLCo
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @MatlGroup
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier=@MatlGroupID and IMWE.RecordType=@rectype
    	end
    
    	if @ynECM = 'Y' or @ynUnitCost = 'Y' or @ynGLAcct = 'Y' or @ynUM = 'Y'
    	begin
    		--only call validation procedure if we need to default one or more of these.
    		SELECT @DefUM = NULL, @DefUnitCost = NULL, @DefECM = NULL, @DefGLAcct = NULL
    		exec @rcode = bspINLocMatlVal @INCo, @Loc, @Material, @MatlGroup, 'Y', 'N', @DefUM output, null, null, null, 
    				@DefUnitCost output, @DefECM output, null, null, @DefGLAcct output, null, null, null, @desc output
    
    		if @rcode <> 0
    		begin	
    			select @finalrcode = @rcode
   			select @errmsg = @desc
    			--Added Material Identifier for #25350
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			 values(@ImportId,@ImportTemplate,@Form,@currrecseq,null,@errmsg,@MaterialID)			
    		end
   
    		if @ynECM = 'Y' AND (ISNULL(@OverwriteECM, 'Y') = 'Y' OR ISNULL(@IsECMEmpty, 'Y') = 'Y')
    		begin
    			if isnull(@UM,'') = 'LS' 
    				select @ECM = ''		--can't be null
    			else
    				select @ECM = @DefECM
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @ECM
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@ECMID and IMWE.RecordType=@rectype
    			
    		end
    		
    		if @ynUnitCost = 'Y' AND (ISNULL(@OverwriteUnitCost, 'Y') = 'Y' OR ISNULL(@IsUnitCostEmpty, 'Y') = 'Y')
    		begin
    			select @UnitCost = @DefUnitCost
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @UnitCost
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@UnitCostID and IMWE.RecordType=@rectype
    
    		end
    
    		if @ynGLAcct = 'Y' and @GLCo is not null AND (ISNULL(@OverwriteGLAcct, 'Y') = 'Y' OR ISNULL(@IsGLAcctEmpty, 'Y') = 'Y')
    		begin
    			select @GLAcct = @DefGLAcct
    	
    			UPDATE IMWE
    			SET IMWE.UploadVal = @GLAcct
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@GLAcctID and IMWE.RecordType=@rectype
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

   	--issue #29451, TotalCost default
   	if @ynTotalCost = 'Y' AND (ISNULL(@OverwriteTotalCost, 'Y') = 'Y' OR ISNULL(@IsTotalCostEmpty, 'Y') = 'Y')
   	begin
   		--135290
   		select @TotalCost = isnull(@UnitCost,0) * isnull(@Units,0) / case @ECM when 'E' then 1 when 'C' then 100 when 'M' then 1000 else 1 end

   		UPDATE IMWE
   		SET IMWE.UploadVal = @TotalCost
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@TotalCostID and IMWE.RecordType=@rectype
   		
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
    
        select @msg = isnull(@errmsg,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsARCM]'
    
        return @finalrcode




GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsINAB] TO [public]
GO
