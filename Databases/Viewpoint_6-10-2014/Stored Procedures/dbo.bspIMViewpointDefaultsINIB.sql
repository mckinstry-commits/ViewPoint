SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[bspIMViewpointDefaultsINIB]
   /***********************************************************
    * CREATED BY:   RBT 09/08/04 for issue #22564
    * MODIFIED BY:  RBT 07/26/05 - issue #29402, fix where clause in MOItem default code.
	*			    Dan So - 07/31/08 - Issue #129195 - added NULL to bspINMOCoVal call
	*				TRL  10/27/08	- 130765 format numeric imports according viewpoint datatypes
	*				CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
	*				CC  05/29/09 - Issue #133516 - Correct defaulting of Company
	*				GP	07/20/09 - Issue #134439 - Correct defaulting of Material Description
	*				GF 09/14/2010 - issue #141031 changed to use function vfDateOnly
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
   
   declare @rcode int, @recode int, @desc varchar(120), @status int, @defaultvalue varchar(30), 
   	@CursorOpen int, @FormDetail varchar(20), @FormHeader varchar(20), @HeaderRecordType varchar(10),
   	@RecKey varchar(10), @HeaderReqSeq varchar(10), @TodaysDate varchar(10)
   
   
   select @rcode = 0
   
   --Identifiers
   declare @CoID int, @MthID int, @BatchTransTypeID int, @PhaseGroupID int, 
   @PhaseID int, @JCCoID int, @JCCTypeID int, @GLCoID int, @GLAcctID int, 
   @MatlGroupID int, @TaxGroupID int, @UMID int, @ECMID int, @UnitPriceID int, 
   @RemainUnitsID int, @TaxCodeID int, @MaterialID int, @TaxAmtID int,
   @reckeyid int, @headerreckeyid int, @JobID int, @HeaderJobID int, 
   @HeaderJCCoID int, @TotalPriceID int, @MOItemID int, @OrderedUnitsID int,
   @MatlDescID int
   
   --Values
   declare @Co bCompany, @PhaseGroup bGroup, @Phase bPhase, @JCCo bCompany, @JCCType bJCCType, 
   @GLCo bCompany, @GLAcct bGLAcct, @MatlGroup bGroup, @TaxGroup bGroup, @UM bUM, 
   @ECM bECM, @UnitPrice bUnitCost, @RemainUnits bUnits, @Material bMatl, @Loc bLoc,
   @DefPhase bPhase, @DefJCCType bJCCType, @DefUM bUM, @DefECM bECM, 
   @TaxCode bTaxCode, @Mth bMonth, @DefTaxGroup bGroup, @DefGLCo bCompany, @Job bJob,
   @OverrideGLAcctYN bYN, @DummyUnitCost bUnitCost, @TaxAmt bDollar, @TotalPrice bDollar,
   @TaxRate bRate, @OrderedUnits bUnits, @MOItem bItem, @MatlDesc bItemDesc
   
   --Flags for dependent defaults
   declare @ynPhaseGroup bYN, @ynPhase bYN, @ynJCCo bYN, @ynJCCType bYN, 
   @ynGLCo bYN, @ynGLAcct bYN, @ynMatlGroup bYN, @ynTaxGroup bYN, @ynUM bYN, 
   @ynECM bYN, @ynUnitPrice bYN, @ynTaxCode bYN, @ynTaxAmt bYN,
   @ynJob bYN, @ynTotalPrice bYN, @ynMOItem bYN, @ynMatlDesc bYN
   
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
			 @OverwriteMth 	 			 bYN
			, @OverwriteBatchTransType 	 bYN
			, @OverwritePhaseGroup 	 	 bYN
			, @OverwriteJCCo 	 		 bYN
			, @OverwritePhase 	 		 bYN
			, @OverwriteJob 	 		 bYN
			, @OverwriteJCCType 	 	 bYN
			, @OverwriteGLCo 	 		 bYN
			, @OverwriteGLAcct 	 		 bYN
			, @OverwriteTaxGroup 	 	 bYN
			, @OverwriteUM 	 			 bYN
			, @OverwriteMatlGroup 	 	 bYN
			, @OverwriteECM 	 		 bYN
			, @OverwriteUnitPrice 	 	 bYN
			, @OverwriteTaxCode 	 	 bYN
			, @OverwriteTaxAmt 	 		 bYN
			, @OverwriteTotalPrice 	 	 bYN
			, @OverwriteMOItem 	 		 bYN
			, @OverwriteCo				 bYN
			,	@IsCoEmpty 				 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsMOItemEmpty 			 bYN
			,	@IsBatchTransTypeEmpty 	 bYN
			,	@IsLocEmpty 			 bYN
			,	@IsMatlGroupEmpty 		 bYN
			,	@IsMaterialEmpty 		 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsJCCoEmpty 			 bYN
			,	@IsJobEmpty 			 bYN
			,	@IsPhaseGroupEmpty 		 bYN
			,	@IsPhaseEmpty 			 bYN
			,	@IsJCCTypeEmpty 		 bYN
			,	@IsGLCoEmpty 			 bYN
			,	@IsGLAcctEmpty 			 bYN
			,	@IsReqDateEmpty 		 bYN
			,	@IsUMEmpty 				 bYN
			,	@IsECMEmpty 			 bYN
			,	@IsOrderedUnitsEmpty 	 bYN
			,	@IsRemainUnitsEmpty 	 bYN
			,	@IsUnitPriceEmpty 		 bYN
			,	@IsTotalPriceEmpty 		 bYN
			,	@IsTaxGroupEmpty 		 bYN
			,	@IsTaxCodeEmpty 		 bYN
			,	@IsTaxAmtEmpty 			 bYN
			,	@IsNotesEmpty 			 bYN

   
    SELECT @OverwriteMth = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Mth', @rectype);
	SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
	SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
	SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
	SELECT @OverwritePhase = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Phase', @rectype);
	SELECT @OverwriteJob = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Job', @rectype);
	SELECT @OverwriteJCCType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCType', @rectype);
	SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
	SELECT @OverwriteGLAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLAcct', @rectype);
	SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype);
	SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UM', @rectype);
	SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
	SELECT @OverwriteECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ECM', @rectype);
	SELECT @OverwriteUnitPrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnitPrice', @rectype);
	SELECT @OverwriteTaxCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxCode', @rectype);
	SELECT @OverwriteTaxAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxAmt', @rectype);
	SELECT @OverwriteTotalPrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TotalPrice', @rectype);
	SELECT @OverwriteMOItem = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MOItem', @rectype);
	SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
	
   --Get RecordKey information
    	select @FormHeader = 'INMOEntry'
    	select @FormDetail = 'INMOEntryItems'
    
    	select @HeaderRecordType = RecordType
    	from IMTR
    	where @ImportTemplate = ImportTemplate and Form = @FormHeader
   
   	select @reckeyid = a.Identifier
   	From IMTD a join DDUD b on a.Identifier = b.Identifier
   	Where a.ImportTemplate=@ImportTemplate AND b.ColumnName = 'RecKey'
   	and a.RecordType = @rectype and b.Form = @FormDetail
   
   	select @headerreckeyid = a.Identifier
   	From IMTD a join DDUD b on a.Identifier = b.Identifier
   	Where a.ImportTemplate=@ImportTemplate AND b.ColumnName = 'RecKey'
   	and a.RecordType = @HeaderRecordType and b.Form = @FormHeader
   
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
	SET IMWE.UploadVal = CONVERT(VARCHAR(10), dbo.vfDateOnlyMonth(),101)
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
   
   ------------------------

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
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMth, 'Y') = 'N')
   begin
   	Update IMWE
	----#141031
	SET IMWE.UploadVal = CONVERT(VARCHAR(10), dbo.vfDateOnlyMonth(),101)
   	----SET IMWE.UploadVal = right('0' + convert(varchar(2), month(getxdate())),2) + '/01/' + convert(varchar(4), year(getxdate()))
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MthID and IMWE.RecordType = @rectype
   	AND IMWE.UploadVal IS NULL
   end
   
   select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'A'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID and IMWE.RecordType = @rectype
   	AND IMWE.UploadVal IS NULL
   end
   
   --Get Identifiers for dependent defaults.
   select @ynPhaseGroup = 'N'
   select @PhaseGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGroup', @rectype, 'Y')
   if @PhaseGroupID <> 0 select @ynPhaseGroup = 'Y'
   
   select @ynPhase = 'N'
   select @PhaseID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Phase', @rectype, 'Y')
   if @PhaseID <> 0 select @ynPhase = 'Y'
   
   select @ynJCCo = 'N'
   select @JCCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCo', @rectype, 'Y')
   if @JCCoID <> 0 select @ynJCCo = 'Y'
   
   select @ynJob = 'N'
   select @JobID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Job', @rectype, 'Y')
   if @JobID <> 0 select @ynJob = 'Y'
   
   select @ynJCCType = 'N'
   select @JCCTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCType', @rectype, 'Y')
   if @JCCTypeID <> 0 select @ynJCCType = 'Y'
   
   select @ynGLCo = 'N'
   select @GLCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLCo', @rectype, 'Y')
   if @GLCoID <> 0 select @ynGLCo = 'Y'
   
   select @ynGLAcct = 'N'
   select @GLAcctID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLAcct', @rectype, 'Y')
   if @GLAcctID <> 0 select @ynGLAcct = 'Y'
   
   select @ynMatlGroup = 'N'
   select @MatlGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MatlGroup', @rectype, 'Y')
   if @MatlGroupID <> 0 select @ynMatlGroup = 'Y'
   
   select @ynTaxGroup = 'N'
   select @TaxGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxGroup', @rectype, 'Y')
   if @TaxGroupID <> 0 select @ynTaxGroup = 'Y'
   
   select @ynUM = 'N'
   select @UMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UM', @rectype, 'Y')
   if @UMID <> 0 select @ynUM = 'Y'
   
   select @ynECM = 'N'
   select @ECMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ECM', @rectype, 'Y')
   if @ECMID <> 0 select @ynECM = 'Y'
   
   select @ynUnitPrice = 'N'
   select @UnitPriceID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnitPrice', @rectype, 'Y')
   if @UnitPriceID <> 0 select @ynUnitPrice = 'Y'
   
   select @ynTaxCode = 'N'
   select @TaxCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxCode', @rectype, 'Y')
   if @TaxCodeID <> 0 select @ynTaxCode = 'Y'
   
   select @ynTaxAmt = 'N'
   select @TaxAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxAmt', @rectype, 'Y')
   if @TaxAmtID <> 0 select @ynTaxAmt = 'Y'
   
   select @ynTotalPrice = 'N'
   select @TotalPriceID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TotalPrice', @rectype, 'Y')
   if @TotalPriceID <> 0 select @ynTotalPrice = 'Y'
   
   select @ynMOItem = 'N'
   select @MOItemID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MOItem', @rectype, 'Y')
   if @MOItemID <> 0 select @ynMOItem = 'Y'
   
   select @ynMatlDesc = 'N'
   select @MatlDescID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Description', @rectype, 'Y')
   if @MatlDescID <> 0 select @ynMatlDesc = 'Y'
   
   
   --Get some identifiers regardless of Viewpoint Default status...
   select @MaterialID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Material', @rectype, 'N')
   select @JobID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Job', @rectype, 'N')
   select @HeaderJobID = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Job', @HeaderRecordType, 'N')
   select @HeaderJCCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'JCCo', @HeaderRecordType, 'N')
   select @RemainUnitsID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RemainUnits', @rectype, 'N')
   select @OrderedUnitsID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OrderedUnits', @rectype, 'N')
   select @TotalPriceID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TotalPrice', @rectype, 'N')
   select @TaxAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxAmt', @rectype, 'N')
   select @UnitPriceID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnitPrice', @rectype, 'N')
   
   
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
   --#142350 - removing	 @importid varchar(10), @seq int, @Identifier int,
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
   
       If @Column = 'Co' and isnumeric(@Uploadval)=1 select @Co = convert(int, @Uploadval)
   	If @Column = 'Mth' and isdate(@Uploadval)=1 select @Mth = convert(smalldatetime, @Uploadval)
   	If @Column = 'PhaseGroup' and isnumeric(@Uploadval)=1 select @PhaseGroup = convert(tinyint, @Uploadval)
   	If @Column = 'Phase' select @Phase = @Uploadval
   	If @Column = 'JCCo' and isnumeric(@Uploadval)=1 select @JCCo = convert(int, @Uploadval)
   	If @Column = 'JCCType' and isnumeric(@Uploadval)=1 select @JCCType = convert(tinyint, @Uploadval)
   	If @Column = 'GLCo' and isnumeric(@Uploadval)=1 select @GLCo = convert(int, @Uploadval)
   	If @Column = 'GLAcct' select @GLAcct = @Uploadval
   	If @Column = 'MatlGroup' and isnumeric(@Uploadval)=1 select @MatlGroup = convert(tinyint, @Uploadval)
   	If @Column = 'TaxGroup' and isnumeric(@Uploadval)=1 select @TaxGroup = convert(tinyint, @Uploadval)
   	If @Column = 'UM' select @UM = @Uploadval
   	If @Column = 'ECM' select @ECM = @Uploadval
	--Issue 130765
   	If @Column = 'UnitPrice' and isnumeric(@Uploadval)=1 select @UnitPrice = convert(numeric(16,5),@Uploadval)
   	If @Column = 'RemainUnits' and isnumeric(@Uploadval)=1 select @RemainUnits = convert(numeric(12,3),@Uploadval)
   	If @Column = 'Material' select @Material = @Uploadval
   	If @Column = 'Loc' select @Loc = @Uploadval
   	If @Column = 'TaxCode' select @TaxCode = @Uploadval
   	If @Column = 'Job' select @Job = @Uploadval
   	If @Column = 'TaxAmt' and isnumeric(@Uploadval)=1 select @TaxAmt = convert(numeric(12,2),@Uploadval)
   	If @Column = 'TotalPrice' and isnumeric(@Uploadval)=1 select @TotalPrice = convert(numeric(12,2),@Uploadval)
   	If @Column = 'OrderedUnits' and isnumeric(@Uploadval)=1 select @OrderedUnits = convert(numeric(12,3),@Uploadval)	
   	If @Column = 'Description' select @MatlDesc = @Uploadval

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
	IF @Column='MOItem' 
		IF @Uploadval IS NULL
			SET @IsMOItemEmpty = 'Y'
		ELSE
			SET @IsMOItemEmpty = 'N'
	IF @Column='BatchTransType' 
		IF @Uploadval IS NULL
			SET @IsBatchTransTypeEmpty = 'Y'
		ELSE
			SET @IsBatchTransTypeEmpty = 'N'
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
	IF @Column='JCCType' 
		IF @Uploadval IS NULL
			SET @IsJCCTypeEmpty = 'Y'
		ELSE
			SET @IsJCCTypeEmpty = 'N'
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
	IF @Column='ReqDate' 
		IF @Uploadval IS NULL
			SET @IsReqDateEmpty = 'Y'
		ELSE
			SET @IsReqDateEmpty = 'N'
	IF @Column='UM' 
		IF @Uploadval IS NULL
			SET @IsUMEmpty = 'Y'
		ELSE
			SET @IsUMEmpty = 'N'
	IF @Column='ECM' 
		IF @Uploadval IS NULL
			SET @IsECMEmpty = 'Y'
		ELSE
			SET @IsECMEmpty = 'N'
	IF @Column='OrderedUnits' 
		IF @Uploadval IS NULL
			SET @IsOrderedUnitsEmpty = 'Y'
		ELSE
			SET @IsOrderedUnitsEmpty = 'N'
	IF @Column='RemainUnits' 
		IF @Uploadval IS NULL
			SET @IsRemainUnitsEmpty = 'Y'
		ELSE
			SET @IsRemainUnitsEmpty = 'N'
	IF @Column='UnitPrice' 
		IF @Uploadval IS NULL
			SET @IsUnitPriceEmpty = 'Y'
		ELSE
			SET @IsUnitPriceEmpty = 'N'
	IF @Column='TotalPrice' 
		IF @Uploadval IS NULL
			SET @IsTotalPriceEmpty = 'Y'
		ELSE
			SET @IsTotalPriceEmpty = 'N'
	IF @Column='TaxGroup' 
		IF @Uploadval IS NULL
			SET @IsTaxGroupEmpty = 'Y'
		ELSE
			SET @IsTaxGroupEmpty = 'N'
	IF @Column='TaxCode' 
		IF @Uploadval IS NULL
			SET @IsTaxCodeEmpty = 'Y'
		ELSE
			SET @IsTaxCodeEmpty = 'N'
	IF @Column='TaxAmt' 
		IF @Uploadval IS NULL
			SET @IsTaxAmtEmpty = 'Y'
		ELSE
			SET @IsTaxAmtEmpty = 'N'
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
   
   
   	if @ynJCCo = 'Y'  AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y' OR ISNULL(@IsJCCoEmpty, 'Y') = 'Y')
   	begin
   		--GET HEADER JCCo
   		select @RecKey=IMWE.UploadVal
   		from IMWE with (nolock)
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
   		and IMWE.Identifier = @reckeyid and IMWE.RecordType = @rectype 
   		and IMWE.RecordSeq = @currrecseq
   
   		select @HeaderReqSeq=IMWE.RecordSeq
   		from IMWE with (nolock)
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
   		and IMWE.Identifier = @headerreckeyid and IMWE.RecordType = @HeaderRecordType 
   		and IMWE.UploadVal = @RecKey
   
   		select @JCCo=IMWE.UploadVal
   		from IMWE with (nolock)
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
   		and IMWE.Identifier = @HeaderJCCoID and IMWE.RecordType = @HeaderRecordType 
   		and IMWE.RecordSeq = @HeaderReqSeq
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @JCCo
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@JCCoID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynJob = 'Y'  AND (ISNULL(@OverwriteJob, 'Y') = 'Y' OR ISNULL(@IsJobEmpty, 'Y') = 'Y')
   	begin
   		--GET HEADER JOB
   		select @RecKey=IMWE.UploadVal
   		from IMWE with (nolock)
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
   		and IMWE.Identifier = @reckeyid and IMWE.RecordType = @rectype 
   		and IMWE.RecordSeq = @currrecseq
   
   		select @HeaderReqSeq=IMWE.RecordSeq
   		from IMWE with (nolock)
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
   		and IMWE.Identifier = @headerreckeyid and IMWE.RecordType = @HeaderRecordType 
   		and IMWE.UploadVal = @RecKey
   
   		select @Job=IMWE.UploadVal
   		from IMWE with (nolock)
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
   		and IMWE.Identifier = @HeaderJobID and IMWE.RecordType = @HeaderRecordType 
   		and IMWE.RecordSeq = @HeaderReqSeq
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @Job
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@JobID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynMOItem = 'Y' AND (ISNULL(@OverwriteMOItem, 'Y') = 'Y' OR ISNULL(@IsMOItemEmpty, 'Y') = 'Y')
   	begin
   		if @currrecseq = 1 
   		begin
   			--reset all MOItem fields to zero, so auto sequencing starts at 1.
   			UPDATE IMWE
   			SET IMWE.UploadVal = 0
   			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
   			and IMWE.Identifier=@MOItemID and IMWE.RecordType=@rectype
   		end
   		
   		select @RecKey=IMWE.UploadVal
   		from IMWE with (nolock)
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
   		and IMWE.Identifier = @reckeyid and IMWE.RecordType = @rectype 
   		and IMWE.RecordSeq = @currrecseq
   
   		select @MOItem = Max(convert(int,isnull(w.UploadVal,0))) + 1
   		from IMWE w with (nolock)
   		inner join IMWE e with (nolock)
   		on w.ImportTemplate=e.ImportTemplate and w.ImportId=e.ImportId	--issue #29402
   		and w.RecordType=e.RecordType and w.Identifier=@MOItemID and e.Identifier=@reckeyid
   		and w.RecordSeq=e.RecordSeq
   		where w.ImportTemplate=@ImportTemplate and w.ImportId=@ImportId
   		and w.RecordType = @rectype and e.UploadVal = @RecKey --and isnumeric(w.UploadVal) = 1 
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @MOItem
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@MOItemID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynPhaseGroup = 'Y'  AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')
   	begin
   		exec @recode = bspJCPhaseGrpGet @Co, @PhaseGroup output, @msg output
   		
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
   
   	exec @recode = bspINMOMaterialVal @Co, @Loc, @Material, @DefPhase output, @DefJCCType output, 
   			@DefUM output, @DefECM output, null, @msg output
   
   	if @recode <> 0
   	begin
   		insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
   		 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@MaterialID)			
   
   		select @rcode = 1
   		select @desc = @msg
   	end
   
   	--bspINMOMaterialVal
   	if @ynPhase = 'Y'  AND (ISNULL(@OverwritePhase, 'Y') = 'Y' OR ISNULL(@IsPhaseEmpty, 'Y') = 'Y')
   	begin
   		select @Phase = @DefPhase
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @Phase
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@PhaseID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynJCCType = 'Y' AND (ISNULL(@OverwriteJCCType, 'Y') = 'Y' OR ISNULL(@IsJCCTypeEmpty, 'Y') = 'Y')
   	begin
   		select @JCCType = @DefJCCType
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @JCCType
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@JCCTypeID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynUM = 'Y' AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')
   	begin
   		select @UM = @DefUM
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @UM
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@UMID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynECM = 'Y' AND (ISNULL(@OverwriteECM, 'Y') = 'Y' OR ISNULL(@IsECMEmpty, 'Y') = 'Y')
   	begin
   		select @ECM = @DefECM
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @ECM
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@ECMID and IMWE.RecordType=@rectype
   
   	end
   	--bspINMOMaterialVal
   
   
   	if @ynGLAcct = 'Y'  AND (ISNULL(@OverwriteGLAcct, 'Y') = 'Y' OR ISNULL(@IsGLAcctEmpty, 'Y') = 'Y')
   	begin
   		exec @recode = bspJCCAGlacctDflt @JCCo, @Job, @PhaseGroup, @Phase, @JCCType, 'N', @GLAcct output, @msg output
   	
   		if @recode <> 0
   		begin
   			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
   			 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@GLAcctID)			
   	
   			select @rcode = 1
   			select @desc = @msg
   		end
   
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @GLAcct
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@GLAcctID and IMWE.RecordType=@rectype
   
   	end
   
   	exec @recode = bspINMOCoVal @Co, @Mth, @DefTaxGroup output, @DefGLCo output, @OverrideGLAcctYN output, NULL, @msg output
   	--bspINMOCoVal
   	if @recode <> 0
   	begin
   		insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
   		 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@CoID)			
   
   		select @rcode = 1
   		select @desc = @msg
   	end
   
   	if @ynTaxGroup = 'Y'  AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y' OR ISNULL(@IsTaxGroupEmpty, 'Y') = 'Y')
   	begin
   		select @TaxGroup = @DefTaxGroup
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @TaxGroup
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@TaxGroupID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynGLCo = 'Y'  AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
   	begin
   		select @GLCo = @DefGLCo
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @GLCo
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@GLCoID and IMWE.RecordType=@rectype
   
   	end
   	--bspINMOCoVal
   
   	if @ynMatlGroup = 'Y'  AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR ISNULL(@IsMatlGroupEmpty, 'Y') = 'Y')
   	begin
   		exec @recode = bspHQMatlGrpGet @Co, @MatlGroup output, @msg output
   
   		if @recode <> 0
   		begin
   			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
   			 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@MatlGroupID)			
   	
   			select @rcode = 1
   			select @desc = @msg
   		end
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @MatlGroup
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@MatlGroupID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynUnitPrice = 'Y'  AND (ISNULL(@OverwriteUnitPrice, 'Y') = 'Y' OR ISNULL(@IsUnitPriceEmpty, 'Y') = 'Y')
   	begin
   		exec @recode = bspINMOMatlUMVal @Co, @Loc, @Material, @MatlGroup, @UM, @JCCo, @Job, @DummyUnitCost output,
   				@DefECM output, @UnitPrice output, @msg output
   	
   		if @recode <> 0
   		begin
   			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
   			 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@UnitPriceID)			
   	
   			select @rcode = 1
   			select @desc = @msg
   		end
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @UnitPrice
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@UnitPriceID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynTaxCode = 'Y'   AND (ISNULL(@OverwriteTaxCode, 'Y') = 'Y' OR ISNULL(@IsTaxCodeEmpty, 'Y') = 'Y')
   	begin
   		exec @recode = bspINMOJobVal @JCCo, @Job, @TaxCode output, null, null, null, @msg output
   
   		if @recode <> 0
   		begin
   			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
   			 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@TaxCodeID)			
   	
   			select @rcode = 1
   			select @desc = @msg
   		end
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @TaxCode
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@TaxCodeID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynTotalPrice = 'Y'  AND (ISNULL(@OverwriteTotalPrice, 'Y') = 'Y' OR ISNULL(@IsTotalPriceEmpty, 'Y') = 'Y')
   	begin
   		select @TotalPrice = isnull(@UnitPrice,0) * isnull(@OrderedUnits,0)
   
   		if @ECM = 'C'
   			select @TotalPrice = @TotalPrice * 10
   		else if @ECM = 'M'
   			select @TotalPrice = @TotalPrice * 100
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @TotalPrice
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@TotalPriceID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynTaxAmt = 'Y'  AND (ISNULL(@OverwriteTaxAmt, 'Y') = 'Y' OR ISNULL(@IsTaxAmtEmpty, 'Y') = 'Y')
   	begin
   		--get @TaxRate
   		----#141031
   		select @TodaysDate = convert(varchar(10), dbo.vfDateOnly(),101)
   		exec @recode = bspHQTaxRateGet @TaxGroup, @TaxCode, @TodaysDate, @TaxRate output, null, null, @msg output
   		if @recode <> 0
   		begin
   			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
   			 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@TaxAmtID)
   	
   			select @rcode = 1
   			select @desc = @msg
   		end
   
   		select @TaxAmt = isnull(@TaxRate,0) * isnull(@TotalPrice,0)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @TaxAmt
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@TaxAmtID and IMWE.RecordType=@rectype
   
   	end
   
	if @ynMatlDesc = 'Y' and isnull(@IsDescriptionEmpty, 'Y') = 'Y'
	begin
		exec @recode = bspHQMatlVal @MatlGroup, @Material, null, @MatlDesc output
		
		update IMWE
		set IMWE.UploadVal = @MatlDesc
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
		and IMWE.Identifier=@MatlDescID and IMWE.RecordType=@rectype
	end
   
   	--Unconditional defaults
   
   	--ALWAYS SET REMAINUNITS = ORDERED UNITS - per DanF
   	select @RemainUnits = @OrderedUnits
   
   	UPDATE IMWE
   	SET IMWE.UploadVal = @RemainUnits
   	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   	and IMWE.Identifier=@RemainUnitsID and IMWE.RecordType=@rectype
   
   
   	--Cleanup
   	if isnull(@UnitPrice,0) = 0 
   	begin	
   		UPDATE IMWE
   		SET IMWE.UploadVal = '0'
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@UnitPriceID and IMWE.RecordType=@rectype
   	end
   
   	if isnull(@OrderedUnits,0) = 0
   	begin	
   		UPDATE IMWE
   		SET IMWE.UploadVal = '0'
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@OrderedUnitsID and IMWE.RecordType=@rectype
   	end
   
   	if isnull(@TotalPrice,0) = 0
   	begin	
   		UPDATE IMWE
   		SET IMWE.UploadVal = '0'
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@TotalPriceID and IMWE.RecordType=@rectype
   	end
   
   	if isnull(@TaxAmt,0) = 0
   	begin	
   		UPDATE IMWE
   		SET IMWE.UploadVal = '0'
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@TaxAmtID and IMWE.RecordType=@rectype
   	end
   
   	if isnull(@RemainUnits,0) = 0
   	begin	
   		UPDATE IMWE
   		SET IMWE.UploadVal = '0'
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@RemainUnitsID and IMWE.RecordType=@rectype
   	end
   
   	--Reset variables to null
   	select @UnitPrice = null, @OrderedUnits = null, @TotalPrice = null, @TaxAmt = null, @RemainUnits = null
   
   
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
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsINIB]'
   
       return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsINIB] TO [public]
GO
