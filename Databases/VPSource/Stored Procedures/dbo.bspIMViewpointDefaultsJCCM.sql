
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsJCCM]
/***********************************************************
* CREATED BY:	RBT	06/21/2004	- Issue #24373
* MODIFIED BY:	CC	08/07/2008	- Issue #128919 - Added update for StartMonth to correctly format into month format
*				CC	09/22/2008	- Issue #128919 - Corrected to use @StartMonth instead of @UploadVal
*				CC	02/18/2009	- Issue #24531 - Use default only if set to overwrite or value is null
*				TJL 01/11/2010	- Issue #137430, Add Maximum Retainage Fields to import
*				CHS 01/15/2010	- Issue #135068
*				GF 09/14/2010 - issue #141031 changed to use vfDateOnly, vfDateOnlyMonth
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
* 
* Defaulted Columns:
*	JCCo, RetainagePCT, TaxInterface, ContractStatus, StartMonth, OriginalDays, CurrentDays,
*	SIMetric, CustGroup, TaxGroup, DefaultBillType, JBTemplate, SecurityGroup.
*	
************************************************************/
   
(@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), 
	@Form varchar(20), @rectype varchar(30), @msg varchar(120) output)
   
as

set nocount on

declare @rcode int, @desc varchar(120), @status int, @defaultvalue varchar(30), @CursorOpen int

--Identifiers
   
declare @JCCoID int, @CustGroupID int, @RetainagePCTID int, @TaxGroupID int, @SIMetricID int,
	@TaxInterfaceID int, @ContractStatusID int, @StartMonthID int, @OriginalDaysID int, 
	@CurrentDaysID int, @DefaultBillTypeID int, @JBTemplateID int, @SecurityGroupID int,
	@MaxRetgOptID int, @MaxRetgPctID int, @MaxRetgAmtID int, @InclACOinMaxYNID int, @MaxRetgDistStyleID int,
	---- #135068
	@RoundOptID int, @JBFlatBillingAmtID int, @JBLimitOptID	int,
	@BillOnCompletionYNID int, @ReportRetgItemYNID int, 
	@zOriginalDaysID int, @zCurrentDaysID int, @nStartMonthID int, @nContractStatusID int,
	@nTaxInterfaceID int, @zRetainagePCTID int, @nDefaultBillTypeID int, @zOrigContractAmtID int, 
	@zContractAmtID int, @zBilledAmtID int, @zReceivedAmtID int, @zCurrentRetainAmtID int, 
	@nBillOnCompletionYNID int, @nCompleteYNID int, @nRoundOptID int, @nReportRetgItemYNID int,
	@zJBFlatBillingAmtID int, @zJBLimitOptID int, @nUpdateJCCIID int, @nMaxRetgOptID int,
	@zMaxRetgPctID int, @zMaxRetgAmtID int, @nInclACOinMaxYNID int, @nMaxRetgDistStyleID int
	   
   --Values
declare @JCCo bCompany, @CustGroup bGroup, @ARCo bCompany, @TaxGroup bGroup,
	@DefaultBillType bBillType, @JBTemplate varchar(10), @SecurityGroup int, @SecurityOn bYN, @StartMonth varchar(30),
	@MaxRetgOpt char(1), @MaxRetgPct bPct, @MaxRetgAmt bDollar
	

   
SET @StartMonth = NULL

--Flags for dependent defaults
declare @ynCustGroup bYN, @ynTaxGroup bYN, @ynDefaultBillType bYN, @ynJBTemplate bYN, @ynSecurityGroup bYN,
	@ynMaxRetgOpt bYN
   
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
   
DECLARE  @OverwriteJCCo 	 			 bYN
			, @OverwriteRetainagePCT 	 bYN
			, @OverwriteTaxInterface 	 bYN
			, @OverwriteContractStatus 	 bYN
			, @OverwriteStartMonth 	 	 bYN
			, @OverwriteOriginalDays 	 bYN
			, @OverwriteCurrentDays 	 bYN
			, @OverwriteSIMetric 	 	 bYN
			, @OverwriteCustGroup 	 	 bYN
			, @OverwriteTaxGroup 	 	 bYN
			, @OverwriteDefaultBillType	 bYN
			, @OverwriteJBTemplate 	 	 bYN
			, @OverwriteSecurityGroup 	 bYN
			, @OverwriteMaxRetgOpt		 bYN
			, @OverwriteMaxRetgPct		 bYN
			, @OverwriteMaxRetgAmt		 bYN
			, @OverwriteInclACOinMaxYN	 bYN
			, @OverwriteMaxRetgDistStyle bYN
			---- #135068
			, @OverwriteRoundOpt		 bYN			
			, @OverwriteJBFlatBillingAmt bYN
			, @OverwriteJBLimitOpt		 bYN
			, @OverwriteBillOnCompletionYN	bYN
			, @OverwriteReportRetgItemYN	bYN

			
