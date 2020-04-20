SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsJCMatUse]
   /***********************************************************
    * CREATED BY: Danf
    * MODIFIED BY:DANF 03/19/02 - Added Record Type
    *             DANF 09/05/02 - 17738 Added Phase Group to bspJCCAGlacctDflt
    *			  DANF 05/31/07 - 124693 Add Tax Amount to extended Cost amount.
	*			  CC   08/07/08 - 127955 Calculate cost without tax for tax calculations, 
	*									 recalculate cost with tax and update IMWE, clear tax amount and cost at end of update
    *			  CC   09/12/08 - 129760 Added section to default UM for JCCB
    *			CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
    *			CC  05/29/09 - Issue #133516 - Correct defaulting of Company
    *			GF  09/14/2010 - issue #141031 change to use vfDateOnly
	*			AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
	*			HH  02/05/13 - Clientele #141639 TFS-Task 39866 - change the data type conversion for bUnits, bUnitCost and bDollar to their respective (Prec,Scale)
	
    * Usage: Job Cost Material Use Import
    *	Used by Imports to create values for needed or missing
    *      data based upon Bidtek default rules.
    *
    * Input params:
    *	@ImportId	Import Identifier
    *	@ImportTemplate	Import ImportTemplate
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
   
   declare @rcode int, @recode int, @desc varchar(120), @defaultvalue varchar(30)
   
   declare @SourceID int, @TransTypeID int, @CompanyID int,  @fromlocationid int, @fromjccoid int, @fromjobid int,
           @CoId int, @ToJCCoId int, @ToJobId int, @ToLocationId int, @DateInId int, @TimeInId int, @EquipmentId int,
   		@ReversalStatusID int, @ActualDateID int, @JCTransTypeID int, @LocId int, @incoid int, @matlgroupid int,
           @phasegroupid int, @phaseId int, @descriptionId int, @glcoId int, @gltransacctId int, @gloffsetacctId int,
           @pstumId int, @pstunitcostId int, @pstecmId int, @costId int, @taxtypeId int, @taxgroupId int, @taxcodeId int, 
           @taxbasisId int, @taxamtId int, @costtypeId int, @stdUMId int
   
   
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
   
   
   -- Check ImportTemplate detail for columns to set Bidtek Defaults
   select IMTD.DefaultValue
   From IMTD
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
   
   if @@rowcount = 0
     begin
     select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.'
     goto bspexit
     end
   
   DECLARE 
			 @OverwriteSource 	 		 bYN
			, @OverwriteTransType 	 	 bYN
			, @OverwriteReversalStatus 	 bYN
			, @OverwriteActualDate 	 	 bYN
			, @OverwriteJCTransType 	 bYN
			, @OverwriteINCo 	 		 bYN
			, @OverwriteMatlGroup 	 	 bYN
			, @OverwritePhaseGroup 	 	 bYN
			, @OverwritePhase 	 		 bYN
			, @OverwriteCostType 	 	 bYN
			, @OverwriteDescription 	 bYN
			, @OverwriteGLCo 	 		 bYN
			, @OverwriteGLTransAcct 	 bYN
			, @OverwriteGLOffsetAcct 	 bYN
			, @OverwritePstUM 	 		 bYN
			, @OverwritePstUnitCost 	 bYN
			, @OverwritePstECM 	 		 bYN
			, @OverwriteCost 	 		 bYN
			, @OverwriteTaxType 	 	 bYN
			, @OverwriteTaxGroup 	 	 bYN
			, @OverwriteTaxCode 	 	 bYN
			, @OverwriteTaxBasis 	 	 bYN
			, @OverwriteTaxAmt 	 		 bYN
			, @OverwriteCo				 bYN
			,	@IsCoEmpty 				 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsSourceEmpty 			 bYN
			,	@IsTransTypeEmpty 		 bYN
			,	@IsReversalStatusEmpty 	 bYN
			,	@IsJCTransTypeEmpty 	 bYN
			,	@IsINCoEmpty 			 bYN
			,	@IsLocEmpty 			 bYN
			,	@IsMatlGroupEmpty 		 bYN
			,	@IsMaterialEmpty 		 bYN
			,	@IsJobEmpty 			 bYN
			,	@IsPhaseGroupEmpty 		 bYN
			,	@IsPhaseEmpty 			 bYN
			,	@IsCostTypeEmpty 		 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsActualDateEmpty 		 bYN
			,	@IsGLCoEmpty 			 bYN
			,	@IsGLTransAcctEmpty 	 bYN
			,	@IsGLOffsetAcctEmpty 	 bYN
			,	@IsUMEmpty 				 bYN
			,	@IsPstUMEmpty 			 bYN
			,	@IsPstUnitsEmpty 		 bYN
			,	@IsPstUnitCostEmpty 	 bYN
			,	@IsPstECMEmpty 			 bYN
			,	@IsCostEmpty 			 bYN
			,	@IsTaxTypeEmpty 		 bYN
			,	@IsTaxGroupEmpty 		 bYN
			,	@IsTaxCodeEmpty 		 bYN
			,	@IsTaxBasisEmpty 		 bYN
			,	@IsTaxAmtEmpty 			 bYN			
			
			
		SELECT @OverwriteSource = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Source', @rectype);
		SELECT @OverwriteTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TransType', @rectype);
		SELECT @OverwriteReversalStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ReversalStatus', @rectype);
		SELECT @OverwriteActualDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActualDate', @rectype);
		SELECT @OverwriteJCTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCTransType', @rectype);
		SELECT @OverwriteINCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'INCo', @rectype);
		SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
		SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
		SELECT @OverwritePhase = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Phase', @rectype);
		SELECT @OverwriteCostType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostType', @rectype);
		SELECT @OverwriteDescription = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Description', @rectype);
		SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
		SELECT @OverwriteGLTransAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLTransAcct', @rectype);
		SELECT @OverwriteGLOffsetAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLOffsetAcct', @rectype);
		SELECT @OverwritePstUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PstUM', @rectype);
		SELECT @OverwritePstUnitCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PstUnitCost', @rectype);
		SELECT @OverwritePstECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PstECM', @rectype);
		SELECT @OverwriteCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Cost', @rectype);
		SELECT @OverwriteTaxType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxType', @rectype);
		SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype);
		SELECT @OverwriteTaxCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxCode', @rectype);
		SELECT @OverwriteTaxBasis = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxBasis', @rectype);
		SELECT @OverwriteTaxAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxAmt', @rectype);
		SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
   
   
   select @CompanyID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', @rectype, 'Y')
   if isnull(@CompanyID,99999) <> 99999 AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
    end
    
   if isnull(@CompanyID,99999) <> 99999 AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
    end
   
   
   select @SourceID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Source', @rectype, 'Y')
   
   if isnull(@SourceID,0) <> 0 AND (ISNULL(@OverwriteSource, 'Y') = 'Y')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'JC MatUse'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @SourceID
    end
 
    if isnull(@SourceID,0) <> 0 AND (ISNULL(@OverwriteSource, 'Y') = 'N')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'JC MatUse'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @SourceID
      AND IMWE.UploadVal IS NULL
    end  
   
   select @TransTypeID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TransType', @rectype,'Y')
   
   if isnull( @TransTypeID,0) <>0 AND (ISNULL(@OverwriteTransType, 'Y') = 'Y')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'A'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransTypeID
    end
   if isnull( @TransTypeID,0) <>0 AND (ISNULL(@OverwriteTransType, 'Y') = 'N')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'A'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransTypeID
      AND IMWE.UploadVal IS NULL
    end
   
   select @ReversalStatusID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ReversalStatus', @rectype, 'Y')
   
   if isnull( @ReversalStatusID,0) <>0 AND (ISNULL(@OverwriteReversalStatus, 'Y') = 'Y')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ReversalStatusID
    end
    
   if isnull( @ReversalStatusID,0) <>0 AND (ISNULL(@OverwriteReversalStatus, 'Y') = 'N')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ReversalStatusID
      AND IMWE.UploadVal IS NULL
    end
   
   select @ActualDateID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ActualDate', @rectype, 'Y')
   
   if isnull( @ActualDateID,0) <>0  AND (ISNULL(@OverwriteActualDate, 'Y') = 'Y')
    begin
      UPDATE IMWE
      ----#141031
      SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ActualDateID
    end

   if isnull( @ActualDateID,0) <>0  AND (ISNULL(@OverwriteActualDate, 'Y') = 'N')
    begin
      UPDATE IMWE
      ----#141031
      SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ActualDateID
      AND IMWE.UploadVal IS NULL
    end
   
   select @LocId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Loc', @rectype, 'N')
   
   select @JCTransTypeID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCTransType', @rectype, 'Y')
   
   
   select @incoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'INCo', @rectype, 'Y')
   
   select @matlgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MatlGroup', @rectype, 'Y')
   
   select @phasegroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGroup', @rectype, 'Y')
   
   select @phaseId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Phase', @rectype, 'Y')
   
   select @costtypeId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CostType', @rectype, 'Y')
   
   select @descriptionId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Description', @rectype, 'Y')
   
   select @glcoId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLCo', @rectype, 'Y')
   
   select @gltransacctId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLTransAcct', @rectype, 'Y')
   
   select @gloffsetacctId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLOffsetAcct', @rectype, 'Y')
   
   select @pstumId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PstUM', @rectype, 'Y')
   
   select @pstunitcostId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PstUnitCost', @rectype, 'Y')
   
   select @pstecmId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PstECM', @rectype, 'Y')
   
   select @costId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Cost', @rectype, 'Y')
   
   select @taxtypeId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxType', @rectype, 'Y')
   
   select @taxgroupId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxGroup', @rectype, 'Y')
   
   select @taxcodeId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxCode', @rectype, 'Y')
   
   select @taxbasisId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxBasis', @rectype, 'Y')
   
   select @taxamtId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxAmt', @rectype, 'Y')

   select @stdUMId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UM', @rectype, 'N')

   
   declare @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @Source char(10), @TransType char(1),
   @ReversalStatus tinyint, @JCTransType varchar(2), @INCo bCompany, @Loc bLoc, @MatlGroup bGroup,
   @Material bMatl, @Job bJob, @PhaseGroup bGroup, @Phase bPhase, @CostType bJCCType,
   @Description bTransDesc, @ActualDate bDate, @GLCo bCompany, @GLTransAcct bGLAcct,
   @GLOffsetAcct bGLAcct, @PstUM bUM, @PstUnits bUnits,@PstUnitCost bUnitCost, @PstECM bECM,
   @Cost bDollar, @TaxType tinyint, @TaxGroup bGroup, @TaxCode bTaxCode, @TaxBasis bDollar,
   @TaxAmt bDollar, @UM bUM
   
   
   declare @StdUM bUM, @StdUnitCost bUnitCost, @StdECM bECM, @SalUM bUM, @SalUnitCost bUnitCost,
       @SalECM bECM, @MPhase bPhase, @MCostType bJCCType, @Taxable bYN, @JobSalsAcct bGLAcct, @ECMFact int,
       @usetax bYN, @miscmatacct bGLAcct, @taxrate bUnitCost, @OnHand bUnits, @Available bUnits
   
   declare WorkEditCursor cursor for
   select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
       from IMWE
           inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
       where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
       Order by IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   -- set open cursor flag
   --#142350 - removing @importid, @seq, @Identifier
	DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int
	           
   
   declare @crcsq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
           @columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int
   
   
   fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
   select @crcsq = @Recseq, @complete = 0, @counter = 1
   
   -- while cursor is not empty
   while @complete = 0
   
   begin
   
     if @@fetch_status <> 0
       select @Recseq = -1
   
       --if rec sequence = current rec sequence flag
     if @Recseq = @crcsq
       begin
   
       If @Column='Co' and isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
   	If @Column='Mth' and isdate(@Uploadval) =1 select @Mth = Convert( smalldatetime, @Uploadval)
   /*	If @Column='BatchSeq' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
   	If @Column='BatchTransType' select @BatchTransType = @Uploadval*/
   	If @Column='Source' select @Source = @Uploadval
   	If @Column='TransType' select @TransType = @Uploadval
   /*  If @Column='ReversalStatus' select @EMTransType = @Uploadval */
   	If @Column='JCTransType' select @JCTransType = @Uploadval
    	If @Column='INCo' and isnumeric(@Uploadval) =1 select @INCo = convert(tinyint,@Uploadval)
    	If @Column='Loc' select @Loc = @Uploadval
    	If @Column='MatlGroup' and isnumeric(@Uploadval) = 1 select @MatlGroup = Convert( tinyint,@Uploadval)
    	If @Column='Material' select @Material = @Uploadval
   	If @Column='Job' select @Job = @Uploadval
    	If @Column='PhaseGroup' and isnumeric(@Uploadval) =1 select @PhaseGroup = Convert(tinyint,@Uploadval)
    	If @Column='Phase' select @Phase = @Uploadval
    	If @Column='CostType' and isnumeric(@Uploadval) = 1 select @CostType = Convert( tinyint,@Uploadval)
    	If @Column='Description' select @Description = @Uploadval
    	If @Column='ActualDate' and isdate(@Uploadval) =1 select @ActualDate = Convert(smalldatetime,@Uploadval)
    	If @Column='GLCo' and isnumeric(@Uploadval) = 1 select @GLCo = Convert( tinyint,@Uploadval)
    	If @Column='GLTransAcct' select @GLTransAcct = @Uploadval
    	If @Column='GLOffsetAcct' select @GLOffsetAcct = @Uploadval
    	If @Column='PstUM' select @PstUM = @Uploadval
    	If @Column='PstUnits' and isnumeric(@Uploadval) = 1 select @PstUnits = Convert( numeric(12,3), @Uploadval)
    	If @Column='PstUnitCost' and isnumeric(@Uploadval) = 1 select @PstUnitCost = Convert ( numeric(16,5), @Uploadval)
    	If @Column='PstECM' select @PstECM = @Uploadval
    	If @Column='Cost' and isnumeric(@Uploadval) = 1 select @Cost = Convert ( numeric(12,2), @Uploadval)
    	If @Column='TaxType' select @TaxType = @Uploadval
    	If @Column='TaxGroup' and isnumeric(@Uploadval) = 1 select @TaxGroup = Convert( tinyint,@Uploadval)
    	If @Column='TaxCode' select @TaxCode = @Uploadval
    	If @Column='TaxBasis'  and isnumeric(@Uploadval) = 1 select @TaxBasis = @Uploadval
    	If @Column='TaxAmt' and isnumeric(@Uploadval) = 1 select @TaxAmt = Convert ( numeric(12,2), @Uploadval)
   
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
		IF @Column='Source' 
			IF @Uploadval IS NULL
				SET @IsSourceEmpty = 'Y'
			ELSE
				SET @IsSourceEmpty = 'N'
		IF @Column='TransType' 
			IF @Uploadval IS NULL
				SET @IsTransTypeEmpty = 'Y'
			ELSE
				SET @IsTransTypeEmpty = 'N'
		IF @Column='ReversalStatus' 
			IF @Uploadval IS NULL
				SET @IsReversalStatusEmpty = 'Y'
			ELSE
				SET @IsReversalStatusEmpty = 'N'
		IF @Column='JCTransType' 
			IF @Uploadval IS NULL
				SET @IsJCTransTypeEmpty = 'Y'
			ELSE
				SET @IsJCTransTypeEmpty = 'N'
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
		IF @Column='CostType' 
			IF @Uploadval IS NULL
				SET @IsCostTypeEmpty = 'Y'
			ELSE
				SET @IsCostTypeEmpty = 'N'
		IF @Column='Description' 
			IF @Uploadval IS NULL
				SET @IsDescriptionEmpty = 'Y'
			ELSE
				SET @IsDescriptionEmpty = 'N'
		IF @Column='ActualDate' 
			IF @Uploadval IS NULL
				SET @IsActualDateEmpty = 'Y'
			ELSE
				SET @IsActualDateEmpty = 'N'
		IF @Column='GLCo' 
			IF @Uploadval IS NULL
				SET @IsGLCoEmpty = 'Y'
			ELSE
				SET @IsGLCoEmpty = 'N'
		IF @Column='GLTransAcct' 
			IF @Uploadval IS NULL
				SET @IsGLTransAcctEmpty = 'Y'
			ELSE
				SET @IsGLTransAcctEmpty = 'N'
		IF @Column='GLOffsetAcct' 
			IF @Uploadval IS NULL
				SET @IsGLOffsetAcctEmpty = 'Y'
			ELSE
				SET @IsGLOffsetAcctEmpty = 'N'
		IF @Column='UM' 
			IF @Uploadval IS NULL
				SET @IsUMEmpty = 'Y'
			ELSE
				SET @IsUMEmpty = 'N'
		IF @Column='PstUM' 
			IF @Uploadval IS NULL
				SET @IsPstUMEmpty = 'Y'
			ELSE
				SET @IsPstUMEmpty = 'N'
		IF @Column='PstUnits' 
			IF @Uploadval IS NULL
				SET @IsPstUnitsEmpty = 'Y'
			ELSE
				SET @IsPstUnitsEmpty = 'N'
		IF @Column='PstUnitCost' 
			IF @Uploadval IS NULL
				SET @IsPstUnitCostEmpty = 'Y'
			ELSE
				SET @IsPstUnitCostEmpty = 'N'
		IF @Column='PstECM' 
			IF @Uploadval IS NULL
				SET @IsPstECMEmpty = 'Y'
			ELSE
				SET @IsPstECMEmpty = 'N'
		IF @Column='Cost' 
			IF @Uploadval IS NULL
				SET @IsCostEmpty = 'Y'
			ELSE
				SET @IsCostEmpty = 'N'
		IF @Column='TaxType' 
			IF @Uploadval IS NULL
				SET @IsTaxTypeEmpty = 'Y'
			ELSE
				SET @IsTaxTypeEmpty = 'N'
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
		IF @Column='TaxBasis' 
			IF @Uploadval IS NULL
				SET @IsTaxBasisEmpty = 'Y'
			ELSE
				SET @IsTaxBasisEmpty = 'N'
		IF @Column='TaxAmt' 
			IF @Uploadval IS NULL
				SET @IsTaxAmtEmpty = 'Y'
			ELSE
				SET @IsTaxAmtEmpty = 'N'   
   
              --fetch next record
 
           if @@fetch_status <> 0
             select @complete = 1
   
           select @oldrecseq = @Recseq
   
           fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
       end
   
     else
   
       begin
         if isnull(@JCTransTypeID,0) <> 0  AND (ISNULL(@OverwriteJCTransType, 'Y') = 'Y' OR ISNULL(@IsJCTransTypeEmpty, 'Y') = 'Y')
          begin
           IF isnull(@Loc,'') = ''
            begin
              UPDATE IMWE
              SET IMWE.UploadVal = 'MI'
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                    IMWE.RecordSeq=@crcsq and IMWE.Identifier = @JCTransTypeID
            end
           else
            begin
 UPDATE IMWE
              SET IMWE.UploadVal = 'IN'
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                    IMWE.RecordSeq=@crcsq and IMWE.Identifier = @JCTransTypeID
            end
          end
   
         if isnull(@incoid,0) <> 0  AND (ISNULL(@OverwriteINCo, 'Y') = 'Y' OR ISNULL(@IsINCoEmpty, 'Y') = 'Y')
          begin
              select @INCo=INCo from bJCCO where JCCo=@Co
   
              UPDATE IMWE
              SET IMWE.UploadVal = @INCo
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @incoid
          end
   
         if isnull(@matlgroupid,0) <> 0  AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR ISNULL(@IsMatlGroupEmpty, 'Y') = 'Y')
          begin
           if isnull(@INCo,'')=''
              select @MatlGroup=MatlGroup from bHQCO where HQCo=@Co
            else
              select @MatlGroup=MatlGroup from bHQCO where HQCo=@INCo
   
              UPDATE IMWE
              SET IMWE.UploadVal = @MatlGroup
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @matlgroupid
          end
   
         if isnull(@phasegroupid,0) <> 0  AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')
          begin
              select @PhaseGroup=PhaseGroup from bHQCO where HQCo=@Co
   
              UPDATE IMWE
              SET IMWE.UploadVal = @PhaseGroup
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @phasegroupid
          end
   
         if isnull(@phaseId,0) <> 0  AND (ISNULL(@OverwritePhase, 'Y') = 'Y' OR ISNULL(@IsPhaseEmpty, 'Y') = 'Y')
          begin
              select @Phase=MatlPhase from bHQMT where MatlGroup=@MatlGroup and Material=@Material
   
              UPDATE IMWE
              SET IMWE.UploadVal = @Phase
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @phaseId
          end
   
         if isnull(@costtypeId,0) <> 0  AND (ISNULL(@OverwriteCostType, 'Y') = 'Y' OR ISNULL(@IsCostTypeEmpty, 'Y') = 'Y')
          begin
              select @CostType=MatlJCCostType from bHQMT where MatlGroup=@MatlGroup and Material=@Material
   
              UPDATE IMWE
              SET IMWE.UploadVal = @CostType
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @costtypeId
          end
   
         if isnull(@descriptionId,0) <> 0  AND (ISNULL(@OverwriteDescription, 'Y') = 'Y' OR ISNULL(@IsDescriptionEmpty, 'Y') = 'Y')
          begin
              select @Description=Description from bHQMT where MatlGroup=@MatlGroup and Material=@Material
   
              UPDATE IMWE
              SET IMWE.UploadVal = @Description
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @descriptionId
          end
   
         if isnull(@glcoId,0) <> 0 AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
          begin
              select @GLCo=GLCo from bJCCO where JCCo = @Co
   
              UPDATE IMWE
              SET IMWE.UploadVal = @GLCo
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @glcoId
          end
   
         Select @usetax = UseTaxOnMaterial, @miscmatacct = GLMiscMatAcct from JCCO where JCCo= @Co
   
         exec @recode = bspJCINMaterialVal @Material, @MatlGroup, @INCo, @Loc, 
                        @stdum = @StdUM output, @stdunitcost = @StdUnitCost output, @stdecm = @SalECM output,
                        @salum = @SalUM output, @salunitcost = @SalUnitCost output, @salecm = @SalECM output,
                        @mphase = @MPhase output, @mcosttype = @MCostType output, @taxable = @Taxable output,
                        @jobsalesacct = @JobSalsAcct output, @onhand = @OnHand output, @available = @Available output,
                        @jcco = @Co, @valid = 'N', @msg = @msg output
   
         if isnull(@pstumId,0) <> 0 AND (ISNULL(@OverwritePstUM, 'Y') = 'Y' OR ISNULL(@IsPstUMEmpty, 'Y') = 'Y')
          begin
              select @PstUM=@SalUM
   
              UPDATE IMWE
              SET IMWE.UploadVal = @PstUM
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @pstumId
          end
   
         exec @recode = bspJCINMatUnitPrice @MatlGroup, @INCo, @Loc, @Material, @PstUM, @Co, @Job,
                        @salunitcost = @SalUnitCost output, @salecm = @SalECM output, @msg = @msg output
   
   
         if isnull(@gltransacctId,0) <> 0 AND (ISNULL(@OverwriteGLTransAcct, 'Y') = 'Y' OR ISNULL(@IsGLTransAcctEmpty, 'Y') = 'Y')
          begin
              exec @recode = bspJCCAGlacctDflt @Co, @Job, @PhaseGroup, @Phase, @CostType, 'N', @glacct = @GLTransAcct output, @msg = @msg output
   
              UPDATE IMWE
              SET IMWE.UploadVal = @GLTransAcct
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @gltransacctId
          end
   
         if isnull(@gloffsetacctId,0) <> 0 AND (ISNULL(@OverwriteGLOffsetAcct, 'Y') = 'Y' OR ISNULL(@IsGLOffsetAcctEmpty, 'Y') = 'Y')
          begin
              select @GLOffsetAcct=@JobSalsAcct
   
              UPDATE IMWE
              SET IMWE.UploadVal = @GLOffsetAcct
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @gloffsetacctId
          end
   
         if isnull(@pstunitcostId,0) <> 0 AND (ISNULL(@OverwritePstUnitCost, 'Y') = 'Y' OR ISNULL(@IsPstUnitCostEmpty, 'Y') = 'Y')
          begin
              select @PstUnitCost=@SalUnitCost
   
              UPDATE IMWE
              SET IMWE.UploadVal = @PstUnitCost
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @pstunitcostId
          end
   
         if isnull(@pstecmId,0) <> 0  AND (ISNULL(@OverwritePstECM, 'Y') = 'Y' OR ISNULL(@IsPstECMEmpty, 'Y') = 'Y')
          begin--
              select @PstECM=@SalECM
   
              UPDATE IMWE
              SET IMWE.UploadVal = @PstECM
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @pstecmId
          end
   
   
         if isnull(@taxtypeId,0) <> 0  AND (ISNULL(@OverwriteTaxType, 'Y') = 'Y' OR ISNULL(@IsTaxTypeEmpty, 'Y') = 'Y')
          begin--
              select @TaxType=2
   
              UPDATE IMWE
              SET IMWE.UploadVal = @TaxType
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @taxtypeId
          end
   
       if isnull(@taxgroupId,0) <> 0  AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y' OR ISNULL(@IsTaxGroupEmpty, 'Y') = 'Y')
          begin--
              select @TaxGroup=TaxGroup from bHQCO where HQCo = @Co
   
              UPDATE IMWE
              SET IMWE.UploadVal = @TaxGroup
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @taxgroupId
          end
   
         if isnull(@taxcodeId,0) <> 0  AND (ISNULL(@OverwriteTaxCode, 'Y') = 'Y' OR ISNULL(@IsTaxCodeEmpty, 'Y') = 'Y')
          begin
              select @TaxCode=null
              if @usetax = 'Y' and @Taxable = 'Y'
                 select @TaxCode = TaxCode from bJCJM where JCCo=@Co and Job = @Job
   
              UPDATE IMWE
              SET IMWE.UploadVal = @TaxCode
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @taxcodeId
          end

		-- calculate cost for tax basis, cost is recalculated with tax and IMWE updated after tax is calculated
		 if isnull(@costId,0) <> 0  AND (ISNULL(@OverwriteCost, 'Y') = 'Y' OR ISNULL(@IsCostEmpty, 'Y') = 'Y')
  		  begin
 
			select @ECMFact =  CASE @PstECM WHEN 'M' then  1000
                                        WHEN 'C' then  100
                                        else  1 end
  
			if @PstUnitCost is not null and @PstUnits is not null 
				select @Cost =  ( isnull(@PstUnits,0) / @ECMFact )* isnull(@PstUnitCost,0)
	    
		  end

         if isnull(@taxbasisId,0) <> 0  AND (ISNULL(@OverwriteTaxBasis, 'Y') = 'Y' OR ISNULL(@IsTaxBasisEmpty, 'Y') = 'Y')
          begin
             
              select @TaxBasis=0
              if isnull(@TaxCode,'') <> '' and @usetax = 'Y' and @Taxable = 'Y' select @TaxBasis=@Cost
   
              UPDATE IMWE
              SET IMWE.UploadVal = @TaxBasis
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @taxbasisId
          end
   
         if isnull(@taxamtId,0) <> 0 AND (ISNULL(@OverwriteTaxAmt, 'Y') = 'Y' OR ISNULL(@IsTaxAmtEmpty, 'Y') = 'Y')
          begin
             
              select @TaxAmt=0, @taxrate = 0
   
              exec @recode = bspHQTaxRateGet @TaxGroup, @TaxCode, @ActualDate, @taxrate output, @msg = @msg output
   
              if isnull(@TaxBasis,0)<>0 and isnull(@taxrate,0)<>0 and isnull(@TaxCode,'') <> '' and @usetax = 'Y' and @Taxable = 'Y' 
                 select @TaxAmt = @TaxBasis * @taxrate
      
              UPDATE IMWE
              SET IMWE.UploadVal = @TaxAmt
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
                IMWE.RecordSeq=@crcsq and IMWE.Identifier = @taxamtId
				
          end
   
		 if isnull(@costId,0) <> 0  AND (ISNULL(@OverwriteCost, 'Y') = 'Y' OR ISNULL(@IsCostEmpty, 'Y') = 'Y')
  		  begin 
 
			select @ECMFact =  CASE @PstECM WHEN 'M' then  1000
                                        WHEN 'C' then  100
                                        else  1 end
 
 
			if @PstUnitCost is not null and @PstUnits is not null 
				select @Cost =  ( isnull(@PstUnits,0) / @ECMFact )* isnull(@PstUnitCost,0) + isnull(@TaxAmt,0)
	    
			UPDATE IMWE
			SET IMWE.UploadVal = @Cost
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
				  IMWE.RecordSeq=@crcsq and IMWE.Identifier = @costId

		  end

		--Issue #129760
		 if isnull(@stdUMId,0) <> 0 
  		  begin

          exec @rcode = bspJCVCOSTTYPE @Company, @Job, @PhaseGroup, @Phase, @CostType, 'N', @um=@UM output
	    
			UPDATE IMWE
			SET IMWE.UploadVal = @UM
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
				  IMWE.RecordSeq=@crcsq and IMWE.Identifier = @stdUMId

		  end			

    	  --database updates & calculations completed, clear cost and tax amount 
	      select @Cost = 0, @TaxAmt = 0

select @crcsq = @Recseq
          select @counter = @counter + 1
   
       end
   
   end
   
   
   
   close WorkEditCursor
   deallocate WorkEditCursor
   
   
   bspexit:
       select @msg = isnull(@desc,'Job Material Use') + char(13) + char(10) + '[bspIMBidtekDefaultsJCMatUse]'
   
       return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsJCMatUse] TO [public]
GO
