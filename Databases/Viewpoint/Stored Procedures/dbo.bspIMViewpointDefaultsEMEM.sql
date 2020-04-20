SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsEMEM]
/***********************************************************
* CREATED BY:   RBT 03/04/04 - #23941
* MODIFIED BY:  RBT 11/19/04 - #26257, fix default for PhaseGroup, add CustGroup and VendorGroup.
*			RBT 05/16/05 - #28692, add defaults for APCo and ARCo.
*			TRL 12/31/2008 - #131598 Add defaults for Original Equipment Code and ChangeInProgress
*		CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
*			DAN SO 06/18/09 - Issue: #132538 - Added ExpLifeTimeFrame
*			AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
*
* Usage: Used by Imports to create values for needed or missing
* data based upon Viewpoint default rules.
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
      
declare @rcode int, @desc varchar(120), @status int, @defaultvalue varchar(30), @CursorOpen int, @recode int
      
--Identifiers
declare @EMCoID int, @UpdateYNID int, @JCCoID int, @EMGroupID int, @MatlGroupID int, @StatusID int,
@TypeID int, @FuelTypeID int, @PRCoID int, @AttachPostRevenueID int, @CompUpdateHrsID int,
@CompUpdateMilesID int, @CompUpdateFuelID int, @PostCostToCompID int, @OwnershipStatusID int,
@CapitalizedID int,	@ShopGroupID int, @HourReadingID int, @ReplacedHourReadingID int, 
@OdoReadingID int, @ReplacedOdoReadingID int, @FuelUsedID int, @FuelCapacityID int, 
@WeightCapacityID int, @VolumeCapacityID int, @TareWeightID int, @GrossVehicleWeightID int, 
@NoAxlesID int, @PurchasePriceID int, @LeasePaymentID int, @LeaseResidualValueID int, 
@ExpLifeID int, @ExpLifeTimeFrameID int, @ReplCostID int, @CurrentAppraisalID int, @SalePriceID int,
@PhaseGroupID int, @CustGroupID int, @VendorGroupID int, @APCoID int, @ARCoID int,
/* Issue 131589 */
@OriginalEquipmentCodeID int, @DefEquipmentID int
      
--Values
declare @DefJCCo bCompany, @DefEMGroup bGroup, @DefMatlGroup bGroup, @APCo bCompany, @ARCo bCompany,
@DefPRCo bCompany, @DefCompUnattachedEquip bEquip, @DefPostCostsToComp bYN, @EMCo bCompany,
@DefShopGroup bGroup, @JCCo bCompany, @PhaseGroup bGroup, @CustGroup bGroup, @VendorGroup bGroup,
/* Issue 131589 */
@DefEquipment bEquip, @DefEquipmentRecSeq int
      
--Flags for dependent defaults
declare @ynPhaseGroup bYN, @ynCustGroup bYN, @ynVendorGroup bYN, @ynAPCo bYN, @ynARCo bYN
      
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
if not exists(select top 1 1 From IMTD with (nolock) Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
    and IMTD.RecordType = @rectype)
begin
    goto bspexit