DECLARE	@IsJCCoEmpty 					 bYN
			,	@IsContractEmpty 		 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsDepartmentEmpty 		 bYN
			,	@IsCustGroupEmpty 		 bYN
			,	@IsCustomerEmpty 		 bYN
			,	@IsPayTermsEmpty 		 bYN
			,	@IsRetainagePCTEmpty 	 bYN
			,	@IsBillDayOfMthEmpty 	 bYN
			,	@IsTaxCodeEmpty 		 bYN
			,	@IsTaxGroupEmpty 		 bYN
			,	@IsTaxInterfaceEmpty 	 bYN
			,	@IsContractStatusEmpty 	 bYN
			,	@IsNotesEmpty 			 bYN
			,	@IsStartMonthEmpty 		 bYN
			,	@IsMonthClosedEmpty 	 bYN
			,	@IsProjCloseDateEmpty 	 bYN
			,	@IsActualCloseDateEmpty  bYN
			,	@IsOriginalDaysEmpty 	 bYN
			,	@IsCurrentDaysEmpty 	 bYN
			,	@IsDefaultBillTypeEmpty  bYN
			,	@IsJBTemplateEmpty 		 bYN
			,	@IsSIRegionEmpty 		 bYN
			,	@IsSIMetricEmpty 		 bYN
			,	@IsSecurityGroupEmpty 	 bYN
			,	@IsBillCountryEmpty 	 bYN
			,	@IsBillNotesEmpty 		 bYN
			,	@IsMaxRetgOptEmpty		 bYN
			,	@IsMaxRetgPctEmpty		 bYN
			,	@IsMaxRetgAmtEmpty		 bYN
			,	@IsInclACOinMaxYNEmpty	 bYN
			,	@IsMaxRetgDistStyleEmpty bYN
			
			---- #135068			
			,	@IsRoundOptEmpty		 bYN
			,	@IsJBFlatBillingAmtEmpty bYN
			,	@IsJBLimitOptEmpty		 bYN
			,	@IsBillOnCompletionYN	 bYN
			,	@IsReportRetgItemYN		 bYN
			
			
			

/* Get the Overwrite template setting */
SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
SELECT @OverwriteRetainagePCT = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RetainagePCT', @rectype);
SELECT @OverwriteTaxInterface = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxInterface', @rectype);
SELECT @OverwriteContractStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ContractStatus', @rectype);
SELECT @OverwriteStartMonth = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StartMonth', @rectype);
SELECT @OverwriteOriginalDays = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OriginalDays', @rectype);
SELECT @OverwriteCurrentDays = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CurrentDays', @rectype);
SELECT @OverwriteSIMetric = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SIMetric', @rectype);
SELECT @OverwriteCustGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CustGroup', @rectype);
SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype);
SELECT @OverwriteDefaultBillType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DefaultBillType', @rectype);
SELECT @OverwriteJBTemplate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JBTemplate', @rectype);
SELECT @OverwriteSecurityGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SecurityGroup', @rectype);
SELECT @OverwriteMaxRetgOpt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MaxRetgOpt', @rectype);
SELECT @OverwriteMaxRetgPct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MaxRetgPct', @rectype);
SELECT @OverwriteMaxRetgAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MaxRetgAmt', @rectype);
SELECT @OverwriteInclACOinMaxYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InclACOinMaxYN', @rectype);
SELECT @OverwriteMaxRetgDistStyle = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MaxRetgDistStyle', @rectype);
---- #135068
SELECT @OverwriteRoundOpt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RoundOpt', @rectype);		
SELECT @OverwriteJBFlatBillingAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JBFlatBillingAmt', @rectype);
SELECT @OverwriteJBLimitOpt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JBLimitOpt', @rectype);
SELECT @OverwriteBillOnCompletionYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BillOnCompletionYN', @rectype);
SELECT @OverwriteReportRetgItemYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ReportRetgItemYN', @rectype);



