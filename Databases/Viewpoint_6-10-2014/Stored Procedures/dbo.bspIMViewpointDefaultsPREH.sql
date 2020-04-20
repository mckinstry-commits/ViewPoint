SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsPREH]
/***********************************************************
* CREATED BY:	RBT 03/04/04 for issue #23929
* MODIFIED BY:	RBT 01/24/06 - issue #119922, #119979 format SSN.
*				DANF 02/14/07 - issue 120854 Create unique sort name during import process.
*				DANF 04/16/07 - Issue 122202 Upper case sort name.
*				CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
*				TJL 03/10/10 - Issue #138524, Add defaults for UseUnempState and UseInsState
*				TJL 03/17/10 - Issue #137920, Boost SSN (TFN, SIN) formatting to cover Australian and Canadian format
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
  --Issue #138524 - UseUnempState & UseInsState
  declare @PRCoID int, @GLCoID int, @SortNameID int, @SexID int, @AuditYNID int, @HrlyRateID int, @SalaryAmtID int,
  	@OTOptID int, @JCFixedRateID int, @EMFixedRateID int, @DirDepositID int, @ActiveYNID int,
  	@PensionYNID int, @PostToAllID int, @CertYNID int, @UnempStateID int, @InsStateID int,
  	@DefaultPaySeqID int, @CSAllocMethodID int, @UseStateID int, @UseLocalID int, @UseInsID int,
  	@YTDSUIID int, @LastUpdatedID int, @zSSNID int, @UseUnempStateID int, @UseInsStateID int

  --Fields that must be 'N' when not otherwise set by a default
  --Issue #138524
  declare @nUseStateID int, @nUseInsID int, @nUseLocalID int, @nUseUnempStateID int, @nUseInsStateID int,
	@nAuditYNID int, @nActiveYNID int, @nPensionYNID int, @nPostToAllID int, @nCertYNID int, @nDefaultPaySeqID int
  
  --Values
  declare @SortName bSortName, @DefGLCo bCompany, @TaxState bState, @Employee bEmployee,
  	@PRCo bCompany, @FirstName varchar(30), @LastName varchar(30), @DefaultCountry varchar(2)
  
  --Flags for dependent defaults
  declare @ynSortName bYN, @ynUnempState bYN, @ynInsState bYN, @ynPensionNumber bYN
  
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
  
--issue #119922, format SSN.  Put this here in case there are no Viewpoint Defaults.
--issue #137920, include proper formats for Australia and Canada
select @zSSNID = DDUD.Identifier From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SSN'
if @@rowcount <> 0
	begin
	select @DefaultCountry = DefaultCountry
	from bHQCO with (nolock)
	where HQCo = @Company
	
	UPDATE IMWE 
	SET UploadVal = dbo.bfMuliPartFormat(replace (UploadVal,' ', ''),(case when @DefaultCountry = 'US' then '3R-2R-4R' else '3R-3R-3R' end))
	where ImportTemplate=@ImportTemplate and ImportId=@ImportId and Identifier=@zSSNID
	and UploadVal <> dbo.bfMuliPartFormat(replace (UploadVal,' ', ''),(case when @DefaultCountry = 'US' then '3R-2R-4R' else '3R-3R-3R' end))
	end

  -- Check ImportTemplate detail for columns to set Bidtek Defaults
  if not exists(select top 1 1 From IMTD with (nolock)
  Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
  and IMTD.RecordType = @rectype)
  goto bspexit
  
  --Issue #138524 - @OverwriteUseUnempState & @OverwriteUseInsState
  DECLARE 
			  @OverwritePRCo 	 	 	 bYN
			, @OverwriteGLCo 	 	 	 bYN
			, @OverwriteSex 	 	 	 bYN
			, @OverwriteAuditYN 	 	 bYN
			, @OverwriteHrlyRate 	 	 bYN
			, @OverwriteSalaryAmt 	 	 bYN
			, @OverwriteOTOpt 	 		 bYN
			, @OverwriteJCFixedRate 	 bYN
			, @OverwriteEMFixedRate 	 bYN
			, @OverwriteDirDeposit 	 	 bYN
			, @OverwriteActiveYN 	 	 bYN
			, @OverwritePensionYN 	 	 bYN
			, @OverwritePostToAll 	 	 bYN
			, @OverwriteCertYN 	 		 bYN
			, @OverwriteDefaultPaySeq  	 bYN
			, @OverwriteCSAllocMethod  	 bYN
			, @OverwriteUseState 	 	 bYN
			, @OverwriteUseUnempState  	 bYN
			, @OverwriteUseInsState 	 bYN
			, @OverwriteUseLocal 	 	 bYN
			, @OverwriteUseIns 	 		 bYN
			, @OverwriteYTDSUI 	 		 bYN
			, @OverwriteLastUpdated 	 bYN
			, @OverwriteSortName 	 	 bYN
			, @OverwriteUnempState 	 	 bYN
			, @OverwriteInsState 	 	 bYN

			,	@IsPRCoEmpty 			 bYN
			,	@IsEmployeeEmpty 		 bYN
			,	@IsLastNameEmpty 		 bYN
			,	@IsFirstNameEmpty 		 bYN
			,	@IsMidNameEmpty 		 bYN
			,	@IsSortNameEmpty 		 bYN
			,	@IsSuffixEmpty 			 bYN
			,	@IsAddressEmpty 		 bYN
			,	@IsCityEmpty 			 bYN
			,	@IsStateEmpty 			 bYN
			,	@IsCountryEmpty 		 bYN
			,	@IsZipEmpty 			 bYN
			,	@IsAddress2Empty 		 bYN
			,	@IsEmailEmpty 			 bYN
			,	@IsPhoneEmpty 			 bYN
			,	@IsSSNEmpty 			 bYN
			,	@IsRaceEmpty 			 bYN
			,	@IsSexEmpty 			 bYN
			,	@IsBirthDateEmpty 		 bYN
			,	@IsHireDateEmpty 		 bYN
			,	@IsTermDateEmpty 		 bYN
			,	@IsPRGroupEmpty 		 bYN
			,	@IsPRDeptEmpty 			 bYN
			,	@IsCraftEmpty 			 bYN
			,	@IsClassEmpty 			 bYN
			,	@IsNotesEmpty 			 bYN
			,	@IsInsCodeEmpty 		 bYN
			,	@IsTaxStateEmpty 		 bYN
			,	@IsUnempStateEmpty 		 bYN
			,	@IsInsStateEmpty 		 bYN
			,	@IsLocalCodeEmpty 		 bYN
			,	@IsGLCoEmpty 			 bYN
			,	@IsShiftEmpty 			 bYN
			,	@IsUseStateEmpty 		 bYN
			,	@IsUseLocalEmpty 		 bYN
			,	@IsUseInsEmpty 			 bYN
			,	@IsJCCoEmpty 			 bYN
			,	@IsJobEmpty 			 bYN
			,	@IsCrewEmpty 			 bYN
			,	@IsLastUpdatedEmpty 	 bYN
			,	@IsEarnCodeEmpty 		 bYN
			,	@IsHrlyRateEmpty 		 bYN
			,	@IsSalaryAmtEmpty 		 bYN
			,	@IsOTOptEmpty 			 bYN
			,	@IsOTSchedEmpty 		 bYN
			,	@IsJCFixedRateEmpty 	 bYN
			,	@IsEMFixedRateEmpty 	 bYN
			,	@IsOccupCatEmpty 		 bYN
			,	@IsCatStatusEmpty 		 bYN
			,	@IsDirDepositEmpty 		 bYN
			,	@IsRoutingIdEmpty 		 bYN
			,	@IsBankAcctEmpty 		 bYN
			,	@IsAcctTypeEmpty 		 bYN
			,	@IsActiveYNEmpty 		 bYN
			,	@IsPensionYNEmpty 		 bYN
			,	@IsPostToAllEmpty 		 bYN
			,	@IsCertYNEmpty 			 bYN
			,	@IsAuditYNEmpty 		 bYN
			,	@IsChkSortEmpty 		 bYN
			,	@IsTradeSeqEmpty 		 bYN
			,	@IsDefaultPaySeqEmpty 	 bYN
			,	@IsDDPaySeqEmpty 		 bYN
			,	@IsCSLimitEmpty 		 bYN
			,	@IsCSGarnGroupEmpty 	 bYN
			,	@IsCSAllocMethodEmpty 	 bYN
			,	@IsYTDSUIEmpty 			 bYN
  
  
    --Issue #138524 - @OverwriteUseUnempState & @OverwriteUseInsState
	SELECT @OverwritePRCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRCo', @rectype);
	SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
	SELECT @OverwriteSex = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Sex', @rectype);
	SELECT @OverwriteAuditYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AuditYN', @rectype);
	SELECT @OverwriteHrlyRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HrlyRate', @rectype);
	SELECT @OverwriteSalaryAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SalaryAmt', @rectype);
	SELECT @OverwriteOTOpt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OTOpt', @rectype);
	SELECT @OverwriteJCFixedRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCFixedRate', @rectype);
	SELECT @OverwriteEMFixedRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMFixedRate', @rectype);
	SELECT @OverwriteDirDeposit = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DirDeposit', @rectype);
	SELECT @OverwriteActiveYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActiveYN', @rectype);
	SELECT @OverwritePensionYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PensionYN', @rectype);
	SELECT @OverwritePostToAll = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PostToAll', @rectype);
	SELECT @OverwriteCertYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CertYN', @rectype);
	SELECT @OverwriteDefaultPaySeq = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DefaultPaySeq', @rectype);
	SELECT @OverwriteCSAllocMethod = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CSAllocMethod', @rectype);
	SELECT @OverwriteUseState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UseState', @rectype);
	SELECT @OverwriteUseUnempState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UseUnempState', @rectype);
	SELECT @OverwriteUseInsState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UseInsState', @rectype);
	SELECT @OverwriteUseLocal = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UseLocal', @rectype);
	SELECT @OverwriteUseIns = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UseIns', @rectype);
	SELECT @OverwriteYTDSUI = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'YTDSUI', @rectype);
	SELECT @OverwriteLastUpdated = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LastUpdated', @rectype);
	SELECT @OverwriteSortName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SortName', @rectype);
	SELECT @OverwriteUnempState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnempState', @rectype);
	SELECT @OverwriteInsState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InsState', @rectype);
  
  --get database default values
  select @DefGLCo = GLCo from bPRCO where PRCo = @Company
  
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
  
  select @GLCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLCo'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = @DefGLCo
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @GLCoID
  end
  
  select @SexID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Sex'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSex, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'M'
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @SexID
  end
  
  select @AuditYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AuditYN'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAuditYN, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'Y'
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @AuditYNID
  end
  
  select @HrlyRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HrlyRate'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteHrlyRate, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @HrlyRateID
  end
  
  select @SalaryAmtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SalaryAmt'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSalaryAmt, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @SalaryAmtID
  end
  
  select @OTOptID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OTOpt'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOTOpt, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'W'	--Weekly
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @OTOptID
  end
  
  select @JCFixedRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCFixedRate'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCFixedRate, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @JCFixedRateID
  end
  
  select @EMFixedRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMFixedRate'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteEMFixedRate, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @EMFixedRateID
  end
  
  select @DirDepositID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'DirDeposit'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteDirDeposit, 'Y') = 'Y') 
begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @DirDepositID
  end
  
  select @ActiveYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActiveYN'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActiveYN, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'Y'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActiveYNID
  end
  
  select @PensionYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PensionYN'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePensionYN, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @PensionYNID
  end
  
  select @PostToAllID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PostToAll'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePostToAll, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @PostToAllID
  end
  
  select @CertYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CertYN'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCertYN, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'Y'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @CertYNID
  end
  
  select @DefaultPaySeqID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'DefaultPaySeq'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteDefaultPaySeq, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @DefaultPaySeqID
  end
  
  select @CSAllocMethodID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CSAllocMethod'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCSAllocMethod, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'P'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @CSAllocMethodID
  end
  
  select @UseStateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UseState'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUseState, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @UseStateID
  end

  --Issue #138524 - UseUnempState & UseInsState
  select @UseUnempStateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UseUnempState'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUseUnempState, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @UseUnempStateID
  end
  
    select @UseInsStateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UseInsState'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUseInsState, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @UseInsStateID
  end
    
  select @UseLocalID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UseLocal'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUseLocal, 'Y') = 'Y') 
begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @UseLocalID
  end
  
  select @UseInsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UseIns'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUseIns, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @UseInsID
  end
  
  select @YTDSUIID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'YTDSUI'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteYTDSUI, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @YTDSUIID
  end
  
  select @LastUpdatedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LastUpdated'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteLastUpdated, 'Y') = 'Y') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = convert(varchar(10), getdate(), 101) + ' ' + convert(varchar(15), getdate(), 108)
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @LastUpdatedID
  end
  
--------------------  
  
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
  
  select @GLCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLCo'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteGLCo, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = @DefGLCo
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @GLCoID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @SexID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Sex'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSex, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'M'
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @SexID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @AuditYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AuditYN'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAuditYN, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'Y'
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @AuditYNID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @HrlyRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HrlyRate'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteHrlyRate, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @HrlyRateID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @SalaryAmtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SalaryAmt'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSalaryAmt, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @SalaryAmtID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @OTOptID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OTOpt'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOTOpt, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'W'	--Weekly
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @OTOptID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @JCFixedRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCFixedRate'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCFixedRate, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @JCFixedRateID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @EMFixedRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMFixedRate'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteEMFixedRate, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @EMFixedRateID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @DirDepositID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'DirDeposit'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteDirDeposit, 'Y') = 'N') 
begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @DirDepositID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @ActiveYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActiveYN'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActiveYN, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'Y'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActiveYNID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @PensionYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PensionYN'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePensionYN, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @PensionYNID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @PostToAllID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PostToAll'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePostToAll, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @PostToAllID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @CertYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CertYN'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCertYN, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'Y'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @CertYNID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @DefaultPaySeqID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'DefaultPaySeq'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteDefaultPaySeq, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @DefaultPaySeqID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @CSAllocMethodID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CSAllocMethod'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCSAllocMethod, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'P'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @CSAllocMethodID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @UseStateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UseState'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUseState, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @UseStateID
  	AND IMWE.UploadVal IS NULL
  end
  
    --Issue #138524 - UseUnempState & UseInsState
   select @UseUnempStateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UseUnempState'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUseUnempState, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @UseUnempStateID
  	AND IMWE.UploadVal IS NULL
  end
  
    select @UseInsStateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UseInsState'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUseInsState, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @UseInsStateID
  	AND IMWE.UploadVal IS NULL
  end
   
  select @UseLocalID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UseLocal'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUseLocal, 'Y') = 'N') 
begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @UseLocalID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @UseInsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UseIns'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUseIns, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'N'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @UseInsID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @YTDSUIID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'YTDSUI'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteYTDSUI, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = '0'	
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @YTDSUIID
  	AND IMWE.UploadVal IS NULL
  end
  
  select @LastUpdatedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
  inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
  Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LastUpdated'
  if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteLastUpdated, 'Y') = 'N') 
  begin
      UPDATE IMWE
      SET IMWE.UploadVal = convert(varchar(10), getdate(), 101) + ' ' + convert(varchar(15), getdate(), 108)
      where IMWE.ImportTemplate=@ImportTemplate and 
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @LastUpdatedID
  	AND IMWE.UploadVal IS NULL
  end
 
  
  
   
  --Get Identifiers for dependent defaults.
  select @ynSortName = 'N'
  select @SortNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SortName', @rectype, 'Y')
  if @SortNameID <> 0 select @ynSortName = 'Y'
  
  select @ynUnempState = 'N'
  select @UnempStateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnempState', @rectype, 'Y')
  if @UnempStateID <> 0 select @ynUnempState = 'Y'
  
  select @ynInsState = 'N'
  select @InsStateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'InsState', @rectype, 'Y')
  if @InsStateID <> 0 select @ynInsState = 'Y'
  
 
--Used to set required columns to 'N' when not otherwise set by a default. (Cleanup: See end of procedure)
--Issue #138524      
select @nUseStateID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UseState', @rectype, 'N') 
select @nUseInsID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UseIns', @rectype, 'N') 
select @nUseLocalID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UseLocal', @rectype, 'N') 
select @nUseUnempStateID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UseUnempState', @rectype, 'N') 
select @nUseInsStateID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UseInsState', @rectype, 'N') 
select @nAuditYNID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AuditYN', @rectype, 'N') 
select @nActiveYNID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ActiveYN', @rectype, 'N') 
select @nPensionYNID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PensionYN', @rectype, 'N') 
select @nPostToAllID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PostToAll', @rectype, 'N') 
select @nCertYNID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CertYN', @rectype, 'N') 
select @nDefaultPaySeqID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DefaultPaySeq', @rectype, 'N') 
  
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
  --#142350 - removing   @importid varchar(10), @seq int, @Identifier int,
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
  
      If @Column = 'PRCo' select @PRCo = @Uploadval
      If @Column = 'Employee' select @Employee = @Uploadval
      If @Column = 'LastName' select @LastName = @Uploadval
      If @Column = 'FirstName' select @FirstName = @Uploadval
      If @Column = 'TaxState' select @TaxState = @Uploadval
      
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
		IF @Column='LastName' 
			IF @Uploadval IS NULL
				SET @IsLastNameEmpty = 'Y'
			ELSE
				SET @IsLastNameEmpty = 'N'
		IF @Column='FirstName' 
			IF @Uploadval IS NULL
				SET @IsFirstNameEmpty = 'Y'
			ELSE
				SET @IsFirstNameEmpty = 'N'
		IF @Column='MidName' 
			IF @Uploadval IS NULL
				SET @IsMidNameEmpty = 'Y'
			ELSE
				SET @IsMidNameEmpty = 'N'
		IF @Column='SortName' 
			IF @Uploadval IS NULL
				SET @IsSortNameEmpty = 'Y'
			ELSE
				SET @IsSortNameEmpty = 'N'
		IF @Column='Suffix' 
			IF @Uploadval IS NULL
				SET @IsSuffixEmpty = 'Y'
			ELSE
				SET @IsSuffixEmpty = 'N'
		IF @Column='Address' 
			IF @Uploadval IS NULL
				SET @IsAddressEmpty = 'Y'
			ELSE
				SET @IsAddressEmpty = 'N'
		IF @Column='City' 
			IF @Uploadval IS NULL
				SET @IsCityEmpty = 'Y'
			ELSE
				SET @IsCityEmpty = 'N'
		IF @Column='State' 
			IF @Uploadval IS NULL
				SET @IsStateEmpty = 'Y'
			ELSE
				SET @IsStateEmpty = 'N'
		IF @Column='Country' 
			IF @Uploadval IS NULL
				SET @IsCountryEmpty = 'Y'
			ELSE
				SET @IsCountryEmpty = 'N'
		IF @Column='Zip' 
			IF @Uploadval IS NULL
				SET @IsZipEmpty = 'Y'
			ELSE
				SET @IsZipEmpty = 'N'
		IF @Column='Address2' 
			IF @Uploadval IS NULL
				SET @IsAddress2Empty = 'Y'
			ELSE
				SET @IsAddress2Empty = 'N'
		IF @Column='Email' 
			IF @Uploadval IS NULL
				SET @IsEmailEmpty = 'Y'
			ELSE
				SET @IsEmailEmpty = 'N'
		IF @Column='Phone' 
			IF @Uploadval IS NULL
				SET @IsPhoneEmpty = 'Y'
			ELSE
				SET @IsPhoneEmpty = 'N'
		IF @Column='SSN' 
			IF @Uploadval IS NULL
				SET @IsSSNEmpty = 'Y'
			ELSE
				SET @IsSSNEmpty = 'N'
		IF @Column='Race' 
			IF @Uploadval IS NULL
				SET @IsRaceEmpty = 'Y'
			ELSE
				SET @IsRaceEmpty = 'N'
		IF @Column='Sex' 
			IF @Uploadval IS NULL
				SET @IsSexEmpty = 'Y'
			ELSE
				SET @IsSexEmpty = 'N'
		IF @Column='BirthDate' 
			IF @Uploadval IS NULL
				SET @IsBirthDateEmpty = 'Y'
			ELSE
				SET @IsBirthDateEmpty = 'N'
		IF @Column='HireDate' 
			IF @Uploadval IS NULL
				SET @IsHireDateEmpty = 'Y'
			ELSE
				SET @IsHireDateEmpty = 'N'
		IF @Column='TermDate' 
			IF @Uploadval IS NULL
				SET @IsTermDateEmpty = 'Y'
			ELSE
				SET @IsTermDateEmpty = 'N'
		IF @Column='PRGroup' 
			IF @Uploadval IS NULL
				SET @IsPRGroupEmpty = 'Y'
			ELSE
				SET @IsPRGroupEmpty = 'N'
		IF @Column='PRDept' 
			IF @Uploadval IS NULL
				SET @IsPRDeptEmpty = 'Y'
			ELSE
				SET @IsPRDeptEmpty = 'N'
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
		IF @Column='Notes' 
			IF @Uploadval IS NULL
				SET @IsNotesEmpty = 'Y'
			ELSE
				SET @IsNotesEmpty = 'N'
		IF @Column='InsCode' 
			IF @Uploadval IS NULL
				SET @IsInsCodeEmpty = 'Y'
			ELSE
				SET @IsInsCodeEmpty = 'N'
		IF @Column='TaxState' 
			IF @Uploadval IS NULL
				SET @IsTaxStateEmpty = 'Y'
			ELSE
				SET @IsTaxStateEmpty = 'N'
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
		IF @Column='LocalCode' 
			IF @Uploadval IS NULL
				SET @IsLocalCodeEmpty = 'Y'
			ELSE
				SET @IsLocalCodeEmpty = 'N'
		IF @Column='GLCo' 
			IF @Uploadval IS NULL
				SET @IsGLCoEmpty = 'Y'
			ELSE
				SET @IsGLCoEmpty = 'N'
		IF @Column='Shift' 
			IF @Uploadval IS NULL
				SET @IsShiftEmpty = 'Y'
			ELSE
				SET @IsShiftEmpty = 'N'
		IF @Column='UseState' 
			IF @Uploadval IS NULL
				SET @IsUseStateEmpty = 'Y'
			ELSE
				SET @IsUseStateEmpty = 'N'
		IF @Column='UseLocal' 
			IF @Uploadval IS NULL
				SET @IsUseLocalEmpty = 'Y'
			ELSE
				SET @IsUseLocalEmpty = 'N'
		IF @Column='UseIns' 
			IF @Uploadval IS NULL
				SET @IsUseInsEmpty = 'Y'
			ELSE
				SET @IsUseInsEmpty = 'N'
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
		IF @Column='Crew' 
			IF @Uploadval IS NULL
				SET @IsCrewEmpty = 'Y'
			ELSE
				SET @IsCrewEmpty = 'N'
		IF @Column='LastUpdated' 
			IF @Uploadval IS NULL
				SET @IsLastUpdatedEmpty = 'Y'
			ELSE
				SET @IsLastUpdatedEmpty = 'N'
		IF @Column='EarnCode' 
			IF @Uploadval IS NULL
				SET @IsEarnCodeEmpty = 'Y'
			ELSE
				SET @IsEarnCodeEmpty = 'N'
		IF @Column='HrlyRate' 
			IF @Uploadval IS NULL
				SET @IsHrlyRateEmpty = 'Y'
			ELSE
				SET @IsHrlyRateEmpty = 'N'
		IF @Column='SalaryAmt' 
			IF @Uploadval IS NULL
				SET @IsSalaryAmtEmpty = 'Y'
			ELSE
				SET @IsSalaryAmtEmpty = 'N'
		IF @Column='OTOpt' 
			IF @Uploadval IS NULL
				SET @IsOTOptEmpty = 'Y'
			ELSE
				SET @IsOTOptEmpty = 'N'
		IF @Column='OTSched' 
			IF @Uploadval IS NULL
				SET @IsOTSchedEmpty = 'Y'
			ELSE
				SET @IsOTSchedEmpty = 'N'
		IF @Column='JCFixedRate' 
			IF @Uploadval IS NULL
				SET @IsJCFixedRateEmpty = 'Y'
			ELSE
				SET @IsJCFixedRateEmpty = 'N'
		IF @Column='EMFixedRate' 
			IF @Uploadval IS NULL
				SET @IsEMFixedRateEmpty = 'Y'
			ELSE
				SET @IsEMFixedRateEmpty = 'N'
		IF @Column='OccupCat' 
			IF @Uploadval IS NULL
				SET @IsOccupCatEmpty = 'Y'
			ELSE
				SET @IsOccupCatEmpty = 'N'
		IF @Column='CatStatus' 
			IF @Uploadval IS NULL
				SET @IsCatStatusEmpty = 'Y'
			ELSE
				SET @IsCatStatusEmpty = 'N'
		IF @Column='DirDeposit' 
			IF @Uploadval IS NULL
				SET @IsDirDepositEmpty = 'Y'
			ELSE
				SET @IsDirDepositEmpty = 'N'
		IF @Column='RoutingId' 
			IF @Uploadval IS NULL
				SET @IsRoutingIdEmpty = 'Y'
			ELSE
				SET @IsRoutingIdEmpty = 'N'
		IF @Column='BankAcct' 
			IF @Uploadval IS NULL
				SET @IsBankAcctEmpty = 'Y'
			ELSE
				SET @IsBankAcctEmpty = 'N'
		IF @Column='AcctType' 
			IF @Uploadval IS NULL
				SET @IsAcctTypeEmpty = 'Y'
			ELSE
				SET @IsAcctTypeEmpty = 'N'
		IF @Column='ActiveYN' 
			IF @Uploadval IS NULL
				SET @IsActiveYNEmpty = 'Y'
			ELSE
				SET @IsActiveYNEmpty = 'N'
		IF @Column='PensionYN' 
			IF @Uploadval IS NULL
				SET @IsPensionYNEmpty = 'Y'
			ELSE
				SET @IsPensionYNEmpty = 'N'
		IF @Column='PostToAll' 
			IF @Uploadval IS NULL
				SET @IsPostToAllEmpty = 'Y'
			ELSE
				SET @IsPostToAllEmpty = 'N'
		IF @Column='CertYN' 
			IF @Uploadval IS NULL
				SET @IsCertYNEmpty = 'Y'
			ELSE
				SET @IsCertYNEmpty = 'N'
		IF @Column='AuditYN' 
			IF @Uploadval IS NULL
				SET @IsAuditYNEmpty = 'Y'
			ELSE
				SET @IsAuditYNEmpty = 'N'
		IF @Column='ChkSort' 
			IF @Uploadval IS NULL
				SET @IsChkSortEmpty = 'Y'
			ELSE
				SET @IsChkSortEmpty = 'N'
		IF @Column='TradeSeq' 
			IF @Uploadval IS NULL
				SET @IsTradeSeqEmpty = 'Y'
			ELSE
				SET @IsTradeSeqEmpty = 'N'
		IF @Column='DefaultPaySeq' 
			IF @Uploadval IS NULL
				SET @IsDefaultPaySeqEmpty = 'Y'
			ELSE
				SET @IsDefaultPaySeqEmpty = 'N'
		IF @Column='DDPaySeq' 
			IF @Uploadval IS NULL
				SET @IsDDPaySeqEmpty = 'Y'
			ELSE
				SET @IsDDPaySeqEmpty = 'N'
		IF @Column='CSLimit' 
			IF @Uploadval IS NULL
				SET @IsCSLimitEmpty = 'Y'
			ELSE
				SET @IsCSLimitEmpty = 'N'
		IF @Column='CSGarnGroup' 
			IF @Uploadval IS NULL
				SET @IsCSGarnGroupEmpty = 'Y'
			ELSE
				SET @IsCSGarnGroupEmpty = 'N'
		IF @Column='CSAllocMethod' 
			IF @Uploadval IS NULL
				SET @IsCSAllocMethodEmpty = 'Y'
			ELSE
				SET @IsCSAllocMethodEmpty = 'N'
		IF @Column='YTDSUI' 
			IF @Uploadval IS NULL
				SET @IsYTDSUIEmpty = 'Y'
			ELSE
				SET @IsYTDSUIEmpty = 'N'
		
  
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
  	if @ynSortName = 'Y' AND (ISNULL(@OverwriteSortName, 'Y') = 'Y' OR ISNULL(@IsSortNameEmpty, 'Y') = 'Y')
  	begin
		declare @reccount int, @emptemp varchar(10)
  	    select @SortName = upper(left(@LastName,15))
  	    --check if the sortname is in use by another Employee
  	    select @reccount = count(*) from bPREH where PRCo = @PRCo and SortName = @SortName
  		and Employee <> @Employee	--exclude existing record for this employee
  	    if @reccount > 0	--if sortname is already in use, append employee number
  			begin	--(max length of SortName is 15 characters)
  				select @emptemp = convert(varchar(10),@Employee)	--max val is 10 digits
  				select @SortName = upper(rtrim(left(@LastName, 15-len(@emptemp)))) + @emptemp
  			end

		--issue #123214, also check IMWE for existing SortName.
		select @reccount = count(*) from IMWE where IMWE.ImportTemplate = @ImportTemplate and 
		IMWE.Identifier = @SortNameID and IMWE.RecordType = @rectype and 
		IMWE.UploadVal = @SortName

		if @reccount > 0	--if sortname is already in use, append employee number
			begin	--(max length of SortName is 15 characters)
 				select @emptemp = convert(varchar(10),@Employee)	--max val is 10 digits
 				select @SortName = upper(left(@LastName, 15-len(@emptemp))) + @emptemp
			end

  	    UPDATE IMWE
  	    SET IMWE.UploadVal = @SortName
  	    where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  	        and IMWE.Identifier=@SortNameID and IMWE.RecordType=@rectype
  	end
  
  	if @ynUnempState = 'Y' AND (ISNULL(@OverwriteUnempState, 'Y') = 'Y' OR ISNULL(@IsUnempStateEmpty, 'Y') = 'Y')
 
  	begin
  	    if isnull(@TaxState,'') <> ''
  	    begin
  			UPDATE IMWE
  			SET IMWE.UploadVal = @TaxState
  			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  			and IMWE.Identifier=@UnempStateID and IMWE.RecordType=@rectype
  	    end	
  	end
  
  	if @ynInsState = 'Y' AND (ISNULL(@OverwriteInsState, 'Y') = 'Y' OR ISNULL(@IsInsStateEmpty, 'Y') = 'Y')
  	begin
  	    if isnull(@TaxState,'') <> ''
  	    begin
  			UPDATE IMWE
  			SET IMWE.UploadVal = @TaxState
  			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  			and IMWE.Identifier=@InsStateID and IMWE.RecordType=@rectype
  	    end	
  	end

  	-- set Current Req Seq to next @Recseq unless we are processing last record.
  	if @Recseq = -1
  		select @complete = 1	-- exit the loop
  	else
  		select @currrecseq = @Recseq
  
    end
  end
  

UPDATE IMWE
SET IMWE.UploadVal = UPPER(IMWE.UploadVal)
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordType = @rectype
and IMWE.Identifier = @SortNameID and isnull(IMWE.UploadVal,'') <> UPPER(isnull(IMWE.UploadVal,'')) 

/* Set required (Y/N) inputs to 'N' where not already set with some other value */ 
--Issue #138524      
UPDATE IMWE
SET IMWE.UploadVal = 'N'
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') not in ('N','Y') and
	(IMWE.Identifier = @nUseStateID or IMWE.Identifier = @nUseInsID or IMWE.Identifier = @nUseLocalID 
	or IMWE.Identifier = @nUseUnempStateID	or IMWE.Identifier = @nUseInsStateID or IMWE.Identifier = @nAuditYNID
	or IMWE.Identifier = @nActiveYNID or IMWE.Identifier = @nPensionYNID or IMWE.Identifier = @nPostToAllID	
	or IMWE.Identifier = @nCertYNID or IMWE.Identifier = @nDefaultPaySeqID)
	
bspexit:
  
if @CursorOpen = 1
begin
	close WorkEditCursor
	deallocate WorkEditCursor	
end
  
select @msg = isnull(@desc,'Clear') + char(13) + char(13) + '[bspIMViewpointDefaultsPREH]'

return @rcode






GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsPREH] TO [public]
GO