end     
 
 DECLARE 
			  @OverwriteJCCo 	 			 	bYN
			, @OverwriteEMGroup 	 		 	bYN
			, @OverwriteMatlGroup 	 		 	bYN
			, @OverwriteStatus 	 			 	bYN
			, @OverwriteType 	 			 	bYN
			, @OverwriteFuelType 	 		 	bYN
			, @OverwritePRCo 	 			 	bYN
			, @OverwriteAttachPostRevenue 	 	bYN
			, @OverwriteCompUpdateHrs 	 	 	bYN
			, @OverwriteCompUpdateMiles 	 	bYN
			, @OverwriteCompUpdateFuel 	 	 	bYN
			, @OverwritePostCostToComp 	 	 	bYN
			, @OverwriteOwnershipStatus 	 	bYN
			, @OverwriteCapitalized 	 	 	bYN
			, @OverwriteShopGroup 	 		 	bYN
			, @OverwriteHourReading 	 	 	bYN
			, @OverwriteReplacedHourReading  	bYN
			, @OverwriteOdoReading 	 		 	bYN
			, @OverwriteReplacedOdoReading 	 	bYN
			, @OverwriteFuelUsed 	 		 	bYN
			, @OverwriteFuelCapacity 	 	 	bYN
			, @OverwriteWeightCapacity 	 	 	bYN
			, @OverwriteVolumeCapacity 	 	 	bYN
			, @OverwriteTareWeight 	 		 	bYN
			, @OverwriteGrossVehicleWeight 	 	bYN
			, @OverwriteNoAxles 	 		 	bYN
			, @OverwritePurchasePrice 	 	 	bYN
			, @OverwriteLeasePayment 	 	 	bYN
			, @OverwriteLeaseResidualValue 	 	bYN
			, @OverwriteExpLife 	 		 	bYN
			, @OverwriteExpLifeTimeFrame		bYN
			, @OverwriteReplCost 	 		 	bYN
			, @OverwriteCurrentAppraisal 	 	bYN
			, @OverwriteSalePrice 	 		 	bYN
			, @OverwriteOriginalEquipmentCode 	bYN
			, @OverwriteEquipment 	 			bYN
			, @OverwritePhaseGrp 	 			bYN
			, @OverwriteCustGroup 	 			bYN
			, @OverwriteVendorGroup 	 		bYN
			, @OverwriteAPCo 	 				bYN
			, @OverwriteARCo 	 				bYN
			,	@IsEMCoEmpty 					 bYN
			,	@IsEquipmentEmpty 				 bYN
			,	@IsPhaseGrpEmpty 				 bYN
			,	@IsEMGroupEmpty 				 bYN
			,	@IsVINNumberEmpty 				 bYN
			,	@IsMatlGroupEmpty 				 bYN
			,	@IsCustGroupEmpty 				 bYN
			,	@IsVendorGroupEmpty 			 bYN
			,	@IsDescriptionEmpty 			 bYN
			,	@IsManufacturerEmpty 			 bYN
			,	@IsModelEmpty 					 bYN
			,	@IsModelYrEmpty 				 bYN
			,	@IsStatusEmpty 					 bYN
			,	@IsTypeEmpty 					 bYN
			,	@IsCategoryEmpty 				 bYN
			,	@IsDepartmentEmpty 				 bYN
			,	@IsLocationEmpty 				 bYN
			,	@IsShopEmpty 					 bYN
			,	@IsRevenueCodeEmpty 			 bYN
			,	@IsUsageCostTypeEmpty 			 bYN
			,	@IsNotesEmpty 					 bYN
			,	@IsPRCoEmpty 					 bYN
			,	@IsOperatorEmpty 				 bYN
			,	@IsJCCoEmpty 					 bYN
			,	@IsJobEmpty 					 bYN
			,	@IsJobDateEmpty 				 bYN
			,	@IsLastUsedDateEmpty 			 bYN
			,	@IsLicensePlateNoEmpty 			 bYN
			,	@IsLicensePlateStateEmpty 		 bYN
			,	@IsLicensePlateExpDateEmpty 	 bYN
			,	@IsIRPFleetEmpty 				 bYN
			,	@IsHourReadingEmpty 			 bYN
			,	@IsHourDateEmpty 				 bYN
			,	@IsReplacedHourReadingEmpty 	 bYN
			,	@IsReplacedHourDateEmpty 		 bYN
			,	@IsOdoReadingEmpty 				 bYN
			,	@IsOdoDateEmpty 				 bYN
			,	@IsReplacedOdoReadingEmpty 		 bYN
			,	@IsReplacedOdoDateEmpty 		 bYN
			,	@IsFuelUsedEmpty 				 bYN
			,	@IsLastFuelDateEmpty 			 bYN
			,	@IsFuelTypeEmpty 				 bYN
			,	@IsFuelMatlCodeEmpty 			 bYN
			,	@IsFuelCostCodeEmpty 			 bYN
			,	@IsFuelCostTypeEmpty 			 bYN
			,	@IsFuelCapacityEmpty 			 bYN
			,	@IsFuelCapUMEmpty 				 bYN
			,	@IsWeightUMEmpty 				 bYN
			,	@IsWeightCapacityEmpty 			 bYN
			,	@IsVolumeUMEmpty 				 bYN
			,	@IsVolumeCapacityEmpty 		 	 bYN
			,	@IsTareWeightEmpty 			 	 bYN
			,	@IsGrossVehicleWeightEmpty 	 	 bYN
			,	@IsHeightEmpty 				 	 bYN
			,	@IsWheelbaseEmpty 				 bYN
			,	@IsNoAxlesEmpty 				 bYN
			,	@IsAttachToEquipEmpty 			 bYN
			,	@IsAttachPostRevenueEmpty 		 bYN
			,	@IsCompOfEquipEmpty 			 bYN
			,	@IsComponentTypeCodeEmpty 		 bYN
			,	@IsCompUpdateHrsEmpty 			 bYN
			,	@IsCompUpdateMilesEmpty 		 bYN
			,	@IsCompUpdateFuelEmpty 			 bYN
			,	@IsPostCostToCompEmpty 			 bYN
			,	@IsCapitalizedEmpty 			 bYN
			,	@IsWidthEmpty 					 bYN
			,	@IsOverallLengthEmpty 			 bYN
			,	@IsHorsePowerEmpty 				 bYN
			,	@IsTireSizeEmpty 				 bYN
			,	@IsMSTruckTypeEmpty 			 bYN
			,	@IsOwnershipStatusEmpty 		 bYN
			,	@IsPurchasedFromEmpty 			 bYN
			,	@IsPurchDateEmpty 				 bYN
			,	@IsPurchasePriceEmpty 			 bYN
			,	@IsAPCoEmpty 					 bYN
			,	@IsLeasedFromEmpty 				 bYN
			,	@IsLeaseStartDateEmpty 			 bYN
			,	@IsLeaseEndDateEmpty 			 bYN
			,	@IsLeasePaymentEmpty 			 bYN
			,	@IsLeaseResidualValueEmpty 		 bYN
			,	@IsARCoEmpty 					 bYN
			,	@IsCustomerEmpty 				 bYN
			,	@IsCustEquipNoEmpty 			 bYN
			,	@IsInServiceDateEmpty 			 bYN
			,	@IsExpLifeEmpty 				 bYN
			,	@IsExpLifeTimeFrameEmpty		 bYN
			,	@IsSoldDateEmpty 				 bYN
			,	@IsReplCostEmpty 				 bYN
			,	@IsCurrentAppraisalEmpty 		 bYN
			,	@IsSalePriceEmpty 				 bYN
			,	@IsUpdateYNEmpty 				 bYN
			,	@IsMechanicNotesEmpty 			 bYN
			,	@IsIFTAStateEmpty 				 bYN
			,	@IsShopGroupEmpty 				 bYN
			,	@IsOriginalEquipmentCodeEmpty 	 bYN


 
		SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
		SELECT @OverwriteEMGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMGroup', @rectype);
		SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
		SELECT @OverwriteStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Status', @rectype);
		SELECT @OverwriteType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Type', @rectype);
		SELECT @OverwriteFuelType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FuelType', @rectype);
		SELECT @OverwritePRCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRCo', @rectype);
		SELECT @OverwriteAttachPostRevenue = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AttachPostRevenue', @rectype);
		SELECT @OverwriteCompUpdateHrs = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CompUpdateHrs', @rectype);
		SELECT @OverwriteCompUpdateMiles = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CompUpdateMiles', @rectype);
		SELECT @OverwriteCompUpdateFuel = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CompUpdateFuel', @rectype);
		SELECT @OverwritePostCostToComp = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PostCostToComp', @rectype);
		SELECT @OverwriteOwnershipStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OwnershipStatus', @rectype);
		SELECT @OverwriteCapitalized = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Capitalized', @rectype);
		SELECT @OverwriteShopGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ShopGroup', @rectype);
		SELECT @OverwriteHourReading = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HourReading', @rectype);
		SELECT @OverwriteReplacedHourReading = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ReplacedHourReading', @rectype);
		SELECT @OverwriteOdoReading = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OdoReading', @rectype);
		SELECT @OverwriteReplacedOdoReading = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ReplacedOdoReading', @rectype);
		SELECT @OverwriteFuelUsed = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FuelUsed', @rectype);
		SELECT @OverwriteFuelCapacity = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FuelCapacity', @rectype);
		SELECT @OverwriteWeightCapacity = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'WeightCapacity', @rectype);
		SELECT @OverwriteVolumeCapacity = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VolumeCapacity', @rectype);
		SELECT @OverwriteTareWeight = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TareWeight', @rectype);
		SELECT @OverwriteGrossVehicleWeight = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GrossVehicleWeight', @rectype);
		SELECT @OverwriteNoAxles = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'NoAxles', @rectype);
		SELECT @OverwritePurchasePrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PurchasePrice', @rectype);
		SELECT @OverwriteLeasePayment = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LeasePayment', @rectype);
		SELECT @OverwriteLeaseResidualValue = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LeaseResidualValue', @rectype);
		SELECT @OverwriteExpLife = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ExpLife', @rectype);
		SELECT @OverwriteExpLifeTimeFrame = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ExpLifeTimeFrame', @rectype);
		SELECT @OverwriteReplCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ReplCost', @rectype);
		SELECT @OverwriteCurrentAppraisal = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CurrentAppraisal', @rectype);
		SELECT @OverwriteSalePrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SalePrice', @rectype);
		SELECT @OverwriteOriginalEquipmentCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OriginalEquipmentCode', @rectype);
		SELECT @OverwriteEquipment = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Equipment', @rectype);
		SELECT @OverwritePhaseGrp = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGrp', @rectype);
		SELECT @OverwriteCustGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CustGroup', @rectype);
		SELECT @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype);
		SELECT @OverwriteAPCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'APCo', @rectype);
		SELECT @OverwriteARCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ARCo', @rectype);


 