---- #135068
--Used to set required columns to ZERO when not otherwise set by a default. (Cleanup: See end of procedure) 
select @zRetainagePCTID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RetainagePCT', @rectype, 'N')
select @zOrigContractAmtID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OrigContractAmt', @rectype, 'N')
select @zContractAmtID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ContractAmt', @rectype, 'N')
select @zBilledAmtID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BilledAmt', @rectype, 'N')
select @zReceivedAmtID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ReceivedAmt', @rectype, 'N')
select @zCurrentRetainAmtID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CurrentRetainAmt', @rectype, 'N')
select @zJBFlatBillingAmtID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JBFlatBillingAmt', @rectype, 'N')
select @zJBLimitOptID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JBLimitOpt', @rectype, 'N')
select @zMaxRetgPctID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MaxRetgPct', @rectype, 'N')
select @zMaxRetgAmtID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MaxRetgAmt', @rectype, 'N')

---- #135068
--Used to set required columns to 'N' when not otherwise set by a default. (Cleanup: See end of procedure) 
select @zOriginalDaysID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OriginalDays', @rectype, 'N')
select @zCurrentDaysID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CurrentDays', @rectype, 'N')
select @nStartMonthID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StartMonth', @rectype, 'N')
select @nContractStatusID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ContractStatus', @rectype, 'N')
select @nTaxInterfaceID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxInterface', @rectype, 'N')
select @nDefaultBillTypeID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DefaultBillType', @rectype, 'N')
select @nBillOnCompletionYNID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BillOnCompletionYN', @rectype, 'N')
select @nCompleteYNID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CompleteYN', @rectype, 'N')
select @nRoundOptID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RoundOpt', @rectype, 'N')
select @nReportRetgItemYNID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ReportRetgItemYN', @rectype, 'N')
select @nUpdateJCCIID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UpdateJCCI', @rectype, 'N')
select @nMaxRetgOptID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MaxRetgOpt', @rectype, 'N')
select @nInclACOinMaxYNID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'InclACOinMaxYN', @rectype, 'N')
select @nMaxRetgDistStyleID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MaxRetgDistStyle', @rectype, 'N')


	   
-- get database default values	
   
-- Multiple IMWE Seq Update: set common defaults 
-- Default those template fields setup to use VP Defaults and setup to Overwrite imported values
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

select @MaxRetgPctID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MaxRetgPct'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMaxRetgPct, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @MaxRetgPctID
	end
	
select @MaxRetgAmtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MaxRetgAmt'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMaxRetgAmt, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @MaxRetgAmtID
	end
	
select @InclACOinMaxYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InclACOinMaxYN'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteInclACOinMaxYN, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'Y'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @InclACOinMaxYNID
	end
	
select @MaxRetgDistStyleID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MaxRetgDistStyle'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMaxRetgDistStyle, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'C'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @MaxRetgDistStyleID
	end

select @RetainagePCTID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RetainagePCT'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteRetainagePCT, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @RetainagePCTID
	end
   
select @TaxInterfaceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxInterface'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteTaxInterface, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @TaxInterfaceID
	end
   
select @ContractStatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ContractStatus'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteContractStatus, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '1'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @ContractStatusID
	end
   
select @StartMonthID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'StartMonth'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteStartMonth, 'Y') = 'Y')
	begin
	Update IMWE
	----#141031
	SET IMWE.UploadVal = CONVERT(VARCHAR(10), dbo.vfDateOnlyMonth(), 101)
	----SET IMWE.UploadVal = '0' + convert(varchar(2), month(getxdate())) + '/01/' + convert(varchar(4), year(getxdate()))
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @StartMonthID
	end
   
select @OriginalDaysID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OriginalDays'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOriginalDays, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @OriginalDaysID
	end
   
select @CurrentDaysID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CurrentDays'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCurrentDays, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @CurrentDaysID
	end
   
select @SIMetricID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SIMetric'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSIMetric, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @SIMetricID
	end
	
	


---- #135068   @RoundOptID @JBFlatBillingAmtID @JBLimitOptID @PotentialProjectID
select @RoundOptID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RoundOpt'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteRoundOpt, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @RoundOptID
	end   
	
select @JBFlatBillingAmtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JBFlatBillingAmt'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJBFlatBillingAmt, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @JBFlatBillingAmtID
	end   
   
select @JBLimitOptID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JBLimitOpt'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJBLimitOpt, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @JBLimitOptID
	end  
	
