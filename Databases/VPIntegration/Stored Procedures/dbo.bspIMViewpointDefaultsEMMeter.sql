SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsEMMeter]
   /***********************************************************
    * CREATED BY:   RBT 06/22/04 - #23332, cloned from bspIMBidtekDefaultsEMBF
    * MODIFIED BY:  DANF 04/16/07 - Issue 122479 Wrap isnull Meter Readings
    *				TRL 10/23/08 - Issue 130699 added formatting for numeric conversion
    *				CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
    *				CC  05/29/09 - Issue #133516 - Correct defaulting of Company
    *               ECV 06/23/10 - Issue #138450 - Update validation for changes to validation routine
    *				GF 09/14/2010 - issue #141031 change to use function vfDateOnly
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
   declare @CoID int, @MthID int, @BatchTransTypeID int, @ActualDateID int, 
   @DescriptionID int, @PreviousHourMeterID int, @CurrentHourMeterID int, @MeterHrsID int, @PreviousOdometerID int, 
   @CurrentOdometerID int, @MeterMilesID int, @MeterReadDateID int, @SourceID int, @EMTransTypeID int, 
   @GLCoID int, @INStkUnitCostID int, @UnitPriceID int, @AutoUsageID int, @PreviousTotalHourMeterID int, 
   @CurrentTotalHourMeterID int, @PreviousTotalOdometerID int, @CurrentTotalOdometerID int
   
   --Values
   declare @Co bCompany, @GLCo bCompany, @Description bDesc, @PreviousHourMeter bHrs, @CurrentHourMeter bHrs, @MeterHrs bHrs, 
   @PreviousOdometer bHrs, @CurrentOdometer bHrs, @MeterMiles bHrs, @DefDescription bDesc, @ActualDate bDate, 
   @PreviousTotalHourMeter bHrs, @CurrentTotalHourMeter bHrs, @PreviousTotalOdometer bHrs, @CurrentTotalOdometer bHrs,
   @Equipment bEquip, @DefOdoReading bHrs, @DefOdoDate bDate, @DefReplacedOdoReading bHrs, @DefPreviousTotalOdometer bHrs,
   @DefHourReading bHrs, @DefHourDate bDate, @DefReplacedHourReading bHrs, @DefPreviousTotalHourMeter bHrs
   
   --Flags for dependent defaults
   declare @ynGLCo bYN, @ynDescription bYN, @ynPreviousHourMeter bYN, @ynCurrentHourMeter bYN, @ynMeterHrs bYN, 
   @ynPreviousOdometer bYN, @ynCurrentOdometer bYN, @ynMeterMiles bYN, @ynPreviousTotalHourMeter bYN, 
   @ynCurrentTotalHourMeter bYN, @ynPreviousTotalOdometer bYN, @ynCurrentTotalOdometer bYN
   
   
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
			  @OverwriteMth 	 		 		bYN
			, @OverwriteBatchTransType 	 		bYN
			, @OverwriteActualDate 	 	 		bYN
			, @OverwriteSource 	 		 		bYN
			, @OverwriteEMTransType 	 		bYN
			, @OverwriteMeterReadDate 	 		bYN
			, @OverwriteINStkUnitCost 	 		bYN
			, @OverwriteUnitPrice 	 	 		bYN
			, @OverwriteAutoUsage 	 	 		bYN
			, @OverwriteGLCo 	 		 		bYN
			, @OverwriteDescription 	 		bYN
			, @OverwritePreviousHourMeter 	 	bYN
			, @OverwriteCurrentHourMeter 	 	bYN
			, @OverwriteMeterHrs 	 			bYN
			, @OverwritePreviousOdometer 	 	bYN
			, @OverwriteCurrentOdometer 	 	bYN
			, @OverwriteMeterMiles 	 			bYN
			, @OverwritePreviousTotalHourMeter 	bYN
			, @OverwriteCurrentTotalHourMeter 	bYN
			, @OverwritePreviousTotalOdometer 	bYN
			, @OverwriteCurrentTotalOdometer 	bYN
			, @OverwriteCo						bYN
			,	@IsCoEmpty 						 bYN
			,	@IsMthEmpty 					 bYN
			,	@IsBatchIdEmpty 				 bYN
			,	@IsBatchSeqEmpty 				 bYN
			,	@IsBatchTransTypeEmpty 			 bYN
			,	@IsEMTransEmpty 				 bYN
			,	@IsActualDateEmpty 				 bYN
			,	@IsEquipmentEmpty 				 bYN
			,	@IsDescriptionEmpty 			 bYN
			,	@IsPreviousHourMeterEmpty 		 bYN
			,	@IsCurrentHourMeterEmpty 		 bYN
			,	@IsMeterHrsEmpty 				 bYN
			,	@IsPreviousOdometerEmpty 		 bYN
			,	@IsCurrentOdometerEmpty 		 bYN
			,	@IsMeterMilesEmpty 				 bYN
			,	@IsMeterReadDateEmpty 			 bYN
			,	@IsPreviousTotalHourMeterEmpty 	 bYN
			,	@IsCurrentTotalHourMeterEmpty 	 bYN
			,	@IsPreviousTotalOdometerEmpty 	 bYN
			,	@IsCurrentTotalOdometerEmpty 	 bYN
			,	@IsSourceEmpty 					 bYN
			,	@IsEMTransTypeEmpty 			 bYN
			,	@IsGLCoEmpty 					 bYN
			,	@IsINStkUnitCostEmpty 			 bYN
			,	@IsUnitPriceEmpty 				 bYN
			,	@IsAutoUsageEmpty 				 bYN
   
   
    SELECT @OverwriteMth = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Mth', @rectype);
	SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
	SELECT @OverwriteActualDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActualDate', @rectype);
	SELECT @OverwriteSource = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Source', @rectype);
	SELECT @OverwriteEMTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMTransType', @rectype);
	SELECT @OverwriteMeterReadDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MeterReadDate', @rectype);
	SELECT @OverwriteINStkUnitCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'INStkUnitCost', @rectype);
	SELECT @OverwriteUnitPrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnitPrice', @rectype);
	SELECT @OverwriteAutoUsage = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AutoUsage', @rectype);
	SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
	SELECT @OverwriteDescription = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Description', @rectype);
	SELECT @OverwritePreviousHourMeter = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PreviousHourMeter', @rectype);
	SELECT @OverwriteCurrentHourMeter = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CurrentHourMeter', @rectype);
	SELECT @OverwriteMeterHrs = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MeterHrs', @rectype);
	SELECT @OverwritePreviousOdometer = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PreviousOdometer', @rectype);
	SELECT @OverwriteCurrentOdometer = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CurrentOdometer', @rectype);
	SELECT @OverwriteMeterMiles = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MeterMiles', @rectype);
	SELECT @OverwritePreviousTotalHourMeter = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PreviousTotalHourMeter', @rectype);
	SELECT @OverwriteCurrentTotalHourMeter = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CurrentTotalHourMeter', @rectype);
	SELECT @OverwritePreviousTotalOdometer = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PreviousTotalOdometer', @rectype);
	SELECT @OverwriteCurrentTotalOdometer = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CurrentTotalOdometer', @rectype);
	SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);

   
   
   --get database default values
   
   --set common defaults
   select @CoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @Company
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CoID
   end
   
   select @MthID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Mth'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMth, 'Y') = 'Y') 
   begin
   	Update IMWE
   	----#141031
   	SET IMWE.UploadVal = CONVERT(VARCHAR(10), dbo.vfDateOnlyMonth(), 101)
   	----SET IMWE.UploadVal = right('0' + convert(varchar(2), month(getxdate())),2) + '/01/' + convert(varchar(4), year(getxdate()))
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MthID
   end
   
   select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'A'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
   end
   
   select @ActualDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActualDate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActualDate, 'Y') = 'Y')
   begin
   	Update IMWE
   	----#141031
   	SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(),101)
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActualDateID
   end
   
   select @SourceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Source'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteSource, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'EMMeter'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @SourceID
   end
   
   select @EMTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteEMTransType, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'Equip'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @EMTransTypeID
   end
   
   select @MeterReadDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MeterReadDate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMeterReadDate, 'Y') = 'Y') 
   begin
   	Update IMWE
   	----#141031
   	SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(),101)
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MeterReadDateID
   end
   
   select @INStkUnitCostID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'INStkUnitCost'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteINStkUnitCost, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @INStkUnitCostID
   end
   
   select @UnitPriceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UnitPrice'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUnitPrice, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @UnitPriceID
   end
   
   select @AutoUsageID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AutoUsage'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAutoUsage, 'Y') = 'Y') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @AutoUsageID
   end

---------------------------  
   select @CoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = @Company
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CoID
   end

      select @MthID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Mth'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMth, 'Y') = 'N') 
   begin
   	Update IMWE
   	----#141031
   	SET IMWE.UploadVal = CONVERT(VARCHAR(10), dbo.vfDateOnlyMonth(), 101)
   	----SET IMWE.UploadVal = right('0' + convert(varchar(2), month(getxdate())),2) + '/01/' + convert(varchar(4), year(getxdate()))
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MthID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'A'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @ActualDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActualDate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActualDate, 'Y') = 'N')
   begin
   	Update IMWE
   	----#141031
   	SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(),101)
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActualDateID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @SourceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Source'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteSource, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'EMMeter'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @SourceID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @EMTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteEMTransType, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'Equip'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @EMTransTypeID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @MeterReadDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MeterReadDate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMeterReadDate, 'Y') = 'N') 
   begin
   	Update IMWE
   	----#141031
   	SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(),101)
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @MeterReadDateID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @INStkUnitCostID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'INStkUnitCost'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteINStkUnitCost, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @INStkUnitCostID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @UnitPriceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UnitPrice'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUnitPrice, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = '0'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @UnitPriceID
   	AND IMWE.UploadVal IS NULL
   end
   
   select @AutoUsageID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AutoUsage'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAutoUsage, 'Y') = 'N') 
   begin
   	Update IMWE
   	SET IMWE.UploadVal = 'N'
   	where IMWE.ImportTemplate=@ImportTemplate and
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @AutoUsageID
   	AND IMWE.UploadVal IS NULL
   end
   
   
   --Get Identifiers for dependent defaults.
   select @ynGLCo = 'N'
   select @GLCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLCo', @rectype, 'Y')
   if @GLCoID <> 0 select @ynGLCo = 'Y'
   
   
   select @ynDescription = 'N'
   select @DescriptionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Description', @rectype, 'Y')
   if @DescriptionID <> 0 select @ynDescription = 'Y'
   
   select @ynPreviousHourMeter = 'N'
   select @PreviousHourMeterID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PreviousHourMeter', @rectype, 'Y')
   if @PreviousHourMeterID <> 0 select @ynPreviousHourMeter = 'Y'
   
   select @ynCurrentHourMeter = 'N'
   select @CurrentHourMeterID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CurrentHourMeter', @rectype, 'Y')
   if @CurrentHourMeterID <> 0 select @ynCurrentHourMeter = 'Y'
   
   select @ynMeterHrs = 'N'
   select @MeterHrsID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MeterHrs', @rectype, 'Y')
   if @MeterHrsID <> 0 select @ynMeterHrs = 'Y'
   
   select @ynPreviousOdometer = 'N'
   select @PreviousOdometerID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PreviousOdometer', @rectype, 'Y')
   if @PreviousOdometerID <> 0 select @ynPreviousOdometer = 'Y'
   
   select @ynCurrentOdometer = 'N'
   select @CurrentOdometerID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CurrentOdometer', @rectype, 'Y')
   if @CurrentOdometerID <> 0 select @ynCurrentOdometer = 'Y'
   
   select @ynMeterMiles = 'N'
   select @MeterMilesID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MeterMiles', @rectype, 'Y')
   if @MeterMilesID <> 0 select @ynMeterMiles = 'Y'
   
   select @ynPreviousTotalHourMeter = 'N'
   select @PreviousTotalHourMeterID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PreviousTotalHourMeter', @rectype, 'Y')
   if @PreviousTotalHourMeterID <> 0 select @ynPreviousTotalHourMeter = 'Y'
   
   select @ynCurrentTotalHourMeter = 'N'
   select @CurrentTotalHourMeterID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CurrentTotalHourMeter', @rectype, 'Y')
   if @CurrentTotalHourMeterID <> 0 select @ynCurrentTotalHourMeter = 'Y'
   
   select @ynPreviousTotalOdometer = 'N'
   select @PreviousTotalOdometerID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PreviousTotalOdometer', @rectype, 'Y')
   if @PreviousTotalOdometerID <> 0 select @ynPreviousTotalOdometer = 'Y'
   
   select @ynCurrentTotalOdometer = 'N'
   select @CurrentTotalOdometerID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CurrentTotalOdometer', @rectype, 'Y')
   if @CurrentTotalOdometerID <> 0 select @ynCurrentTotalOdometer = 'Y'
   
   
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
   
       If @Column = 'Co' select @Co = convert(int,@Uploadval)
   	If @Column = 'Equipment' select @Equipment = @Uploadval
   	If @Column = 'Description' select @Description = @Uploadval
   	If @Column = 'ActualDate' select @ActualDate = @Uploadval
	--Issue 130699
   	If @Column = 'PreviousHourMeter' select @PreviousHourMeter = convert(numeric(10,2),@Uploadval)
   	If @Column = 'CurrentHourMeter' select @CurrentHourMeter = convert(numeric(10,2),@Uploadval)
   	If @Column = 'MeterHrs' select @MeterHrs = convert(numeric,@Uploadval)
   	If @Column = 'PreviousOdometer' select @PreviousOdometer = convert(numeric(10,2),@Uploadval)
   	If @Column = 'CurrentOdometer' select @CurrentOdometer = convert(numeric(10,2),@Uploadval)
   	If @Column = 'MeterMiles' select @MeterMiles = convert(numeric,@Uploadval)
   	If @Column = 'PreviousTotalHourMeter' select @PreviousTotalHourMeter = convert(numeric(10,2),@Uploadval)
   	If @Column = 'CurrentTotalHourMeter' select @CurrentTotalHourMeter = convert(numeric(10,2),@Uploadval)
   	If @Column = 'PreviousTotalOdometer' select @PreviousTotalOdometer = convert(numeric(10,2),@Uploadval)
   	If @Column = 'CurrentTotalOdometer' select @CurrentTotalOdometer = convert(numeric(10,2),@Uploadval)

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
	IF @Column='EMTrans' 
		IF @Uploadval IS NULL
			SET @IsEMTransEmpty = 'Y'
		ELSE
			SET @IsEMTransEmpty = 'N'
	IF @Column='ActualDate' 
		IF @Uploadval IS NULL
			SET @IsActualDateEmpty = 'Y'
		ELSE
			SET @IsActualDateEmpty = 'N'
	IF @Column='Equipment' 
		IF @Uploadval IS NULL
			SET @IsEquipmentEmpty = 'Y'
		ELSE
			SET @IsEquipmentEmpty = 'N'
	IF @Column='Description' 
		IF @Uploadval IS NULL
			SET @IsDescriptionEmpty = 'Y'
		ELSE
			SET @IsDescriptionEmpty = 'N'
	IF @Column='PreviousHourMeter' 
		IF @Uploadval IS NULL
			SET @IsPreviousHourMeterEmpty = 'Y'
		ELSE
			SET @IsPreviousHourMeterEmpty = 'N'
	IF @Column='CurrentHourMeter' 
		IF @Uploadval IS NULL
			SET @IsCurrentHourMeterEmpty = 'Y'
		ELSE
			SET @IsCurrentHourMeterEmpty = 'N'
	IF @Column='MeterHrs' 
		IF @Uploadval IS NULL
			SET @IsMeterHrsEmpty = 'Y'
		ELSE
			SET @IsMeterHrsEmpty = 'N'
	IF @Column='PreviousOdometer' 
		IF @Uploadval IS NULL
			SET @IsPreviousOdometerEmpty = 'Y'
		ELSE
			SET @IsPreviousOdometerEmpty = 'N'
	IF @Column='CurrentOdometer' 
		IF @Uploadval IS NULL
			SET @IsCurrentOdometerEmpty = 'Y'
		ELSE
			SET @IsCurrentOdometerEmpty = 'N'
	IF @Column='MeterMiles' 
		IF @Uploadval IS NULL
			SET @IsMeterMilesEmpty = 'Y'
		ELSE
			SET @IsMeterMilesEmpty = 'N'
	IF @Column='MeterReadDate' 
		IF @Uploadval IS NULL
			SET @IsMeterReadDateEmpty = 'Y'
		ELSE
			SET @IsMeterReadDateEmpty = 'N'
	IF @Column='PreviousTotalHourMeter' 
		IF @Uploadval IS NULL
			SET @IsPreviousTotalHourMeterEmpty = 'Y'
		ELSE
			SET @IsPreviousTotalHourMeterEmpty = 'N'
	IF @Column='CurrentTotalHourMeter' 
		IF @Uploadval IS NULL
			SET @IsCurrentTotalHourMeterEmpty = 'Y'
		ELSE
			SET @IsCurrentTotalHourMeterEmpty = 'N'
	IF @Column='PreviousTotalOdometer' 
		IF @Uploadval IS NULL
			SET @IsPreviousTotalOdometerEmpty = 'Y'
		ELSE
			SET @IsPreviousTotalOdometerEmpty = 'N'
	IF @Column='CurrentTotalOdometer' 
		IF @Uploadval IS NULL
			SET @IsCurrentTotalOdometerEmpty = 'Y'
		ELSE
			SET @IsCurrentTotalOdometerEmpty = 'N'
	IF @Column='Source' 
		IF @Uploadval IS NULL
			SET @IsSourceEmpty = 'Y'
		ELSE
			SET @IsSourceEmpty = 'N'
	IF @Column='EMTransType' 
		IF @Uploadval IS NULL
			SET @IsEMTransTypeEmpty = 'Y'
		ELSE
			SET @IsEMTransTypeEmpty = 'N'
	IF @Column='GLCo' 
		IF @Uploadval IS NULL
			SET @IsGLCoEmpty = 'Y'
		ELSE
			SET @IsGLCoEmpty = 'N'
	IF @Column='INStkUnitCost' 
		IF @Uploadval IS NULL
			SET @IsINStkUnitCostEmpty = 'Y'
		ELSE
			SET @IsINStkUnitCostEmpty = 'N'
	IF @Column='UnitPrice' 
		IF @Uploadval IS NULL
			SET @IsUnitPriceEmpty = 'Y'
		ELSE
			SET @IsUnitPriceEmpty = 'N'
	IF @Column='AutoUsage' 
		IF @Uploadval IS NULL
			SET @IsAutoUsageEmpty = 'Y'
		ELSE
			SET @IsAutoUsageEmpty = 'N'
		   
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
   	if @ynGLCo = 'Y' AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
   	begin
   		select @GLCo = GLCo from EMCO with (nolock) where EMCo = @Co
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @GLCo
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@GLCoID and IMWE.RecordType=@rectype
   
   	end
   
   	select @DefOdoReading = null, @DefOdoDate = null, @DefReplacedOdoReading = null, @DefPreviousTotalOdometer = null,
   		@DefHourReading = null, @DefHourDate = null, @DefReplacedHourReading = null, @DefPreviousTotalHourMeter = null,
   		@DefDescription = null
   
/* Issue #138450 Change parameters
	exec bspEMEquipValForMeterReadings @Co, @Equipment, null, null, null, @ActualDate,
		@DefOdoReading output, @DefOdoDate output, @DefReplacedOdoReading output, @DefPreviousTotalOdometer output,
   		@DefHourReading output, @DefHourDate output, @DefReplacedHourReading output, @DefPreviousTotalHourMeter output,
   		@DefDescription output
*/   
   	exec vspEMEquipValForMeterReadings @Co, @Equipment, null, null, null, null, null, @ActualDate,
		@DefReplacedOdoReading output, null, @DefPreviousTotalOdometer output, @DefReplacedHourReading output, null,
		@DefPreviousTotalHourMeter output, @DefOdoReading output, @DefOdoDate output, 		
		null,null,null,null,null,null,null,null,null,
   		@DefHourReading output, @DefHourDate output, 
   		null,null,null,null,null,null,null,null,null,
   		@DefDescription output
   
   	if @ynDescription = 'Y'  AND (ISNULL(@OverwriteDescription, 'Y') = 'Y' OR ISNULL(@IsDescriptionEmpty, 'Y') = 'Y')
   	begin
   		select @Description = @DefDescription
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @Description
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@DescriptionID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynPreviousHourMeter = 'Y'  AND (ISNULL(@OverwritePreviousHourMeter, 'Y') = 'Y' OR ISNULL(@IsPreviousHourMeterEmpty, 'Y') = 'Y')
   	begin
   		select @PreviousHourMeter = isnull(@DefHourReading,0)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @PreviousHourMeter
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@PreviousHourMeterID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynCurrentHourMeter = 'Y' AND (ISNULL(@OverwriteCurrentHourMeter, 'Y') = 'Y' OR ISNULL(@IsCurrentHourMeterEmpty, 'Y') = 'Y')
   	begin
   		select @CurrentHourMeter = isnull(@PreviousHourMeter,0)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @CurrentHourMeter
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@CurrentHourMeterID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynMeterHrs = 'Y' and @CurrentHourMeter is not null and @PreviousHourMeter is not null AND (ISNULL(@OverwriteMeterHrs, 'Y') = 'Y' OR ISNULL(@IsMeterHrsEmpty, 'Y') = 'Y')
   	begin
   		select @MeterHrs = isnull(@CurrentHourMeter,0) - isnull(@PreviousHourMeter,0)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @MeterHrs
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@MeterHrsID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynPreviousTotalHourMeter = 'Y'  AND (ISNULL(@OverwritePreviousTotalHourMeter, 'Y') = 'Y' OR ISNULL(@IsPreviousTotalHourMeterEmpty, 'Y') = 'Y')
   	begin
   		select @PreviousTotalHourMeter = isnull(@DefPreviousTotalHourMeter,0)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @PreviousTotalHourMeter
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@PreviousTotalHourMeterID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynCurrentTotalHourMeter = 'Y' and @PreviousTotalHourMeter is not null and @MeterHrs is not null  AND (ISNULL(@OverwriteCurrentTotalHourMeter, 'Y') = 'Y' OR ISNULL(@IsCurrentTotalHourMeterEmpty, 'Y') = 'Y')
   	begin
   		select @CurrentTotalHourMeter = isnull(@PreviousTotalHourMeter,0) + isnull(@MeterHrs,0)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @CurrentTotalHourMeter
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@CurrentTotalHourMeterID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynPreviousOdometer = 'Y'  AND (ISNULL(@OverwritePreviousOdometer, 'Y') = 'Y' OR ISNULL(@IsPreviousOdometerEmpty, 'Y') = 'Y')
   	begin
   		select @PreviousOdometer = isnull(@DefOdoReading,0)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @PreviousOdometer
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
		and IMWE.Identifier=@PreviousOdometerID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynCurrentOdometer = 'Y'  AND (ISNULL(@OverwriteCurrentOdometer, 'Y') = 'Y' OR ISNULL(@IsCurrentOdometerEmpty, 'Y') = 'Y')
   	begin
   		select @CurrentOdometer = isnull(@PreviousOdometer,0)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @CurrentOdometer
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@CurrentOdometerID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynMeterMiles = 'Y' and @CurrentOdometer is not null and @PreviousOdometer is not null AND (ISNULL(@OverwriteMeterMiles, 'Y') = 'Y' OR ISNULL(@IsMeterMilesEmpty, 'Y') = 'Y')
   	begin
   		select @MeterMiles = isnull(@CurrentOdometer,0) - isnull(@PreviousOdometer,0)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @MeterMiles
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@MeterMilesID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynPreviousTotalOdometer = 'Y' AND (ISNULL(@OverwritePreviousTotalOdometer, 'Y') = 'Y' OR ISNULL(@IsPreviousTotalOdometerEmpty, 'Y') = 'Y')
   	begin
   		select @PreviousTotalOdometer = isnull(@DefPreviousTotalOdometer,0)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @PreviousTotalOdometer
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@PreviousTotalOdometerID and IMWE.RecordType=@rectype
   
   	end
   
   	if @ynCurrentTotalOdometer = 'Y' and @PreviousTotalOdometer is not null and @MeterMiles is not null   AND (ISNULL(@OverwriteCurrentTotalOdometer, 'Y') = 'Y' OR ISNULL(@IsCurrentTotalOdometerEmpty, 'Y') = 'Y')
   	begin
   		select @CurrentTotalOdometer = isnull(@PreviousTotalOdometer,0) + isnull(@MeterMiles,0)
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = @CurrentTotalOdometer
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@CurrentTotalOdometerID and IMWE.RecordType=@rectype
   
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
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsEMMeter]'
   
       return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsEMMeter] TO [public]
GO
