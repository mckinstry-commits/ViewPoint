SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsEMBFUsage]
   /***********************************************************
    * CREATED BY: Danf
    * MODIFIED BY: DANF 03/19/02 - Added Record Type
    * 		DANF 06/13/03 - #21409 Corrected Dollar default for unit based revenue codes.
    *		RBT  03/03/04 - #23900 Fixed default for revenue code.
    *		RBT  05/10/04 - #24565 Fixed default for revusedonequipgroup, add @finalrcode.
    *		RBT  05/19/04 - #24647 Fixed GLTransAcct default.
    *		RBT  05/27/04 - #24647 Fix GLTransAcct default again.
    *		RBT  07/06/04 - #25027 Fix OffSetGLCo default to work as in the form.
    *		RBT  09/27/05 - #29905 Set CostCode to null if EM Trans Type is Job.
	*		DANF 09/19/06 - #121525	Set Current Odometer and Hour meter to zero if it is empty or null.
	*		TRL  10/27/08 - #130765 format numeric imports according viewpoint datatypes
    *		TRL  12/17/08 - #131454 change format on Unit to 16,5.
    *		CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
	*		TRL 05/27/09 - Issue 133733, Added  Recompile
	*		JVH 5/20/10 - ISSUE 138959 - Defaulting current hours from time units and rev code
	*		GF 09/12/2010 - issue #141031 changed to use vfDateOnly
	*		AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
	*
    * Usage: Equipment Usage Import
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
   
   with recompile as
   
   set nocount on
   
   declare @rcode int, @finalrcode int, @recode int, @desc varchar(120), @defaultvalue varchar(30),
           @ynactualdate bYN, @ynemgroup bYN, @yncostcode bYN, @yncosttype bYN, @ynmatlgroup bYN, @yninco bYN,
           @ynglco bYN, @yntaxgroup bYN, @yngltransacct bYN, @yngloffsetacct bYN, @ynmaterial bYN,
           @ynum bYN, @ynrevrate bYN, @ynrevdollars bYN, @ynrevcode bYN, @ynrevusedonequipco bYN,
           @ynjcco bYN, @ynprco bYN, @ynphasegroup bYN, @ynrevusedonequipgroup bYN, @ynrevusedonequip bYN, @ynoffsetglco bYN,
           @ynrevtimeunits bYN, @yntimeum bYN, @ynrevworkunits bYN, @ynprevioushourmeter bYN, @ynpreviousodometer bYN
   -- #142350 removing @actualdateid paramater
   declare @revdollarsid int, @equipid int, @emgroupid int, @costcodeid int, @emcosttypeid int, @matlgroupid int,
           @incoid int, @glcoid int, @taxgroupid int, @gltransacctid int, @gloffsetacctid int, @materialid int,
           @umid int, @revrateid int, @dollarsid int, @CompanyID int, @timeumid int,
           @SourceID int, @BatchTransTypeID int, @ActualDateID int, @jccoid int, @prcoid int, @phasegroupid int,
           @RevUsedOnEquipCoID int, @revusedonequipgroupid int, @revusedonequipid int, @offsetglcoid int, @revtimeunitsid int,
           @revworkunitsid int, @currenthourmeterid int, @currentodometerid int, @costtypeid int,
           @previoushourmeterid int, @previousodometerid int, @revcodeid int,
           @componentid int, @componenttypecodeid int
   -- #142350 renaming @revrate paramater
   declare @RevenueRate bUnitCost, @time_um bUM, @work_um bUM, @offsetglacct bGLAcct, @rglcode int,
  		 @dept bDept
   
   
   select @ynactualdate ='N', @ynemgroup ='N', @yncostcode ='N', @yncosttype ='N', @ynmatlgroup ='N', @yninco ='N',
          @ynglco ='N', @yntaxgroup ='N', @yngltransacct ='N', @yngloffsetacct ='N', @ynmaterial = 'N',
          @ynum ='N', @ynrevrate ='N', @ynrevdollars ='N',  @yntimeum = 'N', @ynjcco ='N', 
  		@ynprco='N', @ynphasegroup = 'N', @ynrevusedonequipgroup = 'N', @ynrevusedonequip='N', @ynoffsetglco = 'N',
          @ynrevtimeunits = 'N', @ynprevioushourmeter ='N', @ynpreviousodometer = 'N', @ynrevcode = 'N',
  		@ynrevusedonequipco = 'N'
   
   /* check required input params */
   
  select @rcode = 0, @finalrcode = 0
  
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
   
   
   -- Check ImportTemplate detail for columns to set Bidtek Defaults
   if not exists(select 1 From IMTD with (nolock)
                 Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
                  and IMTD.RecordType = @rectype)
   goto bspexit
   
   DECLARE 
			  @OverwriteCo 	 					bYN
			, @OverwriteSource 	 				bYN
			, @OverwriteBatchTransType 	 		bYN
			, @OverwriteActualDate 	 			bYN
			, @OverwriteEMGroup 	 			bYN
			, @OverwritePRCo 	 				bYN
			, @OverwriteJCCo 	 				bYN
			, @OverwritePhaseGrp 	 			bYN
			, @OverwriteJCCostType 	 			bYN
			, @OverwriteRevUsedOnEquipCo 		bYN
			, @OverwriteRevUsedOnEquipGroup 	bYN
			, @OverwriteRevUsedOnEquip			bYN
			, @OverwriteGLCo 	 				bYN
			, @OverwriteOffsetGLCo 	 			bYN
			, @OverwriteGLTransAcct 	 		bYN
			, @OverwriteGLOffsetAcct 	 		bYN
			, @OverwriteRevTimeUnits 	 		bYN
			, @OverwriteRevWorkUnits 	 		bYN
			, @OverwriteTimeUM 	 				bYN
			, @OverwriteUM 	 					bYN
			, @OverwriteRevRate 	 			bYN
			, @OverwriteRevDollars 	 			bYN
			, @OverwritePreviousOdometer 		bYN
			, @OverwritePreviousHourMeter 		bYN
			, @OverwriteRevCode 	 			bYN
			,	@IsCoEmpty 					 	bYN
			,	@IsMthEmpty 				 	bYN
			,	@IsBatchIdEmpty 			 	bYN
			,	@IsBatchSeqEmpty 			 	bYN
			,	@IsEMTransEmpty 			 	bYN
			,	@IsEMTransTypeEmpty 		 	bYN
			,	@IsBatchTransTypeEmpty 		 	bYN
			,	@IsSourceEmpty 				 	bYN
			,	@IsEMGroupEmpty 			 	bYN
			,	@IsEquipmentEmpty 			 	bYN
			,	@IsRevCodeEmpty 			 	bYN
			,	@IsPRCoEmpty 				 	bYN
			,	@IsPREmployeeEmpty 			 	bYN
			,	@IsJCCoEmpty 				 	bYN
			,	@IsJobEmpty 				 	bYN
			,	@IsPhaseGrpEmpty 			 	bYN
			,	@IsJCPhaseEmpty 			 	bYN
			,	@IsJCCostTypeEmpty 			 	bYN
			,	@IsRevUsedOnEquipCoEmpty 	 	bYN
			,	@IsRevUsedOnEquipGroupEmpty  	bYN
			,	@IsRevUsedOnEquipEmpty 		 	bYN
			,	@IsComponentTypeCodeEmpty 	 	bYN
			,	@IsComponentEmpty 			 	bYN
			,	@IsCostCodeEmpty 			 	bYN
			,	@IsEMCostTypeEmpty 			 	bYN
			,	@IsWorkOrderEmpty 			 	bYN
			,	@IsWOItemEmpty 				 	bYN
			,	@IsActualDateEmpty 			 	bYN
			,	@IsGLCoEmpty 				 	bYN
			,	@IsGLTransAcctEmpty 		 	bYN
			,	@IsOffsetGLCoEmpty 			 	bYN
			,	@IsGLOffsetAcctEmpty 		 	bYN
			,	@IsTimeUMEmpty 				 	bYN
			,	@IsRevTimeUnitsEmpty 		 	bYN
			,	@IsUMEmpty 					 	bYN
			,	@IsRevWorkUnitsEmpty 		 	bYN
			,	@IsRevRateEmpty 			 	bYN
			,	@IsRevDollarsEmpty 			 	bYN
			,	@IsCurrentOdometerEmpty 	 	bYN
			,	@IsCurrentHourMeterEmpty 	 	bYN
			,	@IsPreviousOdometerEmpty 	 	bYN
			,	@IsPreviousHourMeterEmpty 	 	bYN

	SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
	SELECT @OverwriteSource = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Source', @rectype);
	SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
	SELECT @OverwriteActualDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActualDate', @rectype);
    SELECT @OverwriteEMGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMGroup', @rectype);
	SELECT @OverwritePRCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRCo', @rectype);
	SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
	SELECT @OverwritePhaseGrp = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGrp', @rectype);
	SELECT @OverwriteJCCostType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCostType', @rectype);
	SELECT @OverwriteRevUsedOnEquipCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevUsedOnEquipCo', @rectype);
	SELECT @OverwriteRevUsedOnEquipGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevUsedOnEquipGroup', @rectype);
	SELECT @OverwriteRevUsedOnEquip = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevUsedOnEquip', @rectype);
	SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
	SELECT @OverwriteOffsetGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OffsetGLCo', @rectype);
	SELECT @OverwriteGLTransAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLTransAcct', @rectype);
	SELECT @OverwriteGLOffsetAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLOffsetAcct', @rectype);
	SELECT @OverwriteRevTimeUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevTimeUnits', @rectype);
	SELECT @OverwriteRevWorkUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevWorkUnits', @rectype);
	SELECT @OverwriteTimeUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TimeUM', @rectype);
	SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UM', @rectype);
	SELECT @OverwriteRevRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevRate', @rectype);
	SELECT @OverwriteRevDollars = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevDollars', @rectype);
	SELECT @OverwritePreviousOdometer = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PreviousOdometer', @rectype);
	SELECT @OverwritePreviousHourMeter = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PreviousHourMeter', @rectype);
	SELECT @OverwriteRevCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevCode', @rectype);
   
   
   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
    end
   
   select @SourceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Source'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSource, 'Y') = 'Y')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'EMRev'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @SourceID
    end
   
   select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD  with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'Y')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'A'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
    end
   
   select @ActualDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD  with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActualDate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActualDate, 'Y') = 'Y')
    begin
      UPDATE IMWE
      ----#141031
      SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ActualDateID
    end
    
    ------------------------------
    select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
      AND IMWE.UploadVal IS NULL
    end
   
   select @SourceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Source'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSource, 'Y') = 'N')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'EMRev'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @SourceID
      AND IMWE.UploadVal IS NULL
    end
   
   select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD  with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'A'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
      AND IMWE.UploadVal IS NULL
    end
   
   select @ActualDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD  with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActualDate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActualDate, 'Y') = 'N')
    begin
      UPDATE IMWE
      ----#141031
      SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ActualDateID
      AND IMWE.UploadVal IS NULL
    end
    
    
   
   select @defaultvalue = IMTD.DefaultValue, @emgroupid = DDUD.Identifier From IMTD  with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMGroup'
   if @defaultvalue = '[Bidtek]'  select @ynemgroup ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @prcoid = DDUD.Identifier From IMTD  with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PRCo'
   if @defaultvalue = '[Bidtek]'  select @ynprco ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @jccoid = DDUD.Identifier From IMTD  with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
   if @defaultvalue = '[Bidtek]'  select @ynjcco ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @phasegroupid = DDUD.Identifier From IMTD  with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PhaseGrp'
   if @defaultvalue = '[Bidtek]'  select @ynphasegroup ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @costtypeid = DDUD.Identifier From IMTD  with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCostType'
   if @defaultvalue = '[Bidtek]'  select @yncosttype ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @RevUsedOnEquipCoID = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevUsedOnEquipCo'
   if @defaultvalue = '[Bidtek]' select @ynrevusedonequipco = 'Y'
   
   select @defaultvalue = IMTD.DefaultValue, @revusedonequipgroupid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevUsedOnEquipGroup'
   if @defaultvalue = '[Bidtek]'  select @ynrevusedonequipgroup ='Y'

   select @defaultvalue = IMTD.DefaultValue, @revusedonequipid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevUsedOnEquip'
   if @defaultvalue = '[Bidtek]'  select @ynrevusedonequip ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @glcoid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLCo'
   if @defaultvalue = '[Bidtek]'  select @ynglco ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @offsetglcoid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OffsetGLCo'
   if @defaultvalue = '[Bidtek]'  select @ynoffsetglco ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @gltransacctid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLTransAcct'
   if @defaultvalue = '[Bidtek]'  select @yngltransacct  ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @gloffsetacctid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLOffsetAcct'
   if @defaultvalue = '[Bidtek]'  select @yngloffsetacct  ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @revtimeunitsid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevTimeUnits'
   if @defaultvalue = '[Bidtek]'  select @ynrevtimeunits ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @revworkunitsid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevWorkUnits'
   if @defaultvalue = '[Bidtek]'  select @ynrevworkunits ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @timeumid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TimeUM'
   if @defaultvalue = '[Bidtek]'  select @yntimeum ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @umid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UM'
   if @defaultvalue = '[Bidtek]'  select @ynum ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @revrateid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevRate'
   if @defaultvalue = '[Bidtek]' select @ynrevrate ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @revdollarsid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevDollars'
   if @defaultvalue = '[Bidtek]' select @ynrevdollars  ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @currentodometerid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CurrentOdometer'
   
   select @defaultvalue = IMTD.DefaultValue, @currenthourmeterid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CurrentHourMeter'
   
   select @defaultvalue = IMTD.DefaultValue, @previousodometerid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PreviousOdometer'
   if @defaultvalue = '[Bidtek]' select @ynpreviousodometer ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @previoushourmeterid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PreviousHourMeter'
   if @defaultvalue = '[Bidtek]' select @ynprevioushourmeter ='Y'
   
   --Added for issue #23900
   select @defaultvalue = IMTD.DefaultValue, @revcodeid = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevCode'
   if @defaultvalue = '[Bidtek]' select @ynrevcode ='Y'
   
   --Added for issue #29905
   select @costcodeid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CostCode', @rectype, 'N')
   
   select @componentid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Component', @rectype, 'N')
   select @componenttypecodeid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ComponentTypeCode', @rectype, 'N')

 
 
   declare  @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @BatchTransType char, @Source bSource,
    @Equipment bEquip, @RevCode bRevCode, @EMTrans bTrans, @EMTransType  varchar(10), @ComponentTypeCode varchar(10), @Component bEquip,
    @Asset varchar(20), @EMGroup bGroup, @CostCode bCostCode, @EMCostType bEMCType, @ActualDate  bDate, @Description bDesc, @GLCo bCompany,
    @GLTransAcct bGLAcct, @GLOffsetAcct bGLAcct, @ReversalStatus tinyint, @OrigMth bMonth, @OrigEMTrans bTrans,
    @PRCo bCompany, @PREmployee bEmployee, @APCo bCompany, @APTrans bTrans, @APLine bItem, @VendorGrp bGroup, @APVendor bVendor,
    @APRef bAPReference, @WorkOrder bWO, @WOItem bItem, @MatlGroup bGroup, @INCo bCompany, @INLocation bLoc, @Material bMatl,
    @SerialNo varchar(20), @UM bUM, @Units bUnits, @Dollars bDollar, @UnitPrice bUnitCost, @Hours bHrs, @PerECM bECM,
    @JCCo bCompany, @Job bJob, @PhaseGrp bGroup, @JCPhase bPhase, @JCCostType bJCCType, @TaxGroup bGroup,
    @Department bDept, @FuelCostCode bCostCode, @FuelMaterial bMatl, @FuelEMCostType bEMCType,
    @CurrentHourMeter bHrs, @CurrentOdoMeter bHrs, @FuelUM bUM, @ECMFact int, @EMEP_HQMatl bMatl, @stdum bUM,
    @price bUnitCost, @stocked bYN, @category varchar(10), @taxcodein bTaxCode,
    @TimeUM bUM, @RevTimeUnits bUnits, @RevWorkUnits bUnits, @RevDollars bDollar, @RevRate bUnitCost,
    @RevUsedOnEquipCo bCompany, @RevUsedOnEquipGroup bGroup, @RevUsedOnEquip bEquip, @OffSetGLCo bCompany,
    @odoreading bHrs, @hourreading bHrs, @Basis char(1)
   
   
   declare WorkEditCursor cursor local fast_forward for
   select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
       from IMWE
           inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
       where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
       Order by IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   -- set open cursor flag
   -- #142350 removing @importid paramater
   declare @Recseq int, @Tablename varchar(20), @Column varchar(30), @Uploadval varchar(60), @Ident int,
           @seq int, @Identifier int
   
   declare @crcsq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
           @columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int
   
   declare @costtypeout bEMCType
   
 
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
   	If @Column='Equipment' select @Equipment = @Uploadval
   	If @Column='RevCode' select @RevCode = @Uploadval
   /*	If @Column='EMTrans' and isdate(@Uploadval) =1 select @EMTrans = Convert( smalldatetime, @Uploadval)*/
   	If @Column='ComponentTypeCode' select @ComponentTypeCode = @Uploadval
   	If @Column='Component' select @Component = @Uploadval
   /*	If @Column='Asset' select @Type = @Asset */
   	If @Column='EMTransType' select @EMTransType = @Uploadval
   	If @Column='EMGroup' and isnumeric(@Uploadval) =1 select @EMGroup = Convert( int, @Uploadval)
   	If @Column='CostCode' select @CostCode = @Uploadval
    	If @Column='EMCostType' and  isnumeric(@Uploadval) =1 select @EMCostType = @Uploadval
   	If @Column='ActualDate' and isdate(@Uploadval) =1 select @ActualDate = Convert( smalldatetime, @Uploadval)
   	If @Column='Description' select @Description = @Uploadval
   	If @Column='GLCo' and isnumeric(@Uploadval) =1 select @GLCo = Convert( int, @Uploadval)
   	If @Column='GLTransAcct' select @GLTransAcct = @Uploadval
   	If @Column='OffSetGLCo' and isnumeric(@Uploadval) =1 select @OffSetGLCo = @Uploadval
   	If @Column='GLOffsetAcct' select @GLOffsetAcct = @Uploadval
   /*	If @Column='ReversalStatus' select @ReversalStatus = @Uploadval
       If @Column='OrigMth' and  isnumeric(@Uploadval) =1 select @OrigMth = convert(numeric,@Uploadval)
   	If @Column='OrigEMTrans' select @OrigEMTrans = @Uploadval  */
   	If @Column='PRCo' and  isnumeric(@Uploadval) =1 select @PRCo = convert(numeric,@Uploadval)
   	If @Column='PREmployee' select @PREmployee = @Uploadval
   /*	If @Column='APCo' select @APCo = @Uploadval
   	If @Column='APTrans' select @APTrans = @Uploadval
   	If @Column='APLine' select @APLine = @Uploadval
   	If @Column='VendorGrp' select @VendorGrp = @Uploadval
   	If @Column='APVendor' and  isnumeric(@Uploadval) =1 select @APVendor = convert(decimal(10,3),@Uploadval)
   	If @Column='APRef' select @APRef = @Uploadval  */
   	If @Column='WorkOrder' select @WorkOrder = @Uploadval
   	If @Column='WOItem' and isnumeric(@Uploadval)=1 select @WOItem = @Uploadval 
   /* 	If @Column='MatlGroup' and isnumeric(@Uploadval) =1 select @MatlGroup = Convert( int, @Uploadval)
   	If @Column='INCo' and isnumeric(@Uploadval) =1 select @INCo = Convert( int, @Uploadval)
   	If @Column='INLocation' select @INLocation = @Uploadval
   	If @Column='Material' select @Material = @Uploadval
   	If @Column='SerialNo' select @SerialNo = @Uploadval*/
   	If @Column='UM' select @UM = @Uploadval
   	If @Column='TimeUM' select @TimeUM = @Uploadval
   /*	If @Column='Units' and isnumeric (@Uploadval) = 1 select @Units = convert(decimal(12,3),@Uploadval)
   	If @Column='Dollars' and isnumeric(@Uploadval) =1 select @Dollars = convert(numeric,@Uploadval)
   	If @Column='UnitPrice' and isnumeric(@Uploadval) =1 select @UnitPrice = convert(numeric,@Uploadval)
   	If @Column='Hours' and isnumeric(@Uploadval) =1 select @Hours = convert(decimal(10,3),@Uploadval)
   	If @Column='PerECM' select @PerECM = @Uploadval */
	--Issue 130765
    If @Column='CurrentHourMeter' and isnumeric(@Uploadval) =1 select @CurrentHourMeter = convert(numeric(10,2),@Uploadval)
   	If @Column='CurrentOdometer' and isnumeric(@Uploadval) =1 select @CurrentOdoMeter = convert(numeric(10,2),@Uploadval)
   	If @Column='JCCo' and isnumeric(@Uploadval) =1 select @JCCo = convert(decimal(10,2),@Uploadval)
    	If @Column='Job' select @Job = @Uploadval
   	If @Column='PhaseGrp' and isnumeric(@Uploadval)=1 select @PhaseGrp = @Uploadval
   	If @Column='JCPhase' select @JCPhase = @Uploadval
   	If @Column='JCCostType' and isnumeric(@Uploadval)=1 select @JCCostType = @Uploadval
   /*	If @Column='TaxType' select @TaxType = @Uploadval 
   	If @Column='TaxGroup' and isnumeric(@Uploadval) =1 select @TaxGroup = Convert( int, @Uploadval)
   	If @Column='TaxBasis' select @TaxBasis = @Uploadval
   	If @Column='TaxRate' and isnumeric(@Uploadval) =1 select @TaxRate = convert(numeric,@Uploadval)
   	If @Column='TaxAmount' and isnumeric(@Uploadval) =1 select @TaxAmount = convert(numeric,@Uploadval)*/
	-- #131454
   	If @Column='RevTimeUnits' and isnumeric(@Uploadval) =1 select @RevTimeUnits = convert(decimal(16,5),@Uploadval)
	-- #131454
   	If @Column='RevWorkUnits' and isnumeric(@Uploadval) =1 select @RevWorkUnits = convert(decimal(16,5),@Uploadval)

   	If @Column='RevRate' and isnumeric(@Uploadval) =1 select @RevRate = convert(numeric(16,5),@Uploadval)
   	If @Column='RevDollars' and isnumeric(@Uploadval) =1 select @RevDollars = convert(numeric(12,2),@Uploadval)
   	If @Column='RevUsedOnEquipCo' and isnumeric(@Uploadval) =1 select @RevUsedOnEquipCo = @Uploadval
   	If @Column='RevUsedOnEquipGroup' and isnumeric(@Uploadval)=1 select @RevUsedOnEquipGroup = @Uploadval
   	If @Column='RevUsedOnEquip' select @RevUsedOnEquip = @Uploadval
      
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
	IF @Column='EMTrans' 
		IF @Uploadval IS NULL
			SET @IsEMTransEmpty = 'Y'
		ELSE
			SET @IsEMTransEmpty = 'N'
	IF @Column='EMTransType' 
		IF @Uploadval IS NULL
			SET @IsEMTransTypeEmpty = 'Y'
		ELSE
			SET @IsEMTransTypeEmpty = 'N'
	IF @Column='BatchTransType' 
		IF @Uploadval IS NULL
			SET @IsBatchTransTypeEmpty = 'Y'
		ELSE
			SET @IsBatchTransTypeEmpty = 'N'
	IF @Column='Source' 
		IF @Uploadval IS NULL
			SET @IsSourceEmpty = 'Y'
		ELSE
			SET @IsSourceEmpty = 'N'
	IF @Column='EMGroup' 
		IF @Uploadval IS NULL
			SET @IsEMGroupEmpty = 'Y'
		ELSE
			SET @IsEMGroupEmpty = 'N'
	IF @Column='Equipment' 
		IF @Uploadval IS NULL
			SET @IsEquipmentEmpty = 'Y'
		ELSE
			SET @IsEquipmentEmpty = 'N'
	IF @Column='RevCode' 
		IF @Uploadval IS NULL
			SET @IsRevCodeEmpty = 'Y'
		ELSE
			SET @IsRevCodeEmpty = 'N'
	IF @Column='PRCo' 
		IF @Uploadval IS NULL
			SET @IsPRCoEmpty = 'Y'
		ELSE
			SET @IsPRCoEmpty = 'N'
	IF @Column='PREmployee' 
		IF @Uploadval IS NULL
			SET @IsPREmployeeEmpty = 'Y'
		ELSE
			SET @IsPREmployeeEmpty = 'N'
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
	IF @Column='PhaseGrp' 
		IF @Uploadval IS NULL
			SET @IsPhaseGrpEmpty = 'Y'
		ELSE
			SET @IsPhaseGrpEmpty = 'N'
	IF @Column='JCPhase' 
		IF @Uploadval IS NULL
			SET @IsJCPhaseEmpty = 'Y'
		ELSE
			SET @IsJCPhaseEmpty = 'N'
	IF @Column='JCCostType' 
		IF @Uploadval IS NULL
			SET @IsJCCostTypeEmpty = 'Y'
		ELSE
			SET @IsJCCostTypeEmpty = 'N'
	IF @Column='RevUsedOnEquipCo' 
		IF @Uploadval IS NULL
			SET @IsRevUsedOnEquipCoEmpty = 'Y'
		ELSE
			SET @IsRevUsedOnEquipCoEmpty = 'N'
	IF @Column='RevUsedOnEquipGroup' 
		IF @Uploadval IS NULL
			SET @IsRevUsedOnEquipGroupEmpty = 'Y'
		ELSE
			SET @IsRevUsedOnEquipGroupEmpty = 'N'
	IF @Column='RevUsedOnEquip' 
		IF @Uploadval IS NULL
			SET @IsRevUsedOnEquipEmpty = 'Y'
		ELSE
			SET @IsRevUsedOnEquipEmpty = 'N'
	IF @Column='ComponentTypeCode' 
		IF @Uploadval IS NULL
			SET @IsComponentTypeCodeEmpty = 'Y'
		ELSE
			SET @IsComponentTypeCodeEmpty = 'N'
	IF @Column='Component' 
		IF @Uploadval IS NULL
			SET @IsComponentEmpty = 'Y'
		ELSE
			SET @IsComponentEmpty = 'N'
	IF @Column='CostCode' 
		IF @Uploadval IS NULL
			SET @IsCostCodeEmpty = 'Y'
		ELSE
			SET @IsCostCodeEmpty = 'N'
	IF @Column='EMCostType' 
		IF @Uploadval IS NULL
			SET @IsEMCostTypeEmpty = 'Y'
		ELSE
			SET @IsEMCostTypeEmpty = 'N'
	IF @Column='WorkOrder' 
		IF @Uploadval IS NULL
			SET @IsWorkOrderEmpty = 'Y'
		ELSE
			SET @IsWorkOrderEmpty = 'N'
	IF @Column='WOItem' 
		IF @Uploadval IS NULL
			SET @IsWOItemEmpty = 'Y'
		ELSE
			SET @IsWOItemEmpty = 'N'
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
	IF @Column='OffsetGLCo' 
		IF @Uploadval IS NULL
			SET @IsOffsetGLCoEmpty = 'Y'
		ELSE
			SET @IsOffsetGLCoEmpty = 'N'
	IF @Column='GLOffsetAcct' 
		IF @Uploadval IS NULL
			SET @IsGLOffsetAcctEmpty = 'Y'
		ELSE
			SET @IsGLOffsetAcctEmpty = 'N'
	IF @Column='TimeUM' 
		IF @Uploadval IS NULL
			SET @IsTimeUMEmpty = 'Y'
		ELSE
			SET @IsTimeUMEmpty = 'N'
	IF @Column='RevTimeUnits' 
		IF @Uploadval IS NULL
			SET @IsRevTimeUnitsEmpty = 'Y'
		ELSE
			SET @IsRevTimeUnitsEmpty = 'N'
	IF @Column='UM' 
		IF @Uploadval IS NULL
			SET @IsUMEmpty = 'Y'
		ELSE
			SET @IsUMEmpty = 'N'
	IF @Column='RevWorkUnits' 
		IF @Uploadval IS NULL
			SET @IsRevWorkUnitsEmpty = 'Y'
		ELSE
			SET @IsRevWorkUnitsEmpty = 'N'
	IF @Column='RevRate' 
		IF @Uploadval IS NULL
			SET @IsRevRateEmpty = 'Y'
		ELSE
			SET @IsRevRateEmpty = 'N'
	IF @Column='RevDollars' 
		IF @Uploadval IS NULL
			SET @IsRevDollarsEmpty = 'Y'
		ELSE
			SET @IsRevDollarsEmpty = 'N'
	IF @Column='CurrentOdometer' 
		IF @Uploadval IS NULL
			SET @IsCurrentOdometerEmpty = 'Y'
		ELSE
			SET @IsCurrentOdometerEmpty = 'N'
	IF @Column='CurrentHourMeter' 
		IF @Uploadval IS NULL
			SET @IsCurrentHourMeterEmpty = 'Y'
		ELSE
			SET @IsCurrentHourMeterEmpty = 'N'
	IF @Column='PreviousOdometer' 
		IF @Uploadval IS NULL
			SET @IsPreviousOdometerEmpty = 'Y'
		ELSE
			SET @IsPreviousOdometerEmpty = 'N'
	IF @Column='PreviousHourMeter' 
		IF @Uploadval IS NULL
			SET @IsPreviousHourMeterEmpty = 'Y'
		ELSE
			SET @IsPreviousHourMeterEmpty = 'N'   

              --fetch next record
   
           if @@fetch_status <> 0
             select @complete = 1
   
           select @oldrecseq = @Recseq
   
           fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
       end
   
     else
   
       begin
   
        if @ynglco ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
    	  begin
          select @GLCo = GLCo
          from bEMCO
          Where EMCo = @Co
   
          UPDATE IMWE
          SET IMWE.UploadVal = @GLCo
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @glcoid
         end
   
        if @ynjcco ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y' OR ISNULL(@IsJCCoEmpty, 'Y') = 'Y')
    	  begin
          select @JCCo = JCCo
          from bEMCO
          Where EMCo = @Co
   
          UPDATE IMWE
          SET IMWE.UploadVal = @JCCo
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @jccoid
         end
   
        if @ynprco ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwritePhaseGrp, 'Y') = 'Y' OR ISNULL(@IsPhaseGrpEmpty, 'Y') = 'Y')
    	  begin
          select @PRCo = PRCo
          from bEMCO with (nolock)
          Where EMCo = @Co
   
          UPDATE IMWE
          SET IMWE.UploadVal = @PRCo
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @prcoid
         end
   
  	if @ynrevusedonequipco = 'Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteRevUsedOnEquipCo, 'Y') = 'Y' OR ISNULL(@IsRevUsedOnEquipCoEmpty, 'Y') = 'Y')
  	begin
  		select @RevUsedOnEquipCo = @Co
  
  	    UPDATE IMWE
  	    SET IMWE.UploadVal = @RevUsedOnEquipCo
  	    where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @RevUsedOnEquipCoID
  	end
  
   	if @ynemgroup ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteEMGroup, 'Y') = 'Y' OR ISNULL(@IsEMGroupEmpty, 'Y') = 'Y')
    	  begin
          exec @rcode = bspEMGroupGet @Co, @EMGroup output, @desc output
  
  		if @rcode <> 0
  		begin
  			select @finalrcode = @rcode
  	
  			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
  			 values(@ImportId,@ImportTemplate,@Form,@crcsq,null,@desc,@emgroupid)
  		end
   
          UPDATE IMWE
          SET IMWE.UploadVal = @EMGroup
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @emgroupid
         end
   
   	if @ynphasegroup ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwritePhaseGrp, 'Y') = 'Y' OR ISNULL(@IsPhaseGrpEmpty, 'Y') = 'Y') 
    	  begin
          select @PhaseGrp = PhaseGroup
          from bHQCO with (nolock)
          where HQCo = @JCCo
   
          UPDATE IMWE
          SET IMWE.UploadVal = @PhaseGrp
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @phasegroupid
         end

   	if @yncosttype ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteJCCostType, 'Y') = 'Y' OR ISNULL(@IsJCCostTypeEmpty, 'Y') = 'Y')
    	  begin
          select @JCCostType = UsageCostType
          from bEMEM with (nolock)
          where EMCo = @Co and Equipment = @Equipment

          UPDATE IMWE
          SET IMWE.UploadVal = @JCCostType
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @costtypeid
         end
   
   	if @ynrevusedonequipgroup ='Y' and isnull(@RevUsedOnEquipCo,'') <> '' AND (ISNULL(@OverwriteRevUsedOnEquipGroup, 'Y') = 'Y' OR ISNULL(@IsRevUsedOnEquipGroupEmpty, 'Y') = 'Y')
    	begin
          exec @rcode = bspEMGroupGet @RevUsedOnEquipCo, @EMGroup output, @desc output
   
  		  if @rcode <> 0
  		  begin
  			select @finalrcode = @rcode
  	
  			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
  			 values(@ImportId,@ImportTemplate,@Form,@crcsq,null,@desc,@revusedonequipgroupid)
  		  end
  
          UPDATE IMWE
          SET IMWE.UploadVal = @EMGroup		--fixed for issue #24565
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @revusedonequipgroupid
         end
   
  
    if @ynoffsetglco ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteOffsetGLCo, 'Y') = 'Y' OR ISNULL(@IsOffsetGLCoEmpty, 'Y') = 'Y')
    	  begin
  			--Revised for #25027
  			if @EMTransType = 'E' OR @EMTransType = 'W'
  			begin
  				select @OffSetGLCo = GLCo from EMCO with (nolock) where EMCo = @RevUsedOnEquipCo
  			end
  			else if @EMTransType = 'J'
  			begin
  				select @OffSetGLCo = GLCo from JCCO with (nolock) where JCCo = @JCCo
  			end
  			else if @EMTransType = 'X'
  			begin
  				select @OffSetGLCo = @GLCo
  			end
  
			UPDATE IMWE
			  SET IMWE.UploadVal = @OffSetGLCo
			  where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @offsetglcoid
         end


	   	if @EMTransType = 'W' AND @ynrevusedonequip ='Y' and isnull(@RevUsedOnEquipCo,'') <> '' AND (ISNULL(@OverwriteRevUsedOnEquip, 'Y') = 'Y' OR ISNULL(@IsRevUsedOnEquipEmpty, 'Y') = 'Y')
		begin
			exec @rcode=bspEMWOItemValForUsePosting @emco=@RevUsedOnEquipCo, @workorder=@WorkOrder, @woitem=@WOItem, @equipment=@RevUsedOnEquip OUTPUT, @comp=@Component OUTPUT, @comptypecode=@ComponentTypeCode OUTPUT, @costcode=@CostCode OUTPUT, @gltransacct=@GLOffsetAcct OUTPUT, @msg=@msg OUTPUT
			IF @rcode<>1
			BEGIN
				UPDATE IMWE
				  SET IMWE.UploadVal = @GLOffsetAcct
				  where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @gloffsetacctid
				UPDATE IMWE
				  SET IMWE.UploadVal = @RevUsedOnEquip
				  where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @revusedonequipid
				IF @IsComponentTypeCodeEmpty = 'Y'
					UPDATE IMWE
					  SET IMWE.UploadVal = @ComponentTypeCode
					  where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @componenttypecodeid
				IF @IsComponentEmpty = 'Y'
					UPDATE IMWE
					  SET IMWE.UploadVal = @Component
					  where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @componentid
				IF @IsCostCodeEmpty = 'Y'
					UPDATE IMWE
					  SET IMWE.UploadVal = @CostCode
					  where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @costcodeid
			END
		end

   
   	--Added for issue #23900
   	if @ynrevcode = 'Y' AND (ISNULL(@OverwriteRevCode, 'Y') = 'Y' OR ISNULL(@IsRevCodeEmpty, 'Y') = 'Y') 
   	begin
   	  select @RevCode = RevenueCode
   	  from bEMEM
   	  where EMCo = @Co and Equipment = @Equipment
   
             UPDATE IMWE
             SET IMWE.UploadVal = @RevCode
             where IMWE.ImportTemplate = @ImportTemplate and IMWE.ImportId = @ImportId and 
   		IMWE.RecordSeq = @crcsq and IMWE.Identifier = @revcodeid
   
   	end
   
   
	select @category = Category, @odoreading = OdoReading, @hourreading = HourReading 
    from EMEM with (nolock)
    where EMCo = @Co and Equipment = @Equipment

	exec @rcode = bspEMRevRateUMDflt @Co, @EMGroup, @EMTransType, @Equipment, @category, @RevCode, @JCCo,
		  @Job, @RevenueRate output, @time_um output, @work_um output, @msg output
   
	if @rcode <> 0
	begin
		select @finalrcode = @rcode

		insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
		 values(@ImportId,@ImportTemplate,@Form,@crcsq,null,@msg,@revrateid)
	end
  
   	select @Basis = Basis from EMRC with (nolock)
   	where EMGroup=@EMGroup and RevCode=@RevCode
   
   	if @yntimeum ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteTimeUM, 'Y') = 'Y' OR ISNULL(@IsTimeUMEmpty, 'Y') = 'Y')
    	  begin
          select @TimeUM = @time_um
   
          UPDATE IMWE
          SET IMWE.UploadVal = @TimeUM
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @timeumid
         end
   
   	if @ynum ='Y' and isnull(@Co,'') <> ''  AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')
    	  begin
          select @UM = @work_um
   
          UPDATE IMWE
          SET IMWE.UploadVal = @UM
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @umid
         end
   
   	if @ynrevrate ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteRevRate, 'Y') = 'Y' OR ISNULL(@IsRevRateEmpty, 'Y') = 'Y')
    	  begin
          select @RevRate = isnull(@RevenueRate,0)
   
          UPDATE IMWE
          SET IMWE.UploadVal = @RevRate
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @revrateid
         end
   
   	if @ynrevdollars ='Y' and isnull(@Co,'') <> ''  AND (ISNULL(@OverwriteRevDollars, 'Y') = 'Y' OR ISNULL(@IsRevDollarsEmpty, 'Y') = 'Y')
    	begin
              select @RevDollars = 0
   	 	if @Basis = 'H'
   		       if 	isnumeric(isnull(@RevTimeUnits,0)) = 1 and 
   					isnumeric(isnull(@RevRate,0)) = 1 select @RevDollars = isnull(@RevRate,0) * isnull(@RevTimeUnits,0)
   		if @Basis = 'U'
   		       if 	isnumeric(isnull(@RevWorkUnits,0)) = 1 and 
   					isnumeric(isnull(@RevRate,0)) = 1 select @RevDollars = isnull(@RevRate,0) * isnull(@RevWorkUnits,0)
   
              UPDATE IMWE
              SET IMWE.UploadVal = @RevDollars
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @revdollarsid
           end
   
  	if @yngltransacct = 'Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteGLTransAcct, 'Y') = 'Y' OR ISNULL(@IsGLTransAcctEmpty, 'Y') = 'Y') --added for issue #24647
  	begin
  		select @dept = Department
          from bEMEM
          where EMCo = @Co and Equipment = @Equipment and Status in ('A', 'D')
  
  		select @GLTransAcct = GLAcct
  		from bEMDR
  		where EMCo = @Co and EMGroup = @EMGroup and Department = @dept and RevCode = @RevCode
  
  		UPDATE IMWE
          SET IMWE.UploadVal = @GLTransAcct
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq 
  			and IMWE.Identifier = @gltransacctid
  	end
 
 	if @EMTransType = 'J'	--issue #29905, set cost code to null if job type trans.
 	begin
  		UPDATE IMWE
          SET IMWE.UploadVal = null
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq 
  			and IMWE.Identifier = @costcodeid
 	end
  
  	select @offsetglacct = null

   	exec @rglcode = bspEMUsageGlacctDflt @Co, @EMGroup, @EMTransType, @JCCo, @Job, @JCPhase, @JCCostType, 
  			@RevUsedOnEquipCo, @RevUsedOnEquip, @CostCode, @EMCostType, @offsetglacct output, @desc output
   
  	if @rglcode <> 0 
  	begin
  		select @finalrcode = @rglcode
  
  		insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
  		 values(@ImportId,@ImportTemplate,@Form,@crcsq,@rglcode,@desc,@gloffsetacctid)
  	end
    
        if @yngloffsetacct ='Y' and isnull(@Co,'') <> '' and @rglcode = 0 AND (ISNULL(@OverwriteGLOffsetAcct, 'Y') = 'Y' OR ISNULL(@IsGLOffsetAcctEmpty, 'Y') = 'Y')
    	  begin
   
          select @GLOffsetAcct = @offsetglacct
   
          UPDATE IMWE
          SET IMWE.UploadVal = @GLOffsetAcct
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq 
  			and IMWE.Identifier = @gloffsetacctid
         end
   
   
        if @ynpreviousodometer ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwritePreviousOdometer, 'Y') = 'Y' OR ISNULL(@IsPreviousOdometerEmpty, 'Y') = 'Y')
    	  begin
   
          UPDATE IMWE
          SET IMWE.UploadVal = @odoreading
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @previousodometerid
         end
   
        if @ynprevioushourmeter ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwritePreviousHourMeter, 'Y') = 'Y' OR ISNULL(@IsPreviousHourMeterEmpty, 'Y') = 'Y')
    	  begin
   
   
          UPDATE IMWE
          SET IMWE.UploadVal = @hourreading
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @previoushourmeterid
         end
   
   
               select @crcsq = @Recseq
               select @counter = @counter + 1
   
           end
   
   end
   
   
   
   close WorkEditCursor
   deallocate WorkEditCursor

	--ISSUE 138959 - Defaulting current hours from time units and rev code
	UPDATE IMWE
	SET IMWE.UploadVal = ISNULL(ISNULL(HourReading, 0) + HrsPerTimeUM * RevTimeUnits.UploadVal, 0)
	FROM IMWE
		INNER JOIN vfIMGetTemplateDetails(@ImportTemplate, @rectype) Details ON IMWE.Identifier = Details.Identifier
		-- Get the RevTimeUnits for each record
		OUTER APPLY vfIMGetRelatedValues(IMWE.ImportId, IMWE.ImportTemplate, IMWE.RecordType, IMWE.RecordSeq, 'RevTimeUnits') RevTimeUnits
		-- Get the EMCo and Equipment to get the last hours entered for the piece of equipment
		OUTER APPLY vfIMGetRelatedValues(IMWE.ImportId, IMWE.ImportTemplate, IMWE.RecordType, IMWE.RecordSeq, 'Co') Companys
		OUTER APPLY vfIMGetRelatedValues(IMWE.ImportId, IMWE.ImportTemplate, IMWE.RecordType, IMWE.RecordSeq, 'Equipment') Equipments
		LEFT JOIN EMEM ON Companys.UploadVal = EMEM.EMCo AND Equipments.UploadVal = EMEM.Equipment
		-- Get the EMGroup and RevCode to get the RevTimeUnits for the revenue code
		OUTER APPLY vfIMGetRelatedValues(IMWE.ImportId, IMWE.ImportTemplate, IMWE.RecordType, IMWE.RecordSeq, 'EMGroup') EMGroups
		OUTER APPLY vfIMGetRelatedValues(IMWE.ImportId, IMWE.ImportTemplate, IMWE.RecordType, IMWE.RecordSeq, 'RevCode') RevCodes
		LEFT JOIN EMRC ON EMGroups.UploadVal = EMRC.EMGroup AND RevCodes.UploadVal = EMRC.RevCode
	WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND Details.ColumnName = 'CurrentHourMeter' -- The column to update
		AND (Details.UserOverwrite = 1 OR ((Details.TableAllowsNull = 0 OR Details.UseDefault = 1) AND dbo.vpfIsNullOrEmpty(IMWE.UploadVal) = 1)) -- The standard checks for updating

   UPDATE IMWE
   SET IMWE.UploadVal = 0
   where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and isnull(IMWE.UploadVal,'')='' and
   (IMWE.Identifier = @revtimeunitsid or IMWE.Identifier = @revworkunitsid or
    IMWE.Identifier = @previousodometerid or IMWE.Identifier = @previoushourmeterid or
    IMWE.Identifier = @currentodometerid or IMWE.Identifier = @currenthourmeterid)
   
   bspexit:
       select @msg = isnull(@desc,'Equipment Usage') + char(13) + char(13) + '[bspIMBidtekDefaultsEMBFUsage]'
   
       return @finalrcode



GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsEMBFUsage] TO [public]
GO