--get database default values	
select @DefJCCo = JCCo, @DefPRCo = PRCo, @DefCompUnattachedEquip = CompUnattachedEquip, @DefPostCostsToComp = CompPostCosts
from bEMCO with (nolock) where EMCo = @Company 
    
select @DefEMGroup = EMGroup, @DefMatlGroup = MatlGroup, @DefShopGroup = ShopGroup
from bHQCO with (nolock) where HQCo = @Company
     
--set common defaults
select @EMCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue 
From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMCo'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
begin
	UPDATE IMWE
	SET IMWE.UploadVal = @Company
    where IMWE.ImportTemplate=@ImportTemplate and 
    IMWE.ImportId=@ImportId and IMWE.Identifier = @EMCoID
end

/******* Issue 131589 ********/
select @OriginalEquipmentCodeID = DDUD.Identifier From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OriginalEquipmentCode'
 
--Get Equipment column Identifier
select @DefEquipmentID = DDUD.Identifier From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Equipment'
/******* Issue 131589 ********/
   
      
select @JCCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y')
begin
	Update IMWE
    SET IMWE.UploadVal = @DefJCCo
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @JCCoID
end
      
select @EMGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMGroup'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteEMGroup, 'Y') = 'Y') 
begin
	Update IMWE
  	SET IMWE.UploadVal = @DefEMGroup
  	where IMWE.ImportTemplate=@ImportTemplate and
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @EMGroupID
end
      
select @MatlGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MatlGroup'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = @DefMatlGroup
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MatlGroupID
end
      
select @StatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Status'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteStatus, 'Y') = 'Y') 
begin
 	Update IMWE
  	SET IMWE.UploadVal = 'A'
  	where IMWE.ImportTemplate=@ImportTemplate and
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @StatusID
end
      
select @TypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Type'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteType, 'Y') = 'Y') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = 'E'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @TypeID
end
      
select @FuelTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'FuelType'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteFuelType, 'Y') = 'Y') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @FuelTypeID
end
      
select @PRCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PRCo'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePRCo, 'Y') = 'Y') 
begin
  	Update IMWE
  	SET IMWE.UploadVal = @DefPRCo
  	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PRCoID
end
      
select @AttachPostRevenueID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AttachPostRevenue'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAttachPostRevenue, 'Y') = 'Y') 
begin
   	Update IMWE
  	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @AttachPostRevenueID
end
      
select @CompUpdateHrsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CompUpdateHrs'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCompUpdateHrs, 'Y') = 'Y') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = 'Y'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompUpdateHrsID
end
      
select @CompUpdateMilesID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CompUpdateMiles'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCompUpdateMiles, 'Y') = 'Y') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = 'Y'
  	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompUpdateMilesID
end
      
select @CompUpdateFuelID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CompUpdateFuel'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCompUpdateFuel, 'Y') = 'Y') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = 'Y'
   	where IMWE.ImportTemplate=@ImportTemplate and
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompUpdateFuelID
end
      
select @PostCostToCompID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PostCostToComp'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePostCostToComp, 'Y') = 'Y') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = @DefPostCostsToComp
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PostCostToCompID
end
      
select @OwnershipStatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OwnershipStatus'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOwnershipStatus, 'Y') = 'Y') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = 'O'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @OwnershipStatusID
end
      
select @CapitalizedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Capitalized'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCapitalized, 'Y') = 'Y') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CapitalizedID
end
      
select @ShopGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ShopGroup'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteShopGroup, 'Y') = 'Y') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = @DefShopGroup
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ShopGroupID
end
      
select @HourReadingID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HourReading'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteHourReading, 'Y') = 'Y') 
begin
 	Update IMWE
  	SET IMWE.UploadVal = '0'
  	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @HourReadingID
end
      
select @ReplacedHourReadingID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ReplacedHourReading'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReplacedHourReading, 'Y') = 'Y') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ReplacedHourReadingID
end
      
select @OdoReadingID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OdoReading'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOdoReading, 'Y') = 'Y') 
begin
	Update IMWE
    sET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @OdoReadingID
end
      
select @ReplacedOdoReadingID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ReplacedOdoReading'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReplacedOdoReading, 'Y') = 'Y') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @ReplacedOdoReadingID
end
      
select @FuelUsedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'FuelUsed'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteFuelUsed, 'Y') = 'Y') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @FuelUsedID
end
      
select @FuelCapacityID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'FuelCapacity'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteFuelCapacity, 'Y') = 'Y') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @FuelCapacityID
end
      
select @WeightCapacityID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'WeightCapacity'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteWeightCapacity, 'Y') = 'Y') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @WeightCapacityID
end
      
select @VolumeCapacityID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'VolumeCapacity'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteVolumeCapacity, 'Y') = 'Y') 
begin
	Update IMWE
    set IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @VolumeCapacityID
end
      
select @TareWeightID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TareWeight'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteTareWeight, 'Y') = 'Y') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @TareWeightID
end
      
select @GrossVehicleWeightID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GrossVehicleWeight'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteGrossVehicleWeight, 'Y') = 'Y') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @GrossVehicleWeightID
end
      
select @NoAxlesID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'NoAxles'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteNoAxles, 'Y') = 'Y') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @NoAxlesID
end
      
select @PurchasePriceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PurchasePrice'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePurchasePrice, 'Y') = 'Y') 
begin
  	Update IMWE
  	SET IMWE.UploadVal = '0'
  	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PurchasePriceID
end
      
select @LeasePaymentID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LeasePayment'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteLeasePayment, 'Y') = 'Y') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @LeasePaymentID
end
      
select @LeaseResidualValueID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LeaseResidualValue'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteLeaseResidualValue, 'Y') = 'Y') 
begin
	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @LeaseResidualValueID
