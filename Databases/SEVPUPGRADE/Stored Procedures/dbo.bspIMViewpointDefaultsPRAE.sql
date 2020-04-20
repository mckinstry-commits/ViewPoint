SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsPRAE]
 /***********************************************************
  * CREATED BY:   DANF 09/20/2006
  * MODIFIED BY:  
  *		CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
  *		EN 3/9/09 #131498 fix error (converting varchar to numeric) when checking usage units for correct default
  *		AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
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
 
 declare @PRCoID int, @PRDeptID int, @InsCodeID int, @CraftID int, @ClassID int, @GLCoID int, @JCCoID int, @PhaseGroupID int,
		 @EMCoID int, @EMGroupID int, @RevCodeID int, @RateAmtID int, @LimitOvrAmtID int, @StdHoursYNID int, @OvrStdLimitYNID int,
		@cCraftID int, @cClassID int, @cJCCoID int, @cJobID int, @cPhaseID int, @cLimitOvrAmtID int, @cHoursID int,
		@cEMCoID int, @cEquipmentID int, @cRevCodeID int, @cMechanicsCCID int, @cUsageUnitsID int,
		@cRateAmtID int, @cStdHoursID int, @cOvrStdLimitYNID int



 declare @ynDepartment bYN, @ynInsurance bYN, @ynCraft bYN, @ynClass bYN, @ynGLCo bYN, @ynEMCo bYN, @ynEMGroup bYN,
		@ynRevCode bYN, @ynRateAmt bYN, @ynLimitOvrAmt bYN, @ynJCCo bYN, @ynPhaseGroup bYN

 
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
			  @OverwritePRCo 	 		bYN
			, @OverwriteStdHours 	 	bYN
			, @OverwriteOvrStdLimitYN 	bYN
			, @OverwriteRateAmt 	 	bYN
			, @OverwriteLimitOvrAmt 	bYN
			, @OverwritePRDept 	 		bYN
			, @OverwriteInsCode 	 	bYN
			, @OverwriteCraft 	 		bYN
			, @OverwriteClass 	 	 	bYN
			, @OverwriteGLCo 	 	 	bYN
			, @OverwriteJCCo 	 	 	bYN
			, @OverwritePhaseGroup 	 	bYN
			, @OverwriteEMCo 	 		bYN
			, @OverwriteEMGroup 	 	bYN
			, @OverwriteRevCode 	 	bYN
			,	@IsPRCoEmpty 			 bYN
			,	@IsEmployeeEmpty 		 bYN
			,	@IsEarnCodeEmpty 		 bYN
			,	@IsSeqEmpty 			 bYN
			,	@IsPaySeqEmpty 			 bYN
			,	@IsPRDeptEmpty 			 bYN
			,	@IsInsCodeEmpty 		 bYN
			,	@IsCraftEmpty 			 bYN
			,	@IsClassEmpty 			 bYN
			,	@IsJCCoEmpty 			 bYN
			,	@IsPhaseGroupEmpty 		 bYN
			,	@IsJobEmpty 			 bYN
			,	@IsPhaseEmpty 			 bYN
			,	@IsGLCoEmpty 			 bYN
			,	@IsStdHoursEmpty 		 bYN
			,	@IsHoursEmpty 			 bYN
			,	@IsRateAmtEmpty 		 bYN
			,	@IsOvrStdLimitYNEmpty 	 bYN
			,	@IsLimitOvrAmtEmpty 	 bYN
			,	@IsFrequencyEmpty 		 bYN
			,	@IsEMCoEmpty 			 bYN
			,	@IsEMGroupEmpty 		 bYN
			,	@IsEquipmentEmpty 		 bYN
			,	@IsRevCodeEmpty 		 bYN
			,	@IsUsageUnitsEmpty 		 bYN
			,	@IsMechanicsCCEmpty 	 bYN
			,	@IsNotesEmpty 			 bYN



	SELECT @OverwritePRCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRCo', @rectype);
	SELECT @OverwriteStdHours = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StdHours', @rectype);
	SELECT @OverwriteOvrStdLimitYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OvrStdLimitYN', @rectype);
	SELECT @OverwriteRateAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RateAmt', @rectype);
	SELECT @OverwriteLimitOvrAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LimitOvrAmt', @rectype);
	SELECT @OverwritePRDept = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRDept', @rectype);
	SELECT @OverwriteInsCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InsCode', @rectype);
	SELECT @OverwriteCraft = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Craft', @rectype);
	SELECT @OverwriteClass = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Class', @rectype);
	SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
	SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
	SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
	SELECT @OverwriteEMCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMCo', @rectype);
	SELECT @OverwriteEMGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMGroup', @rectype);
	SELECT @OverwriteRevCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevCode', @rectype);
 
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

  select @StdHoursYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdHours', @rectype, 'Y')
  if @StdHoursYNID <> 0  AND (ISNULL(@OverwriteStdHours, 'Y') = 'Y') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @StdHoursYNID
	end
 
  select @OvrStdLimitYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OvrStdLimitYN', @rectype, 'Y')
  if @OvrStdLimitYNID <> 0  AND (ISNULL(@OverwriteOvrStdLimitYN, 'Y') = 'Y') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @OvrStdLimitYNID
	end

  select @RateAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RateAmt', @rectype, 'Y')
  if @RateAmtID <> 0  AND (ISNULL(@OverwriteRateAmt, 'Y') = 'Y') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 0
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @RateAmtID
	end

  select @LimitOvrAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LimitOvrAmt', @rectype, 'Y')
  if @ynLimitOvrAmt <> 0  AND (ISNULL(@OverwriteLimitOvrAmt, 'Y') = 'Y') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 0
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @ynLimitOvrAmt
	end
	
------------------------------------

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

  select @StdHoursYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdHours', @rectype, 'Y')
  if @StdHoursYNID <> 0  AND (ISNULL(@OverwriteStdHours, 'Y') = 'N') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @StdHoursYNID
 		AND IMWE.UploadVal IS NULL
	end
 
  select @OvrStdLimitYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OvrStdLimitYN', @rectype, 'Y')
  if @OvrStdLimitYNID <> 0  AND (ISNULL(@OverwriteOvrStdLimitYN, 'Y') = 'N') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @OvrStdLimitYNID
 		AND IMWE.UploadVal IS NULL
	end

  select @RateAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RateAmt', @rectype, 'Y')
  if @RateAmtID <> 0  AND (ISNULL(@OverwriteRateAmt, 'Y') = 'N') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 0
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @RateAmtID
 		AND IMWE.UploadVal IS NULL
	end
	
  select @LimitOvrAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LimitOvrAmt', @rectype, 'Y')
  if @ynLimitOvrAmt <> 0  AND (ISNULL(@OverwriteLimitOvrAmt, 'Y') = 'N') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 0
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @ynLimitOvrAmt
 		AND IMWE.UploadVal IS NULL
	end



   set @ynDepartment = 'N'
   select @PRDeptID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PRDept', @rectype, 'Y')
   if @PRDeptID <> 0 select @ynDepartment = 'Y'

   set @ynInsurance = 'N'
   select @InsCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'InsCode', @rectype, 'Y')
   if @InsCodeID <> 0 select @ynInsurance = 'Y'

   set @ynCraft = 'N'
   select @CraftID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Craft', @rectype, 'Y')
   if @CraftID <> 0 select @ynCraft = 'Y'

   set @ynClass = 'N'
   select @ClassID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Class', @rectype, 'Y')
   if @ClassID <> 0 select @ynClass = 'Y'

   set @ynGLCo = 'N'
   select @GLCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLCo', @rectype, 'Y')
   if @GLCoID <> 0 select @ynGLCo = 'Y'

   set @ynJCCo = 'N'
   select @JCCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCo', @rectype, 'Y')
   if @JCCoID <> 0 select @ynJCCo = 'Y'

   set @ynPhaseGroup = 'N'
   select @PhaseGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGroup', @rectype, 'Y')
   if @PhaseGroupID <> 0 select @ynPhaseGroup = 'Y'


   set @ynEMCo = 'N'
   select @EMCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EMCo', @rectype, 'Y')
   if @EMCoID <> 0 select @ynEMCo = 'Y'

   set @ynEMGroup = 'N'
   select @EMGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EMGroup', @rectype, 'Y')
   if @EMGroupID <> 0 select @ynEMGroup = 'Y'

   set @ynRevCode = 'N'
   select @RevCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RevCode', @rectype, 'Y')
   if @RevCodeID <> 0 select @ynRevCode = 'Y'
 
 --Get Identifiers for dependent defaults.
  select @cCraftID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Craft', @rectype, 'N')
  select @cClassID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Class', @rectype, 'N')
  select @cJCCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCo', @rectype, 'N')
  select @cJobID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Job', @rectype, 'N')
  select @cPhaseID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Phase', @rectype, 'N')
  select @cLimitOvrAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LimitOvrAmt', @rectype, 'N')
  select @cHoursID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Hours', @rectype, 'N')
  select @cEMCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EMCo', @rectype, 'N')
  select @cEquipmentID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Equipment', @rectype, 'N')
  select @cRevCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RevCode', @rectype, 'N')
  select @cMechanicsCCID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MechanicsCC', @rectype, 'N')
  select @cUsageUnitsID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UsageUnits', @rectype, 'N')
  select @cRateAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RateAmt', @rectype, 'N')
  select @cStdHoursID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdHours', @rectype, 'N')
  select @cOvrStdLimitYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OvrStdLimitYN', @rectype, 'N')

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
 --#142350 -- removing  @importid varchar(10), @seq int, @Identifier int,
	DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int,
			@complete int
 
 declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
         @columnlist varchar(255), @records int, @oldrecseq int

declare @PRCo tinyint, @Employee bEmployee, @EarnCode bEDLCode, @Seq tinyint, @PaySeq tinyint,
		@PRDept bDept, @InsCode bInsCode, @Craft bCraft, @Class bClass, @JCCo tinyint, @PhaseGroup bGroup,
		@Job bJob, @Phase bPhase, @GLCo tinyint, @StdHours bYN, @Hours bHrs, @RateAmt bUnitCost, @OvrStdLimitYN bYN,
		@LimitOvrAmt bDollar, @Frequency bFreq, @EMCo tinyint, @EMGroup bGroup, @Equipment bEquip, @RevCode bRevCode,
		@UsageUnits bHrs, @MechanicsCC bCostCode

declare @DefGLCo bCompany, @DefEMCo bCompany, @DefJCCo bCompany, 
		@DefPRDept bDept, @DefInsCode bInsCode, @DefCraft bCraft, @DefClass bClass

 
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

       select @Uploadval = RTRIM(@Uploadval)
        If @Column='PRCo' and isnumeric(@Uploadval) =1 select @PRCo = Convert( int, @Uploadval)
      	If @Column='Employee' and isnumeric(@Uploadval) =1 select @Employee = @Uploadval
      	If @Column='EarnCode' and  isnumeric(@Uploadval) =1 select @EarnCode = @Uploadval
      	If @Column='Seq' and  isnumeric(@Uploadval) =1 select @Seq = @Uploadval
      	If @Column='PaySeq' and isnumeric(@Uploadval) =1 select @PaySeq = Convert( int, @Uploadval)
		If @Column='InsCode' select @InsCode =  @Uploadval
      	If @Column='Craft' select @Craft = @Uploadval
		If @Column='Class'select @Class =  @Uploadval
		If @Column='JCCo' and isnumeric(@Uploadval) =1 select @JCCo = Convert( tinyint, @Uploadval)
		If @Column='PhaseGroup' and isnumeric(@Uploadval) =1 select @PhaseGroup = Convert( tinyint, @Uploadval)
		If @Column='Job' select @Job = @Uploadval
		If @Column='Phase' select @Phase =  @Uploadval
		If @Column='GLCo' and isnumeric(@Uploadval) =1 select @GLCo = Convert(tinyint, @Uploadval)
		If @Column='StdHours'  select @StdHours =  @Uploadval
		If @Column='Hours' and isnumeric(@Uploadval) =1 select @Hours = Convert( numeric(16,5), @Uploadval)
		If @Column='RateAmt' and isnumeric(@Uploadval) =1 select @RateAmt = Convert( numeric(16,5), @Uploadval)
		If @Column='OvrStdLimitYN' select @OvrStdLimitYN =  @Uploadval
		If @Column='LimitOvrAmt' and isnumeric(@Uploadval) =1 select @LimitOvrAmt = Convert( numeric(16,2), @Uploadval)
		If @Column='Frequency' select @Frequency = @Uploadval
		If @Column='EMCo' and isnumeric(@Uploadval) =1 select @EMCo = Convert( tinyint, @Uploadval)
		If @Column='EMGroup' and isnumeric(@Uploadval) =1 select @EMGroup = Convert( tinyint, @Uploadval)
		If @Column='Equipment' select @Equipment =  @Uploadval
		If @Column='RevCode' select @RevCode = @Uploadval
		If @Column='UsageUnits' and isnumeric(@Uploadval) =1 select @UsageUnits = Convert( numeric(16,3), @Uploadval)
		If @Column='MechanicsCC' select @MechanicsCC = @Uploadval

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
		IF @Column='EarnCode' 
			IF @Uploadval IS NULL
				SET @IsEarnCodeEmpty = 'Y'
			ELSE
				SET @IsEarnCodeEmpty = 'N'
		IF @Column='Seq' 
			IF @Uploadval IS NULL
				SET @IsSeqEmpty = 'Y'
			ELSE
				SET @IsSeqEmpty = 'N'
		IF @Column='PaySeq' 
			IF @Uploadval IS NULL
				SET @IsPaySeqEmpty = 'Y'
			ELSE
				SET @IsPaySeqEmpty = 'N'
		IF @Column='PRDept' 
			IF @Uploadval IS NULL
				SET @IsPRDeptEmpty = 'Y'
			ELSE
				SET @IsPRDeptEmpty = 'N'
		IF @Column='InsCode' 
			IF @Uploadval IS NULL
				SET @IsInsCodeEmpty = 'Y'
			ELSE
				SET @IsInsCodeEmpty = 'N'
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
		IF @Column='JCCo' 
			IF @Uploadval IS NULL
				SET @IsJCCoEmpty = 'Y'
			ELSE
				SET @IsJCCoEmpty = 'N'
		IF @Column='PhaseGroup' 
			IF @Uploadval IS NULL
				SET @IsPhaseGroupEmpty = 'Y'
			ELSE
				SET @IsPhaseGroupEmpty = 'N'
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
		IF @Column='GLCo' 
			IF @Uploadval IS NULL
				SET @IsGLCoEmpty = 'Y'
			ELSE
				SET @IsGLCoEmpty = 'N'
		IF @Column='StdHours' 
			IF @Uploadval IS NULL
				SET @IsStdHoursEmpty = 'Y'
			ELSE
				SET @IsStdHoursEmpty = 'N'
		IF @Column='Hours' 
			IF @Uploadval IS NULL
				SET @IsHoursEmpty = 'Y'
			ELSE
				SET @IsHoursEmpty = 'N'
		IF @Column='RateAmt' 
			IF @Uploadval IS NULL
				SET @IsRateAmtEmpty = 'Y'
			ELSE
				SET @IsRateAmtEmpty = 'N'
		IF @Column='OvrStdLimitYN' 
			IF @Uploadval IS NULL
				SET @IsOvrStdLimitYNEmpty = 'Y'
			ELSE
				SET @IsOvrStdLimitYNEmpty = 'N'
		IF @Column='LimitOvrAmt' 
			IF @Uploadval IS NULL
				SET @IsLimitOvrAmtEmpty = 'Y'
			ELSE
				SET @IsLimitOvrAmtEmpty = 'N'
		IF @Column='Frequency' 
			IF @Uploadval IS NULL
				SET @IsFrequencyEmpty = 'Y'
			ELSE
				SET @IsFrequencyEmpty = 'N'
		IF @Column='EMCo' 
			IF @Uploadval IS NULL
				SET @IsEMCoEmpty = 'Y'
			ELSE
				SET @IsEMCoEmpty = 'N'
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
		IF @Column='UsageUnits' 
			IF @Uploadval IS NULL
				SET @IsUsageUnitsEmpty = 'Y'
			ELSE
				SET @IsUsageUnitsEmpty = 'N'
		IF @Column='MechanicsCC' 
			IF @Uploadval IS NULL
				SET @IsMechanicsCCEmpty = 'Y'
			ELSE
				SET @IsMechanicsCCEmpty = 'N'
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
		select @DefGLCo = GLCo, @DefEMCo = EMCo, @DefJCCo = JCCo
		from bPRCO with (nolock)
		where PRCo = @PRCo

		select	@DefPRDept = PRDept, @DefInsCode = InsCode, 
				@DefCraft = Craft, @DefClass = Class
		from bPREH with (nolock)
		where PRCo = @PRCo and Employee = @Employee


  	   	if isnull(@ynJCCo,'N') = 'Y' AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y' OR ISNULL(@IsJCCoEmpty, 'Y') = 'Y')
      	  begin
			select @JCCo = @DefJCCo

            UPDATE IMWE
            SET IMWE.UploadVal = @JCCo
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @JCCoID
           end


  	   	if isnull(@ynPhaseGroup,'N') = 'Y' AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')
      	  begin
			select @PhaseGroup = PhaseGroup
			from bHQCO	with (nolock)
			where HQCo = @JCCo

            UPDATE IMWE
            SET IMWE.UploadVal = @PhaseGroup
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @PhaseGroupID
           end

  	   	if isnull(@ynGLCo,'N') = 'Y' AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
      	  begin
			select @GLCo = @DefGLCo

            UPDATE IMWE
            SET IMWE.UploadVal = @GLCo
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @GLCoID
           end

  	   	if isnull(@ynEMCo,'N') = 'Y' AND (ISNULL(@OverwriteEMCo, 'Y') = 'Y' OR ISNULL(@IsEMCoEmpty, 'Y') = 'Y')
      	  begin
			select @EMCo = @DefEMCo

            UPDATE IMWE
            SET IMWE.UploadVal = @EMCo
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @EMCoID
           end

  	   	if isnull(@ynEMGroup,'N') = 'Y' AND (ISNULL(@OverwriteEMGroup, 'Y') = 'Y' OR ISNULL(@IsEMGroupEmpty, 'Y') = 'Y')
      	  begin
			select @EMGroup = EMGroup
			from bHQCO	with (nolock)
			where HQCo = @EMCo

            UPDATE IMWE
            SET IMWE.UploadVal = @EMGroup
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @EMGroupID
           end

  	   	if isnull(@ynDepartment,'N') = 'Y' AND (ISNULL(@OverwritePRDept, 'Y') = 'Y' OR ISNULL(@IsPRDeptEmpty, 'Y') = 'Y')
      	  begin
			select @PRDept = @DefPRDept

            UPDATE IMWE
            SET IMWE.UploadVal = @PRDept
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @PRDeptID
           end

  	   	if isnull(@ynInsurance,'N') = 'Y' AND (ISNULL(@OverwriteInsCode, 'Y') = 'Y' OR ISNULL(@IsInsCodeEmpty, 'Y') = 'Y')
      	  begin
			select @InsCode = @DefInsCode

            UPDATE IMWE
            SET IMWE.UploadVal = @InsCode
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @InsCodeID
           end


  	   	if isnull(@ynCraft,'N') = 'Y' AND (ISNULL(@OverwriteCraft, 'Y') = 'Y' OR ISNULL(@IsCraftEmpty, 'Y') = 'Y')
      	  begin
			select @Craft = @DefCraft

            UPDATE IMWE
            SET IMWE.UploadVal = @DefCraft
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @CraftID
           end

  	   	if isnull(@ynClass,'N') = 'Y' AND (ISNULL(@OverwriteClass, 'Y') = 'Y' OR ISNULL(@IsClassEmpty, 'Y') = 'Y')
      	  begin
			select @Class = @DefClass

            UPDATE IMWE
            SET IMWE.UploadVal = @DefClass
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @ClassID
           end



  	   	if isnull(@ynRevCode,'N') = 'Y' AND (ISNULL(@OverwriteRevCode, 'Y') = 'Y' OR ISNULL(@IsRevCodeEmpty, 'Y') = 'Y')
      	  begin
			set @RevCode = ''

			select @RevCode = RevenueCode
			from EMEM with (nolock)
			where EMCo = @EMCo and Equipment = @Equipment

            UPDATE IMWE
            SET IMWE.UploadVal = @RevCode
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @RevCodeID
           end


		-- Clean up Rules for imported data:

 	   	if isnull(@Craft,'') = '' and isnull(@Class,'') <> ''
      	  begin

			set @Class = ''

            UPDATE IMWE
            SET IMWE.UploadVal = @Class
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cClassID
           end

 	   	if isnull(@JCCo,'') = '' and isnull(@Job,'') <> ''
      	  begin

			set @Job = ''

            UPDATE IMWE
            SET IMWE.UploadVal = @Job
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cJobID
           end


 	   	if isnull(@JCCo,'') = '' and isnull(@Phase,'') <> ''
      	  begin

			set @Phase = ''

            UPDATE IMWE
            SET IMWE.UploadVal = @Job
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cPhaseID
           end



 	   	if isnull(@StdHours,'') <> 'Y'
      	  begin

			set @Hours = '0'

            UPDATE IMWE
            SET IMWE.UploadVal = @Hours
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cHoursID
           end


 	   	if isnull(@OvrStdLimitYN,'') <> 'Y'
      	  begin

			set @LimitOvrAmt = '0'

            UPDATE IMWE
            SET IMWE.UploadVal = @LimitOvrAmt
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cLimitOvrAmtID
           end


 	   	if isnull(@EMCo,'') = '' and isnull(@Equipment,'') <> ''
      	  begin

			set @Equipment = ''

            UPDATE IMWE
            SET IMWE.UploadVal = @Equipment
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cEquipmentID
           end


 	   	if isnull(@EMCo,'') = '' and isnull(@RevCode,'') <> ''
      	  begin

			set @RevCode = ''

            UPDATE IMWE
            SET IMWE.UploadVal = @RevCode
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cRevCodeID
           end

 	   	if isnull(@EMCo,'') = '' and isnull(@UsageUnits,0) <> 0 --#131498
      	  begin

			set @UsageUnits = 0

            UPDATE IMWE
            SET IMWE.UploadVal = @UsageUnits
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cUsageUnitsID
           end


 	   	if isnull(@EMCo,'') = '' and isnull(@MechanicsCC,'') <> ''
      	  begin

			set @MechanicsCC = ''

            UPDATE IMWE
            SET IMWE.UploadVal = @MechanicsCC
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cMechanicsCCID
           end
		--Frequency cannot be null

 	-- set Current Req Seq to next @Recseq unless we are processing last record.
 	if @Recseq = -1
 		select @complete = 1	-- exit the loop
 	else
 		select @currrecseq = @Recseq
 
   end
 end
 

      UPDATE IMWE
      SET IMWE.UploadVal = 0
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and isnull(IMWE.UploadVal,'') = ''and
      (IMWE.Identifier = @cRateAmtID or IMWE.Identifier = @cLimitOvrAmtID )

      UPDATE IMWE
      SET IMWE.UploadVal = 'N'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and isnull(IMWE.UploadVal,'') not in ('N','Y') and
      (IMWE.Identifier = @cStdHoursID or IMWE.Identifier = @cOvrStdLimitYNID )


 bspexit:
 
 	if @CursorOpen = 1
 	begin
 		close WorkEditCursor
 		deallocate WorkEditCursor	
 	end
 
     select @msg = isnull(@desc,'Clear') + char(13) + char(13) + '[bspIMViewpointDefaultsPRAE]'
 
     return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsPRAE] TO [public]
GO