select @BillOnCompletionYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BillOnCompletionYN'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBillOnCompletionYN, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @BillOnCompletionYNID
	end  
	
select @ReportRetgItemYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ReportRetgItemYN'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReportRetgItemYN, 'Y') = 'Y') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @ReportRetgItemYNID
	end  	
	
	
	
	
	
   
-- Multiple IMWE Seq Update:  Default those template fields setup to use VP Defaults but NOT setup to Overwrite and for which
-- no value has been imported.
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

select @MaxRetgPctID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MaxRetgPct'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMaxRetgPct, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @MaxRetgPctID
	AND IMWE.UploadVal IS NULL
	end
	
select @MaxRetgAmtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MaxRetgAmt'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMaxRetgAmt, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @MaxRetgAmtID
	AND IMWE.UploadVal IS NULL
	end
	
select @InclACOinMaxYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InclACOinMaxYN'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteInclACOinMaxYN, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'Y'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @InclACOinMaxYNID
	AND IMWE.UploadVal IS NULL
	end
	
select @MaxRetgDistStyleID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MaxRetgDistStyle'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMaxRetgDistStyle, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'C'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @MaxRetgDistStyleID
	AND IMWE.UploadVal IS NULL
	end	

select @RetainagePCTID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RetainagePCT'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteRetainagePCT, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @RetainagePCTID
	AND IMWE.UploadVal IS NULL
	end
   
select @TaxInterfaceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxInterface'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteTaxInterface, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @TaxInterfaceID
	AND IMWE.UploadVal IS NULL
	end
   
select @ContractStatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ContractStatus'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteContractStatus, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '1'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @ContractStatusID
	AND IMWE.UploadVal IS NULL
	end
   
select @StartMonthID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'StartMonth'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteStartMonth, 'Y') = 'N')
	begin
	Update IMWE
	----#141031
	SET IMWE.UploadVal = CONVERT(VARCHAR(10), dbo.vfDateOnlyMonth(), 101)
	----SET IMWE.UploadVal = '0' + convert(varchar(2), month(getxdate())) + '/01/' + convert(varchar(4), year(getxdate()))
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @StartMonthID
	AND IMWE.UploadVal IS NULL
	end
   
select @OriginalDaysID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OriginalDays'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOriginalDays, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @OriginalDaysID
	AND IMWE.UploadVal IS NULL
	end
   
select @CurrentDaysID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CurrentDays'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCurrentDays, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @CurrentDaysID
	AND IMWE.UploadVal IS NULL
	end
   
select @SIMetricID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SIMetric'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSIMetric, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @SIMetricID
	AND IMWE.UploadVal IS NULL
	end
   
   
   
---- #135068   @RoundOptID @JBFlatBillingAmtID @JBLimitOptID @PotentialProjectID
select @RoundOptID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RoundOpt'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteRoundOpt, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @RoundOptID
	AND IMWE.UploadVal IS NULL
	end   
	
select @JBFlatBillingAmtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JBFlatBillingAmt'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJBFlatBillingAmt, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @JBFlatBillingAmtID
	AND IMWE.UploadVal IS NULL
	end   
   
select @JBLimitOptID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JBLimitOpt'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJBLimitOpt, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @JBLimitOptID
	AND IMWE.UploadVal IS NULL
	end  
   
select @BillOnCompletionYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BillOnCompletionYN'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBillOnCompletionYN, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @BillOnCompletionYNID
	AND IMWE.UploadVal IS NULL
	end  
	
select @ReportRetgItemYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ReportRetgItemYN'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReportRetgItemYN, 'Y') = 'N') 
	begin
	Update IMWE
	SET IMWE.UploadVal = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @ReportRetgItemYNID
	AND IMWE.UploadVal IS NULL
	end  	
	






--Get Identifiers for dependent defaults.
select @ynCustGroup = 'N'
select @CustGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustGroup', @rectype, 'Y')
if @CustGroupID <> 0 select @ynCustGroup = 'Y'

select @ynMaxRetgOpt = 'N'
select @MaxRetgOptID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MaxRetgOpt', @rectype, 'Y')
if @MaxRetgOptID <> 0 select @ynMaxRetgOpt = 'Y'

select @ynTaxGroup = 'N'
select @TaxGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxGroup', @rectype, 'Y')
if @TaxGroupID <> 0 select @ynTaxGroup = 'Y'