end
      
select @ExpLifeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ExpLife'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteExpLife, 'Y') = 'Y') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ExpLifeID
end
     
select @ExpLifeTimeFrameID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ExpLifeTimeFrame'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteExpLifeTimeFrame, 'Y') = 'Y') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = 'Y'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ExpLifeTimeFrameID
end
     
     
select @ReplCostID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ReplCost'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReplCost, 'Y') = 'Y') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ReplCostID
end
      
select @CurrentAppraisalID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CurrentAppraisal'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCurrentAppraisal, 'Y') = 'Y') 
begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @CurrentAppraisalID
end

select @SalePriceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SalePrice'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSalePrice, 'Y') = 'Y') 
begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @SalePriceID
end


---------------------

select @JCCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJCCo, 'Y') = 'N')
begin
	Update IMWE
    SET IMWE.UploadVal = @DefJCCo
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @JCCoID
	AND IMWE.UploadVal IS NULL
end
      
select @EMGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMGroup'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteEMGroup, 'Y') = 'N') 
begin
	Update IMWE
  	SET IMWE.UploadVal = @DefEMGroup
  	where IMWE.ImportTemplate=@ImportTemplate and
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @EMGroupID
  	AND IMWE.UploadVal IS NULL
end
      
select @MatlGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MatlGroup'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'N') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = @DefMatlGroup
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MatlGroupID
   	AND IMWE.UploadVal IS NULL
end
      
select @StatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Status'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteStatus, 'Y') = 'N') 
begin
 	Update IMWE
  	SET IMWE.UploadVal = 'A'
  	where IMWE.ImportTemplate=@ImportTemplate and
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @StatusID
  	AND IMWE.UploadVal IS NULL
end
      
select @TypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Type'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteType, 'Y') = 'N') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = 'E'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @TypeID
   	AND IMWE.UploadVal IS NULL
end
      
select @FuelTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'FuelType'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteFuelType, 'Y') = 'N') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @FuelTypeID
   	AND IMWE.UploadVal IS NULL
end
      
select @PRCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PRCo'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePRCo, 'Y') = 'N') 
begin
  	Update IMWE
  	SET IMWE.UploadVal = @DefPRCo
  	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PRCoID
   	AND IMWE.UploadVal IS NULL
end
      
select @AttachPostRevenueID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AttachPostRevenue'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAttachPostRevenue, 'Y') = 'N') 
begin
   	Update IMWE
  	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @AttachPostRevenueID
  	AND IMWE.UploadVal IS NULL
end
      
select @CompUpdateHrsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CompUpdateHrs'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCompUpdateHrs, 'Y') = 'N') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = 'Y'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompUpdateHrsID
   	AND IMWE.UploadVal IS NULL
end
      
select @CompUpdateMilesID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CompUpdateMiles'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCompUpdateMiles, 'Y') = 'N') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = 'Y'
  	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompUpdateMilesID
   	AND IMWE.UploadVal IS NULL
end
      
select @CompUpdateFuelID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CompUpdateFuel'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCompUpdateFuel, 'Y') = 'N') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = 'Y'
   	where IMWE.ImportTemplate=@ImportTemplate and
  	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompUpdateFuelID
  	AND IMWE.UploadVal IS NULL
end
      
select @PostCostToCompID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PostCostToComp'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePostCostToComp, 'Y') = 'N') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = @DefPostCostsToComp
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PostCostToCompID
   	AND IMWE.UploadVal IS NULL
end
      
select @OwnershipStatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OwnershipStatus'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOwnershipStatus, 'Y') = 'N') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = 'O'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @OwnershipStatusID
   	AND IMWE.UploadVal IS NULL
end
      
select @CapitalizedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Capitalized'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCapitalized, 'Y') = 'N') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CapitalizedID
   	AND IMWE.UploadVal IS NULL
end
      
select @ShopGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ShopGroup'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteShopGroup, 'Y') = 'N') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = @DefShopGroup
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ShopGroupID
   	AND IMWE.UploadVal IS NULL
end
      
select @HourReadingID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HourReading'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteHourReading, 'Y') = 'N') 
begin
 	Update IMWE
  	SET IMWE.UploadVal = '0'
  	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @HourReadingID
   	AND IMWE.UploadVal IS NULL
end
      
select @ReplacedHourReadingID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ReplacedHourReading'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReplacedHourReading, 'Y') = 'N') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ReplacedHourReadingID
   	AND IMWE.UploadVal IS NULL
end
      
select @OdoReadingID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OdoReading'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOdoReading, 'Y') = 'N') 
begin
	Update IMWE
    sET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @OdoReadingID
    AND IMWE.UploadVal IS NULL
end
      
select @ReplacedOdoReadingID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ReplacedOdoReading'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReplacedOdoReading, 'Y') = 'N') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @ReplacedOdoReadingID
    AND IMWE.UploadVal IS NULL
end
      
select @FuelUsedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'FuelUsed'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteFuelUsed, 'Y') = 'N') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @FuelUsedID
    AND IMWE.UploadVal IS NULL
end
      
select @FuelCapacityID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'FuelCapacity'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteFuelCapacity, 'Y') = 'N') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @FuelCapacityID
    AND IMWE.UploadVal IS NULL
end
      
select @WeightCapacityID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'WeightCapacity'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteWeightCapacity, 'Y') = 'N') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @WeightCapacityID
    AND IMWE.UploadVal IS NULL
end
      
select @VolumeCapacityID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'VolumeCapacity'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteVolumeCapacity, 'Y') = 'N') 
begin
	Update IMWE
    set IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @VolumeCapacityID
    AND IMWE.UploadVal IS NULL
end
      
select @TareWeightID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TareWeight'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteTareWeight, 'Y') = 'N') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @TareWeightID
    AND IMWE.UploadVal IS NULL
end
      
select @GrossVehicleWeightID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GrossVehicleWeight'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteGrossVehicleWeight, 'Y') = 'N') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @GrossVehicleWeightID
    AND IMWE.UploadVal IS NULL
end
      
select @NoAxlesID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'NoAxles'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteNoAxles, 'Y') = 'N') 
begin
	Update IMWE
    SET IMWE.UploadVal = '0'
    where IMWE.ImportTemplate=@ImportTemplate and
    IMWE.ImportId=@ImportId and IMWE.Identifier = @NoAxlesID
    AND IMWE.UploadVal IS NULL
end
      
select @PurchasePriceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PurchasePrice'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePurchasePrice, 'Y') = 'N') 
begin
  	Update IMWE
  	SET IMWE.UploadVal = '0'
  	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @PurchasePriceID
   	AND IMWE.UploadVal IS NULL
