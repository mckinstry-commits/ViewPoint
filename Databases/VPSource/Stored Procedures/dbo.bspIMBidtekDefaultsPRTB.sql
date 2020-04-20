
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsPRTB]
/***********************************************************
* CREATED BY: Danf
* MODIFIED BY: EN 6/15/00 - Fix to use variable earnings rates if any have been set up
*           DANF 03/06/01 - Added Default for Equipment Useage Cost type and corrected Craft default for override.
*           DANF 05/09/01 - Corrected isnull value
*           DANF 10/26/01 - Clean EM usage cost type if no Job.
*           DANF 03/19/02 - Added Record Type
*           DANF 05/20/02 - Added Revenue default.
* 			DANF 05/09/2003 - Issue 21221 Added Equipment and Cost Code Defaults from Work Orders.
*			RBT 01/28/04 - Issue 23621, added defaults for EMCo, EquipPhase, and UsageUnits.
*			RBT 02/04/04 - Issue 23621, fixed to only default equipphase and usageunits if there is equipment.
*			RBT 04/23/04 - Issue 24429, use @JCCo and @EMCo for respective group retrieval.
*			RBT 04/30/04 - Issue 24469, fixed phase group, EMCo, and shift defaults.
*			RBT 05/10/04 - Issue 24490, carry error codes until the end instead of overwriting.
*			RBT 06/15/04 - Issue 24799, update defaults for PostDate and Type.
*			RBT 09/28/04 - Issue 25652, optionally default PostDate based on DayNum.
*			RBT 06/07/05 - Issue 28884, fix shift default.
*			DANF 04/10/07 - Issue 122773, Correct Missing Crew error when defaulting shift
*			DANF 04/11/07 - Issue 123036 Add default for batch trans type to 'A'
*			CC	 08/08/08 - Issue 128151 If EarnCode's Method is 'A' (Amount), then set Rate = 0 if rate is being defaulted
*			CC	 02/02/09 - Issue 132058 Correct import for salaried employees
*			CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
*			TJL 08/07/09 - Issue #133834, Amount not calculating from imported Hours and Rate values.
*			EN 11/06/2009 #135051 need to get craft template for mech timecards as well as job timecards
*			TJL 03/11/10 - Issue #138524, Add Work Office Tax State and LocalCode to PR Employee Master
*			TJL 03/15/10 - Issue #138549, GLCo not defaulting from EMCo on Mechanic TimeCard
*			TJL 08/10/10 - Issue #140781, Minor adjustment to Viewpoint Rate Default.  (Use @EmplRate variable)
*			EN 03/01/10 - D-01065 / #142912 modified to call vspPRGetStateLocalIMDflts rather than
*							vspPRGetStateLocalDflts which will return null state/local values for invalid jobs rather
*							than returning an error
*			EN/KK 09/09/11 - TK-08287 Added code to call new stored proc bspIMPRTB_SMTECHNICIAN to verify employee is a Tech before adding a SM Timecard.
*			EN/KK 09/13/11 - TK-08924 Added code to "J", "M" and "S" to clear out un-needed fields
*			DAN SO 08/06/2012 - TK-16681 - Changed datatype from bState to VARCHAR(4) for @TaxState, @UnempState, @InsState
*           JayR 10/16/2012 TK-16099 Fix overlapping variables
*			ScottAlvey 08/26/2013 add in get default @SMCo for Technician validation
*			ScottAlvey 08/27/2013 add in get default for @SMJCCostType
* Usage:
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

declare @rcode int, @finalrcode int, @desc varchar(120), @opencursor int, @defaultvalue varchar(30),
        @ynphasegroup bYN, @ynemgroup bYN, @yntaxstate bYN, @ynlocalcode bYN, @ynunempstate bYN, @yninsstate bYN,
        @yninscode bYN, @ynprdept bYN, @yncrew bYN, @yncert bYN, @yncraft bYN, @ynclass bYN, @ynearncode bYN,
        @ynrate bYN, @ynamt bYN, @ynprgroup bYN, @ynprenddate bYN, @ynglco bYN, @ynequipctype bYN, @yncompany bYN,
	    @ynRevCode bYN, @ynEMCo bYN, @ynEquipPhase bYN, @ynUsageUnits bYN, @ynPostDate bYN, @yndaynum bYN, @ynshift bYN,
		@ynSMCo bYN, @ynSMJCCostType bYN
       
select @ynphasegroup ='N', @ynemgroup ='N', @yntaxstate ='N', @ynlocalcode ='N', @ynunempstate ='N', @yninsstate ='N',
       @yninscode ='N', @ynprdept ='N', @yncrew ='N', @yncert ='N', @yncraft ='N', @ynclass ='N', @ynearncode ='N',
       @ynrate ='N', @ynamt ='N', @ynprgroup ='N', @ynprenddate ='N', @ynglco ='N', @ynequipctype = 'N', @yncompany = 'N',
	   @ynRevCode = 'N', @ynEMCo = 'N', @ynEquipPhase = 'N', @ynUsageUnits = 'N', @ynPostDate = 'N', @yndaynum = 'N',
	   @ynshift = 'N', @ynSMCo = 'N', @ynSMJCCostType = 'N'

declare	@PhaseGroupID int, @EMGroupID int, @TaxStateID int, @LocalCodeID int, @UnempStateID int, @InsStateID int,
	    @InsCodeID int, @PRDeptID int, @CrewID int, @CertID int, @CraftID int, @ClassID int, @EarnCodeID int,
	    @RateID int, @AmtID int, @PRGroupID int, @PREndDateID int, @GLCoID int, @EquipCTypeID int, @CompanyID int,
	    @daynumid int, @jccoid int, @RevCodeID int, @PhaseID int, @UsageUnitsID int, @EquipPhaseID int,
	    @WOID int, @WOItemID int, @CostCodeID int, @CompTypeID int, @ComponentID int, @EMCategory bCat,
	    @equipmentid int, @costcodeid_lower int, @EMCoID int, @ShiftID int, @PostDateID int, @TypeID int, @BatchTransTypeID int,
	    @EmployeeID int, @SMCoID int, @SMWorkOrderID int, @SMScopeID int, @SMPayTypeID int, @SMCostTypeID int, @JobID int,
	    @JCCoID int, @EquipmentID int, @SMJCCostTypeID int
       
       /* check required input params */
       
       Select @rcode = 0, @finalrcode = 0
       
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
       --
       -- Check ImportTemplate detail for columns to set Bidtek Defaults
      if not exists	( select 1 From IMTD with (nolock)
      				 Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]')
         begin
      	   select @desc='No Viewpoint Defaults set up for ImportTemplate ' + @ImportTemplate + '.'
         		goto bspexit
         end
       
       DECLARE 
			  @OverwriteType 	 		 bYN
			, @OverwriteBatchTransType 	 bYN
			, @OverwriteJCCo 	 		 bYN
			, @OverwriteEquipment 	 	 bYN
			, @OverwriteCostCode 	 	 bYN
 			, @OverwriteShift 	 		 bYN
			, @OverwriteDayNum 	 		 bYN
			, @OverwritePhaseGroup 	 	 bYN
			, @OverwriteCo 	 			 bYN
			, @OverwriteEMGroup 	 	 bYN
			, @OverwriteTaxState 	 	 bYN
			, @OverwriteLocalCode 	 	 bYN
			, @OverwriteUnempState 	 	 bYN
			, @OverwriteInsState 	 	 bYN
			, @OverwriteInsCode 	 	 bYN
			, @OverwritePRDept 	 	 	 bYN
			, @OverwriteCrew 	 	 	 bYN
			, @OverwriteCert 	 	 	 bYN
			, @OverwriteCraft 	 	 	 bYN
			, @OverwriteClass 	 	 	 bYN
			, @OverwriteEarnCode 	 	 bYN
			, @OverwriteRate 	 	 	 bYN
			, @OverwriteAmt 	 	 	 bYN
			, @OverwritePRGroup 	 	 bYN
			, @OverwritePREndDate 	 	 bYN
			, @OverwriteGLCo 	 		 bYN
			, @OverwriteRevCode 	 	 bYN
			, @OverwriteEquipCType 	 	 bYN
			, @OverwriteEMCo 	 		 bYN
			, @OverwriteEquipPhase 	 	 bYN
			, @OverwriteUsageUnits 	 	 bYN
			, @OverwritePostDate 	 	 bYN    
			, @OverwriteSMCo			 bYN  
			, @OverwriteSMJCCostType	 bYN
			,	@IsCoEmpty 				 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsBatchTransTypeEmpty 	 bYN
			,	@IsEmployeeEmpty 		 bYN
			,	@IsPRGroupEmpty 		 bYN
			,	@IsPREndDateEmpty 		 bYN
			,	@IsPaySeqEmpty 			 bYN
			,	@IsPostSeqEmpty 		 bYN
			,	@IsTypeEmpty 			 bYN
			,	@IsDayNumEmpty 			 bYN
			,	@IsPostDateEmpty 		 bYN
			,	@IsJCCoEmpty 			 bYN
			,	@IsJobEmpty 			 bYN
			,	@IsPhaseGroupEmpty 		 bYN
			,	@IsPhaseEmpty 			 bYN
			,	@IsGLCoEmpty 			 bYN
			,	@IsEMCoEmpty 			 bYN
			,	@IsWOEmpty 				 bYN
			,	@IsWOItemEmpty 			 bYN
			,	@IsEquipmentEmpty 		 bYN
			,	@IsEMGroupEmpty 		 bYN
			,	@IsEquipPhaseEmpty 		 bYN
			,	@IsCostCodeEmpty 		 bYN
			,	@IsCompTypeEmpty 		 bYN
			,	@IsComponentEmpty 		 bYN
			,	@IsRevCodeEmpty 		 bYN
			,	@IsEquipCTypeEmpty 		 bYN
			,	@IsUsageUnitsEmpty 		 bYN
			,	@IsTaxStateEmpty 		 bYN
			,	@IsLocalCodeEmpty 		 bYN
			,	@IsUnempStateEmpty 		 bYN
			,	@IsInsStateEmpty 		 bYN
			,	@IsInsCodeEmpty 		 bYN
			,	@IsPRDeptEmpty 			 bYN
			,	@IsCrewEmpty 			 bYN
			,	@IsCertEmpty 			 bYN
			,	@IsCraftEmpty 			 bYN
			,	@IsClassEmpty 			 bYN
			,	@IsEarnCodeEmpty 		 bYN
			,	@IsShiftEmpty 			 bYN
			,	@IsHoursEmpty 			 bYN
			,	@IsRateEmpty 			 bYN
			,	@IsAmtEmpty 			 bYN
			,	@IsMemoEmpty 			 bYN
			,   @IsSMCoEmpty			 bYN
			,   @IsSMJCCostTypeEmpty	 bYN
       
        SELECT @OverwriteType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Type', @rectype);
		SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
		SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
		SELECT @OverwriteEquipment = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Equipment', @rectype);
		SELECT @OverwriteCostCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostCode', @rectype);
		SELECT @OverwriteShift = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Shift', @rectype);
		SELECT @OverwriteDayNum = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DayNum', @rectype);
		SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
		SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
		SELECT @OverwriteEMGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMGroup', @rectype);
		SELECT @OverwriteTaxState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxState', @rectype);
		SELECT @OverwriteLocalCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LocalCode', @rectype);
		SELECT @OverwriteUnempState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnempState', @rectype);
		SELECT @OverwriteInsState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InsState', @rectype);
		SELECT @OverwriteInsCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InsCode', @rectype);
		SELECT @OverwritePRDept = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRDept', @rectype);
		SELECT @OverwriteCrew = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Crew', @rectype);
		SELECT @OverwriteCert = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Cert', @rectype);
		SELECT @OverwriteCraft = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Craft', @rectype);
		SELECT @OverwriteClass = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Class', @rectype);
		SELECT @OverwriteEarnCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EarnCode', @rectype);
		SELECT @OverwriteRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Rate', @rectype);
		SELECT @OverwriteAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Amt', @rectype);
		SELECT @OverwritePRGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRGroup', @rectype);
		SELECT @OverwritePREndDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PREndDate', @rectype);
		SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
		SELECT @OverwriteRevCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevCode', @rectype);
		SELECT @OverwriteEquipCType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EquipCType', @rectype);
		SELECT @OverwriteEMCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMCo', @rectype);
		SELECT @OverwriteEquipPhase = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EquipPhase', @rectype);
		SELECT @OverwriteUsageUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UsageUnits', @rectype);
		SELECT @OverwritePostDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PostDate', @rectype);
		
    	--added for issue #24799
    	select @TypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Type', @rectype, 'Y')
    	if isnull(@TypeID,0) <> 0 AND (ISNULL(@OverwriteType, 'Y') = 'Y')
    	begin
    		UPDATE IMWE
    		SET UploadVal = 'J'
    		where ImportTemplate=@ImportTemplate and ImportId=@ImportId and Identifier = @TypeID
    	end
    	if isnull(@TypeID,0) <> 0 AND (ISNULL(@OverwriteType, 'Y') = 'N')
    	begin
    		UPDATE IMWE
    		SET UploadVal = 'J'
    		where ImportTemplate=@ImportTemplate and ImportId=@ImportId and Identifier = @TypeID
    		AND IMWE.UploadVal IS NULL
    	end
       
    	--added for issue #123036
    	select @BatchTransTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BatchTransType', @rectype, 'Y')
    	if isnull(@BatchTransTypeID,0) <> 0 AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'Y')
    	begin
    		UPDATE IMWE
    		SET UploadVal = 'A'
    		where ImportTemplate=@ImportTemplate and ImportId=@ImportId and Identifier = @BatchTransTypeID
    	end
    	
    	if isnull(@BatchTransTypeID,0) <> 0 AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N')
    	begin
    		UPDATE IMWE
    		SET UploadVal = 'A'
    		where ImportTemplate=@ImportTemplate and ImportId=@ImportId and Identifier = @BatchTransTypeID
    		AND IMWE.UploadVal IS NULL
    	end

       --Get default flags for certain fields.
       select @jccoid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCo', @rectype, 'Y')
       
       select @defaultvalue = IMTD.DefaultValue, @ShiftID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Shift'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynshift ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @daynumid = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'DayNum'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @yndaynum ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @PhaseGroupID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PhaseGroup'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynphasegroup ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @CompanyID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @yncompany ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @EMGroupID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMGroup'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynemgroup ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @TaxStateID =  DDUD.Identifier From IMTD with (nolock)
  inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxState'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @yntaxstate ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @LocalCodeID =  DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LocalCode'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynlocalcode ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @UnempStateID =  DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UnempState'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynunempstate ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @InsStateID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InsState'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @yninsstate ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @InsCodeID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InsCode'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @yninscode ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @PRDeptID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PRDept'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynprdept ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @CrewID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Crew'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @yncrew ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @CertID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Cert'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @yncert ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @CraftID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Craft'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @yncraft ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @ClassID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Class'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynclass ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @EarnCodeID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EarnCode'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynearncode ='Y'
  
       select @defaultvalue = IMTD.DefaultValue, @RateID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Rate'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynrate ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @AmtID =  DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Amt'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynamt ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @PRGroupID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PRGroup'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynprgroup ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @PREndDateID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PREndDate'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynprenddate ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @GLCoID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLCo'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynglco ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @RevCodeID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevCode'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynRevCode ='Y'
       
       select @defaultvalue = IMTD.DefaultValue, @EquipCTypeID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EquipCType'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynequipctype ='Y'
       
     --#23621
       select @defaultvalue = IMTD.DefaultValue, @EMCoID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMCo'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynEMCo ='Y'
     
       select @defaultvalue = IMTD.DefaultValue, @EquipPhaseID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EquipPhase'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynEquipPhase ='Y'
     
       select @defaultvalue = IMTD.DefaultValue, @UsageUnitsID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UsageUnits'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynUsageUnits ='Y'
     
     --end #23621
     
     --#24799
       select @defaultvalue = IMTD.DefaultValue, @PostDateID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PostDate'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynPostDate ='Y'
     --end #24799
    
     --Get ID's for other fields
       select @PhaseID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Phase'
      
     /* 
       select @UsageUnitsID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UsageUnits'
       
       select @EquipPhaseID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EquipPhase'
       */ --#23621
     
       select @WOID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'WO'
       
       select @WOItemID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'WOItem'
       
       select @CostCodeID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CostCode'
       
       select @CompTypeID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CompType'
       
       select @ComponentID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Component'
       
       --TK-08294
       SELECT @EmployeeID = DDUD.Identifier FROM dbo.IMTD WITH (NOLOCK)
       INNER JOIN dbo.DDUD WITH (NOLOCK) ON IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
       WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Employee'

       SELECT @SMCoID = DDUD.Identifier FROM dbo.IMTD WITH (NOLOCK)
       INNER JOIN dbo.DDUD WITH (NOLOCK) ON IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
       WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SMCo'

	   select @defaultvalue = IMTD.DefaultValue, @SMCoID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SMCo'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynSMCo ='Y'

       SELECT @SMWorkOrderID = DDUD.Identifier FROM dbo.IMTD WITH (NOLOCK)
       INNER JOIN dbo.DDUD WITH (NOLOCK) ON IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
       WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SMWorkOrder'

       SELECT @SMScopeID = DDUD.Identifier FROM dbo.IMTD WITH (NOLOCK)
       INNER JOIN dbo.DDUD WITH (NOLOCK) ON IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
       WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SMScope'

       SELECT @SMPayTypeID = DDUD.Identifier FROM dbo.IMTD WITH (NOLOCK)
       INNER JOIN dbo.DDUD WITH (NOLOCK) ON IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
       WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SMPayType'

       SELECT @SMCostTypeID = DDUD.Identifier FROM dbo.IMTD WITH (NOLOCK)
       INNER JOIN dbo.DDUD WITH (NOLOCK) ON IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
       WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SMCostType'
	   
	   select @defaultvalue = IMTD.DefaultValue, @SMJCCostTypeID = DDUD.Identifier From IMTD with (nolock)
       inner join DDUD with (nolock)  on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
       Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SMJCCostType'
       if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynSMJCCostType ='Y'
       
       SELECT @JCCoID = DDUD.Identifier FROM dbo.IMTD WITH (NOLOCK)
       INNER JOIN dbo.DDUD WITH (NOLOCK) ON IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
       WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
       
       SELECT @JobID = DDUD.Identifier FROM dbo.IMTD WITH (NOLOCK)
       INNER JOIN dbo.DDUD WITH (NOLOCK) ON IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
       WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Job'
       
       SELECT @EquipmentID = DDUD.Identifier FROM dbo.IMTD WITH (NOLOCK)
       INNER JOIN dbo.DDUD WITH (NOLOCK) ON IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
       WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Equipment'

           
      select @equipmentid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Equipment', @rectype, 'Y')
      
      select @costcodeid_lower=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CostCode', @rectype, 'Y')
             
       declare  @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @BatchTransType char, @Employee bEmployee,
        @PaySeq tinyint, @PostSeq smallint, @Type char, @DayNum smallint, @PostDate bDate, @JCCo bCompany,
        @Job bJob, @PhaseGroup bGroup, @Phase bPhase, @GLCo bCompany, @EMCo bCompany, @WO bWO, @WOItem bItem,
        @Equipment bEquip, @EMGroup bGroup, @CostCode bCostCode, @CompType varchar(10), @Component bEquip,
        @RevCode bRevCode, @EquipCType bJCCType, @UsageUnits bHrs, @TaxState VARCHAR(4), @LocalCode bLocalCode,
        @UnempState VARCHAR(4), @InsState VARCHAR(4), @InsCode bInsCode, @PRDept bDept, @Crew varchar(10), @Cert bYN,
        @Craft bCraft, @Class bClass, @EarnCode bEDLCode, @Shift tinyint, @Hours bHrs, @Rate bUnitCost, @Amt bDollar,
        @crafttemplate smallint, @PRGroup bGroup, @PREndDate bDate, @JobCraft bCraft, @RevBasis varchar(1),
    	@BeginDate bDate, @EmpShift tinyint, @CrewShift tinyint, @SMCo bCompany, @SMJCCostType bJCCType
    
       
       declare WorkEditCursor cursor local fast_forward for 
       select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
           from IMWE
               inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
           where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
           Order by IMWE.RecordSeq, IMWE.Identifier
       
       open WorkEditCursor
       -- set open cursor flag
     select @opencursor = 1
       
       declare @Recseq int, @Tablename varchar(20), @Column varchar(30), @Uploadval varchar(60), @Ident int,
                @seq int, @Identifier INT  /*  @importid varchar(10) */
       
       declare @currec int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
               @columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int
       
       declare @ctdesc varchar(60),@trackhours bYN, @costtypeout bJCCType, @retainpct bPct
       
       fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
       
       select @currec = @Recseq, @complete = 0, @counter = 1
       
       -- while cursor is not empty
       while @complete = 0
       
       begin
       
         if @@fetch_status <> 0
           select @Recseq = -1
       
           --if rec sequence = current rec sequence flag
         if @Recseq = @currec
           begin
       
        If @Column='Co' and isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
       	If @Column='Mth' and isdate(@Uploadval) =1 select @Mth = Convert( smalldatetime, @Uploadval)
       /*	If @Column='BatchSeq' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
       	If @Column='BatchTransType' select @BatchTransType = @Uploadval*/
       	If @Column='Employee' and isnumeric(@Uploadval) =1 select @Employee = Convert( int, @Uploadval)
       	If @Column='PRGroup' and isnumeric(@Uploadval) =1 select @PRGroup = Convert( int, @Uploadval)
       	If @Column='PREndDate' and isdate(@Uploadval) =1 select @PREndDate = Convert( smalldatetime, @Uploadval)
       	If @Column='PaySeq' select @PaySeq = @Uploadval
       	If @Column='PostSeq' select @PostSeq = @Uploadval
       	If @Column='Type' select @Type = @Uploadval
       	If @Column='DayNum' and isnumeric(@Uploadval) =1 select @DayNum = Convert( int, @Uploadval)
       	If @Column='PostDate' and isdate(@Uploadval) =1 select @PostDate = Convert( smalldatetime, @Uploadval)
        If @Column='JCCo' and  isnumeric(@Uploadval) =1 select @JCCo = @Uploadval
       	If @Column='Job' select @Job = @Uploadval
       	If @Column='PhaseGroup' and isnumeric(@Uploadval) = 1 select @PhaseGroup = convert(numeric,@Uploadval)
       	If @Column='Phase' select @Phase = @Uploadval
       	If @Column='GLCo' and isnumeric(@Uploadval) =1 select @GLCo = Convert(int, @Uploadval)
       	If @Column='EMCo' and isnumeric(@Uploadval) =1 select @EMCo = convert(numeric,@Uploadval)
       	If @Column='WO' select @WO = @Uploadval
        If @Column='WOItem' and  isnumeric(@Uploadval) =1 select @WOItem = convert(numeric,@Uploadval)
       	If @Column='Equipment' select @Equipment = @Uploadval
       	If @Column='EMGroup' and  isnumeric(@Uploadval) =1 select @EMGroup = convert(numeric,@Uploadval)
       	If @Column='CostCode' select @CostCode = @Uploadval
       	If @Column='CompType' select @CompType = @Uploadval
       	If @Column='Component' select @Component = @Uploadval
       	If @Column='RevCode' select @RevCode = @Uploadval
       	If @Column='EquipCType' and isnumeric(@Uploadval) =1 select @EquipCType = convert(tinyint,@Uploadval)
       	If @Column='UsageUnits' and  isnumeric(@Uploadval) =1 select @UsageUnits = convert(decimal(10,3),@Uploadval)
       	If @Column='TaxState' select @TaxState = @Uploadval
       	If @Column='LocalCode' select @LocalCode = @Uploadval
       	If @Column='UnempState' select @UnempState = @Uploadval
        If @Column='InsState' select @InsState = @Uploadval
       	If @Column='InsCode' select @InsCode = @Uploadval
       	If @Column='PRDept' select @PRDept = @Uploadval
       	If @Column='Crew' select @Crew = @Uploadval
       	If @Column='Cert' select @Cert = @Uploadval
       	If @Column='Craft' select @Craft = @Uploadval
       	If @Column='Class' select @Class = @Uploadval
       	If @Column='EarnCode' and isnumeric(@Uploadval) =1 select @EarnCode = convert(numeric,@Uploadval)
       	If @Column='Shift' and isnumeric(@Uploadval) =1 select @Shift = convert(numeric,@Uploadval)
       	If @Column='Hours' and isnumeric(@Uploadval) =1 select @Hours = convert(decimal(10,3),@Uploadval)
       	If @Column='Rate' and isnumeric(@Uploadval) =1 select @Rate = convert(decimal(10,5),@Uploadval)
       	If @Column='Amt' and isnumeric(@Uploadval) =1 select @Amt = convert(decimal(10,2),@Uploadval)
       	If @Column='SMCo' select @SMCo = @Uploadval
		If @Column='SMJCCostType' select @SMJCCostType = @Uploadval

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
		IF @Column='BatchTransType' 
			IF @Uploadval IS NULL
				SET @IsBatchTransTypeEmpty = 'Y'
			ELSE
				SET @IsBatchTransTypeEmpty = 'N'
		IF @Column='Employee' 
			IF @Uploadval IS NULL
				SET @IsEmployeeEmpty = 'Y'
			ELSE
				SET @IsEmployeeEmpty = 'N'
		IF @Column='PRGroup' 
			IF @Uploadval IS NULL
				SET @IsPRGroupEmpty = 'Y'
			ELSE
				SET @IsPRGroupEmpty = 'N'
		IF @Column='PREndDate' 
			IF @Uploadval IS NULL
				SET @IsPREndDateEmpty = 'Y'
			ELSE
				SET @IsPREndDateEmpty = 'N'
		IF @Column='PaySeq' 
			IF @Uploadval IS NULL
				SET @IsPaySeqEmpty = 'Y'
			ELSE
				SET @IsPaySeqEmpty = 'N'
		IF @Column='PostSeq' 
			IF @Uploadval IS NULL
				SET @IsPostSeqEmpty = 'Y'
			ELSE
				SET @IsPostSeqEmpty = 'N'
		IF @Column='Type' 
			IF @Uploadval IS NULL
				SET @IsTypeEmpty = 'Y'
			ELSE
				SET @IsTypeEmpty = 'N'
		IF @Column='DayNum' 
			IF @Uploadval IS NULL
				SET @IsDayNumEmpty = 'Y'
			ELSE
				SET @IsDayNumEmpty = 'N'
		IF @Column='PostDate' 
			IF @Uploadval IS NULL
				SET @IsPostDateEmpty = 'Y'
			ELSE
				SET @IsPostDateEmpty = 'N'
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
		IF @Column='GLCo' 
			IF @Uploadval IS NULL
				SET @IsGLCoEmpty = 'Y'
			ELSE
				SET @IsGLCoEmpty = 'N'
		IF @Column='EMCo' 
			IF @Uploadval IS NULL
				SET @IsEMCoEmpty = 'Y'
			ELSE
				SET @IsEMCoEmpty = 'N'
		IF @Column='WO' 
			IF @Uploadval IS NULL
				SET @IsWOEmpty = 'Y'
			ELSE
				SET @IsWOEmpty = 'N'
		IF @Column='WOItem' 
			IF @Uploadval IS NULL
				SET @IsWOItemEmpty = 'Y'
			ELSE
				SET @IsWOItemEmpty = 'N'
		IF @Column='Equipment' 
			IF @Uploadval IS NULL
				SET @IsEquipmentEmpty = 'Y'
			ELSE
				SET @IsEquipmentEmpty = 'N'
		IF @Column='EMGroup' 
			IF @Uploadval IS NULL
				SET @IsEMGroupEmpty = 'Y'
			ELSE
				SET @IsEMGroupEmpty = 'N'
		IF @Column='EquipPhase' 
			IF @Uploadval IS NULL
				SET @IsEquipPhaseEmpty = 'Y'
			ELSE
				SET @IsEquipPhaseEmpty = 'N'
		IF @Column='CostCode' 
			IF @Uploadval IS NULL
				SET @IsCostCodeEmpty = 'Y'
			ELSE
				SET @IsCostCodeEmpty = 'N'
		IF @Column='CompType' 
			IF @Uploadval IS NULL
				SET @IsCompTypeEmpty = 'Y'
			ELSE
				SET @IsCompTypeEmpty = 'N'
		IF @Column='Component' 
			IF @Uploadval IS NULL
				SET @IsComponentEmpty = 'Y'
			ELSE
				SET @IsComponentEmpty = 'N'
		IF @Column='RevCode' 
			IF @Uploadval IS NULL
				SET @IsRevCodeEmpty = 'Y'
			ELSE
				SET @IsRevCodeEmpty = 'N'
		IF @Column='EquipCType' 
			IF @Uploadval IS NULL
				SET @IsEquipCTypeEmpty = 'Y'
			ELSE
				SET @IsEquipCTypeEmpty = 'N'
		IF @Column='UsageUnits' 
			IF @Uploadval IS NULL
				SET @IsUsageUnitsEmpty = 'Y'
			ELSE
				SET @IsUsageUnitsEmpty = 'N'
		IF @Column='TaxState' 
			IF @Uploadval IS NULL
				SET @IsTaxStateEmpty = 'Y'
			ELSE
				SET @IsTaxStateEmpty = 'N'
		IF @Column='LocalCode' 
			IF @Uploadval IS NULL
				SET @IsLocalCodeEmpty = 'Y'
			ELSE
				SET @IsLocalCodeEmpty = 'N'
		IF @Column='UnempState' 
			IF @Uploadval IS NULL
				SET @IsUnempStateEmpty = 'Y'
			ELSE
				SET @IsUnempStateEmpty = 'N'
		IF @Column='InsState' 
			IF @Uploadval IS NULL
				SET @IsInsStateEmpty = 'Y'
			ELSE
				SET @IsInsStateEmpty = 'N'
		IF @Column='InsCode' 
			IF @Uploadval IS NULL
				SET @IsInsCodeEmpty = 'Y'
			ELSE
				SET @IsInsCodeEmpty = 'N'
		IF @Column='PRDept' 
			IF @Uploadval IS NULL
				SET @IsPRDeptEmpty = 'Y'
			ELSE
				SET @IsPRDeptEmpty = 'N'
		IF @Column='Crew' 
			IF @Uploadval IS NULL
				SET @IsCrewEmpty = 'Y'
			ELSE
				SET @IsCrewEmpty = 'N'
		IF @Column='Cert' 
			IF @Uploadval IS NULL
				SET @IsCertEmpty = 'Y'
			ELSE
				SET @IsCertEmpty = 'N'
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
		IF @Column='EarnCode' 
			IF @Uploadval IS NULL
				SET @IsEarnCodeEmpty = 'Y'
			ELSE
				SET @IsEarnCodeEmpty = 'N'
		IF @Column='Shift' 
			IF @Uploadval IS NULL
				SET @IsShiftEmpty = 'Y'
			ELSE
				SET @IsShiftEmpty = 'N'
		IF @Column='Hours' 
			IF @Uploadval IS NULL
				SET @IsHoursEmpty = 'Y'
			ELSE
				SET @IsHoursEmpty = 'N'
		IF @Column='Rate' 
			IF @Uploadval IS NULL
				SET @IsRateEmpty = 'Y'
			ELSE
				SET @IsRateEmpty = 'N'
		IF @Column='Amt' 
			IF @Uploadval IS NULL
				SET @IsAmtEmpty = 'Y'
			ELSE
				SET @IsAmtEmpty = 'N'
		IF @Column='Memo' 
			IF @Uploadval IS NULL
				SET @IsMemoEmpty = 'Y'
			ELSE
				SET @IsMemoEmpty = 'N'
		IF @Column='SMCo' 
			IF @Uploadval IS NULL
				SET @IsSMCoEmpty = 'Y'
			ELSE
				SET @IsSMCoEmpty = 'N'
		IF @Column='SMJCCostType' 
			IF @Uploadval IS NULL
				SET @IsSMJCCostTypeEmpty = 'Y'
			ELSE
				SET @IsSMJCCostTypeEmpty = 'N'
       
                  --fetch next record
       
               if @@fetch_status <> 0
                 select @complete = 1
       
               select @oldrecseq = @Recseq
       
       
               fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
       
           end
       
         else
       
           begin
	
            if @yncompany ='Y' AND (ISNULL(@OverwriteCo, 'Y') = 'Y' OR ISNULL(@IsCoEmpty, 'Y') = 'Y')
     		begin
    	 		select @Co = @Company
    	 		
    	 		UPDATE IMWE
    	 		SET IMWE.UploadVal = @Co
    	 		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @CompanyID
             end
     
    	 --start #23621
    	 	if @ynEMCo = 'Y' AND (ISNULL(@OverwriteEMCo, 'Y') = 'Y' OR ISNULL(@IsEMCoEmpty, 'Y') = 'Y')
    	 	begin
    	 		select @EMCo = EMCo from bPRCO where PRCo = @Co
    	 
    	 		UPDATE IMWE
    	 		SET IMWE.UploadVal = @EMCo
    	 		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @EMCoID
    	 	end
    	 	
    	 	if @ynEquipPhase = 'Y' and isnull(@Equipment,'') <> '' AND (ISNULL(@OverwriteEquipPhase, 'Y') = 'Y' OR ISNULL(@IsEquipPhaseEmpty, 'Y') = 'Y')--fix 02/04/04, do not default if no equipment.
    	 	begin
    	 		if isnull(@Phase,'') <> ''
    	 		begin
    	 			UPDATE IMWE
    	 			SET IMWE.UploadVal = @Phase
    	 			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @EquipPhaseID
    	 		end
    	 	end
    	 --end #23621
     
            if @ynprgroup ='Y'  and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwritePRGroup, 'Y') = 'Y' OR ISNULL(@IsPRGroupEmpty, 'Y') = 'Y')
        	  begin
              exec @rcode = bspIMPRTB_PRGROUP @Co, @Employee, @PRGroup output,  @desc output
    
    		  if @rcode <> 0
    		  begin
    			select @finalrcode = @rcode
    
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@PRGroupID)
    		  end
       
              UPDATE IMWE
              SET IMWE.UploadVal = @PRGroup
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
			and IMWE.Identifier = @PRGroupID
             end
       
			----Issue #138549 - Because GLCo default might be based upon Type, EMCo (defaulted above) or JCC0/Job (defaulted below)
			----I have moved this code down below the JCCo default below.
   --         if @ynglco ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
   --     	  begin
        	  
   --           exec @rcode = bspIMPRTB_GLCO @Co, @JCCo, @Phase, @GLCo output, @desc output
       
   -- 		  if @rcode <> 0
   -- 		  begin
   -- 			select @finalrcode = @rcode
    
   -- 			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
   -- 			 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@GLCoID)
   -- 		  end
    
   --           UPDATE IMWE
   --           SET IMWE.UploadVal = @GLCo
   --           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
   -- 			and IMWE.Identifier = @GLCoID
   --          end
       
            if @ynprenddate ='Y' and isnull(@Co,'')<>'' and isnull(@PRGroup,'') <> '' AND (ISNULL(@OverwritePREndDate, 'Y') = 'Y' OR ISNULL(@IsPREndDateEmpty, 'Y') = 'Y')
        	begin
    			exec @rcode = bspIMPRTB_PRENDDATE @Co, @PRGroup, @PREndDate output,  @desc output
    			
    			if @rcode <> 0
    			begin
    			select @finalrcode = @rcode
    			
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@PREndDateID)
    			end
    			
    			UPDATE IMWE
    			SET IMWE.UploadVal = @PREndDate
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
    				IMWE.RecordSeq=@currec and IMWE.Identifier = @PREndDateID
            end
    
    		--issue #24799
    		if @yndaynum = 'Y' and isnull(@PREndDate,'') <> '' and isnull(@PostDate,'') <> '' AND (ISNULL(@OverwriteDayNum, 'Y') = 'Y' OR ISNULL(@IsDayNumEmpty, 'Y') = 'Y')
    		begin
    			select @BeginDate = BeginDate from PRPC 
    				where PRCo = @Co and PRGroup = @PRGroup and PREndDate = @PREndDate
    			select @DayNum = DateDiff(d, @BeginDate, @PostDate) + 1
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = convert(varchar(3),@DayNum)
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
    				IMWE.RecordSeq=@currec and IMWE.Identifier = @daynumid
    		end
    
    		--issue #24799, modified for issue #25652
    		if @ynPostDate = 'Y' and @DayNum is not null AND (ISNULL(@OverwritePostDate, 'Y') = 'Y' OR ISNULL(@IsPostDateEmpty, 'Y') = 'Y')
    		begin
    			select @BeginDate = BeginDate from PRPC 
    				where PRCo = @Co and PRGroup = @PRGroup and PREndDate = @PREndDate
    
    			select @PostDate = DateAdd(d, @DayNum - 1, @BeginDate)
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @PostDate
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
    			IMWE.RecordSeq=@currec and IMWE.Identifier = @PostDateID
    			
 
    			if @yndaynum = 'Y'
    			begin
    				select @finalrcode = 1
    				select @desc = 'Warning: PostDate and DayNum should not use Viewpoint Defaults simultaneously.'
    
    				insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    				 values(@ImportId,@ImportTemplate,@Form,@currec,@finalrcode,@desc,@PostDateID)
    			end
    
    		end
    
    
    	   	if isnull(@jccoid,0)<>0
        	  begin
              select @JCCo=JCCo from bPRCO where PRCo=@Co
       
              UPDATE IMWE
              SET IMWE.UploadVal = @JCCo
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
    				IMWE.RecordSeq=@currec and IMWE.Identifier = @jccoid
             end
       
    		--#24429, corrected to use @JCCo
    		--#24469, moved to be after JCCo retrieval (duh!)
    	   	if @ynphasegroup ='Y' and isnull(@JCCo,'') <> '' AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')
    	    begin
    			exec @rcode = bspJCPhaseGrpGet @JCCo, @PhaseGroup output, @desc output
    			
    			  if @rcode <> 0
    			  begin
    				select @finalrcode = @rcode
    	
    				insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    				 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@PhaseGroupID)
    			  end
    	
    			UPDATE IMWE
    			SET IMWE.UploadVal = @PhaseGroup
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
    				IMWE.RecordSeq=@currec and IMWE.Identifier = @PhaseGroupID
    	    end
 
			--Issue #138549 - GLCo default might be based upon Type, EMCo (defaulted above) or JCC0 (defaulted above)
			--By now Type, EMCo, and JCCo has either been imported or defaults have been set above. Either way they have 
			--now been placed into the appropriate variables.  We can now pass them into a procedure to determine the correct GLCo default.
			if @ynglco ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
				begin
				exec @rcode = bspIMPRTB_GLCO @Co, @Employee, @JCCo, @Job, @Phase, @EMCo, @Type, @GLCo output, @desc output
				if @rcode <> 0
					begin
					select @finalrcode = @rcode

					insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
					values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@GLCoID)
					end

				UPDATE IMWE
				SET IMWE.UploadVal = @GLCo
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
					and IMWE.Identifier = @GLCoID
				end

