SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsPRED]
/***********************************************************
* CREATED BY:   DANF 08/23/2006
* MODIFIED BY:  CC	02/18/2009	- #24531 - Use default only if set to overwrite or value is null
*				EN	11/06/2009	- #135039 removed code to default EICStatus to 'S' ... it should default to null
*				CHS	11/29/2010	- #139723 - add column MiscAmt2
*				AMR 01/12/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
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
 declare @AuditYNID int, @SubjectAmtID int, @EligibleAmtID int
 
 declare @PRCoID int, @EmplBasedYNID int, @OverMiscAmtYNID int, @OverCalcsID int,
		 @OverLimitYNID int, @NetPayOptYNID int, @AddonTypeID int,
		 @VendorGroupID int, @CSMedCovID int, @GLCoID int,
		 @EICStatusID int, @CSAllocYNID int, @cMiscAmtID int, @cMiscAmt2ID int,  --#139723
		 @cOverMiscAmtID int,
		 @cEmplBasedYNID int, @cOverCalcsID int, @cNetPayOptYNID int,
		 @cOverLimitID int, @cAddonTypeID int, @cCSAllocYNID int, @cFileStatusID int,
		 @cFrequency int, @cProcessSeq int, @cOverGLAcct int, @cEICStatus int,
		 @cVendor int, @cAPDesc int, @cCSMedCov int, @cCSFipsCode int,
		 @cCSCaseId int, @cCSAllocGroup int, @cFileStatus int, @cRegExempts int,
		 @cAddExempts int, @cOverMiscAmt int, @cMiscAmt int, @cMiscAmt2 int,  --#139723
		 @cMiscFactor int,
		 @cRateAmt int, @cLimit int, @cLimitRate int, @cNetPayOpt int, 
		 @cMinNetPay int, @cAddonRateAmt int



 declare @ynVendorGroup bYN, @ynGLCo bYN

 
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
			  @OverwritePRCo 	 		 bYN
			, @OverwriteEmplBased 	 	 bYN
			, @OverwriteOverMiscAmt 	 bYN
			, @OverwriteOverMiscAmt2 	 bYN --#139723
			, @OverwriteOverCalcs 	 	 bYN
			, @OverwriteOverLimit 	 	 bYN
			, @OverwriteNetPayOpt 	 	 bYN
			, @OverwriteAddonType 	 	 bYN
			, @OverwriteVendorGroup 	 bYN
			, @OverwriteCSMedCov 	 	 bYN
			, @OverwriteGLCo 	 		 bYN
			, @OverwriteEICStatus 	 	 bYN
			, @OverwriteCSAllocYN 	 	 bYN
			,	@IsPRCoEmpty 			bYN
			,	@IsEmployeeEmpty 		bYN
			,	@IsDLCodeEmpty 		 	bYN
			,	@IsEmplBasedEmpty 	 	bYN
			,	@IsFrequencyEmpty 	 	bYN
			,	@IsProcessSeqEmpty 	 	bYN
			,	@IsFileStatusEmpty 	 	bYN
			,	@IsRegExemptsEmpty 	 	bYN
			,	@IsAddExemptsEmpty 	 	bYN
			,	@IsOverMiscAmtEmpty 	bYN
			,	@IsMiscAmtEmpty 		bYN
			,	@IsMiscAmt2Empty 		bYN	 --#139723		
			,	@IsMiscFactorEmpty 	 	bYN
			,	@IsOverCalcsEmpty 	 	bYN
			,	@IsRateAmtEmpty 		bYN
			,	@IsOverLimitEmpty 	 	bYN
			,	@IsLimitEmpty 		 	bYN
			,	@IsLimitRateEmpty 	 	bYN
			,	@IsNetPayOptEmpty 	 	bYN
			,	@IsMinNetPayEmpty 	 	bYN
			,	@IsAddonTypeEmpty 	 	bYN
			,	@IsAddonRateAmtEmpty 	bYN
			,	@IsVendorGroupEmpty 	bYN
			,	@IsVendorEmpty 		 	bYN
			,	@IsAPDescEmpty 		 	bYN
			,	@IsCSCaseIdEmpty 		bYN
			,	@IsCSFipsCodeEmpty 		bYN
			,	@IsCSMedCovEmpty 		bYN
			,	@IsGLCoEmpty 			bYN
			,	@IsOverGLAcctEmpty 	 	bYN
			,	@IsEICStatusEmpty 	 	bYN
			,	@IsCSAllocYNEmpty 	 	bYN
			,	@IsCSAllocGroupEmpty 	bYN
			,	@IsNotesEmpty 			bYN


	SELECT @OverwritePRCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRCo', @rectype);
	SELECT @OverwriteEmplBased = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EmplBased', @rectype);
	SELECT @OverwriteOverMiscAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OverMiscAmt', @rectype);
	SELECT @OverwriteOverCalcs = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OverCalcs', @rectype);
	SELECT @OverwriteOverLimit = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OverLimit', @rectype);
	SELECT @OverwriteNetPayOpt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'NetPayOpt', @rectype);
	SELECT @OverwriteAddonType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AddonType', @rectype);
	SELECT @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype);
	SELECT @OverwriteCSMedCov = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CSMedCov', @rectype);
	SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
	SELECT @OverwriteEICStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EICStatus', @rectype);
	SELECT @OverwriteCSAllocYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CSAllocYN', @rectype);

 
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
 

  select @EmplBasedYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EmplBased', @rectype, 'Y')
  if @EmplBasedYNID <> 0  AND (ISNULL(@OverwriteEmplBased, 'Y') = 'Y') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @EmplBasedYNID
	end
 
  select @OverMiscAmtYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OverMiscAmt', @rectype, 'Y')
  if @OverMiscAmtYNID <> 0  AND (ISNULL(@OverwriteOverMiscAmt, 'Y') = 'Y') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @OverMiscAmtYNID
	end

  select @OverCalcsID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OverCalcs', @rectype, 'Y')
  if @OverCalcsID<> 0  AND (ISNULL(@OverwriteOverCalcs, 'Y') = 'Y') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @OverCalcsID
	end

  select @OverLimitYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OverLimit', @rectype, 'Y')
  if @OverLimitYNID <> 0  AND (ISNULL(@OverwriteOverLimit, 'Y') = 'Y') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @OverLimitYNID
	end
 
   select @NetPayOptYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'NetPayOpt', @rectype, 'Y')
  if @NetPayOptYNID <> 0  AND (ISNULL(@OverwriteNetPayOpt, 'Y') = 'Y') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @NetPayOptYNID
	end

   select @AddonTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AddonType', @rectype, 'Y')
   if @AddonTypeID <> 0  AND (ISNULL(@OverwriteAddonType, 'Y') = 'Y') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @AddonTypeID
	end

   set @ynVendorGroup = 'N'
   select @VendorGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'Y')
   if @VendorGroupID <> 0 select @ynVendorGroup = 'Y'

   select @CSMedCovID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CSMedCov', @rectype, 'Y')
   if @CSMedCovID <> 0  AND (ISNULL(@OverwriteCSMedCov, 'Y') = 'Y') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @CSMedCovID
	end

   set @ynGLCo = 'N'
   select @GLCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLCo', @rectype, 'Y')
   if @GLCoID <> 0 select @ynGLCo = 'Y'

--   select @EICStatusID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EICStatus', @rectype, 'Y')
--   if @EICStatusID <> 0  AND (ISNULL(@OverwriteEICStatus, 'Y') = 'Y') 
--	begin
-- 		Update IMWE
-- 		SET IMWE.UploadVal = 'S'
-- 		where IMWE.ImportTemplate=@ImportTemplate and
-- 		IMWE.ImportId=@ImportId and IMWE.Identifier = @EICStatusID
--	end

   select @CSAllocYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CSAllocYN', @rectype, 'Y')
   if @CSAllocYNID <> 0  AND (ISNULL(@OverwriteCSAllocYN, 'Y') = 'Y') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @CSAllocYNID
	end

------------------------

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
 

  select @EmplBasedYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EmplBased', @rectype, 'Y')
  if @EmplBasedYNID <> 0  AND (ISNULL(@OverwriteEmplBased, 'Y') = 'N') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @EmplBasedYNID
 		AND IMWE.UploadVal IS NULL
	end
 
  select @OverMiscAmtYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OverMiscAmt', @rectype, 'Y')
  if @OverMiscAmtYNID <> 0  AND (ISNULL(@OverwriteOverMiscAmt, 'Y') = 'N') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @OverMiscAmtYNID
 		AND IMWE.UploadVal IS NULL
	end

  select @OverCalcsID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OverCalcs', @rectype, 'Y')
  if @OverCalcsID<> 0  AND (ISNULL(@OverwriteOverCalcs, 'Y') = 'N') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @OverCalcsID
 		AND IMWE.UploadVal IS NULL
	end

  select @OverLimitYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OverLimit', @rectype, 'Y')
  if @OverLimitYNID <> 0  AND (ISNULL(@OverwriteOverLimit, 'Y') = 'N') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @OverLimitYNID
 		AND IMWE.UploadVal IS NULL
	end
 
   select @NetPayOptYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'NetPayOpt', @rectype, 'Y')
  if @NetPayOptYNID <> 0  AND (ISNULL(@OverwriteNetPayOpt, 'Y') = 'N') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @NetPayOptYNID
 		AND IMWE.UploadVal IS NULL
	end

   select @AddonTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AddonType', @rectype, 'Y')
   if @AddonTypeID <> 0  AND (ISNULL(@OverwriteAddonType, 'Y') = 'N') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @AddonTypeID
 		AND IMWE.UploadVal IS NULL
	end
	
   select @CSMedCovID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CSMedCov', @rectype, 'Y')
   if @CSMedCovID <> 0  AND (ISNULL(@OverwriteCSMedCov, 'Y') = 'N') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @CSMedCovID
 		AND IMWE.UploadVal IS NULL
	end

--   select @EICStatusID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EICStatus', @rectype, 'Y')
--   if @EICStatusID <> 0  AND (ISNULL(@OverwriteEICStatus, 'Y') = 'N') 
--	begin
-- 		Update IMWE
-- 		SET IMWE.UploadVal = 'S'
-- 		where IMWE.ImportTemplate=@ImportTemplate and
-- 		IMWE.ImportId=@ImportId and IMWE.Identifier = @EICStatusID
-- 		AND IMWE.UploadVal IS NULL
--	end

   select @CSAllocYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CSAllocYN', @rectype, 'Y')
   if @CSAllocYNID <> 0  AND (ISNULL(@OverwriteCSAllocYN, 'Y') = 'N') 
	begin
 		Update IMWE
 		SET IMWE.UploadVal = 'N'
 		where IMWE.ImportTemplate=@ImportTemplate and
 		IMWE.ImportId=@ImportId and IMWE.Identifier = @CSAllocYNID
 		AND IMWE.UploadVal IS NULL
	end



 --Get Identifiers for dependent defaults.
  select @cMiscAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MiscAmt', @rectype, 'N')
  select @cMiscAmt2ID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MiscAmt2', @rectype, 'N') --#139723
  select @cOverMiscAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OverMiscAmt', @rectype, 'N')
  select @cEmplBasedYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EmplBased', @rectype, 'N')
  select @cOverCalcsID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OverCalcs', @rectype, 'N')
  select @cNetPayOptYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'NetPayOpt', @rectype, 'N')
  select @cOverLimitID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OverLimit', @rectype, 'N')
  select @cAddonTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AddonType', @rectype, 'N')
  select @cCSAllocYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CSAllocYN', @rectype, 'N')
  select @cFileStatusID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FileStatus', @rectype, 'N')
  select @cOverGLAcct = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OverGLAcct', @rectype, 'N')
  select @cProcessSeq = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ProcessSeq', @rectype, 'N')
  select @cFrequency = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Frequency', @rectype, 'N')
  select @cEICStatus = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EICStatus', @rectype, 'N')
  select @cVendor = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Vendor', @rectype, 'N')
  select @cAPDesc = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'APDesc', @rectype, 'N')
  select @cCSMedCov = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CSMedCov', @rectype, 'N')
  select @cCSFipsCode = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CSFipsCode', @rectype, 'N')
  select @cCSCaseId = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CSCaseId', @rectype, 'N')
  select @cCSAllocGroup = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CSAllocGroup', @rectype, 'N')


  select @cFileStatus = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FileStatus', @rectype, 'N')
  select @cRegExempts = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RegExempts', @rectype, 'N')
  select @cAddExempts = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AddExempts', @rectype, 'N')
  select @cOverMiscAmt = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OverMiscAmt', @rectype, 'N')
  select @cMiscAmt = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MiscAmt', @rectype, 'N')
  select @cMiscAmt2 = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MiscAmt2', @rectype, 'N') --#139723
  select @cMiscFactor = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MiscFactor', @rectype, 'N')
  select @cRateAmt = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RateAmt', @rectype, 'N')
  select @cLimit = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Limit', @rectype, 'N')
  select @cLimitRate = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LimitRate', @rectype, 'N')
  select @cNetPayOpt = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'NetPayOpt', @rectype, 'N')
  select @cMinNetPay = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MinNetPay', @rectype, 'N')
  select @cAddonRateAmt = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AddonRateAmt', @rectype, 'N')

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

declare @PRCo bCompany, @Employee bEmployee, @DLCode bEDLCode, @EmplBased bYN, @Frequency bFreq,
		@ProcessSeq tinyint, @FileStatus char(1), @RegExempts tinyint, @AddExempts tinyint,
		@OverMiscAmt bYN, @MiscAmt bDollar, @MiscAmt2 bDollar,  --#139723
		@MiscFactor bRate, @VendorGroup bGroup,
		@Vendor bVendor, @APDesc bDesc, @GLCo bCompany, @OverGLAcct bGLAcct,
		@OverCalcs char(1), @RateAmt bUnitCost, @OverLimit bYN, @Limit bDollar,
		@NetPayOpt char(1), @MinNetPay bDollar, @AddonType char(1), @AddonRateAmt bUnitCost,
		@CSCaseId varchar(20), @CSFipsCode varchar(10), @CSMedCov bYN, @EICStatus char(1),
		@LimitRate bRate, @CSAllocYN bYN, @CSAllocGroup tinyint,
		@APCo bCompany, @DefVendorGroup bGroup, @DefGLCo bCompany,
		@CalcCategory varchar(1), @AutoAP bYN, @AddendaTypeId tinyint, @Method varchar(10),	
		@LimitBasis char(1)

 
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
      	If @Column='DLCode' and  isnumeric(@Uploadval) =1 select @DLCode = @Uploadval
      	If @Column='EmplBased' select @EmplBased = @Uploadval
      	If @Column='Frequency' and isnumeric(@Uploadval) =1 select @Frequency = Convert( int, @Uploadval)
		If @Column='ProcessSeq' and isnumeric(@Uploadval) =1 select @ProcessSeq = Convert( tinyint, @Uploadval)
      	If @Column='FileStatus' select @FileStatus = @Uploadval
		If @Column='RegExempts' and isnumeric(@Uploadval) =1 select @RegExempts = Convert( tinyint, @Uploadval)
		If @Column='AddExempts' and isnumeric(@Uploadval) =1 select @AddExempts = Convert( tinyint, @Uploadval)
		If @Column='OverMiscAmt' select @OverMiscAmt = @Uploadval
		If @Column='MiscAmt' and isnumeric(@Uploadval) =1 select @MiscAmt = Convert( numeric(16,2), @Uploadval)
		If @Column='MiscAmt2' and isnumeric(@Uploadval) =1 select @MiscAmt2 = Convert( numeric(16,2), @Uploadval) --#139723
		If @Column='MiscFactor' and isnumeric(@Uploadval) =1 select @MiscFactor = Convert( numeric(16,5), @Uploadval)
		If @Column='VendorGroup' and isnumeric(@Uploadval) =1 select @VendorGroup = Convert( tinyint, @Uploadval)
		If @Column='Vendor' and isnumeric(@Uploadval) =1 select @Vendor = Convert( int, @Uploadval)
		If @Column='APDesc' select @APDesc = @Uploadval
		If @Column='GLCo' and isnumeric(@Uploadval) =1 select @GLCo = Convert( tinyint, @Uploadval)
		If @Column='OverGLAcct' select @OverGLAcct = @Uploadval
		If @Column='OverCalcs' select @OverCalcs = @Uploadval
		If @Column='RateAmt' and isnumeric(@Uploadval) =1 select @RateAmt = Convert( numeric(16,5), @Uploadval)
		If @Column='OverLimit' select @OverLimit = @Uploadval
		If @Column='Limit' and isnumeric(@Uploadval) =1 select @Limit = Convert( numeric(16,2), @Uploadval)
		If @Column='NetPayOpt' select @NetPayOpt = @Uploadval
		If @Column='MinNetPay' and isnumeric(@Uploadval) =1 select @MinNetPay = Convert( numeric(16,2), @Uploadval)
		If @Column='AddonType' select @AddonType = @Uploadval
		If @Column='AddonRateAmt' and isnumeric(@Uploadval) =1 select @AddonRateAmt = Convert( numeric(16,5), @Uploadval)
		If @Column='CSCaseId' select @CSCaseId = @Uploadval
		If @Column='CSFipsCode' select @CSFipsCode = @Uploadval
		If @Column='CSMedCov' select @CSMedCov = @Uploadval
		If @Column='EICStatus' select @EICStatus = @Uploadval
		If @Column='LimitRate' and isnumeric(@Uploadval) =1 select @LimitRate = Convert( numeric(16,5), @Uploadval)
		If @Column='CSAllocYN' select @CSAllocYN = @Uploadval
		If @Column='CSAllocGroup' and isnumeric(@Uploadval) =1 select @CSAllocGroup = Convert( tinyint, @Uploadval)

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
			IF @Column='DLCode' 
				IF @Uploadval IS NULL
					SET @IsDLCodeEmpty = 'Y'
				ELSE
					SET @IsDLCodeEmpty = 'N'
			IF @Column='EmplBased' 
				IF @Uploadval IS NULL
					SET @IsEmplBasedEmpty = 'Y'
				ELSE
					SET @IsEmplBasedEmpty = 'N'
			IF @Column='Frequency' 
				IF @Uploadval IS NULL
					SET @IsFrequencyEmpty = 'Y'
				ELSE
					SET @IsFrequencyEmpty = 'N'
			IF @Column='ProcessSeq' 
				IF @Uploadval IS NULL
					SET @IsProcessSeqEmpty = 'Y'
				ELSE
					SET @IsProcessSeqEmpty = 'N'
			IF @Column='FileStatus' 
				IF @Uploadval IS NULL
					SET @IsFileStatusEmpty = 'Y'
				ELSE
					SET @IsFileStatusEmpty = 'N'
			IF @Column='RegExempts' 
				IF @Uploadval IS NULL
					SET @IsRegExemptsEmpty = 'Y'
				ELSE
					SET @IsRegExemptsEmpty = 'N'
			IF @Column='AddExempts' 
				IF @Uploadval IS NULL
					SET @IsAddExemptsEmpty = 'Y'
				ELSE
					SET @IsAddExemptsEmpty = 'N'
			IF @Column='OverMiscAmt' 
				IF @Uploadval IS NULL
					SET @IsOverMiscAmtEmpty = 'Y'
				ELSE
					SET @IsOverMiscAmtEmpty = 'N'
			IF @Column='MiscAmt' 
				IF @Uploadval IS NULL
					SET @IsMiscAmtEmpty = 'Y'
				ELSE
					SET @IsMiscAmtEmpty = 'N'
			IF @Column='MiscAmt2'  --#139723
				IF @Uploadval IS NULL
					SET @IsMiscAmt2Empty = 'Y'
				ELSE
					SET @IsMiscAmt2Empty = 'N'					
			IF @Column='MiscFactor' 
				IF @Uploadval IS NULL
					SET @IsMiscFactorEmpty = 'Y'
				ELSE
					SET @IsMiscFactorEmpty = 'N'
			IF @Column='OverCalcs' 
				IF @Uploadval IS NULL
					SET @IsOverCalcsEmpty = 'Y'
				ELSE
					SET @IsOverCalcsEmpty = 'N'
			IF @Column='RateAmt' 
				IF @Uploadval IS NULL
					SET @IsRateAmtEmpty = 'Y'
				ELSE
					SET @IsRateAmtEmpty = 'N'
			IF @Column='OverLimit' 
				IF @Uploadval IS NULL
					SET @IsOverLimitEmpty = 'Y'
				ELSE
					SET @IsOverLimitEmpty = 'N'
			IF @Column='Limit' 
				IF @Uploadval IS NULL
					SET @IsLimitEmpty = 'Y'
				ELSE
					SET @IsLimitEmpty = 'N'
			IF @Column='LimitRate' 
				IF @Uploadval IS NULL
					SET @IsLimitRateEmpty = 'Y'
				ELSE
					SET @IsLimitRateEmpty = 'N'
			IF @Column='NetPayOpt' 
				IF @Uploadval IS NULL
					SET @IsNetPayOptEmpty = 'Y'
				ELSE
					SET @IsNetPayOptEmpty = 'N'
			IF @Column='MinNetPay' 
				IF @Uploadval IS NULL
					SET @IsMinNetPayEmpty = 'Y'
				ELSE
					SET @IsMinNetPayEmpty = 'N'
			IF @Column='AddonType' 
				IF @Uploadval IS NULL
					SET @IsAddonTypeEmpty = 'Y'
				ELSE
					SET @IsAddonTypeEmpty = 'N'
			IF @Column='AddonRateAmt' 
				IF @Uploadval IS NULL
					SET @IsAddonRateAmtEmpty = 'Y'
				ELSE
					SET @IsAddonRateAmtEmpty = 'N'
			IF @Column='VendorGroup' 
				IF @Uploadval IS NULL
					SET @IsVendorGroupEmpty = 'Y'
				ELSE
					SET @IsVendorGroupEmpty = 'N'
			IF @Column='Vendor' 
				IF @Uploadval IS NULL
					SET @IsVendorEmpty = 'Y'
				ELSE
					SET @IsVendorEmpty = 'N'
			IF @Column='APDesc' 
				IF @Uploadval IS NULL
					SET @IsAPDescEmpty = 'Y'
				ELSE
					SET @IsAPDescEmpty = 'N'
			IF @Column='CSCaseId' 
				IF @Uploadval IS NULL
					SET @IsCSCaseIdEmpty = 'Y'
				ELSE
					SET @IsCSCaseIdEmpty = 'N'
			IF @Column='CSFipsCode' 
				IF @Uploadval IS NULL
					SET @IsCSFipsCodeEmpty = 'Y'
				ELSE
					SET @IsCSFipsCodeEmpty = 'N'
			IF @Column='CSMedCov' 
				IF @Uploadval IS NULL
					SET @IsCSMedCovEmpty = 'Y'
				ELSE
					SET @IsCSMedCovEmpty = 'N'
			IF @Column='GLCo' 
				IF @Uploadval IS NULL
					SET @IsGLCoEmpty = 'Y'
				ELSE
					SET @IsGLCoEmpty = 'N'
			IF @Column='OverGLAcct' 
				IF @Uploadval IS NULL
					SET @IsOverGLAcctEmpty = 'Y'
				ELSE
					SET @IsOverGLAcctEmpty = 'N'
			IF @Column='EICStatus' 
				IF @Uploadval IS NULL
					SET @IsEICStatusEmpty = 'Y'
				ELSE
					SET @IsEICStatusEmpty = 'N'
			IF @Column='CSAllocYN' 
				IF @Uploadval IS NULL
					SET @IsCSAllocYNEmpty = 'Y'
				ELSE
					SET @IsCSAllocYNEmpty = 'N'
			IF @Column='CSAllocGroup' 
				IF @Uploadval IS NULL
					SET @IsCSAllocGroupEmpty = 'Y'
				ELSE
					SET @IsCSAllocGroupEmpty = 'N'
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
 
	-- get GL and AP Company from payroll company
		select @DefGLCo = GLCo, @APCo = APCo 
		from bPRCO with (nolock)
		where PRCo = @PRCo
	-- get vendor group default based on AP Company
		select @DefVendorGroup = VendorGroup 
		from bHQCO with (nolock) 
		where HQCo = @APCo
	-- get Deduction  and Liability information
		select @CalcCategory = CalcCategory, @AutoAP = AutoAP, 
			   @Method = Method , @LimitBasis = LimitBasis
		from bPRDL with (nolock) 
		where PRCo = @PRCo and DLCode = @DLCode

	-- get APVM_AddendaTypeId
		if isnull(@Vendor,-1) <> -1
			begin
			select @AddendaTypeId = AddendaTypeId
			from bAPVM with (nolock)
			where VendorGroup = @DefVendorGroup and Vendor = @Vendor
			end


  	   	if isnull(@ynVendorGroup,'N') = 'Y' AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'Y' OR ISNULL(@IsVendorGroupEmpty, 'Y') = 'Y')
      	  begin
			select @VendorGroup = @DefVendorGroup

            UPDATE IMWE
            SET IMWE.UploadVal = @DefVendorGroup
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @VendorGroupID
           end

  	   	if isnull(@ynGLCo,'N') = 'Y' AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
      	  begin
			select @GLCo = @DefGLCo

            UPDATE IMWE
            SET IMWE.UploadVal = @DefGLCo
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @GLCoID
           end


	-- Clean up Rules for imported data:
	-- FileStatus is always upper case
		if isnull(@FileStatus,'') <> '' and upper(@FileStatus) <> @FileStatus
			begin
			select @FileStatus =  upper(@FileStatus)

            UPDATE IMWE
            SET IMWE.UploadVal = @FileStatus
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cFileStatusID
			end

	-- EmplBased can only be set to "Y" when PRDL_CalcCategory is set to "E" or "A"
		if isnull(@EmplBased,'') = 'Y' and (isnull(@CalcCategory,'') <> 'E' and isnull(@CalcCategory,'') <> 'A') AND (ISNULL(@OverwriteEmplBased, 'Y') = 'Y' OR ISNULL(@IsEmplBasedEmpty, 'Y') = 'Y')
			begin
			select @EmplBased = 'N'

            UPDATE IMWE
            SET IMWE.UploadVal = @EmplBased
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cEmplBasedYNID
			end

	-- Frequency, ProcessSeq, and OverGLAcct can only have values when EmplBased is set to "Y"
		if isnull(@EmplBased,'') = 'N' and (isnull(@Frequency,'') <> '' or isnull(@ProcessSeq,113) <> 113 or isnull(@OverGLAcct,'') <> '')
			begin
				select @Frequency=null, @ProcessSeq = null, @OverGLAcct = null

            UPDATE IMWE
            SET IMWE.UploadVal = @Frequency
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cFrequency

            UPDATE IMWE
            SET IMWE.UploadVal = @ProcessSeq
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cProcessSeq

            UPDATE IMWE
            SET IMWE.UploadVal = @OverGLAcct
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cOverGLAcct

			end


	-- EICStatus can only have a value other than "S" when EmplBased is set to "Y"
	-- #135039 correction to above note: EICStatus must be null if EmplBased is set to "N"
		if isnull(@EmplBased,'') = 'N' and isnull(@EICStatus,'') <> ''
			begin
				select @EICStatus=null

            UPDATE IMWE
            SET IMWE.UploadVal = @EICStatus
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cEICStatus
			end

	-- Vendor and APDesc can ony have values when PRDL_AutoAP is set to "Y"
		if isnull(@AutoAP, '') <> 'Y' and (isnull(@Vendor,-1) <> -1 or isnull(@APDesc, '') <> '' )
			begin
				select @Vendor=null, @APDesc = null

            UPDATE IMWE
            SET IMWE.UploadVal = @Vendor
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cVendor

            UPDATE IMWE
            SET IMWE.UploadVal = @APDesc
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cAPDesc

			end		

	-- CSCaseId and CSPipsCode can only have values and CSMedCov can only be set to "Y" when Vendor has been selected and APVM_AddendaTypeId is set to 2 (Child Support)
		if isnull(@AddendaTypeId, 0) <> 2 
			begin
				select @CSCaseId = null, @CSFipsCode = null, @CSMedCov = null

            UPDATE IMWE
            SET IMWE.UploadVal = @CSCaseId
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cCSCaseId

            UPDATE IMWE
            SET IMWE.UploadVal = @CSFipsCode
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cCSFipsCode

            UPDATE IMWE
            SET IMWE.UploadVal = @CSMedCov
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cCSMedCov

			end
			
		-- CSAllocGroup can only have a value when CSAllocYN is set to "Y"
		if isnull(@CSAllocYN,'') <> 'Y' and isnull(@CSAllocGroup,99) <> 99 AND (ISNULL(@OverwriteCSAllocYN, 'Y') = 'Y' OR ISNULL(@IsCSAllocYNEmpty, 'Y') = 'Y')
			begin
			select @CSAllocGroup = null

            UPDATE IMWE
            SET IMWE.UploadVal = @CSAllocGroup
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cCSAllocGroup
			end
			
		--#139723
		-- FileStatus, RegExempts,AddExempts, OverMiscAmt, MiscAmt, MiscAmt2, and MiscFactor can only have values when PRDL.Method is set to "R" (Routine)
		if isnull(@Method,'') <> 'R' and (isnull (@FileStatus, '') <> '' or isnull(@RegExempts, 97) <> 97 or isnull(@AddExempts, 97) <> 97 or 
		   isnull(@OverMiscAmt, '') <> '' or isnull(@MiscAmt, 97) <> 97 or isnull(@MiscAmt2, 97) <> 97 or isnull(@MiscFactor,97)<> 97 )
			begin
			select  @FileStatus = null, @RegExempts = null, @AddExempts = null, @OverMiscAmt = null, @MiscAmt = null, @MiscAmt2 = null, @MiscFactor = null


            UPDATE IMWE
            SET IMWE.UploadVal = @FileStatus
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cFileStatus

            UPDATE IMWE
            SET IMWE.UploadVal = @RegExempts
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cRegExempts

            UPDATE IMWE
            SET IMWE.UploadVal = @AddExempts
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cAddExempts

            UPDATE IMWE
            SET IMWE.UploadVal = @OverMiscAmt
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cOverMiscAmt

            UPDATE IMWE
            SET IMWE.UploadVal = @MiscAmt
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cMiscAmt
  				
            UPDATE IMWE --#139723
            SET IMWE.UploadVal = @MiscAmt2
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cMiscAmt2  				

            UPDATE IMWE
            SET IMWE.UploadVal = @MiscFactor
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cMiscFactor

			end

	-- RateAmt can only be set to a non-zero value when OverCalcs is not set to "N" (Use calculated amount) … otherwise RateAmt is set to 0
		if isnull(@OverCalcs,'') ='N' and isnull(@RateAmt, 0 ) <> 0 
			begin
			select @RateAmt = 0

            UPDATE IMWE
            SET IMWE.UploadVal = @RateAmt
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cRateAmt
			end 
	-- Limit and LimitRate are set when OverLimit is set to "Y" … LimitRate is used when PRDL_LimitBasis is set to "R" (Rate of earnings) … otherwise Limit is used
		if isnull(@OverLimit, '') <> 'Y' and ( isnull(@LimitRate,0)<> 0 or isnull(@Limit, 0)<>0) AND (ISNULL(@OverwriteOverLimit, 'Y') = 'Y' OR ISNULL(@IsOverLimitEmpty, 'Y') = 'Y')
			begin
			select @LimitRate=null, @Limit=null

            UPDATE IMWE
            SET IMWE.UploadVal = @LimitRate
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cLimitRate

            UPDATE IMWE
            SET IMWE.UploadVal = @Limit
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cLimit
			end

	-- NetPayOpt can only be set to a value other than "N" (No minimum) when PRDL_Method is set to "N" (Rate of net)
		if isnull(@Method,'N')<>'N' and isnull(@NetPayOpt,'')<> 'N'
			begin
			select @NetPayOpt = 'N'

            UPDATE IMWE
            SET IMWE.UploadVal = @NetPayOpt
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cNetPayOpt
			end
	-- NetPayAmt can only have a value when NetPayOpt is not set to "N" (No mimimum)
		if isnull(@NetPayOpt,'N') = 'N' and isnull(@MinNetPay, 0 ) <> 0 
			begin
			select @MinNetPay = null

            UPDATE IMWE
            SET IMWE.UploadVal = @MinNetPay
            where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
  				IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cMinNetPay
			end

	-- AddonRateAmt can only have a value whern Addon is not set to "N" (None)
		if isnull(@AddonType,'N')='N' and isnull(@AddonRateAmt, 0) <> 0
		begin
		select @AddonRateAmt = null

        UPDATE IMWE
        SET IMWE.UploadVal = @AddonRateAmt
        where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
			IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @cAddonRateAmt
		end

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
      (IMWE.Identifier = @cMiscAmtID or IMWE.Identifier = @cMiscAmt2ID )  --#139723
            
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and isnull(IMWE.UploadVal,'') not in ('N','Y') and
      (IMWE.Identifier = @cEmplBasedYNID or IMWE.Identifier = @cOverMiscAmtID or 
		IMWE.Identifier = @cOverLimitID or IMWE.Identifier = @cCSAllocYNID )

      UPDATE IMWE
      SET IMWE.UploadVal = 'N'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and isnull(IMWE.UploadVal,'') not in ('N','M','R','A') and
      (IMWE.Identifier = @cOverCalcsID )

      UPDATE IMWE
      SET IMWE.UploadVal = 'N'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and isnull(IMWE.UploadVal,'') not in ('N','P','A') and
      (IMWE.Identifier = @cNetPayOptYNID)

      UPDATE IMWE
      SET IMWE.UploadVal = 'N'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and isnull(IMWE.UploadVal,'') not in ('N','A','R') and
      (IMWE.Identifier = @cAddonTypeID )

/*
General Notes for Programmatic Defaults:
PRED records can be entered either in form PRFileStat or PREmplDL.  Therefore the Defaults in the grid reflect an amalgam of both forms as follows...
Defaults for EmplBased, MiscFactor, and OverLimit apply only when adding a record in PRFileStat.
Defaults for VendorGroup, RateAmt, EICStatus, and CSAllocGroup only apply when adding a record in PREmplDL.
All other defaults occur either when adding a record in PRFileStat or PREmplDL.

VendorGroup defaults from HQCO_VendorGroup where HQCo equals PRCO_APCo.

*/

 bspexit:
 
 	if @CursorOpen = 1
 	begin
 		close WorkEditCursor
 		deallocate WorkEditCursor	
 	end
 
     select @msg = isnull(@desc,'Clear') + char(13) + char(13) + '[bspIMViewpointDefaultsPRED]'
 
     return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsPRED] TO [public]
GO