end
      
select @LeasePaymentID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LeasePayment'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteLeasePayment, 'Y') = 'N') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @LeasePaymentID
   	AND IMWE.UploadVal IS NULL
end
      
select @LeaseResidualValueID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LeaseResidualValue'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteLeaseResidualValue, 'Y') = 'N') 
begin
	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @LeaseResidualValueID
   	AND IMWE.UploadVal IS NULL
end
      
select @ExpLifeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ExpLife'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteExpLife, 'Y') = 'N') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ExpLifeID
   	AND IMWE.UploadVal IS NULL
end
 
select @ExpLifeTimeFrameID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ExpLifeTimeFrame'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteExpLifeTimeFrame, 'Y') = 'N') 
begin
  	Update IMWE
   	SET IMWE.UploadVal = 'Y'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ExpLifeTimeFrameID
   	AND IMWE.UploadVal IS NULL
end
     
select @ReplCostID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ReplCost'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReplCost, 'Y') = 'N') 
begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ReplCostID
   	AND IMWE.UploadVal IS NULL
end
      
select @CurrentAppraisalID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CurrentAppraisal'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCurrentAppraisal, 'Y') = 'N') 
begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @CurrentAppraisalID
	AND IMWE.UploadVal IS NULL
end

select @SalePriceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SalePrice'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSalePrice, 'Y') = 'N') 
begin
	Update IMWE
	SET IMWE.UploadVal = '0'
	where IMWE.ImportTemplate=@ImportTemplate and
	IMWE.ImportId=@ImportId and IMWE.Identifier = @SalePriceID
	AND IMWE.UploadVal IS NULL
end




  --Get Identifiers for dependent defaults.
select @ynPhaseGroup = 'N'
select @PhaseGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGrp', @rectype, 'Y')
if @PhaseGroupID <> 0 select @ynPhaseGroup = 'Y'

select @ynCustGroup = 'N'
select @CustGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustGroup', @rectype, 'Y')
if @CustGroupID <> 0 select @ynCustGroup = 'Y'

select @ynVendorGroup = 'N'
select @VendorGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'Y')
if @VendorGroupID <> 0 select @ynVendorGroup = 'Y'

select @ynAPCo = 'N'
select @APCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'APCo', @rectype, 'Y')
if @APCoID <> 0 select @ynAPCo = 'Y'

select @ynARCo = 'N'
select @ARCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ARCo', @rectype, 'Y')
if @ARCoID <> 0 select @ynARCo = 'Y'
   
      
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
	--#142350 removing @importid varchar(10), @seq int, @Identifier int,
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
			If @Column = 'Equipment' select @DefEquipment = @Uploadval,@DefEquipmentRecSeq=@Recseq

			If @Column = 'EMCo' and isnumeric(@Uploadval) = 1 select @EMCo = @Uploadval
			If @Column = 'JCCo' and isnumeric(@Uploadval) = 1 select @JCCo = @Uploadval
			If @Column = 'APCo' and isnumeric(@Uploadval) = 1 select @APCo = @Uploadval		
			If @Column = 'ARCo' and isnumeric(@Uploadval) = 1 select @ARCo = @Uploadval

IF @Column='EMCo' 
	IF @Uploadval IS NULL
		SET @IsEMCoEmpty = 'Y'
	ELSE
		SET @IsEMCoEmpty = 'N'
IF @Column='Equipment' 
	IF @Uploadval IS NULL
		SET @IsEquipmentEmpty = 'Y'
	ELSE
		SET @IsEquipmentEmpty = 'N'
IF @Column='PhaseGrp' 
	IF @Uploadval IS NULL
		SET @IsPhaseGrpEmpty = 'Y'
	ELSE
		SET @IsPhaseGrpEmpty = 'N'
IF @Column='EMGroup' 
	IF @Uploadval IS NULL
		SET @IsEMGroupEmpty = 'Y'
	ELSE
		SET @IsEMGroupEmpty = 'N'
IF @Column='VINNumber' 
	IF @Uploadval IS NULL
		SET @IsVINNumberEmpty = 'Y'
	ELSE
		SET @IsVINNumberEmpty = 'N'
IF @Column='MatlGroup' 
	IF @Uploadval IS NULL
		SET @IsMatlGroupEmpty = 'Y'
	ELSE
		SET @IsMatlGroupEmpty = 'N'
IF @Column='CustGroup' 
	IF @Uploadval IS NULL
		SET @IsCustGroupEmpty = 'Y'
	ELSE
		SET @IsCustGroupEmpty = 'N'
IF @Column='VendorGroup' 
	IF @Uploadval IS NULL
		SET @IsVendorGroupEmpty = 'Y'
	ELSE
		SET @IsVendorGroupEmpty = 'N'
IF @Column='Description' 
	IF @Uploadval IS NULL
		SET @IsDescriptionEmpty = 'Y'
	ELSE
		SET @IsDescriptionEmpty = 'N'
IF @Column='Manufacturer' 
	IF @Uploadval IS NULL
		SET @IsManufacturerEmpty = 'Y'
	ELSE
		SET @IsManufacturerEmpty = 'N'
IF @Column='Model' 
	IF @Uploadval IS NULL
		SET @IsModelEmpty = 'Y'
	ELSE
		SET @IsModelEmpty = 'N'
IF @Column='ModelYr' 
	IF @Uploadval IS NULL
		SET @IsModelYrEmpty = 'Y'
	ELSE
		SET @IsModelYrEmpty = 'N'
IF @Column='Status' 
	IF @Uploadval IS NULL
		SET @IsStatusEmpty = 'Y'
	ELSE
		SET @IsStatusEmpty = 'N'
IF @Column='Type' 
	IF @Uploadval IS NULL
		SET @IsTypeEmpty = 'Y'
	ELSE
		SET @IsTypeEmpty = 'N'
IF @Column='Category' 
	IF @Uploadval IS NULL
		SET @IsCategoryEmpty = 'Y'
	ELSE
		SET @IsCategoryEmpty = 'N'
IF @Column='Department' 
	IF @Uploadval IS NULL
		SET @IsDepartmentEmpty = 'Y'
	ELSE
		SET @IsDepartmentEmpty = 'N'
IF @Column='Location' 
	IF @Uploadval IS NULL
		SET @IsLocationEmpty = 'Y'
	ELSE
		SET @IsLocationEmpty = 'N'
IF @Column='Shop' 
	IF @Uploadval IS NULL
		SET @IsShopEmpty = 'Y'
	ELSE
		SET @IsShopEmpty = 'N'