select @ynDefaultBillType = 'N'
select @DefaultBillTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DefaultBillType', @rectype, 'Y')
if @DefaultBillTypeID <> 0 select @ynDefaultBillType = 'Y'

select @ynJBTemplate = 'N'
select @JBTemplateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JBTemplate', @rectype, 'Y')
if @JBTemplateID <> 0 select @ynJBTemplate = 'Y'

select @ynSecurityGroup = 'N'
select @SecurityGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SecurityGroup', @rectype, 'Y')
if @SecurityGroupID <> 0 select @ynSecurityGroup = 'Y'




   
-- Single IMWE record update:  Start Processing
DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD FOR
SELECT IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
FROM IMWE with (nolock)
INNER join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
WHERE IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
ORDER BY IMWE.RecordSeq, IMWE.Identifier

open WorkEditCursor
-- set open cursor flag
select @CursorOpen = 1
--#142350 - removed following items	@importid varchar(10), @seq int, @Identifier int,
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
	   
		-- Get the current value (imported or defaulted) for the following fields
		If @Column = 'JCCo' select @JCCo = @Uploadval
		IF @Column = 'StartMonth' SELECT @StartMonth = @Uploadval
		IF @Column = 'MaxRetgPct' SELECT @MaxRetgPct = @Uploadval
		IF @Column = 'MaxRetgAmt' SELECT @MaxRetgAmt = @Uploadval

		-- Set each field flag.  During single IMWE record defaults, these have the potential for being used
		-- as part of the evaluation of when to default a value for a particular IMWE sequence and field.
		IF @Column='JCCo' 
			IF @Uploadval IS NULL
				SET @IsJCCoEmpty = 'Y'
			ELSE
				SET @IsJCCoEmpty = 'N'
		IF @Column='Contract' 
			IF @Uploadval IS NULL
				SET @IsContractEmpty = 'Y'
			ELSE
				SET @IsContractEmpty = 'N'
		IF @Column='Description' 
			IF @Uploadval IS NULL
				SET @IsDescriptionEmpty = 'Y'
			ELSE
				SET @IsDescriptionEmpty = 'N'
		IF @Column='Department' 
			IF @Uploadval IS NULL
				SET @IsDepartmentEmpty = 'Y'
			ELSE
				SET @IsDepartmentEmpty = 'N'
		IF @Column='CustGroup' 
			IF @Uploadval IS NULL
				SET @IsCustGroupEmpty = 'Y'
			ELSE
				SET @IsCustGroupEmpty = 'N'
		IF @Column='Customer' 
			IF @Uploadval IS NULL
				SET @IsCustomerEmpty = 'Y'
			ELSE
				SET @IsCustomerEmpty = 'N'
		IF @Column='PayTerms' 
			IF @Uploadval IS NULL
				SET @IsPayTermsEmpty = 'Y'
			ELSE
				SET @IsPayTermsEmpty = 'N'
		IF @Column='MaxRetgOpt' 
			IF @Uploadval IS NULL
				SET @IsMaxRetgOptEmpty = 'Y'
			ELSE
				SET @IsMaxRetgOptEmpty = 'N'
		IF @Column='MaxRetgPct' 
			IF @Uploadval IS NULL
				SET @IsMaxRetgPctEmpty = 'Y'
			ELSE
				SET @IsMaxRetgPctEmpty = 'N'
		IF @Column='MaxRetgAmt' 
			IF @Uploadval IS NULL
				SET @IsMaxRetgAmtEmpty = 'Y'
			ELSE
				SET @IsMaxRetgAmtEmpty = 'N'
		IF @Column='InclACOinMaxYN' 
			IF @Uploadval IS NULL
				SET @IsInclACOinMaxYNEmpty = 'Y'
			ELSE
				SET @IsInclACOinMaxYNEmpty = 'N'
		IF @Column='MaxRetgDistStyle' 
			IF @Uploadval IS NULL
				SET @IsMaxRetgDistStyleEmpty = 'Y'
			ELSE
				SET @IsMaxRetgDistStyleEmpty = 'N'
		IF @Column='RetainagePCT' 
			IF @Uploadval IS NULL
				SET @IsRetainagePCTEmpty = 'Y'
			ELSE
				SET @IsRetainagePCTEmpty = 'N'
		IF @Column='BillDayOfMth' 
			IF @Uploadval IS NULL
				SET @IsBillDayOfMthEmpty = 'Y'
			ELSE
				SET @IsBillDayOfMthEmpty = 'N'
		IF @Column='TaxCode' 
			IF @Uploadval IS NULL
				SET @IsTaxCodeEmpty = 'Y'
			ELSE
				SET @IsTaxCodeEmpty = 'N'
		IF @Column='TaxGroup' 
			IF @Uploadval IS NULL
				SET @IsTaxGroupEmpty = 'Y'
			ELSE
				SET @IsTaxGroupEmpty = 'N'
		IF @Column='TaxInterface' 
			IF @Uploadval IS NULL
				SET @IsTaxInterfaceEmpty = 'Y'
			ELSE
				SET @IsTaxInterfaceEmpty = 'N'
		IF @Column='ContractStatus' 
			IF @Uploadval IS NULL
				SET @IsContractStatusEmpty = 'Y'
			ELSE
				SET @IsContractStatusEmpty = 'N'
		IF @Column='Notes' 
			IF @Uploadval IS NULL
				SET @IsNotesEmpty = 'Y'
			ELSE
				SET @IsNotesEmpty = 'N'
		IF @Column='StartMonth' 
			IF @Uploadval IS NULL
				SET @IsStartMonthEmpty = 'Y'
			ELSE
				SET @IsStartMonthEmpty = 'N'
		IF @Column='MonthClosed' 
			IF @Uploadval IS NULL
				SET @IsMonthClosedEmpty = 'Y'
			ELSE
				SET @IsMonthClosedEmpty = 'N'
		IF @Column='ProjCloseDate' 
			IF @Uploadval IS NULL
				SET @IsProjCloseDateEmpty = 'Y'
			ELSE
				SET @IsProjCloseDateEmpty = 'N'
		IF @Column='ActualCloseDate' 
			IF @Uploadval IS NULL
				SET @IsActualCloseDateEmpty = 'Y'
			ELSE
				SET @IsActualCloseDateEmpty = 'N'
		IF @Column='OriginalDays' 
			IF @Uploadval IS NULL
				SET @IsOriginalDaysEmpty = 'Y'
			ELSE
				SET @IsOriginalDaysEmpty = 'N'
		IF @Column='CurrentDays' 
			IF @Uploadval IS NULL
				SET @IsCurrentDaysEmpty = 'Y'
			ELSE
				SET @IsCurrentDaysEmpty = 'N'
		IF @Column='DefaultBillType' 
			IF @Uploadval IS NULL
				SET @IsDefaultBillTypeEmpty = 'Y'
			ELSE
				SET @IsDefaultBillTypeEmpty = 'N'
		IF @Column='JBTemplate' 
			IF @Uploadval IS NULL
				SET @IsJBTemplateEmpty = 'Y'
			ELSE
				SET @IsJBTemplateEmpty = 'N'
		IF @Column='SIRegion' 
			IF @Uploadval IS NULL
				SET @IsSIRegionEmpty = 'Y'
			ELSE
				SET @IsSIRegionEmpty = 'N'
		IF @Column='SIMetric' 
			IF @Uploadval IS NULL
				SET @IsSIMetricEmpty = 'Y'
			ELSE
				SET @IsSIMetricEmpty = 'N'
		IF @Column='SecurityGroup' 
			IF @Uploadval IS NULL
				SET @IsSecurityGroupEmpty = 'Y'
			ELSE
				SET @IsSecurityGroupEmpty = 'N'
		IF @Column='BillCountry' 
			IF @Uploadval IS NULL
				SET @IsBillCountryEmpty = 'Y'
			ELSE
				SET @IsBillCountryEmpty = 'N'
		IF @Column='BillNotes' 
			IF @Uploadval IS NULL
				SET @IsBillNotesEmpty = 'Y'
			ELSE
				SET @IsBillNotesEmpty = 'N'
				

				
		---- #135068				
		IF @Column='RoundOpt' 
			IF @Uploadval IS NULL
				SET @IsRoundOptEmpty = 'Y'
			ELSE
				SET @IsRoundOptEmpty = 'N'
				
		IF @Column='JBFlatBillingAmt' 
			IF @Uploadval IS NULL
				SET @IsJBFlatBillingAmtEmpty = 'Y'
			ELSE
				SET @IsJBFlatBillingAmtEmpty = 'N'
				
		IF @Column='JBLimitOpt' 
			IF @Uploadval IS NULL
				SET @IsJBLimitOptEmpty = 'Y'
			ELSE
				SET @IsJBLimitOptEmpty = 'N'
	
		IF @Column='IsBillOnCompletionYN' 
			IF @Uploadval IS NULL
				SET @IsBillOnCompletionYN = 'Y'
			ELSE
				SET @IsBillOnCompletionYN = 'N'
				
		IF @Column='IsReportRetgItemYN' 
			IF @Uploadval IS NULL
				SET @IsReportRetgItemYN = 'Y'
			ELSE
				SET @IsReportRetgItemYN = 'N'		
																
				

		select @oldrecseq = @Recseq
   
		--fetch next record
		fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
   		-- if this is the last record, set the sequence to -1 to process last record.
   		if @@fetch_status <> 0 
   		select @Recseq = -1
   
		end
	else
		begin
		/* A DIFFERENT import RecordSeq has been detected.  Before moving on, set the default values for our previous Import Record. */
		
		/*************************************** SET DEFAULT VALUES ****************************************/
		/* At this moment, all columns of a single imported record have been processed above.  The defaults for 
		   this single imported record will be set below before the cursor moves on to the columns of the next
		   imported record. */
   		-- set values that depend on other columns
   		if @ynCustGroup = 'Y'  AND (ISNULL(@OverwriteCustGroup, 'Y') = 'Y' OR ISNULL(@IsCustGroupEmpty, 'Y') = 'Y')
   			begin
   			select @ARCo = ARCo from JCCO with (nolock) where JCCo = @JCCo
   			exec bspHQCustGrpGet @ARCo, @CustGroup output, @msg output
   
   			UPDATE IMWE
   			SET IMWE.UploadVal = @CustGroup
   			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   				and IMWE.Identifier=@CustGroupID and IMWE.RecordType=@rectype
   
   			end
  
		if @ynMaxRetgOpt = 'Y'  AND (ISNULL(@OverwriteMaxRetgOpt, 'Y') = 'Y' OR ISNULL(@IsMaxRetgOptEmpty, 'Y') = 'Y')
   			begin
   			select @MaxRetgOpt = case when isnull(@MaxRetgPct, 0) = 0 and isnull(@MaxRetgAmt, 0) = 0 then 'N'
   				when isnull(@MaxRetgPct, 0) <> 0 and isnull(@MaxRetgAmt, 0) = 0 then 'P'
   				when isnull(@MaxRetgPct, 0) = 0 and isnull(@MaxRetgAmt, 0) <> 0 then 'A'
   				else 'N' end
   
   			UPDATE IMWE
   			SET IMWE.UploadVal = @MaxRetgOpt
   			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   				and IMWE.Identifier=@MaxRetgOptID and IMWE.RecordType=@rectype
   			end
   			 
   		if @ynTaxGroup = 'Y' AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y' OR ISNULL(@IsTaxGroupEmpty, 'Y') = 'Y')
   			begin
   			exec bspHQTaxGrpGet @JCCo, @TaxGroup output, @msg output
   
   			UPDATE IMWE
   			SET IMWE.UploadVal = @TaxGroup
   			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   				and IMWE.Identifier=@TaxGroupID and IMWE.RecordType=@rectype
   			end
   
   		if @ynDefaultBillType = 'Y' AND (ISNULL(@OverwriteDefaultBillType, 'Y') = 'Y' OR ISNULL(@IsDefaultBillTypeEmpty, 'Y') = 'Y')
   			begin
   			Select @DefaultBillType = DefaultBillType from JCCO with (nolock) where JCCo = @JCCo 
   
   			UPDATE IMWE
   			SET IMWE.UploadVal = @DefaultBillType
   			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   				and IMWE.Identifier=@DefaultBillTypeID and IMWE.RecordType=@rectype
   			end
   
   		if @ynJBTemplate = 'Y'  AND (ISNULL(@OverwriteJBTemplate, 'Y') = 'Y' OR ISNULL(@IsJBTemplateEmpty, 'Y') = 'Y')
   			begin
   			Select @JBTemplate = JBTemplate from JBCO with (nolock) where JBCo = @JCCo
   
   			UPDATE IMWE
   			SET IMWE.UploadVal = @JBTemplate
   			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   				and IMWE.Identifier=@JBTemplateID and IMWE.RecordType=@rectype
   			end
   
   		if @ynSecurityGroup = 'Y' AND (ISNULL(@OverwriteSecurityGroup, 'Y') = 'Y' OR ISNULL(@IsSecurityGroupEmpty, 'Y') = 'Y')
   			begin
   			exec bspVADataTypeSecurityGet 'bContract', @SecurityGroup output, @SecurityOn output, @msg output
   		
   			if @SecurityOn = 'Y' 
   				begin
   				UPDATE IMWE
   				SET IMWE.UploadVal = @SecurityGroup
   				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   					and IMWE.Identifier=@SecurityGroupID and IMWE.RecordType=@rectype
   				end
   			end

		IF @StartMonth IS NOT NULL
			BEGIN
			DECLARE	@ReturnDate VARCHAR(30)
			EXEC [dbo].[vspIMFormatDate] @DateValue = @StartMonth
									 , @SourceFormat = N'MDY'
									 , @DestinationFormat = N'MDY'
									 , @ConvertToMonthFormat = 'Y'
									 , @ReturnDate = @ReturnDate OUTPUT

			UPDATE IMWE
			SET IMWE.UploadVal = @ReturnDate
			WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq=@currrecseq
				AND IMWE.Identifier = @StartMonthID AND IMWE.RecordType = @rectype
			END


		SET @StartMonth = NULL
   
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
   	