--			If @Type = 'J'
--				begin
				select @crafttemplate = null
				if @JCCo is not null and @Job is not null
         			begin
     	            select @crafttemplate=CraftTemplate
     	  	        from bJCJM  with (nolock) where JCCo=@JCCo and Job=@Job
     				end
--				end
    
		--#24429, corrected to use @EMCo
       	if @ynemgroup ='Y' and isnull(@EMCo,'') <> '' AND (ISNULL(@OverwriteEMGroup, 'Y') = 'Y' OR ISNULL(@IsEMGroupEmpty, 'Y') = 'Y')
        	  begin
              exec @rcode = bspEMGroupGet @EMCo, @EMGroup output, @desc output
       
    		  if @rcode <> 0
    		  begin
    			select @finalrcode = @rcode
    
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@EMGroupID)
    		  end
    
              UPDATE IMWE
              SET IMWE.UploadVal = @EMGroup
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @EMGroupID
             end
 
		--Issue #138524, Add Work Office TaxState and LocalCode to PR Employee
       	if @yntaxstate ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwriteTaxState, 'Y') = 'Y' OR ISNULL(@IsTaxStateEmpty, 'Y') = 'Y')
			begin
			--exec @rcode = bspIMPRTB_TAXSTATE @Co, @Employee, @JCCo, @Job, @TaxState output, @desc output
			exec @rcode = vspPRGetStateLocalIMDflts @Co, @Employee, @JCCo, @Job, @LocalCode output, @TaxState output,
				@UnempState output, @InsState output, @desc output
			if @rcode <> 0
    			begin
    			select @finalrcode = @rcode
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@TaxStateID)
    			end
    
			UPDATE IMWE
			SET IMWE.UploadVal = @TaxState
        	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @TaxStateID
			end

		--Issue #138524, Add Work Office TaxState and LocalCode to PR Employee       
       	if @ynlocalcode ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwriteLocalCode, 'Y') = 'Y' OR ISNULL(@IsLocalCodeEmpty, 'Y') = 'Y')
			begin
			--exec @rcode = bspIMPRTB_LOCALCODE @Co, @Employee, @JCCo, @Job, @LocalCode output, @desc output
			exec @rcode = vspPRGetStateLocalIMDflts @Co, @Employee, @JCCo, @Job, @LocalCode output, @TaxState output,
				@UnempState output, @InsState output, @desc output       
    		if @rcode <> 0
    			begin
    			select @finalrcode = @rcode
     			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@LocalCodeID)
    			end
    
			UPDATE IMWE
			SET IMWE.UploadVal = @LocalCode
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @LocalCodeID
			end
 
  		--Issue #138524, Add Work Office TaxState and LocalCode to PR Employee     
       	if @ynunempstate ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwriteUnempState, 'Y') = 'Y' OR ISNULL(@IsUnempStateEmpty, 'Y') = 'Y')
			begin
			--exec @rcode = bspIMPRTB_UNEMPSTATE @Co, @Employee, @JCCo, @Job, @UnempState output, @desc output
			exec @rcode = vspPRGetStateLocalIMDflts @Co, @Employee, @JCCo, @Job, @LocalCode output, @TaxState output,
				@UnempState output, @InsState output, @desc output        
    		if @rcode <> 0
    			begin
    			select @finalrcode = @rcode
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@UnempStateID)
    			end
    
			UPDATE IMWE
			SET IMWE.UploadVal = @UnempState
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @UnempStateID
			end

  		--Issue #138524, Add Work Office TaxState and LocalCode to PR Employee      
		if @yninsstate ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwriteInsState, 'Y') = 'Y' OR ISNULL(@IsInsStateEmpty, 'Y') = 'Y')
			begin
			--exec @rcode = bspIMPRTB_INSSTATE @Co, @Employee, @JCCo, @Job, @InsState output, @desc output
			exec @rcode = vspPRGetStateLocalIMDflts @Co, @Employee, @JCCo, @Job, @LocalCode output, @TaxState output,
				@UnempState output, @InsState output, @desc output         
    		if @rcode <> 0
    			begin
    			select @finalrcode = @rcode
     			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@InsStateID)
    			end
    
			UPDATE IMWE
			SET IMWE.UploadVal = @InsState
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @InsStateID
			end
 
		if @ynprdept ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwritePRDept, 'Y') = 'Y' OR ISNULL(@IsPRDeptEmpty, 'Y') = 'Y')
        	  begin
              exec @rcode = bspIMPRTB_PRDEPT @Co, @Employee, @PRDept output,  @desc output
    
    		  if @rcode <> 0
    		  begin
    			select @finalrcode = @rcode
    
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@PRDeptID)
    		  end
    
              UPDATE IMWE
              SET IMWE.UploadVal = @PRDept
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @PRDeptID
           end
       
            if @yncrew ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwriteCrew, 'Y') = 'Y' OR ISNULL(@IsCrewEmpty, 'Y') = 'Y')
        	  begin
              exec @rcode = bspIMPRTB_CREW @Co, @Employee, @Crew output,  @desc output
       
    		  if @rcode <> 0
    		  begin
    			select @finalrcode = @rcode
    
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@CrewID)
    		  end
    
              UPDATE IMWE
            SET IMWE.UploadVal = @Crew
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @CrewID
             end
       
   		--Issue #28884
   		if @ynshift = 'Y' AND (ISNULL(@OverwriteShift, 'Y') = 'Y' OR ISNULL(@IsShiftEmpty, 'Y') = 'Y')
   		begin
   			exec @rcode = bspPREmployeeInfoGet @Co, @Employee, null, null, null, null, null, null, null, null, null, 
   						null, null, null, null, null, null, null, null, null, null, @EmpShift output, @desc output
   			if @rcode <> 0
   			begin
   				insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
   				values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@ShiftID)
   			end
   
			if isnull(@Crew,'') <> '' 
			begin
   			exec @rcode = bspPRCrewValForTimeCards @Co, @Crew, @CrewShift output, @desc output
   				if @rcode <> 0
   				begin
   					insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
   					values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@ShiftID)
   				end
			end

   			if @Crew is not null and @CrewShift is not null
   				select @Shift = @CrewShift
   			else if @EmpShift is not null
   				select @Shift = @EmpShift
   			else
   				select @Shift = 1
   
   			UPDATE IMWE
   			SET IMWE.UploadVal = @Shift
   			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @ShiftID
   		end
   
        if @yncert ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwriteCert, 'Y') = 'Y' OR ISNULL(@IsCertEmpty, 'Y') = 'Y')
        	  begin
              exec @rcode = bspIMPRTB_CERT @Co, @Employee, @Cert output,  @desc output
       
    		  if @rcode <> 0
    		  begin
    			select @finalrcode = @rcode
    
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@CertID)
    		  end
    
              UPDATE IMWE
              SET IMWE.UploadVal = @Cert
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @CertID
             end
       
            if @yncraft ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwriteCraft, 'Y') = 'Y' OR ISNULL(@IsCraftEmpty, 'Y') = 'Y')
    
        	  begin
              exec @rcode = bspIMPRTB_CRAFT @Co, @Employee, @Craft output,  @desc output
       
    		  if @rcode <> 0
    		  begin
    			select @finalrcode = @rcode
    
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@CraftID)
    		  end
    
              if @Type = 'J' and isnull(@crafttemplate,'') <> '' and isnull(@Craft,'') <> ''
                 begin
                   exec @rcode = bspPRJobCraftDflt @Co, @Craft, @crafttemplate, @JobCraft output, @desc output
    				  if @rcode <> 0
    				  begin
    					select @finalrcode = @rcode
    		
    					insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    					 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@CraftID)
    				  end
    		
                   if isnull(@JobCraft,'') <> '' select @Craft = @JobCraft
                 end
       
              UPDATE IMWE
              SET IMWE.UploadVal = @Craft
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @CraftID
             end
       
            if @ynclass ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwriteClass, 'Y') = 'Y' OR ISNULL(@IsClassEmpty, 'Y') = 'Y')
        	  begin
              exec @rcode = bspIMPRTB_CLASS @Co, @Employee, @Class output,  @desc output
       
    		  if @rcode <> 0
    		  begin
    			select @finalrcode = @rcode
    
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@ClassID)
  		  end

              UPDATE IMWE
              SET IMWE.UploadVal = @Class
    where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @ClassID
             end
       
            if @ynearncode ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwriteEarnCode, 'Y') = 'Y' OR ISNULL(@IsEarnCodeEmpty, 'Y') = 'Y')
        	  begin
              exec @rcode = bspIMPRTB_EARNCODE @Co, @Employee, @EarnCode output,  @desc output
       
    		  if @rcode <> 0
    		  begin
    			select @finalrcode = @rcode
    
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@EarnCodeID)
    		  end
    
              UPDATE IMWE
              SET IMWE.UploadVal = @EarnCode
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @EarnCodeID
             end
       
			--Issue #128151
			--Issue #140781, Add @EmplRate to this process so as not to interfere with @Rate that has been imported.
			DECLARE @TempRate bUnitCost, @EmplRate bUnitCost, @EarnMethod CHAR(1), @IsDistributedEarnings bYN
			IF ISNULL(@EarnCode, '') <> '' AND ISNULL(@Co, '') <> ''
				SELECT @EarnMethod = Method, @IsDistributedEarnings = IncldSalaryDist FROM PREC WHERE EarnCode = @EarnCode AND PRCo = @Co

			If isnull(@Rate,0) = 0 select @Rate = 0

			if @ynrate ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwriteRate, 'Y') = 'Y' OR ISNULL(@IsRateEmpty, 'Y') = 'Y')
			  begin

			  exec @rcode = bspPRRateDefault @Co, @Employee, @PostDate, @Craft, @Class, @crafttemplate, @Shift, @EarnCode, @EmplRate output,  @desc output		 

			  if @rcode <> 0
			  begin
				select @finalrcode = @rcode

				insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
				 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@RateID)
			  end

			  If @EmplRate is null select @EmplRate = 0
			  --Issue #128151
				DECLARE @TempAmt bDollar
				IF ISNULL(@EarnMethod, '') = 'A'
					BEGIN
						SELECT @TempRate = 0, @TempAmt = 0
						EXEC bspIMPRTB_AMT @Co, @Employee, @EarnCode, @Hours, @PRGroup, @PREndDate, @TempRate output, @TempAmt output,  @desc output
					END
				ELSE
					SELECT @TempRate = @EmplRate 

			  UPDATE IMWE
			  SET IMWE.UploadVal = @TempRate
			  where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
				and IMWE.Identifier = @RateID
			 --End #128151
			 end
       
            if (@ynamt ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' and isnull(@EarnCode,'') <> '' AND (ISNULL(@OverwriteAmt, 'Y') = 'Y' OR ISNULL(@IsAmtEmpty, 'Y') = 'Y')) or @Amt is null
         	  begin
         	  select @TempRate = case when isnull(@TempRate,0) = 0 and isnull(@Rate,0) <> 0 then @Rate else @TempRate end
              exec @rcode = bspIMPRTB_AMT @Co, @Employee, @EarnCode, @Hours, @PRGroup, @PREndDate, @TempRate output, @Amt output,  @desc output
       
    		  if @rcode <> 0
    		  begin
    			select @finalrcode = @rcode
    
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@AmtID)
    		  end
    
              If isnull(@Amt,0) = 0 select @Amt = 0
       
              UPDATE IMWE
              SET IMWE.UploadVal = @Amt
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @AmtID
             end

            if @yninscode ='Y' and isnull(@Co,'') <> '' and isnull(@Employee,'') <> '' AND (ISNULL(@OverwriteInsCode, 'Y') = 'Y' OR ISNULL(@IsInsCodeEmpty, 'Y') = 'Y')
        	  begin
              exec @rcode = bspIMPRTB_INSCODE @Co, @Employee, @JCCo, @Job, @Phase, @PhaseGroup, @InsCode output, @InsState, @Rate, @desc output
       
    		  if @rcode <> 0
    		  begin
    			select @finalrcode = @rcode
    
    			insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    			 values(@ImportId,@ImportTemplate,@Form,@currec,null,@desc,@InsCodeID)
    		  end
    
            UPDATE IMWE
  SET IMWE.UploadVal = @InsCode
     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec 
    			and IMWE.Identifier = @InsCodeID
             end
       
            if @ynRevCode ='Y' and isnull(@EMCo,'') <> '' and isnull(@Equipment,'') <> '' and @Type = 'J' AND (ISNULL(@OverwriteRevCode, 'Y') = 'Y' OR ISNULL(@IsRevCodeEmpty, 'Y') = 'Y')
        	  begin
              select @RevCode = RevenueCode
              from bEMEM with (nolock)
              where EMCo = @EMCo and Equipment = @Equipment
       
              UPDATE IMWE
              SET IMWE.UploadVal = @RevCode
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @RevCodeID
             end
       
    	 --#23621 RevCode needed to get RevCodeBasis, and if 'H' then default usage units
    	 --fix 02/04/04, only default if equipment exists.
	if @ynUsageUnits = 'Y' and isnull(@Equipment,'') <> '' AND (ISNULL(@OverwriteUsageUnits, 'Y') = 'Y' OR ISNULL(@IsUsageUnitsEmpty, 'Y') = 'Y')
	begin
    	select @RevBasis = Basis from EMRC
    	where EMGroup = @EMGroup and RevCode = @RevCode
    	 	
		if @RevBasis = 'H'
    	 			select @UsageUnits = @Hours
    	 		else
    	 			select @UsageUnits = 0
    	 	
    	 		UPDATE IMWE
    	 		SET IMWE.UploadVal = @UsageUnits
    	 		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @UsageUnitsID
		end
     
		if @ynequipctype ='Y' and isnull(@EMCo,'') <> '' and isnull(@Equipment,'') <> '' and @Type = 'J'  AND (ISNULL(@OverwriteEquipCType, 'Y') = 'Y' OR ISNULL(@IsEquipCTypeEmpty, 'Y') = 'Y')
		begin
              select @EquipCType = UsageCostType
              from bEMEM with (nolock)
              where EMCo = @EMCo and Equipment = @Equipment
       
              UPDATE IMWE
              SET IMWE.UploadVal = @EquipCType
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @EquipCTypeID
		end
      
		if @equipmentid<>0 and isnull(@WO,'') <> '' AND (ISNULL(@OverwriteEquipment, 'Y') = 'Y' OR ISNULL(@IsEquipmentEmpty, 'Y') = 'Y')
		begin
      		select @Equipment = Equipment
      		from bEMWH with (nolock)
      		where EMCo = @EMCo and WorkOrder = @WO
      
              UPDATE IMWE
              SET IMWE.UploadVal = @Equipment
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @equipmentid
		end
      
        if @costcodeid_lower<>0 and isnull(@WO,'') <> '' and isnull(@WOItem,'') <> '' AND (ISNULL(@OverwriteCostCode, 'Y') = 'Y' OR ISNULL(@IsCostCodeEmpty, 'Y') = 'Y')
        begin
      		select @CostCode = CostCode
      		from bEMWI with (nolock)
      		where EMCo = @EMCo and WorkOrder = @WO and WOItem = @WOItem
      
              UPDATE IMWE
              SET IMWE.UploadVal = @CostCode
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @costcodeid_lower
        end
       
        if isnull(@RevCode,'') <> '' and isnull(@Equipment,'') = '' 
        begin
              -- null out  @RevCode
              UPDATE IMWE
              SET IMWE.UploadVal = null
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and

              (IMWE.Identifier = @RevCodeID)
        end
       
        if isnull(@Job,'') = '' or isnull(@Equipment,'') = ''
        begin
              -- null out  @EquipCTypeID
              UPDATE IMWE
              SET IMWE.UploadVal = null
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and
              (IMWE.Identifier = @EquipCTypeID)
        end

		if @ynSMCo ='Y' AND (ISNULL(@OverwriteSMCo, 'Y') = 'Y' OR ISNULL(@IsSMCoEmpty, 'Y') = 'Y')
     	begin
    	 	select @SMCo = SMCo from PRCO where PRCo = @Co
    	 		
    	 	UPDATE IMWE
    	 	SET IMWE.UploadVal = @SMCo
    	 	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @SMCoID
		end

		if @ynSMJCCostType ='Y' and isnull(@SMCo,'') <> '' AND (ISNULL(@OverwriteSMJCCostType, 'Y') = 'Y' OR ISNULL(@IsSMJCCostTypeEmpty, 'Y') = 'Y')
		BEGIN

			declare @SMPayType varchar(10), @SMCostType smallint

			select @SMPayType = IMWE.UploadVal from IMWE where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @SMPayTypeID
			select @SMCostType = IMWE.UploadVal from IMWE where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @SMCostTypeID

			if @SMPayType is not null and @SMCostType is not null 
			begin
				EXEC @rcode = vspSMJCCostTypeDefaultVal @SMCo = @SMCo, @Job = @Job, @LineType = 2, @PayType = @SMPayType, @SMCostType = @SMCostType, @JCCostType = @SMJCCostType OUTPUT, @msg = @msg OUTPUT
			end
			else
			begin			
				EXEC @rcode = vspSMPayTypeVal @SMCo = @SMCo, @PayType = @SMPayType, @EarnCode = @SMJCCostType OUTPUT, @Msg = @msg OUTPUT
			end
			
			IF @rcode <> 0
			BEGIN
				UPDATE IMWE
    	 		SET IMWE.UploadVal = null
    	 		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @SMJCCostTypeID
			END
			ELSE
			BEGIN
				UPDATE IMWE
    	 		SET IMWE.UploadVal = @SMJCCostType
    	 		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @SMJCCostTypeID
			END
		END
 
        IF @Type = 'J' 
        BEGIN
        -- null out WO, WOItem, CostCode, CompType, Component
              UPDATE IMWE
              SET IMWE.UploadVal = NULL
              WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currec AND
				  (IMWE.Identifier = @WOID OR IMWE.Identifier = @WOItemID OR IMWE.Identifier = @CostCodeID OR
   				   IMWE.Identifier = @CompTypeID OR IMWE.Identifier = @ComponentID OR
   				   IMWE.Identifier = @SMCoID OR IMWE.Identifier = @SMWorkOrderID OR IMWE.Identifier = @SMScopeID OR 
   				   IMWE.Identifier = @SMPayTypeID OR IMWE.Identifier = @SMCostTypeID OR IMWE.Identifier = @SMJCCostTypeID)

        END
       
        IF @Type = 'M' 
        BEGIN
              -- null out  PhaseGroup, Phase, RevCode, EquipCType, UsageUnits, EquipPhase
              UPDATE IMWE
			  SET IMWE.UploadVal = NULL
              WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currec AND
				  (IMWE.Identifier = @PhaseGroupID OR IMWE.Identifier = @PhaseID OR IMWE.Identifier = @RevCodeID OR
    			   IMWE.Identifier = @EquipCTypeID OR IMWE.Identifier = @UsageUnitsID OR IMWE.Identifier = @EquipPhaseID OR
   				   IMWE.Identifier = @SMCoID OR IMWE.Identifier = @SMWorkOrderID OR IMWE.Identifier = @SMScopeID OR 
   				   IMWE.Identifier = @SMPayTypeID OR IMWE.Identifier = @SMCostTypeID OR IMWE.Identifier = @SMJCCostTypeID)
        END

		IF @Type = 'S'
		BEGIN

			if @ynSMCo ='Y' AND (ISNULL(@OverwriteSMCo, 'Y') = 'Y' OR ISNULL(@IsSMCoEmpty, 'Y') = 'Y')
     		begin
    	 		select @SMCo = SMCo from PRCO where PRCo = @Co
    	 		
    	 		UPDATE IMWE
    	 		SET IMWE.UploadVal = @SMCo
    	 		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @SMCoID
			end

			select @JCCo = JCCo, @Job = Job from SMWorkOrder where SMCo = @SMCo and WorkOrder =
				(select IMWE.UploadVal from IMWE where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @SMWorkOrderID)

			UPDATE IMWE
    	 	SET IMWE.UploadVal = @JCCo
    	 	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @JCCoID

			UPDATE IMWE
    	 	SET IMWE.UploadVal = @Job
    	 	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currec and IMWE.Identifier = @JobID
        
			--Add SM code below to null out unneeded field values		
			IF ISNULL(@Employee,'') <> ''
			BEGIN
				EXEC @rcode = bspIMPRTB_SMTECHNICIAN @Co, @Employee, @SMCo, @desc output

				IF @rcode <> 0
				BEGIN
					INSERT INTO IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
					VALUES(@ImportId,@ImportTemplate,@Form,@currec,@rcode,@desc,@Employee)
					
					UPDATE IMWE
					SET IMWE.UploadVal = NULL
					WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currec 
					  AND IMWE.Identifier = @EmployeeID
				END

			END
			
			UPDATE IMWE
			SET IMWE.UploadVal = NULL
			WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currec 
			  AND (IMWE.Identifier = @CrewID OR --IMWE.Identifier = @JCCoID OR IMWE.Identifier = @JobID OR 
			  IMWE.Identifier = @WOID OR IMWE.Identifier = @WOItemID OR IMWE.Identifier = @EquipmentID OR 
			  IMWE.Identifier = @CostCodeID OR IMWE.Identifier = @CompTypeID OR IMWE.Identifier = @EMCoID OR
			  IMWE.Identifier = @EquipPhaseID OR IMWE.Identifier = @EquipCTypeID OR IMWE.Identifier = @RevCodeID OR
			  IMWE.Identifier = @UsageUnitsID OR IMWE.Identifier = @ComponentID OR IMWE.Identifier = @PhaseID)
		END
  
		select @currec = @Recseq
		select @counter = @counter + 1
		select @Co = null, @Mth = null, @BatchId = null, @BatchSeq = null, @BatchTransType = null, @Employee = null,
		@PaySeq = null, @PostSeq = null, @Type = null, @DayNum = null, @PostDate = null, @JCCo = null,
		@Job = null, @PhaseGroup = null, @Phase = null, @GLCo = null, @EMCo = null, @WO = null, @WOItem = null,
		@Equipment = null, @EMGroup = null, @CostCode = null, @CompType = null, @Component = null,
		@RevCode = null, @EquipCType = null, @UsageUnits = null, @TaxState = null, @LocalCode = null,
		@UnempState = null, @InsState = null, @InsCode = null, @PRDept = null, @Crew = null, @Cert = null,
		@Craft = null, @Class = null, @EarnCode = null, @Shift = null, @Hours = null, @Rate = null, @Amt = null,
		@crafttemplate = null, @PRGroup = null, @PREndDate = null, @JobCraft = null, @EmpShift = null, @CrewShift = null,
		@EMCategory = null, @TempAmt = null, @TempRate = null, @SMCo = null, @SMJCCostType = null
	end

end
       
       
       
       bspexit:
       If @opencursor =1
          begin
          close WorkEditCursor
          deallocate WorkEditCursor
          end
           select @msg = isnull(@desc,'TimeCards') + char(13) + char(10) + '[bspBidtekDefaultPRTB]'
       
           return @finalrcode






GO

GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsPRTB] TO [public]
GO