IF @Column='RevenueCode' 
	IF @Uploadval IS NULL
		SET @IsRevenueCodeEmpty = 'Y'
	ELSE
		SET @IsRevenueCodeEmpty = 'N'
IF @Column='UsageCostType' 
	IF @Uploadval IS NULL
		SET @IsUsageCostTypeEmpty = 'Y'
	ELSE
		SET @IsUsageCostTypeEmpty = 'N'
IF @Column='Notes' 
	IF @Uploadval IS NULL
		SET @IsNotesEmpty = 'Y'
	ELSE
		SET @IsNotesEmpty = 'N'
IF @Column='PRCo' 
	IF @Uploadval IS NULL
		SET @IsPRCoEmpty = 'Y'
	ELSE
		SET @IsPRCoEmpty = 'N'
IF @Column='Operator' 
	IF @Uploadval IS NULL
		SET @IsOperatorEmpty = 'Y'
	ELSE
		SET @IsOperatorEmpty = 'N'
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
IF @Column='JobDate' 
	IF @Uploadval IS NULL
		SET @IsJobDateEmpty = 'Y'
	ELSE
		SET @IsJobDateEmpty = 'N'
IF @Column='LastUsedDate' 
	IF @Uploadval IS NULL
		SET @IsLastUsedDateEmpty = 'Y'
	ELSE
		SET @IsLastUsedDateEmpty = 'N'
IF @Column='LicensePlateNo' 
	IF @Uploadval IS NULL
		SET @IsLicensePlateNoEmpty = 'Y'
	ELSE
		SET @IsLicensePlateNoEmpty = 'N'
IF @Column='LicensePlateState' 
	IF @Uploadval IS NULL
		SET @IsLicensePlateStateEmpty = 'Y'
	ELSE
		SET @IsLicensePlateStateEmpty = 'N'
IF @Column='LicensePlateExpDate' 
	IF @Uploadval IS NULL
		SET @IsLicensePlateExpDateEmpty = 'Y'
	ELSE
		SET @IsLicensePlateExpDateEmpty = 'N'
IF @Column='IRPFleet' 
	IF @Uploadval IS NULL
		SET @IsIRPFleetEmpty = 'Y'
	ELSE
		SET @IsIRPFleetEmpty = 'N'
IF @Column='HourReading' 
	IF @Uploadval IS NULL
		SET @IsHourReadingEmpty = 'Y'
	ELSE
		SET @IsHourReadingEmpty = 'N'
IF @Column='HourDate' 
	IF @Uploadval IS NULL
		SET @IsHourDateEmpty = 'Y'
	ELSE
		SET @IsHourDateEmpty = 'N'
IF @Column='ReplacedHourReading' 
	IF @Uploadval IS NULL
		SET @IsReplacedHourReadingEmpty = 'Y'
	ELSE
		SET @IsReplacedHourReadingEmpty = 'N'
IF @Column='ReplacedHourDate' 
	IF @Uploadval IS NULL
		SET @IsReplacedHourDateEmpty = 'Y'
	ELSE
		SET @IsReplacedHourDateEmpty = 'N'
IF @Column='OdoReading' 
	IF @Uploadval IS NULL
		SET @IsOdoReadingEmpty = 'Y'
	ELSE
		SET @IsOdoReadingEmpty = 'N'
IF @Column='OdoDate' 
	IF @Uploadval IS NULL
		SET @IsOdoDateEmpty = 'Y'
	ELSE
		SET @IsOdoDateEmpty = 'N'
IF @Column='ReplacedOdoReading' 
	IF @Uploadval IS NULL
		SET @IsReplacedOdoReadingEmpty = 'Y'
	ELSE
		SET @IsReplacedOdoReadingEmpty = 'N'
IF @Column='ReplacedOdoDate' 
	IF @Uploadval IS NULL
		SET @IsReplacedOdoDateEmpty = 'Y'
	ELSE
		SET @IsReplacedOdoDateEmpty = 'N'
IF @Column='FuelUsed' 
	IF @Uploadval IS NULL
		SET @IsFuelUsedEmpty = 'Y'
	ELSE
		SET @IsFuelUsedEmpty = 'N'
IF @Column='LastFuelDate' 
	IF @Uploadval IS NULL
		SET @IsLastFuelDateEmpty = 'Y'
	ELSE
		SET @IsLastFuelDateEmpty = 'N'
IF @Column='FuelType' 
	IF @Uploadval IS NULL
		SET @IsFuelTypeEmpty = 'Y'
	ELSE
		SET @IsFuelTypeEmpty = 'N'
IF @Column='FuelMatlCode' 
	IF @Uploadval IS NULL
		SET @IsFuelMatlCodeEmpty = 'Y'
	ELSE
		SET @IsFuelMatlCodeEmpty = 'N'
IF @Column='FuelCostCode' 
	IF @Uploadval IS NULL
		SET @IsFuelCostCodeEmpty = 'Y'
	ELSE
		SET @IsFuelCostCodeEmpty = 'N'
IF @Column='FuelCostType' 
	IF @Uploadval IS NULL
		SET @IsFuelCostTypeEmpty = 'Y'
	ELSE
		SET @IsFuelCostTypeEmpty = 'N'
IF @Column='FuelCapacity' 
	IF @Uploadval IS NULL
		SET @IsFuelCapacityEmpty = 'Y'
	ELSE
		SET @IsFuelCapacityEmpty = 'N'
IF @Column='FuelCapUM' 
	IF @Uploadval IS NULL
		SET @IsFuelCapUMEmpty = 'Y'
	ELSE
		SET @IsFuelCapUMEmpty = 'N'
IF @Column='WeightUM' 
	IF @Uploadval IS NULL
		SET @IsWeightUMEmpty = 'Y'
	ELSE
		SET @IsWeightUMEmpty = 'N'
IF @Column='WeightCapacity' 
	IF @Uploadval IS NULL
		SET @IsWeightCapacityEmpty = 'Y'
	ELSE
		SET @IsWeightCapacityEmpty = 'N'
IF @Column='VolumeUM' 
	IF @Uploadval IS NULL
		SET @IsVolumeUMEmpty = 'Y'
	ELSE
		SET @IsVolumeUMEmpty = 'N'
IF @Column='VolumeCapacity' 
	IF @Uploadval IS NULL
		SET @IsVolumeCapacityEmpty = 'Y'
	ELSE
		SET @IsVolumeCapacityEmpty = 'N'
IF @Column='TareWeight' 
	IF @Uploadval IS NULL
		SET @IsTareWeightEmpty = 'Y'
	ELSE
		SET @IsTareWeightEmpty = 'N'