---- #135068   	
/* Set required (dollar) inputs to 0 where not already set with some other value */          
UPDATE IMWE
SET IMWE.UploadVal = 0.00
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'')='' and
	(IMWE.Identifier = @zOrigContractAmtID 
		or IMWE.Identifier = @zOriginalDaysID
		or IMWE.Identifier = @zCurrentDaysID
		or IMWE.Identifier = @zJBFlatBillingAmtID 
		or IMWE.Identifier = @zJBLimitOptID	
		or IMWE.Identifier = @zMaxRetgAmtID)

---- #135068		
/* Set required (pct) inputs to 0 where not already set with some other value */       	
UPDATE IMWE
SET IMWE.UploadVal = 0.00000
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'')='' and
	(IMWE.Identifier = @zRetainagePCTID   	
   		or IMWE.Identifier = @zMaxRetgPctID)
 
---- #135068  	
/* Set required (Y/N) inputs to 'N' where not already set with some other value */       
UPDATE IMWE
SET IMWE.UploadVal = 'N'
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') not in ('N','Y') and
	(IMWE.Identifier = @nTaxInterfaceID
		or IMWE.Identifier = @nBillOnCompletionYNID
		or IMWE.Identifier = @nReportRetgItemYNID)

---- #135068   	
/* Set required (Y/N) inputs to 'Y' where not already set with some other value */       
UPDATE IMWE
SET IMWE.UploadVal = 'Y'
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') not in ('N','Y') and
	(IMWE.Identifier = @nInclACOinMaxYNID)

