SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsJCCBPrg]
   /***********************************************************
    * CREATED BY: Danf
    *  Modified: DANF 03/19/02 - Added Record Type
    *            DANF 06/13/02 - Added ToJCCo Default and GLAccout Default
    *            DANF 09/05/02 - 17738 Added Phase Group to bspJCVCostTypeWithHrs & bspJCCAGlacctDflt
    *			CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
    *			CC  05/29/09 - Issue #133516 - Correct defaulting of Company
    *			GF  06/25/2010 - issue #135813 expanded SL to varchar(30)
    *			AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
    *			TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *
    * Usage:
    *	Used by Imports to create values for needed or missing
    *  data based upon Bidtek default rules. 
    *  This is designed to be used for import progress entries.
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
   
   declare @rcode int, @desc varchar(120), @ynphasegroup bYN, @ynglco bYN, @yngltransacct bYN, @ynum bYN,  @ynsource bYN, @ynToJCCo bYN,
           @CompanyID int, @defaultvalue varchar(30), @ReversalStatusID int, @TransTypeID int,  @JCTransTypeID int
   
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
   --
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
			  @OverwriteTransType 	 		 bYN
			, @OverwriteReversalStatus 	 	 bYN
			, @OverwriteJCTransType 	 	 bYN
			, @OverwritePhaseGroup 	 		 bYN
			, @OverwriteToJCCo 	 			 bYN
			, @OverwriteGLCo 	 			 bYN
			, @OverwriteUM 	 				 bYN
			, @OverwriteSource 	 			 bYN
			, @OverwriteGLTransAcct 	 	 bYN
			, @OverwriteCo					 bYN
			,	@IsCoEmpty 				 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsSourceEmpty 			 bYN
			,	@IsReversalStatusEmpty 	 bYN
			,	@IsPhaseGroupEmpty 		 bYN
			,	@IsGLCoEmpty 			 bYN
			,	@IsOrigMthEmpty 		 bYN
			,	@IsTransTypeEmpty 		 bYN
			,	@IsCostTransEmpty 		 bYN
			,	@IsUMEmpty 				 bYN
			,	@IsToJCCoEmpty 			 bYN
			,	@IsJobEmpty 			 bYN
			,	@IsPhaseEmpty 			 bYN
			,	@IsCostTypeEmpty 		 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsActualDateEmpty 		 bYN
			,	@IsJCTransTypeEmpty 	 bYN
			,	@IsGLTransAcctEmpty 	 bYN
			,	@IsGLOffsetAcctEmpty 	 bYN
			,	@IsHoursEmpty 			 bYN
			,	@IsUnitsEmpty 			 bYN
			,	@IsCostEmpty 			 bYN
			,	@IsPRCoEmpty 			 bYN
			,	@IsCraftEmpty 			 bYN
			,	@IsClassEmpty 			 bYN
			,	@IsCrewEmpty 			 bYN
			,	@IsEarnFactorEmpty 		 bYN
			,	@IsEarnTypeEmpty 		 bYN
			,	@IsLiabilityTypeEmpty 	 bYN
			,	@IsShiftEmpty 			 bYN
			,	@IsVendorGroupEmpty 	 bYN
			,	@IsAPCoEmpty 			 bYN
			,	@IsAPTransEmpty 		 bYN
			,	@IsAPLineEmpty 			 bYN
			,	@IsAPRefEmpty 			 bYN
			,	@IsPOEmpty 				 bYN
			,	@IsSLItemEmpty 			 bYN
			,	@IsSLEmpty 				 bYN
			,	@IsPOItemEmpty 			 bYN
			,	@IsMOEmpty 				 bYN
			,	@IsMOItemEmpty 			 bYN
			,	@IsMatlGroupEmpty 		 bYN
			,	@IsMaterialEmpty 		 bYN
			,	@IsINCoEmpty 			 bYN
			,	@IsLocEmpty 			 bYN
			,	@IsMSTransEmpty 		 bYN
			,	@IsMSTicketEmpty 		 bYN
			,	@IsEMCoEmpty 			 bYN
			,	@IsEMEquipEmpty 		 bYN
			,	@IsEMRevCodeEmpty 		 bYN
			,	@IsEMGroupEmpty 		 bYN
			,	@IsEmployeeEmpty 		 bYN
			,	@IsVendorEmpty 			 bYN
   
	SELECT @OverwriteTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TransType', @rectype);
	SELECT @OverwriteReversalStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ReversalStatus', @rectype);
	SELECT @OverwriteJCTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCTransType', @rectype);
	SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
	SELECT @OverwriteToJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ToJCCo', @rectype);
	SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
	SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UM', @rectype);
	SELECT @OverwriteSource = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Source', @rectype);
	SELECT @OverwriteGLTransAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLTransAcct', @rectype);
	SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);

   
   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
    end
   
   select @TransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TransType' 
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'   AND (ISNULL(@OverwriteTransType, 'Y') = 'Y')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'A'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransTypeID
    end
   
   select @ReversalStatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ReversalStatus'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReversalStatus, 'Y') = 'Y')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ReversalStatusID
    end
   
   select @JCTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCTransType, 'Y') = 'Y')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'JC'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @JCTransTypeID
    end
    
        ------------------------------------------
   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
    end

        
   select @TransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TransType' 
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'   AND (ISNULL(@OverwriteTransType, 'Y') = 'N')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'A'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransTypeID
      AND IMWE.UploadVal IS NULL
    end
   
   select @ReversalStatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ReversalStatus'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReversalStatus, 'Y') = 'N')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ReversalStatusID
      AND IMWE.UploadVal IS NULL
    end
   
   select @JCTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCTransType, 'Y') = 'N')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'JC'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @JCTransTypeID
      AND IMWE.UploadVal IS NULL
    end        
        
   
   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'PhaseGroup'
   if @@rowcount <> 0 select @ynphasegroup ='Y'
   
   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'ToJCCo'
   if @@rowcount <> 0 select @ynToJCCo ='Y'
   
   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLCo'
   if @@rowcount <> 0 select @ynglco ='Y'
   
   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'UM'
   if @@rowcount <> 0 select @ynum ='Y'
   
   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'Source'
   if @@rowcount <> 0 select @ynsource ='Y'
   
   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLTransAcct'
   if @@rowcount <> 0 select @yngltransacct ='Y'
   
   declare WorkEditCursor cursor for
   select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
       from IMWE
           inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
       where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
       Order by IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   -- set open cursor flag
   --#142350 - removing @importid and @seq
	DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int,
			@Identifier int
   
   declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
           @columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int
   
   declare @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @TransType char, @CostTrans bTrans,
   	@Job bJob, @PhaseGroup bGroup, @Phase bPhase, @CostType bJCCType, @ActualDate bDate,
   	@JCTransType varchar(2), @Description bTransDesc, @GLCo bCompany, @GLTransAcct bGLAcct,
   	@GLOffsetAcct bGLAcct, @ReversalStatus tinyint, @OrigMth bMonth, @OrigCostTrans bTrans,
   	@UM bUM, @Hours bHrs, @Units bUnits, @Cost bDollar, @AllocCode smallint, @PRCo bCompany,
   	@Employee int, @Craft bCraft, @Class bClass, @Crew varchar(10), @EarnFactor bRate,
   	@EarnType bEarnType, @LiabilityType bLiabilityType, @VendorGroup bGroup, @Vendor bVendor,
   	@APCo bCompany, @APTrans bTrans, @APLine smallint, @APRef bAPReference, @PO varchar(30), @POItem bItem,
   	@SL VARCHAR(30), @SLItem bItem, @MO int, @MOItem bItem, @MatlGroup bGroup, @Material bMatl, @INCo bCompany,
   	@Loc bLoc, @MSTrans bTrans, @MSTicket varchar(30), @JBBillStatus varchar(10), @EMCo bCompany,
   	@EMEquip bEquip, @EMRevCode bRevCode, @EMGroup bGroup
   
   declare @ctdesc varchar(60),@trackhours bYN, @costtypeout bJCCType, @retainpct bPct
   
   
   fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
   select @currrecseq = @Recseq, @complete = 0, @counter = 1
   
   -- while cursor is not empty
   while @complete = 0
   
   begin
   
     if @@fetch_status <> 0
       select @Recseq = -1
   
       --if rec sequence = current rec sequence flag
     if @Recseq = @currrecseq
       begin
   
       If @Column='Co' and  isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
   	If @Column='Mth' and isdate(@Uploadval) =1 select @Mth = Convert( smalldatetime, @Uploadval)
   /*	If @Column='BatchSeq' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
   	If @Column='TransType' select @TransType = @Uploadval
   	If @Column='CostTrans' select @CostTrans = @Uploadval*/
   	If @Column='Source' select @Job = @Uploadval
   	If @Column='Job' select @Job = @Uploadval
   	If @Column='PhaseGroup' and isnumeric(@Uploadval) = 1 select @PhaseGroup = @Uploadval
   	If @Column='Phase' select @Phase = @Uploadval
   	If @Column='CostType' and isnumeric(@Uploadval) = 1 select @CostType = @Uploadval
   /*	If @Column='AcutalDate' and isdate(@Uploadval) =1 select @ActualDate = Convert( smalldatetime, @Uploadval)
   	If @Column='JCTransType' select @JCTransType = @Uploadval
   	If @Column='Description' select @Description = @Uploadval*/
   	If @Column='GLCo' and isnumeric(@Uploadval) =1 select @GLCo = Convert( int, @Uploadval)
   	If @Column='GLTransAcct' select @GLTransAcct = @Uploadval
   /*	If @Column='GLOffsetAcct' select @GLOffsetAcct = @Uploadval
   	If @Column='ReversalStatus' select @ReversalStatus = @Uploadval
   	If @Column='OrigMth' select @OrigMth = @Uploadval
        	If @Column='OrigCostTrans' select @OrigCostTrans = @Uploadval */
   	If @Column='UM' select @UM = @Uploadval
   /*	If @Column='Hours' and isnumeric(@Uploadval) =1 select @Hours = convert(numeric,@Uploadval)
   	If @Column='Units' and isnumeric(@Uploadval) =1 select @Units = convert(numeric,@Uploadval)
   	If @Column='Cost' and isnumeric(@Uploadval) =1 select @Cost = convert(numeric,@Uploadval)
   	If @Column='AllocCode' and isnumeric(@Uploadval) =1 select @AllocCode = @Uploadval
   	If @Column='PRCo' and isnumeric(@Uploadval) =1 select @PRCo = @Uploadval
   	If @Column='Employee' and isnumeric(@Uploadval) =1 select @Employee = @Uploadval
   	If @Column='Craft' select @Craft = @Uploadval
   	If @Column='Class' select @Class = @Uploadval
   	If @Column='Crew' select @Crew = @Uploadval
   	If @Column='EarnFactor' and isnumeric(@Uploadval) =1 select @EarnFactor = @Uploadval
   	If @Column='EarnType' and isnumeric(@Uploadval) =1 select @EarnType = @Uploadval
   	If @Column='LiabilityType' and isnumeric(@Uploadval) =1 select @LiabilityType = @Uploadval */
   	If @Column='VendorGroup' and isnumeric(@Uploadval) =1 select @VendorGroup = @Uploadval
   /*	If @Column='Vendor' and isnumeric(@Uploadval) =1 select @Vendor = @Uploadval*/
   	If @Column='APCo' and isnumeric(@Uploadval) =1 select @APCo = @Uploadval
   /*	If @Column='APTrans' and isnumeric(@Uploadval) =1 select @APTrans = @Uploadval
   	If @Column='APLine' and isnumeric(@Uploadval) =1 select @APLine = @Uploadval
   	If @Column='APREF' select @APRef = @Uploadval
   	If @Column='PO' select @PO = @Uploadval
   	If @Column='POItem' and isnumeric(@Uploadval) =1 select @POItem = @Uploadval
   	If @Column='SL' select @SL = @Uploadval
   	If @Column='SLItem' and isnumeric(@Uploadval) =1 select @SLItem = @Uploadval
   	If @Column='MO' select @MO = @Uploadval
   	If @Column='MOItem' and isnumeric(@Uploadval) =1 select @MOItem = @Uploadval*/
   	If @Column='MatlGroup' and isnumeric(@Uploadval) =1 select @MatlGroup = @Uploadval
   /*	If @Column='Material' select @Material = @Uploadval
   	If @Column='INCo' and isnumeric(@Uploadval) =1 select @INCo = @Uploadval
   	If @Column='Loc' select @Loc = @Uploadval
   	If @Column='MSTrans' and isnumeric(@Uploadval) =1 select @MSTrans = @Uploadval
   	If @Column='MSTicket' select @MSTicket = @Uploadval
   	If @Column='JBBillStatus' select @JBBillStatus = @Uploadval
   	If @Column='JBInvoice' select @JBInvoice = @Uploadval */
   	If @Column='EMCo' and isnumeric(@Uploadval) =1 select @EMCo = @Uploadval
   /*	If @Column='EMEquip' select @EMEquip = @Uploadval
   	If @Column='EMRevCode' and isnumeric(@Uploadval) =1 select @EMRevCode = @Uploadval*/
   	If @Column='EMGroup' and isnumeric(@Uploadval) =1 select @EMGroup = @Uploadval

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
	IF @Column='ReversalStatus' 
		IF @Uploadval IS NULL
			SET @IsReversalStatusEmpty = 'Y'
		ELSE
			SET @IsReversalStatusEmpty = 'N'
	IF @Column='PhaseGroup' 
		IF @Uploadval IS NULL
			SET @IsPhaseGroupEmpty = 'Y'
		ELSE
			SET @IsPhaseGroupEmpty = 'N'
	IF @Column='GLCo' 
		IF @Uploadval IS NULL
			SET @IsGLCoEmpty = 'Y'
		ELSE
			SET @IsGLCoEmpty = 'N'
	IF @Column='OrigMth' 
		IF @Uploadval IS NULL
			SET @IsOrigMthEmpty = 'Y'
		ELSE
			SET @IsOrigMthEmpty = 'N'
	IF @Column='TransType' 
		IF @Uploadval IS NULL
			SET @IsTransTypeEmpty = 'Y'
		ELSE
			SET @IsTransTypeEmpty = 'N'
	IF @Column='CostTrans' 
		IF @Uploadval IS NULL
			SET @IsCostTransEmpty = 'Y'
		ELSE
			SET @IsCostTransEmpty = 'N'
	IF @Column='UM' 
		IF @Uploadval IS NULL
			SET @IsUMEmpty = 'Y'
		ELSE
			SET @IsUMEmpty = 'N'
	IF @Column='ToJCCo' 
		IF @Uploadval IS NULL
			SET @IsToJCCoEmpty = 'Y'
		ELSE
			SET @IsToJCCoEmpty = 'N'
	IF @Column='Job' 
		IF @Uploadval IS NULL
			SET @IsJobEmpty = 'Y'
		ELSE
			SET @IsJobEmpty = 'N'
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
	IF @Column='JCTransType' 
		IF @Uploadval IS NULL
			SET @IsJCTransTypeEmpty = 'Y'
		ELSE
			SET @IsJCTransTypeEmpty = 'N'
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
	IF @Column='Hours' 
		IF @Uploadval IS NULL
			SET @IsHoursEmpty = 'Y'
		ELSE
			SET @IsHoursEmpty = 'N'
	IF @Column='Units' 
		IF @Uploadval IS NULL
			SET @IsUnitsEmpty = 'Y'
		ELSE
			SET @IsUnitsEmpty = 'N'
	IF @Column='Cost' 
		IF @Uploadval IS NULL
			SET @IsCostEmpty = 'Y'
		ELSE
			SET @IsCostEmpty = 'N'
	IF @Column='PRCo' 
		IF @Uploadval IS NULL
			SET @IsPRCoEmpty = 'Y'
		ELSE
			SET @IsPRCoEmpty = 'N'
	IF @Column='Craft' 
		IF @Uploadval IS NULL
			SET @IsCraftEmpty = 'Y'
		ELSE
			SET @IsCraftEmpty = 'N'
	IF @Column='Class' 
		IF @Uploadval IS NULL
			SET @IsClassEmpty = 'Y'
		ELSE
			SET @IsClassEmpty = 'N'
	IF @Column='Crew' 
		IF @Uploadval IS NULL
			SET @IsCrewEmpty = 'Y'
		ELSE
			SET @IsCrewEmpty = 'N'
	IF @Column='EarnFactor' 
		IF @Uploadval IS NULL
			SET @IsEarnFactorEmpty = 'Y'
		ELSE
			SET @IsEarnFactorEmpty = 'N'
	IF @Column='EarnType' 
		IF @Uploadval IS NULL
			SET @IsEarnTypeEmpty = 'Y'
		ELSE
			SET @IsEarnTypeEmpty = 'N'
	IF @Column='LiabilityType' 
		IF @Uploadval IS NULL
			SET @IsLiabilityTypeEmpty = 'Y'
		ELSE
			SET @IsLiabilityTypeEmpty = 'N'
	IF @Column='Shift' 
		IF @Uploadval IS NULL
			SET @IsShiftEmpty = 'Y'
		ELSE
			SET @IsShiftEmpty = 'N'
	IF @Column='VendorGroup' 
		IF @Uploadval IS NULL
			SET @IsVendorGroupEmpty = 'Y'
		ELSE
			SET @IsVendorGroupEmpty = 'N'
	IF @Column='APCo' 
		IF @Uploadval IS NULL
			SET @IsAPCoEmpty = 'Y'
		ELSE
			SET @IsAPCoEmpty = 'N'
	IF @Column='APTrans' 
		IF @Uploadval IS NULL
			SET @IsAPTransEmpty = 'Y'
		ELSE
			SET @IsAPTransEmpty = 'N'
	IF @Column='APLine' 
		IF @Uploadval IS NULL
			SET @IsAPLineEmpty = 'Y'
		ELSE
			SET @IsAPLineEmpty = 'N'
	IF @Column='APRef' 
		IF @Uploadval IS NULL
			SET @IsAPRefEmpty = 'Y'
		ELSE
			SET @IsAPRefEmpty = 'N'
	IF @Column='PO' 
		IF @Uploadval IS NULL
			SET @IsPOEmpty = 'Y'
		ELSE
			SET @IsPOEmpty = 'N'
	IF @Column='SLItem' 
		IF @Uploadval IS NULL
			SET @IsSLItemEmpty = 'Y'
		ELSE
			SET @IsSLItemEmpty = 'N'
	IF @Column='SL' 
		IF @Uploadval IS NULL
			SET @IsSLEmpty = 'Y'
		ELSE
			SET @IsSLEmpty = 'N'
	IF @Column='POItem' 
		IF @Uploadval IS NULL
			SET @IsPOItemEmpty = 'Y'
		ELSE
			SET @IsPOItemEmpty = 'N'
	IF @Column='MO' 
		IF @Uploadval IS NULL
			SET @IsMOEmpty = 'Y'
		ELSE
			SET @IsMOEmpty = 'N'
	IF @Column='MOItem' 
		IF @Uploadval IS NULL
			SET @IsMOItemEmpty = 'Y'
		ELSE
			SET @IsMOItemEmpty = 'N'
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
	IF @Column='MSTrans' 
		IF @Uploadval IS NULL
			SET @IsMSTransEmpty = 'Y'
		ELSE
			SET @IsMSTransEmpty = 'N'
	IF @Column='MSTicket' 
		IF @Uploadval IS NULL
			SET @IsMSTicketEmpty = 'Y'
		ELSE
			SET @IsMSTicketEmpty = 'N'
	IF @Column='EMCo' 
		IF @Uploadval IS NULL
			SET @IsEMCoEmpty = 'Y'
		ELSE
			SET @IsEMCoEmpty = 'N'
	IF @Column='EMEquip' 
		IF @Uploadval IS NULL
			SET @IsEMEquipEmpty = 'Y'
		ELSE
			SET @IsEMEquipEmpty = 'N'
	IF @Column='EMRevCode' 
		IF @Uploadval IS NULL
			SET @IsEMRevCodeEmpty = 'Y'
		ELSE
			SET @IsEMRevCodeEmpty = 'N'
	IF @Column='EMGroup' 
		IF @Uploadval IS NULL
			SET @IsEMGroupEmpty = 'Y'
		ELSE
			SET @IsEMGroupEmpty = 'N'
	IF @Column='Employee' 
		IF @Uploadval IS NULL
			SET @IsEmployeeEmpty = 'Y'
		ELSE
			SET @IsEmployeeEmpty = 'N'
	IF @Column='Vendor' 
		IF @Uploadval IS NULL
			SET @IsVendorEmpty = 'Y'
		ELSE
			SET @IsVendorEmpty = 'N'
   
   
              --fetch next record
   
           if @@fetch_status <> 0
             select @complete = 1
   
           select @oldrecseq = @Recseq
   
           fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
       end
   
     else
   
       begin
   
       If @ynsource ='Y' AND (ISNULL(@OverwriteSource, 'Y') = 'Y' OR ISNULL(@IsSourceEmpty, 'Y') = 'Y')
          begin
   
      	     select @Identifier = DDUD.Identifier
   	     From DDUD
   	     inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
                     Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'Source'
   
                     UPDATE IMWE
   	     SET IMWE.UploadVal = 'JC CostAdj'
   	     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
           end
   
   
       If @ynToJCCo ='Y' and @Co is not null and @Co <> '' AND (ISNULL(@OverwriteToJCCo, 'Y') = 'Y' OR ISNULL(@IsToJCCoEmpty, 'Y') = 'Y')
    	     begin
   
      	     select @Identifier = DDUD.Identifier
   	     From DDUD
   	     inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
            Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'ToJCCo'
   
            UPDATE IMWE
   	     SET IMWE.UploadVal = @Co
   	     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
           end
   
       If @ynphasegroup ='Y' and @Co is not null and @Co <> '' AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')
    	     begin
            exec @rcode = bspJCPhaseGrpGet @Co, @PhaseGroup output, @desc output
   
      	     select @Identifier = DDUD.Identifier
   	     From DDUD
   	     inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
            Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'PhaseGroup'
   
            UPDATE IMWE
   	     SET IMWE.UploadVal = @PhaseGroup
   	     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
           end
   
        If @ynglco ='Y' and @Co is not null and @Co <> '' AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
    	     begin
              exec @rcode = bspJCGLCoGet @Co, @GLCo output, @desc output
   
        	   select @Identifier = DDUD.Identifier
   	       From DDUD
   	       inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
              Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLCo'
   
              UPDATE IMWE
      	       SET IMWE.UploadVal = @GLCo
   	       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
            end
   
        If @yngltransacct ='Y' and @Co is not null and @Co <> '' AND (ISNULL(@OverwriteGLTransAcct, 'Y') = 'Y' OR ISNULL(@IsGLTransAcctEmpty, 'Y') = 'Y')
    	      begin
               exec @rcode = bspJCCAGlacctDflt @Co, @Job, @PhaseGroup, @Phase, @CostType, 'N', @GLTransAcct output, @desc output
   
         	    select @Identifier = DDUD.Identifier
   	        From DDUD
   	        inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
               Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLTransAcct'
   
               UPDATE IMWE
   	        SET IMWE.UploadVal = @GLTransAcct
   	      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
             end
   
        If @ynum ='Y' and @Co is not null and @Co <> ''and @Job is not null and @Job <> '' and @Phase is not null and @Phase <> '' AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')
    	    begin
               exec @rcode = bspJCVCOSTTYPEWithHrs @Co, @Job, @PhaseGroup, @Phase, @CostType, 'N', @ctdesc output, @UM output, @trackhours output, @costtypeout output, @retainpct output, @desc output
   
         	    select @Identifier = DDUD.Identifier
   	        From DDUD
   	        inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
               Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'UM'
   
               UPDATE IMWE
   	        SET IMWE.UploadVal = @UM
   	        where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
           end
   
               select @currrecseq = @Recseq
               select @counter = @counter + 1
   
           end
   
   end
   
   
   
   UPDATE IMWE
   SET IMWE.UploadVal = 0
   where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.UploadVal is null and
   (IMWE.Identifier = 95 or IMWE.Identifier = 100 or IMWE.Identifier = 105 )
   
   
   close WorkEditCursor
   deallocate WorkEditCursor
   
   bspexit:
       select @msg = isnull(@desc,'Job Cost Progress') + char(13) + char(10) + '[bspBidtekDefaultJCCB]'
   
       return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsJCCBPrg] TO [public]
GO