IF @Column='GrossVehicleWeight' 
	IF @Uploadval IS NULL
		SET @IsGrossVehicleWeightEmpty = 'Y'
	ELSE
		SET @IsGrossVehicleWeightEmpty = 'N'
IF @Column='Height' 
	IF @Uploadval IS NULL
		SET @IsHeightEmpty = 'Y'
	ELSE
		SET @IsHeightEmpty = 'N'
IF @Column='Wheelbase' 
	IF @Uploadval IS NULL
		SET @IsWheelbaseEmpty = 'Y'
	ELSE
		SET @IsWheelbaseEmpty = 'N'
IF @Column='NoAxles' 
	IF @Uploadval IS NULL
		SET @IsNoAxlesEmpty = 'Y'
	ELSE
		SET @IsNoAxlesEmpty = 'N'
IF @Column='AttachToEquip' 
	IF @Uploadval IS NULL
		SET @IsAttachToEquipEmpty = 'Y'
	ELSE
		SET @IsAttachToEquipEmpty = 'N'
IF @Column='AttachPostRevenue' 
	IF @Uploadval IS NULL
		SET @IsAttachPostRevenueEmpty = 'Y'
	ELSE
		SET @IsAttachPostRevenueEmpty = 'N'
IF @Column='CompOfEquip' 
	IF @Uploadval IS NULL
		SET @IsCompOfEquipEmpty = 'Y'
	ELSE
		SET @IsCompOfEquipEmpty = 'N'
IF @Column='ComponentTypeCode' 
	IF @Uploadval IS NULL
		SET @IsComponentTypeCodeEmpty = 'Y'
	ELSE
		SET @IsComponentTypeCodeEmpty = 'N'
IF @Column='CompUpdateHrs' 
	IF @Uploadval IS NULL
		SET @IsCompUpdateHrsEmpty = 'Y'
	ELSE
		SET @IsCompUpdateHrsEmpty = 'N'
IF @Column='CompUpdateMiles' 
	IF @Uploadval IS NULL
		SET @IsCompUpdateMilesEmpty = 'Y'
	ELSE
		SET @IsCompUpdateMilesEmpty = 'N'
IF @Column='CompUpdateFuel' 
	IF @Uploadval IS NULL
		SET @IsCompUpdateFuelEmpty = 'Y'
	ELSE
		SET @IsCompUpdateFuelEmpty = 'N'
IF @Column='PostCostToComp' 
	IF @Uploadval IS NULL
		SET @IsPostCostToCompEmpty = 'Y'
	ELSE
		SET @IsPostCostToCompEmpty = 'N'
IF @Column='Capitalized' 
	IF @Uploadval IS NULL
		SET @IsCapitalizedEmpty = 'Y'
	ELSE
		SET @IsCapitalizedEmpty = 'N'
IF @Column='Width' 
	IF @Uploadval IS NULL
		SET @IsWidthEmpty = 'Y'
	ELSE
		SET @IsWidthEmpty = 'N'
IF @Column='OverallLength' 
	IF @Uploadval IS NULL
		SET @IsOverallLengthEmpty = 'Y'
	ELSE
		SET @IsOverallLengthEmpty = 'N'
IF @Column='HorsePower' 
	IF @Uploadval IS NULL
		SET @IsHorsePowerEmpty = 'Y'
	ELSE
		SET @IsHorsePowerEmpty = 'N'
IF @Column='TireSize' 
	IF @Uploadval IS NULL
		SET @IsTireSizeEmpty = 'Y'
	ELSE
		SET @IsTireSizeEmpty = 'N'
IF @Column='MSTruckType' 
	IF @Uploadval IS NULL
		SET @IsMSTruckTypeEmpty = 'Y'
	ELSE
		SET @IsMSTruckTypeEmpty = 'N'
IF @Column='OwnershipStatus' 
	IF @Uploadval IS NULL
		SET @IsOwnershipStatusEmpty = 'Y'
	ELSE
		SET @IsOwnershipStatusEmpty = 'N'
IF @Column='PurchasedFrom' 
	IF @Uploadval IS NULL
		SET @IsPurchasedFromEmpty = 'Y'
	ELSE
		SET @IsPurchasedFromEmpty = 'N'
IF @Column='PurchDate' 
	IF @Uploadval IS NULL
		SET @IsPurchDateEmpty = 'Y'
	ELSE
		SET @IsPurchDateEmpty = 'N'
IF @Column='PurchasePrice' 
	IF @Uploadval IS NULL
		SET @IsPurchasePriceEmpty = 'Y'
	ELSE
		SET @IsPurchasePriceEmpty = 'N'
IF @Column='APCo' 
	IF @Uploadval IS NULL
		SET @IsAPCoEmpty = 'Y'
	ELSE
		SET @IsAPCoEmpty = 'N'
IF @Column='LeasedFrom' 
	IF @Uploadval IS NULL
		SET @IsLeasedFromEmpty = 'Y'
	ELSE
		SET @IsLeasedFromEmpty = 'N'
IF @Column='LeaseStartDate' 
	IF @Uploadval IS NULL
		SET @IsLeaseStartDateEmpty = 'Y'
	ELSE
		SET @IsLeaseStartDateEmpty = 'N'
IF @Column='LeaseEndDate' 
	IF @Uploadval IS NULL
		SET @IsLeaseEndDateEmpty = 'Y'
	ELSE
		SET @IsLeaseEndDateEmpty = 'N'
IF @Column='LeasePayment' 
	IF @Uploadval IS NULL
		SET @IsLeasePaymentEmpty = 'Y'
	ELSE
		SET @IsLeasePaymentEmpty = 'N'
IF @Column='LeaseResidualValue' 
	IF @Uploadval IS NULL
		SET @IsLeaseResidualValueEmpty = 'Y'
	ELSE
		SET @IsLeaseResidualValueEmpty = 'N'
IF @Column='ARCo' 
	IF @Uploadval IS NULL
		SET @IsARCoEmpty = 'Y'
	ELSE
		SET @IsARCoEmpty = 'N'
IF @Column='Customer' 
	IF @Uploadval IS NULL
		SET @IsCustomerEmpty = 'Y'
	ELSE
		SET @IsCustomerEmpty = 'N'
IF @Column='CustEquipNo' 
	IF @Uploadval IS NULL
		SET @IsCustEquipNoEmpty = 'Y'
	ELSE
		SET @IsCustEquipNoEmpty = 'N'
