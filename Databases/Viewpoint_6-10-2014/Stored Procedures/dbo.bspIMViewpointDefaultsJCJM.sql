SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsJCJM]
/***********************************************************
* CREATED BY:   RBT 03/26/04	- issue #23928
* MODIFIED BY:  CC	 02/18/09	- Issue #24531 - Use default only if set to overwrite or value is null
*				CHS	12/29/2009	- issue #136164 change 'Rate Template' to 'RateTemplate'
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
   
   declare @rcode int, @desc varchar(120), @status int, @defaultvalue varchar(30), @CursorOpen int	
   
   --Identifiers
   declare @JCCoID int, @ContractID int, @JobStatusID int, @TaxGroupID int, 
   @BaseTaxOnID int, @MarkUpDiscRateID int, @ProjMinPctID int, @ShipAddressID int, @ShipCityID int, 
   @ShipStateID int, @ShipZipID int, @ShipAddress2ID int, @PRStateCodeID int, 
   @WghtAvgOTID int, @HaulTaxOptID int, @HrsPerManDayID int, @SecurityGroupID int,
   @LockPhasesID int, @CertifiedID int, @UpdatePlugsID int, @AutoAddItemYNID int, @AutoGenSubNoID int
   
   --Values
   declare @DefTaxGroup bGroup, @DefSecurityGroup int, @SecurityOn bYN, @Job bJob,
   @MailAddress varchar(60), @MailCity varchar(30), @MailState bState, @MailZip bZip, @MailAddress2 varchar(60)
   
   --Flags for dependent defaults
   declare @ynContract bYN, @ynPRStateCode bYN, @ynShipAddress bYN, @ynShipCity bYN, @ynShipState bYN,
   @ynShipZip bYN, @ynShipAddress2 bYN
   
   
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
			  @OverwriteJCCo 	 		 bYN
			, @OverwriteJobStatus 	 	 bYN
			, @OverwriteTaxGroup 	 	 bYN
			, @OverwriteBaseTaxOn 	 	 bYN
			, @OverwriteMarkUpDiscRate 	 bYN
			, @OverwriteProjMinPct 	 	 bYN
			, @OverwriteWghtAvgOT 	 	 bYN
			, @OverwriteHaulTaxOpt 	 	 bYN
			, @OverwriteHrsPerManDay 	 bYN
			, @OverwriteSecurityGroup 	 bYN
			, @OverwriteLockPhases 	 	 bYN
			, @OverwriteCertified 	 	 bYN
			, @OverwriteUpdatePlugs 	 bYN
			, @OverwriteAutoAddItemYN 	 bYN
			, @OverwriteAutoGenSubNo 	 bYN
			, @OverwriteContract 	 	 bYN
			, @OverwritePRStateCode 	 bYN
			, @OverwriteShipAddress 	 bYN
			, @OverwriteShipCity 	 	 bYN
			, @OverwriteShipState 	 	 bYN
			, @OverwriteShipZip 	 	 bYN
			, @OverwriteShipAddress2 	 bYN
			,	@IsJCCoEmpty 			 bYN
			,	@IsJobEmpty 			 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsContractEmpty 		 bYN
			,	@IsJobStatusEmpty 		 bYN
			,	@IsProjectMgrEmpty 		 bYN
			,	@IsBidNumberEmpty 		 bYN
			,	@IsTaxGroupEmpty 		 bYN
			,	@IsTaxCodeEmpty 		 bYN
			,	@IsBaseTaxOnEmpty 		 bYN
			,	@IsLiabTemplateEmpty 	 bYN
			,	@IsInsTemplateEmpty 	 bYN
			,	@IsMarkUpDiscRateEmpty 	 bYN
			,	@IsProjMinPctEmpty 		 bYN
			,	@IsLockPhasesEmpty 		 bYN
			,	@IsUpdatePlugsEmpty 	 bYN
			,	@IsJobPhoneEmpty 		 bYN
			,	@IsJobFaxEmpty 			 bYN
			,	@IsMailAddressEmpty 	 bYN
			,	@IsMailCityEmpty 		 bYN
			,	@IsMailStateEmpty 		 bYN
			,	@IsMailCountryEmpty 	 bYN
			,	@IsMailZipEmpty 		 bYN
			,	@IsMailAddress2Empty 	 bYN
			,	@IsShipAddressEmpty 	 bYN
			,	@IsShipCityEmpty 		 bYN
			,	@IsShipStateEmpty 		 bYN
			,	@IsShipCountryEmpty 	 bYN
			,	@IsShipZipEmpty 		 bYN
			,	@IsShipAddress2Empty 	 bYN
			,	@IsPRStateCodeEmpty 	 bYN
			,	@IsPRLocalCodeEmpty 	 bYN
			,	@IsCertifiedEmpty 		 bYN
			,	@IsEEORegionEmpty 		 bYN
			,	@IsSMSACodeEmpty 		 bYN
			,	@IsCraftTemplateEmpty 	 bYN
			,	@IsOTSchedEmpty 		 bYN
			,	@IsRateTemplateEmpty 	 bYN
			,	@IsWghtAvgOTEmpty 		 bYN
			,	@IsSLCompGroupEmpty 	 bYN
			,	@IsPOCompGroupEmpty 	 bYN
			,	@IsPriceTemplateEmpty 	 bYN
			,	@IsHaulTaxOptEmpty 		 bYN
			,	@IsHrsPerManDayEmpty 	 bYN
			,	@IsSecurityGroupEmpty 	 bYN
			,	@IsGeoCodeEmpty 		 bYN
			,	@IsNotesEmpty 			 bYN

	SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
	SELECT @OverwriteJobStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JobStatus', @rectype);
	SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype);
	SELECT @OverwriteBaseTaxOn = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BaseTaxOn', @rectype);
	SELECT @OverwriteMarkUpDiscRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MarkUpDiscRate', @rectype);
	SELECT @OverwriteProjMinPct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ProjMinPct', @rectype);
	SELECT @OverwriteWghtAvgOT = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'WghtAvgOT', @rectype);
	SELECT @OverwriteHaulTaxOpt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulTaxOpt', @rectype);
	SELECT @OverwriteHrsPerManDay = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HrsPerManDay', @rectype);
	SELECT @OverwriteSecurityGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SecurityGroup', @rectype);
	SELECT @OverwriteLockPhases = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LockPhases', @rectype);
	SELECT @OverwriteCertified = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Certified', @rectype);
	SELECT @OverwriteUpdatePlugs = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UpdatePlugs', @rectype);
	SELECT @OverwriteAutoAddItemYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AutoAddItemYN', @rectype);
	SELECT @OverwriteAutoGenSubNo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AutoGenSubNo', @rectype);
	SELECT @OverwriteContract = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Contract', @rectype);
	SELECT @OverwritePRStateCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRStateCode', @rectype);
	SELECT @OverwriteShipAddress = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ShipAddress', @rectype);
	SELECT @OverwriteShipCity = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ShipCity', @rectype);
	SELECT @OverwriteShipState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ShipState', @rectype);
	SELECT @OverwriteShipZip = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ShipZip', @rectype);
	SELECT @OverwriteShipAddress2 = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ShipAddress2', @rectype);
   
   
   --get database default values	
   exec bspHQTaxGrpGet @Company, @DefTaxGroup output, @desc output
   exec bspVADataTypeSecurityGet 'bJob', @DefSecurityGroup output, @SecurityOn output, @desc output
   
   --set common defaults
   
   select @JCCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @Company
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @JCCoID
   end
   
   select @JobStatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JobStatus'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJobStatus, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '1'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @JobStatusID
   end
   
   select @TaxGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxGroup'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @DefTaxGroup
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @TaxGroupID
   end
   
   select @BaseTaxOnID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BaseTaxOn'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBaseTaxOn, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'J'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @BaseTaxOnID
   end
   
   select @MarkUpDiscRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MarkUpDiscRate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMarkUpDiscRate, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MarkUpDiscRateID
   end
   
   select @ProjMinPctID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ProjMinPct'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteProjMinPct, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ProjMinPctID
   end
   
   select @WghtAvgOTID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'WghtAvgOT'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteWghtAvgOT, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @WghtAvgOTID
   end
   
   select @HaulTaxOptID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulTaxOpt'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteHaulTaxOpt, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @HaulTaxOptID
   end
   
   select @HrsPerManDayID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HrsPerManDay'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteHrsPerManDay, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '8'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @HrsPerManDayID
   end
   
   select @SecurityGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SecurityGroup'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' and @SecurityOn = 'Y' AND (ISNULL(@OverwriteSecurityGroup, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @DefSecurityGroup
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @SecurityGroupID
   end
   
   select @LockPhasesID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LockPhases'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteLockPhases, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @LockPhasesID
   end
   
   select @CertifiedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Certified'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCertified, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CertifiedID
   end
   
   select @UpdatePlugsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UpdatePlugs'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUpdatePlugs, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @UpdatePlugsID
   end
   
   select @AutoAddItemYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AutoAddItemYN'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAutoAddItemYN, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @AutoAddItemYNID
   end
   
   select @AutoGenSubNoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AutoGenSubNo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAutoGenSubNo, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'T'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @AutoGenSubNoID
   end
   
   --------------------------------
      select @JCCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCCo, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @Company
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @JCCoID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @JobStatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JobStatus'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJobStatus, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '1'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @JobStatusID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @TaxGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxGroup'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @DefTaxGroup
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @TaxGroupID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @BaseTaxOnID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BaseTaxOn'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBaseTaxOn, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'J'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @BaseTaxOnID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @MarkUpDiscRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MarkUpDiscRate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMarkUpDiscRate, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MarkUpDiscRateID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @ProjMinPctID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ProjMinPct'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteProjMinPct, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ProjMinPctID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @WghtAvgOTID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'WghtAvgOT'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteWghtAvgOT, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @WghtAvgOTID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @HaulTaxOptID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulTaxOpt'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteHaulTaxOpt, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @HaulTaxOptID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @HrsPerManDayID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HrsPerManDay'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteHrsPerManDay, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '8'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @HrsPerManDayID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @SecurityGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SecurityGroup'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' and @SecurityOn = 'Y' AND (ISNULL(@OverwriteSecurityGroup, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @DefSecurityGroup
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @SecurityGroupID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @LockPhasesID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LockPhases'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteLockPhases, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @LockPhasesID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @CertifiedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Certified'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCertified, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CertifiedID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @UpdatePlugsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UpdatePlugs'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUpdatePlugs, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @UpdatePlugsID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @AutoAddItemYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AutoAddItemYN'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAutoAddItemYN, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @AutoAddItemYNID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @AutoGenSubNoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AutoGenSubNo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAutoGenSubNo, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'T'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @AutoGenSubNoID
   	AND IMWE.UploadVal IS NULL
   end
   
   
   --Get Identifiers for dependent defaults.
   select @ynContract = 'N'
   select @ContractID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Contract', @rectype, 'Y')
   if @ContractID <> 0 select @ynContract = 'Y'
   
   select @ynPRStateCode = 'N'
   select @PRStateCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PRStateCode', @rectype, 'Y')
   if @PRStateCodeID <> 0 select @ynPRStateCode = 'Y'
   
   select @ynShipAddress = 'N'
   select @ShipAddressID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ShipAddress', @rectype, 'Y')
   if @ShipAddressID <> 0 select @ynShipAddress = 'Y'
   
   select @ynShipCity = 'N'
   select @ShipCityID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ShipCity', @rectype, 'Y')
   if @ShipCityID <> 0 select @ynShipCity = 'Y'
   
   select @ynShipState = 'N'
   select @ShipStateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ShipState', @rectype, 'Y')
   if @ShipStateID <> 0 select @ynShipState = 'Y'
   
   select @ynShipZip = 'N'
   select @ShipZipID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ShipZip', @rectype, 'Y')
   if @ShipZipID <> 0 select @ynShipZip = 'Y'
   
   select @ynShipAddress2 = 'N'
   select @ShipAddress2ID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ShipAddress2', @rectype, 'Y')
   if @ShipAddress2ID <> 0 select @ynShipAddress2 = 'Y'
   
   
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
   
       If @Column = 'Job' select @Job = @Uploadval
   	If @Column = 'MailAddress' select @MailAddress = @Uploadval
   	If @Column = 'MailCity' select @MailCity = @Uploadval
   	If @Column = 'MailState' select @MailState = @Uploadval
   	If @Column = 'MailZip' select @MailZip = @Uploadval
   	If @Column = 'MailAddress2' select @MailAddress2 = @Uploadval

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
	IF @Column='Description' 
		IF @Uploadval IS NULL
			SET @IsDescriptionEmpty = 'Y'
		ELSE
			SET @IsDescriptionEmpty = 'N'
	IF @Column='Contract' 
		IF @Uploadval IS NULL
			SET @IsContractEmpty = 'Y'
		ELSE
			SET @IsContractEmpty = 'N'
	IF @Column='JobStatus' 
		IF @Uploadval IS NULL
			SET @IsJobStatusEmpty = 'Y'
		ELSE
			SET @IsJobStatusEmpty = 'N'
	IF @Column='ProjectMgr' 
		IF @Uploadval IS NULL
			SET @IsProjectMgrEmpty = 'Y'
		ELSE
			SET @IsProjectMgrEmpty = 'N'
	IF @Column='BidNumber' 
		IF @Uploadval IS NULL
			SET @IsBidNumberEmpty = 'Y'
		ELSE
			SET @IsBidNumberEmpty = 'N'
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
	IF @Column='BaseTaxOn' 
		IF @Uploadval IS NULL
			SET @IsBaseTaxOnEmpty = 'Y'
		ELSE
			SET @IsBaseTaxOnEmpty = 'N'
	IF @Column='LiabTemplate' 
		IF @Uploadval IS NULL
			SET @IsLiabTemplateEmpty = 'Y'
		ELSE
			SET @IsLiabTemplateEmpty = 'N'
	IF @Column='InsTemplate' 
		IF @Uploadval IS NULL
			SET @IsInsTemplateEmpty = 'Y'
		ELSE
			SET @IsInsTemplateEmpty = 'N'
	IF @Column='MarkUpDiscRate' 
		IF @Uploadval IS NULL
			SET @IsMarkUpDiscRateEmpty = 'Y'
		ELSE
			SET @IsMarkUpDiscRateEmpty = 'N'
	IF @Column='ProjMinPct' 
		IF @Uploadval IS NULL
			SET @IsProjMinPctEmpty = 'Y'
		ELSE
			SET @IsProjMinPctEmpty = 'N'
	IF @Column='LockPhases' 
		IF @Uploadval IS NULL
			SET @IsLockPhasesEmpty = 'Y'
		ELSE
			SET @IsLockPhasesEmpty = 'N'
	IF @Column='UpdatePlugs' 
		IF @Uploadval IS NULL
			SET @IsUpdatePlugsEmpty = 'Y'
		ELSE
			SET @IsUpdatePlugsEmpty = 'N'
	IF @Column='JobPhone' 
		IF @Uploadval IS NULL
			SET @IsJobPhoneEmpty = 'Y'
		ELSE
			SET @IsJobPhoneEmpty = 'N'
	IF @Column='JobFax' 
		IF @Uploadval IS NULL
			SET @IsJobFaxEmpty = 'Y'
		ELSE
			SET @IsJobFaxEmpty = 'N'
	IF @Column='MailAddress' 
		IF @Uploadval IS NULL
			SET @IsMailAddressEmpty = 'Y'
		ELSE
			SET @IsMailAddressEmpty = 'N'
	IF @Column='MailCity' 
		IF @Uploadval IS NULL
			SET @IsMailCityEmpty = 'Y'
		ELSE
			SET @IsMailCityEmpty = 'N'
	IF @Column='MailState' 
		IF @Uploadval IS NULL
			SET @IsMailStateEmpty = 'Y'
		ELSE
			SET @IsMailStateEmpty = 'N'
	IF @Column='MailCountry' 
		IF @Uploadval IS NULL
			SET @IsMailCountryEmpty = 'Y'
		ELSE
			SET @IsMailCountryEmpty = 'N'
	IF @Column='MailZip' 
		IF @Uploadval IS NULL
			SET @IsMailZipEmpty = 'Y'
		ELSE
			SET @IsMailZipEmpty = 'N'
	IF @Column='MailAddress2' 
		IF @Uploadval IS NULL
			SET @IsMailAddress2Empty = 'Y'
		ELSE
			SET @IsMailAddress2Empty = 'N'
	IF @Column='ShipAddress' 
		IF @Uploadval IS NULL
			SET @IsShipAddressEmpty = 'Y'
		ELSE
			SET @IsShipAddressEmpty = 'N'
	IF @Column='ShipCity' 
		IF @Uploadval IS NULL
			SET @IsShipCityEmpty = 'Y'
		ELSE
			SET @IsShipCityEmpty = 'N'
	IF @Column='ShipState' 
		IF @Uploadval IS NULL
			SET @IsShipStateEmpty = 'Y'
		ELSE
			SET @IsShipStateEmpty = 'N'
	IF @Column='ShipCountry' 
		IF @Uploadval IS NULL
			SET @IsShipCountryEmpty = 'Y'
		ELSE
			SET @IsShipCountryEmpty = 'N'
	IF @Column='ShipZip' 
		IF @Uploadval IS NULL
			SET @IsShipZipEmpty = 'Y'
		ELSE
			SET @IsShipZipEmpty = 'N'
	IF @Column='ShipAddress2' 
		IF @Uploadval IS NULL
			SET @IsShipAddress2Empty = 'Y'
		ELSE
			SET @IsShipAddress2Empty = 'N'
	IF @Column='PRStateCode' 
		IF @Uploadval IS NULL
			SET @IsPRStateCodeEmpty = 'Y'
		ELSE
			SET @IsPRStateCodeEmpty = 'N'
	IF @Column='PRLocalCode' 
		IF @Uploadval IS NULL
			SET @IsPRLocalCodeEmpty = 'Y'
		ELSE
			SET @IsPRLocalCodeEmpty = 'N'
	IF @Column='Certified' 
		IF @Uploadval IS NULL
			SET @IsCertifiedEmpty = 'Y'
		ELSE
			SET @IsCertifiedEmpty = 'N'
	IF @Column='EEORegion' 
		IF @Uploadval IS NULL
			SET @IsEEORegionEmpty = 'Y'
		ELSE
			SET @IsEEORegionEmpty = 'N'
	IF @Column='SMSACode' 
		IF @Uploadval IS NULL
			SET @IsSMSACodeEmpty = 'Y'
		ELSE
			SET @IsSMSACodeEmpty = 'N'
	IF @Column='CraftTemplate' 
		IF @Uploadval IS NULL
			SET @IsCraftTemplateEmpty = 'Y'
		ELSE
			SET @IsCraftTemplateEmpty = 'N'
	IF @Column='OTSched' 
		IF @Uploadval IS NULL
			SET @IsOTSchedEmpty = 'Y'
		ELSE
			SET @IsOTSchedEmpty = 'N'
	IF @Column='RateTemplate' 
		IF @Uploadval IS NULL
			SET @IsRateTemplateEmpty = 'Y'
		ELSE
			SET @IsRateTemplateEmpty = 'N'
	IF @Column='WghtAvgOT' 
		IF @Uploadval IS NULL
			SET @IsWghtAvgOTEmpty = 'Y'
		ELSE
			SET @IsWghtAvgOTEmpty = 'N'
	IF @Column='SLCompGroup' 
		IF @Uploadval IS NULL
			SET @IsSLCompGroupEmpty = 'Y'
		ELSE
			SET @IsSLCompGroupEmpty = 'N'
	IF @Column='POCompGroup' 
		IF @Uploadval IS NULL
			SET @IsPOCompGroupEmpty = 'Y'
		ELSE
			SET @IsPOCompGroupEmpty = 'N'
	IF @Column='PriceTemplate' 
		IF @Uploadval IS NULL
			SET @IsPriceTemplateEmpty = 'Y'
		ELSE
			SET @IsPriceTemplateEmpty = 'N'
	IF @Column='HaulTaxOpt' 
		IF @Uploadval IS NULL
			SET @IsHaulTaxOptEmpty = 'Y'
		ELSE
			SET @IsHaulTaxOptEmpty = 'N'
	IF @Column='HrsPerManDay' 
		IF @Uploadval IS NULL
			SET @IsHrsPerManDayEmpty = 'Y'
		ELSE
			SET @IsHrsPerManDayEmpty = 'N'
	IF @Column='SecurityGroup' 
		IF @Uploadval IS NULL
			SET @IsSecurityGroupEmpty = 'Y'
		ELSE
			SET @IsSecurityGroupEmpty = 'N'
	IF @Column='GeoCode' 
		IF @Uploadval IS NULL
			SET @IsGeoCodeEmpty = 'Y'
		ELSE
			SET @IsGeoCodeEmpty = 'N'
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
   	if @ynContract = 'Y' AND (ISNULL(@OverwriteContract, 'Y') = 'Y' OR ISNULL(@IsContractEmpty, 'Y') = 'Y')
   	begin
   		UPDATE IMWE
   		SET IMWE.UploadVal = @Job
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@ContractID and IMWE.RecordType=@rectype
   	end
   	if @ynPRStateCode = 'Y' AND (ISNULL(@OverwritePRStateCode, 'Y') = 'Y' OR ISNULL(@IsPRStateCodeEmpty, 'Y') = 'Y')
   	begin
   		UPDATE IMWE
   		SET IMWE.UploadVal = @MailState
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@PRStateCodeID and IMWE.RecordType=@rectype
   	end
   	if @ynShipAddress = 'Y' AND (ISNULL(@OverwriteShipAddress, 'Y') = 'Y' OR ISNULL(@IsShipAddressEmpty, 'Y') = 'Y')
   	begin
   		UPDATE IMWE
   		SET IMWE.UploadVal = @MailAddress
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@ShipAddressID and IMWE.RecordType=@rectype
   	end
   	if @ynShipCity = 'Y' AND (ISNULL(@OverwriteShipCity, 'Y') = 'Y' OR ISNULL(@IsShipCityEmpty, 'Y') = 'Y')
   	begin
   		UPDATE IMWE
   		SET IMWE.UploadVal = @MailCity
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@ShipCityID and IMWE.RecordType=@rectype
   	end
   	if @ynShipState = 'Y' AND (ISNULL(@OverwriteShipState, 'Y') = 'Y' OR ISNULL(@IsShipStateEmpty, 'Y') = 'Y')
   	begin
   		UPDATE IMWE
   		SET IMWE.UploadVal = @MailState
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@ShipStateID and IMWE.RecordType=@rectype
   	end
   	if @ynShipZip = 'Y' AND (ISNULL(@OverwriteShipZip, 'Y') = 'Y' OR ISNULL(@IsShipZipEmpty, 'Y') = 'Y')
   	begin
   		UPDATE IMWE
   		SET IMWE.UploadVal = @MailZip
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@ShipZipID and IMWE.RecordType=@rectype
   	end
   	if @ynShipAddress2 = 'Y' AND (ISNULL(@OverwriteShipAddress2, 'Y') = 'Y' OR ISNULL(@IsShipAddress2Empty, 'Y') = 'Y')
   	begin
   		UPDATE IMWE
   		SET IMWE.UploadVal = @MailAddress2
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@ShipAddress2ID and IMWE.RecordType=@rectype
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
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsARCM]'
   
       return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsJCJM] TO [public]
GO