---- #135068
/* Set required (style) inputs to 'C' where not already set with some other value */       
UPDATE IMWE
SET IMWE.UploadVal = 'C'
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') not in ('I','C') and
	(IMWE.Identifier = @nMaxRetgDistStyleID)

---- #135068		
/* Set required (bill type) inputs to 'N' where not already set with some other value */       
UPDATE IMWE
SET IMWE.UploadVal = 'N'
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') not in ('N','B','T','P') and
	(IMWE.Identifier = @nDefaultBillTypeID)

---- #135068
/* Set required (jb limit option) inputs to 'N' where not already set with some other value */       
UPDATE IMWE
SET IMWE.UploadVal = 'N'
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') not in ('I','C','N') and
	(IMWE.Identifier = @zJBLimitOptID)

---- #135068
/* Set required (round option) inputs to 'N' where not already set with some other value */       
UPDATE IMWE
SET IMWE.UploadVal = 'N'
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') not in ('R','B','N') and
	(IMWE.Identifier = @nRoundOptID)

---- #135068
/* Set required (max retainage option) inputs to 'N' where not already set with some other value */       
UPDATE IMWE
SET IMWE.UploadVal = 'N'
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') not in ('N','P','A') and
	(IMWE.Identifier = @nMaxRetgOptID)
	
 ---- #135068
/* Set required (start month) input to todays date where not already set with some other value */       
UPDATE IMWE
SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(), 101)
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') = '' and
	(IMWE.Identifier = @nStartMonthID)
	  
 ---- #135068
/* Set required (Contract Status) input to todays date where not already set with some other value */       
UPDATE IMWE
SET IMWE.UploadVal = 1
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') = '' and
	(IMWE.Identifier = @nContractStatusID)
	
   
select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsJCCM]'
   
return @rcode





GO

GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsJCCM] TO [public]
GO