IF @Column='InServiceDate' 
	IF @Uploadval IS NULL
		SET @IsInServiceDateEmpty = 'Y'
	ELSE
		SET @IsInServiceDateEmpty = 'N'
IF @Column='ExpLife' 
	IF @Uploadval IS NULL
		SET @IsExpLifeEmpty = 'Y'
	ELSE
		SET @IsExpLifeEmpty = 'N'
IF @Column='ExpLifeTimeFrame' 
	IF @Uploadval IS NULL
		SET @IsExpLifeTimeFrameEmpty = 'Y'
	ELSE
		SET @IsExpLifeTimeFrameEmpty = 'N'
IF @Column='SoldDate' 
	IF @Uploadval IS NULL
		SET @IsSoldDateEmpty = 'Y'
	ELSE
		SET @IsSoldDateEmpty = 'N'
IF @Column='ReplCost' 
	IF @Uploadval IS NULL
		SET @IsReplCostEmpty = 'Y'
	ELSE
		SET @IsReplCostEmpty = 'N'
IF @Column='CurrentAppraisal' 
	IF @Uploadval IS NULL
		SET @IsCurrentAppraisalEmpty = 'Y'
	ELSE
		SET @IsCurrentAppraisalEmpty = 'N'
IF @Column='SalePrice' 
	IF @Uploadval IS NULL
		SET @IsSalePriceEmpty = 'Y'
	ELSE
		SET @IsSalePriceEmpty = 'N'
IF @Column='UpdateYN' 
	IF @Uploadval IS NULL
		SET @IsUpdateYNEmpty = 'Y'
	ELSE
		SET @IsUpdateYNEmpty = 'N'
IF @Column='MechanicNotes' 
	IF @Uploadval IS NULL
		SET @IsMechanicNotesEmpty = 'Y'
	ELSE
		SET @IsMechanicNotesEmpty = 'N'
IF @Column='IFTAState' 
	IF @Uploadval IS NULL
		SET @IsIFTAStateEmpty = 'Y'
	ELSE
		SET @IsIFTAStateEmpty = 'N'
IF @Column='ShopGroup' 
	IF @Uploadval IS NULL
		SET @IsShopGroupEmpty = 'Y'
	ELSE
		SET @IsShopGroupEmpty = 'N'
IF @Column='OriginalEquipmentCode' 
	IF @Uploadval IS NULL
		SET @IsOriginalEquipmentCodeEmpty = 'Y'
	ELSE
		SET @IsOriginalEquipmentCodeEmpty = 'N'

			select @oldrecseq = @Recseq

			--fetch next record
			fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval

			-- if this is the last record, set the sequence to -1 to process last record.
			if @@fetch_status <> 0  select @Recseq = -1
		end
	else
		begin
	  		-- set values that depend on other columns
  			if @ynPhaseGroup = 'Y' and @JCCo is not null AND (ISNULL(@OverwritePhaseGrp, 'Y') = 'Y' OR ISNULL(@IsPhaseGrpEmpty, 'Y') = 'Y')
  			begin
				select @PhaseGroup = null
  				select @PhaseGroup = PhaseGroup from bHQCO with (nolock) where HQCo = @JCCo
	  
  				UPDATE IMWE
  				SET IMWE.UploadVal = @PhaseGroup
  				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  				and IMWE.Identifier=@PhaseGroupID and IMWE.RecordType=@rectype
	    	end

			if @ynAPCo = 'Y' AND (ISNULL(@OverwriteAPCo, 'Y') = 'Y' OR ISNULL(@IsAPCoEmpty, 'Y') = 'Y')
			begin
				select @APCo = @EMCo

				UPDATE IMWE
				SET IMWE.UploadVal = @APCo
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier=@APCoID and IMWE.RecordType=@rectype
			end

			if @ynARCo = 'Y' AND (ISNULL(@OverwriteARCo, 'Y') = 'Y' OR ISNULL(@IsARCoEmpty, 'Y') = 'Y')
			begin
				select @ARCo = @EMCo

				UPDATE IMWE
				SET IMWE.UploadVal = @ARCo
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier=@ARCoID and IMWE.RecordType=@rectype
			end

  			if @ynCustGroup = 'Y' and @ARCo is not null AND (ISNULL(@OverwriteCustGroup, 'Y') = 'Y' OR ISNULL(@IsCustGroupEmpty, 'Y') = 'Y')
  			begin
				select @CustGroup = null
  				exec @recode = bspHQCustGrpGet @ARCo, @CustGroup output, @msg output
		  
				if @recode <> 0 
				begin
					insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
					 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@CustGroupID)			
			
					select @rcode = 1
					select @desc = @msg
				end

  				UPDATE IMWE
  				SET IMWE.UploadVal = @CustGroup
  				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  				and IMWE.Identifier=@CustGroupID and IMWE.RecordType=@rectype
  			end

			if @ynVendorGroup = 'Y' and @APCo is not null AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'Y' OR ISNULL(@IsVendorGroupEmpty, 'Y') = 'Y')
			begin
				select @VendorGroup = null
				exec @recode = bspAPVendorGrpGet @APCo, @VendorGroup output, @msg output

				if @recode <> 0 
				begin
					insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
					 values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@VendorGroupID)			
					select @rcode = 1
					select @desc = @msg
				end

				UPDATE IMWE
				SET IMWE.UploadVal = @VendorGroup
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier=@VendorGroupID and IMWE.RecordType=@rectype
			end


			/******* Issue 131589 ********/
			--Update OriginalEquipmentCode with Equipment Imported Value	
			If IsNull(@DefEquipment,'') = ''
			begin
				select @DefEquipment = IMWE.UploadVal From IMWE 
				Where ImportTemplate=@ImportTemplate and ImportId=@ImportId and RecordSeq=@DefEquipmentRecSeq
  				and IMWE.Identifier=@DefEquipmentID and IMWE.RecordType=@rectype
			end

			UPDATE IMWE 
			SET IMWE.UploadVal = @DefEquipment
			where ImportTemplate=@ImportTemplate and ImportId=@ImportId and RecordSeq=@currrecseq
  			and IMWE.Identifier=@OriginalEquipmentCodeID and IMWE.RecordType=@rectype
			/******* Issue 131589 ********/

  			-- set Current Req Seq to next @Recseq unless we are processing last record.
  			if @Recseq = -1
				begin
  					select @complete = 1	-- exit the loop
				end
  			else
				begin
  					select @currrecseq = @Recseq
				end
		end
end

bspexit:

if @CursorOpen = 1
begin
	close WorkEditCursor
	deallocate WorkEditCursor	
end

  select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsEMEM]'

  return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsEMEM] TO [public]
GO
