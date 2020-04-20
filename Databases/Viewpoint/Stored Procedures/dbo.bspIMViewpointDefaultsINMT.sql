SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsINMT]
    /***********************************************************
     * CREATED BY:   RBT 09/30/03 for issue #13558
     * MODIFIED BY:  RBT 02/13/04, issue #20538, changed GLUnits to GLSalesUnits, added GLProdUnits.
     *				 RBT 04/22/04, issue #24402, add phase grp and vendor grp defaults based on INCo,
     *							   add defaults for cost and price fields (get from HQMT), def matlgroup for INCo.
     *				 CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
     *				 GF  09/14/2010 - issue #141031 changed to use vfDateOnly
     *				 AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
     *				 LDG 05/25/11 - TK-05469 Add ServiceRate to import.
     *
     * Usage:
     *	Used by Imports to create values for needed or missing
     *      data based upon Viewpoint default rules.
     *
     * Input params:
     *	@ImportId	     Import Identifier
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
    
    declare @rcode int, @desc varchar(120), @status int, 
    		@defaultvalue varchar(30), @CursorOpen int	
    
    --Identifiers
    declare @INCoID int, @MatlGroupID int, @LastCostID int, @LastECMID int, @AvgCostID int,
    		@AvgECMID int, @StdCostID int, @StdECMID int, @StdPriceID int, @PriceECMID int,
    		@LowStockID int, @ReOrderID int, @WeightConvID int, @ActiveID int, @AutoProdID int,
    		@GLProdUnitsID int, @CustRateID int, @JobRateID int, @InvRateID int, @EquipRateID int, 
    		@ServiceRateID int, @OnHandID int, @RecvdNInvcdID int, @AllocID int, @OnOrderID int, 
    		@AuditYNID int, @BookedID int, @GLSalesUnitsID int, @LastCostUpdateID int, 
    		@VendorGroupID int, @PhaseGroupID int
    
    --Values
    declare @INCo bCompany, @MatlGroup bGroup, @Material bMatl, @VendorGroup bGroup, @PhaseGroup bGroup,
   		 @LastCost bUnitCost, @LastECM bECM, @AvgCost bUnitCost, @AvgECM bECM,
   		 @StdCost bUnitCost, @StdECM bECM, @StdPrice bUnitCost, @PriceECM bECM,
   		 @WeightConv bUnits
    
    --Viewpoint Default?
    declare @ynVendorGroup bYN, @ynPhaseGroup bYN, @ynMatlGroup bYN, @ynLastCost bYN,
   		 @ynLastECM bYN, @ynAvgCost bYN, @ynAvgECM bYN, @ynStdCost bYN, @ynStdECM bYN,
   		 @ynStdPrice bYN, @ynPriceECM bYN, @ynWeightConv bYN
   
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
			  @OverwriteINCo 	 		 bYN
			, @OverwriteLowStock 	 	 bYN
			, @OverwriteReOrder 	 	 bYN
			, @OverwriteWeightConv 	 	 bYN
			, @OverwriteActive 	 		 bYN
			, @OverwriteAutoProd 	 	 bYN
			, @OverwriteGLProdUnits 	 bYN
			, @OverwriteGLSaleUnits 	 bYN
			, @OverwriteCustRate 	 	 bYN
			, @OverwriteJobRate 	 	 bYN
			, @OverwriteInvRate 	 	 bYN
			, @OverwriteEquipRate 	 	 bYN
			, @OverwriteServiceRate 	 bYN
			, @OverwriteOnHand 	 		 bYN
			, @OverwriteRecvdNInvcd 	 bYN
			, @OverwriteAlloc 	 		 bYN
			, @OverwriteOnOrder 	 	 bYN
			, @OverwriteAuditYN 	 	 bYN
			, @OverwriteBooked 	 		 bYN
			, @OverwriteLastCostUpdate 	 bYN
			, @OverwriteVendorGroup 	 bYN
			, @OverwritePhaseGroup 	 	 bYN
			, @OverwriteMatlGroup 	 	 bYN
			, @OverwriteLastCost 	 	 bYN
			, @OverwriteLastECM 	 	 bYN
			, @OverwriteAvgCost 	 	 bYN
			, @OverwriteAvgECM 	 		 bYN
			, @OverwriteStdCost 	 	 bYN
			, @OverwriteStdECM 	 		 bYN
			, @OverwriteStdPrice 	 	 bYN
			, @OverwritePriceECM 	 	 bYN		
			,	@IsINCoEmpty 			 bYN
			,	@IsLocEmpty 			 bYN
			,	@IsMaterialEmpty 		 bYN
			,	@IsAuditYNEmpty 		 bYN
			,	@IsLastCostEmpty 		 bYN
			,	@IsLastECMEmpty 		 bYN
			,	@IsLastVendorEmpty 		 bYN
			,	@IsLowStockEmpty 		 bYN
			,	@IsReOrderEmpty 		 bYN
			,	@IsWeightConvEmpty 		 bYN
			,	@IsPhyLocEmpty 			 bYN
			,	@IsLastCntDateEmpty 	 bYN
			,	@IsCostPhaseEmpty 		 bYN
			,	@IsActiveEmpty 			 bYN
			,	@IsAutoProdEmpty 		 bYN
			,	@IsGLProdUnitsEmpty 	 bYN
			,	@IsGLSaleUnitsEmpty 	 bYN
			,	@IsAvgCostEmpty 		 bYN
			,	@IsAvgECMEmpty 			 bYN
			,	@IsStdCostEmpty 		 bYN
			,	@IsStdECMEmpty 			 bYN
			,	@IsStdPriceEmpty 		 bYN
			,	@IsPriceECMEmpty 		 bYN
			,	@IsCustRateEmpty 		 bYN
			,	@IsJobRateEmpty 		 bYN
			,	@IsInvRateEmpty 		 bYN
			,	@IsEquipRateEmpty 		 bYN
			,	@IsServiceRateEmpty		 bYN
			,	@IsNotesEmpty 			 bYN
			,	@IsAllocEmpty 			 bYN
			,	@IsOnOrderEmpty 		 bYN
			,	@IsRecvdNInvcdEmpty 	 bYN
			,	@IsLastCostUpdateEmpty 	 bYN
			,	@IsMatlGroupEmpty 		 bYN
			,	@IsVendorGroupEmpty 	 bYN
			,	@IsPhaseGroupEmpty 		 bYN			
			

	SELECT @OverwriteINCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'INCo', @rectype);
	SELECT @OverwriteLowStock = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LowStock', @rectype);
	SELECT @OverwriteReOrder = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ReOrder', @rectype);
	SELECT @OverwriteWeightConv = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'WeightConv', @rectype);
	SELECT @OverwriteActive = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Active', @rectype);
	SELECT @OverwriteAutoProd = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AutoProd', @rectype);
	SELECT @OverwriteGLProdUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLProdUnits', @rectype);
	SELECT @OverwriteGLSaleUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLSaleUnits', @rectype);
	SELECT @OverwriteCustRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CustRate', @rectype);
	SELECT @OverwriteJobRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JobRate', @rectype);
	SELECT @OverwriteInvRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InvRate', @rectype);
	SELECT @OverwriteEquipRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EquipRate', @rectype);
	SELECT @OverwriteServiceRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ServiceRate', @rectype);
	SELECT @OverwriteOnHand = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OnHand', @rectype);
	SELECT @OverwriteRecvdNInvcd = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RecvdNInvcd', @rectype);
	SELECT @OverwriteAlloc = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Alloc', @rectype);
	SELECT @OverwriteOnOrder = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OnOrder', @rectype);
	SELECT @OverwriteAuditYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AuditYN', @rectype);
	SELECT @OverwriteBooked = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Booked', @rectype);
	SELECT @OverwriteLastCostUpdate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LastCostUpdate', @rectype);
	SELECT @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype);
	SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
	SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
	SELECT @OverwriteLastCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LastCost', @rectype);
	SELECT @OverwriteLastECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LastECM', @rectype);
	SELECT @OverwriteAvgCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AvgCost', @rectype);
	SELECT @OverwriteAvgECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AvgECM', @rectype);
	SELECT @OverwriteStdCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StdCost', @rectype);
	SELECT @OverwriteStdECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StdECM', @rectype);
	SELECT @OverwriteStdPrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StdPrice', @rectype);
	SELECT @OverwritePriceECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PriceECM', @rectype);
    
    
    --set common defaults
     
    select @INCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'INCo'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteINCo, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @Company
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @INCoID
    end
     
    select @LowStockID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LowStock'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteLowStock, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @LowStockID
    end
    
    select @ReOrderID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ReOrder'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReOrder, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @ReOrderID
    end
    
    select @WeightConvID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'WeightConv'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteWeightConv, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '1'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @WeightConvID
    end
    
    select @ActiveID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Active'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActive, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'Y'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActiveID
    end
    
    select @AutoProdID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AutoProd'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAutoProd, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @AutoProdID
    end
    
    select @GLProdUnitsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLProdUnits'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteGLProdUnits, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @GLProdUnitsID
    end
    
    select @GLSalesUnitsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLSaleUnits'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteGLSaleUnits, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @GLSalesUnitsID
    end
    
    select @CustRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CustRate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCustRate, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @CustRateID
    end
    
    select @JobRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JobRate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJobRate, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @JobRateID
    end
    
    select @InvRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InvRate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteInvRate, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @InvRateID
    end
    
    select @EquipRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EquipRate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteEquipRate, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @EquipRateID
    end
    
    select @ServiceRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ServiceRate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteServiceRate, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @ServiceRateID
    end
    
    select @OnHandID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OnHand'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOnHand, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @OnHandID
    end
    
    select @RecvdNInvcdID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RecvdNInvcd'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteRecvdNInvcd, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @RecvdNInvcdID
    end
    
    select @AllocID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Alloc'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAlloc, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @AllocID
    end
    
    select @OnOrderID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OnOrder'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOnOrder, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @OnOrderID
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
    
    select @BookedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Booked'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBooked, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @BookedID
    end
     
    select @LastCostUpdateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LastCostUpdate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteLastCostUpdate, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        ----#141031
        SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(),101)
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @LastCostUpdateID
    end

---------------------------------
    select @INCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'INCo'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteINCo, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @Company
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @INCoID
    	AND IMWE.UploadVal IS NULL
    end
     
    select @LowStockID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LowStock'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteLowStock, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @LowStockID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @ReOrderID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ReOrder'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteReOrder, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @ReOrderID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @WeightConvID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'WeightConv'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteWeightConv, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '1'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @WeightConvID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @ActiveID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Active'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActive, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'Y'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActiveID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @AutoProdID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AutoProd'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAutoProd, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @AutoProdID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @GLProdUnitsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLProdUnits'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteGLProdUnits, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @GLProdUnitsID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @GLSalesUnitsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLSaleUnits'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteGLSaleUnits, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @GLSalesUnitsID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @CustRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CustRate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCustRate, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @CustRateID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @JobRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JobRate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteJobRate, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @JobRateID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @InvRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InvRate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteInvRate, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @InvRateID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @EquipRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EquipRate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteEquipRate, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @EquipRateID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @ServiceRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ServiceRate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteServiceRate, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @ServiceRateID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @OnHandID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OnHand'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOnHand, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @OnHandID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @RecvdNInvcdID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RecvdNInvcd'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteRecvdNInvcd, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @RecvdNInvcdID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @AllocID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Alloc'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAlloc, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @AllocID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @OnOrderID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OnOrder'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteOnOrder, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @OnOrderID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @AuditYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AuditYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAuditYN, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'Y'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @AuditYNID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @BookedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Booked'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBooked, 'Y')= 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @BookedID
    	AND IMWE.UploadVal IS NULL
    end
     
    select @LastCostUpdateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'LastCostUpdate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteLastCostUpdate, 'Y')= 'N')
    begin
        UPDATE IMWE
        ----#141031
        SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(),101)
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @LastCostUpdateID
    	AND IMWE.UploadVal IS NULL
    end
    
    
    --Get Identifiers for dependent defaults.
    select @ynVendorGroup = 'N'
    select @VendorGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'Y')
    if @VendorGroupID <> 0 select @ynVendorGroup = 'Y'
   
    select @ynPhaseGroup = 'N'
    select @PhaseGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGroup', @rectype, 'Y')
    if @PhaseGroupID <> 0 select @ynPhaseGroup = 'Y'
   
    select @ynMatlGroup = 'N'
    select @MatlGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MatlGroup', @rectype, 'Y')
    if @MatlGroupID <> 0 select @ynMatlGroup = 'Y'
   
    select @ynLastCost = 'N'
    select @LastCostID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LastCost', @rectype, 'Y')
    if @LastCostID <> 0 select @ynLastCost = 'Y'
   
    select @ynLastECM = 'N'
    select @LastECMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LastECM', @rectype, 'Y')
    if @LastECMID <> 0 select @ynLastECM = 'Y'
   
    select @ynAvgCost = 'N'
    select @AvgCostID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AvgCost', @rectype, 'Y')
    if @AvgCostID <> 0 select @ynAvgCost = 'Y'
   
    select @ynAvgECM = 'N'
    select @AvgECMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AvgECM', @rectype, 'Y')
    if @AvgECMID <> 0 select @ynAvgECM = 'Y'
   
    select @ynStdCost = 'N'
    select @StdCostID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdCost', @rectype, 'Y')
    if @StdCostID <> 0 select @ynStdCost = 'Y'
   
    select @ynStdECM = 'N'
    select @StdECMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdECM', @rectype, 'Y')
    if @StdECMID <> 0 select @ynStdECM = 'Y'
   
    select @ynStdPrice = 'N'
    select @StdPriceID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdPrice', @rectype, 'Y')
    if @StdPriceID <> 0 select @ynStdPrice = 'Y'
   
    select @ynPriceECM = 'N'
    select @PriceECMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PriceECM', @rectype, 'Y')
    if @PriceECMID <> 0 select @ynPriceECM = 'Y'
   
    select @ynWeightConv = 'N'
    select @WeightConvID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WeightConv', @rectype, 'Y')
    if @WeightConvID <> 0 select @ynWeightConv = 'Y'
   
   
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
    --#142350 - @importid varchar(10), @seq int, @Identifier int,
    DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int,
			@complete int
    
    declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
            @columnlist varchar(255), @records int, @oldrecseq int
    
    declare @UploadDate bDate, @Amount bDollar, 
    		@Co bCompany, @Mth bMonth, @BatchSeq int, @CMAcct bCMAcct, @CMTransType bCMTransType,
    		@CMRef bCMRef, @CMRefSeq tinyint, @AcctDate smalldatetime, @Payee varchar(20), 
    		@Description bDesc, @GLAcct bGLAcct
    
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
    		
        if @Column = 'INCo' select @INCo = @Uploadval
   	 if @Column = 'MatlGroup' select @MatlGroup = @Uploadval
   	 if @Column = 'Material' select @Material = @Uploadval

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
		IF @Column='Material' 
			IF @Uploadval IS NULL
				SET @IsMaterialEmpty = 'Y'
			ELSE
				SET @IsMaterialEmpty = 'N'
		IF @Column='AuditYN' 
			IF @Uploadval IS NULL
				SET @IsAuditYNEmpty = 'Y'
			ELSE
				SET @IsAuditYNEmpty = 'N'
		IF @Column='LastCost' 
			IF @Uploadval IS NULL
				SET @IsLastCostEmpty = 'Y'
			ELSE
				SET @IsLastCostEmpty = 'N'
		IF @Column='LastECM' 
			IF @Uploadval IS NULL
				SET @IsLastECMEmpty = 'Y'
			ELSE
				SET @IsLastECMEmpty = 'N'
		IF @Column='LastVendor' 
			IF @Uploadval IS NULL
				SET @IsLastVendorEmpty = 'Y'
			ELSE
				SET @IsLastVendorEmpty = 'N'
		IF @Column='LowStock' 
			IF @Uploadval IS NULL
				SET @IsLowStockEmpty = 'Y'
			ELSE
				SET @IsLowStockEmpty = 'N'
		IF @Column='ReOrder' 
			IF @Uploadval IS NULL
				SET @IsReOrderEmpty = 'Y'
			ELSE
				SET @IsReOrderEmpty = 'N'
		IF @Column='WeightConv' 
			IF @Uploadval IS NULL
				SET @IsWeightConvEmpty = 'Y'
			ELSE
				SET @IsWeightConvEmpty = 'N'
		IF @Column='PhyLoc' 
			IF @Uploadval IS NULL
				SET @IsPhyLocEmpty = 'Y'
			ELSE
				SET @IsPhyLocEmpty = 'N'
		IF @Column='LastCntDate' 
			IF @Uploadval IS NULL
				SET @IsLastCntDateEmpty = 'Y'
			ELSE
				SET @IsLastCntDateEmpty = 'N'
		IF @Column='CostPhase' 
			IF @Uploadval IS NULL
				SET @IsCostPhaseEmpty = 'Y'
			ELSE
				SET @IsCostPhaseEmpty = 'N'
		IF @Column='Active' 
			IF @Uploadval IS NULL
				SET @IsActiveEmpty = 'Y'
			ELSE
				SET @IsActiveEmpty = 'N'
		IF @Column='AutoProd' 
			IF @Uploadval IS NULL
				SET @IsAutoProdEmpty = 'Y'
			ELSE
				SET @IsAutoProdEmpty = 'N'
		IF @Column='GLProdUnits' 
			IF @Uploadval IS NULL
				SET @IsGLProdUnitsEmpty = 'Y'
			ELSE
				SET @IsGLProdUnitsEmpty = 'N'
		IF @Column='GLSaleUnits' 
			IF @Uploadval IS NULL
				SET @IsGLSaleUnitsEmpty = 'Y'
			ELSE
				SET @IsGLSaleUnitsEmpty = 'N'
		IF @Column='AvgCost' 
			IF @Uploadval IS NULL
				SET @IsAvgCostEmpty = 'Y'
			ELSE
				SET @IsAvgCostEmpty = 'N'
		IF @Column='AvgECM' 
			IF @Uploadval IS NULL
				SET @IsAvgECMEmpty = 'Y'
			ELSE
				SET @IsAvgECMEmpty = 'N'
		IF @Column='StdCost' 
			IF @Uploadval IS NULL
				SET @IsStdCostEmpty = 'Y'
			ELSE
				SET @IsStdCostEmpty = 'N'
		IF @Column='StdECM' 
			IF @Uploadval IS NULL
				SET @IsStdECMEmpty = 'Y'
			ELSE
				SET @IsStdECMEmpty = 'N'
		IF @Column='StdPrice' 
			IF @Uploadval IS NULL
				SET @IsStdPriceEmpty = 'Y'
			ELSE
				SET @IsStdPriceEmpty = 'N'
		IF @Column='PriceECM' 
			IF @Uploadval IS NULL
				SET @IsPriceECMEmpty = 'Y'
			ELSE
				SET @IsPriceECMEmpty = 'N'
		IF @Column='CustRate' 
			IF @Uploadval IS NULL
				SET @IsCustRateEmpty = 'Y'
			ELSE
				SET @IsCustRateEmpty = 'N'
		IF @Column='JobRate' 
			IF @Uploadval IS NULL
				SET @IsJobRateEmpty = 'Y'
			ELSE
				SET @IsJobRateEmpty = 'N'
		IF @Column='InvRate' 
			IF @Uploadval IS NULL
				SET @IsInvRateEmpty = 'Y'
			ELSE
				SET @IsInvRateEmpty = 'N'
		IF @Column='EquipRate' 
			IF @Uploadval IS NULL
				SET @IsEquipRateEmpty = 'Y'
			ELSE
				SET @IsEquipRateEmpty = 'N'
		IF @Column='ServiceRate' 
			IF @Uploadval IS NULL
				SET @IsServiceRateEmpty = 'Y'
			ELSE
				SET @IsServiceRateEmpty = 'N'
		IF @Column='Notes' 
			IF @Uploadval IS NULL
				SET @IsNotesEmpty = 'Y'
			ELSE
				SET @IsNotesEmpty = 'N'
		IF @Column='Alloc' 
			IF @Uploadval IS NULL
				SET @IsAllocEmpty = 'Y'
			ELSE
				SET @IsAllocEmpty = 'N'
		IF @Column='OnOrder' 
			IF @Uploadval IS NULL
				SET @IsOnOrderEmpty = 'Y'
			ELSE
				SET @IsOnOrderEmpty = 'N'
		IF @Column='RecvdNInvcd' 
			IF @Uploadval IS NULL
				SET @IsRecvdNInvcdEmpty = 'Y'
			ELSE
				SET @IsRecvdNInvcdEmpty = 'N'
		IF @Column='LastCostUpdate' 
			IF @Uploadval IS NULL
				SET @IsLastCostUpdateEmpty = 'Y'
			ELSE
				SET @IsLastCostUpdateEmpty = 'N'
		IF @Column='MatlGroup' 
			IF @Uploadval IS NULL
				SET @IsMatlGroupEmpty = 'Y'
			ELSE
				SET @IsMatlGroupEmpty = 'N'
		IF @Column='VendorGroup' 
			IF @Uploadval IS NULL
				SET @IsVendorGroupEmpty = 'Y'
			ELSE
				SET @IsVendorGroupEmpty = 'N'
		IF @Column='PhaseGroup' 
			IF @Uploadval IS NULL
				SET @IsPhaseGroupEmpty = 'Y'
			ELSE
				SET @IsPhaseGroupEmpty = 'N'
   
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
    
    	if @ynVendorGroup = 'Y' AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'Y' OR ISNULL(@IsVendorGroupEmpty, 'Y') = 'Y')
    	begin
    	    if isnull(@INCo,'') <> ''
    	    begin
   			select @VendorGroup = VendorGroup from bHQCO where HQCo = @INCo
   
    			UPDATE IMWE
    			SET IMWE.UploadVal = @VendorGroup
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@VendorGroupID and IMWE.RecordType=@rectype
    	    end	
    	end
   
    	if @ynPhaseGroup = 'Y' AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')
    	begin
    	    if isnull(@INCo,'') <> ''
    	    begin
   			select @PhaseGroup = PhaseGroup from bHQCO where HQCo = @INCo
   
    			UPDATE IMWE
    			SET IMWE.UploadVal = @PhaseGroup
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@PhaseGroupID and IMWE.RecordType=@rectype
    	    end	
    	end
   
    	if @ynMatlGroup = 'Y' AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR ISNULL(@IsMatlGroupEmpty, 'Y') = 'Y')
    	begin
    	    if isnull(@INCo,'') <> ''
    	    begin
   			select @MatlGroup = MatlGroup from bHQCO where HQCo = @INCo
   
    			UPDATE IMWE
    			SET IMWE.UploadVal = @MatlGroup
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@MatlGroupID and IMWE.RecordType=@rectype
    	    end	
    	end
   
    	if @ynLastCost = 'Y' AND (ISNULL(@OverwriteLastCost, 'Y') = 'Y' OR ISNULL(@IsLastCostEmpty, 'Y') = 'Y')
    	begin
   		select @LastCost = Cost from bHQMT where MatlGroup = @MatlGroup and Material = @Material
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = isnull(@LastCost,0)
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@LastCostID and IMWE.RecordType=@rectype
    	end
   
    	if @ynLastECM = 'Y' AND (ISNULL(@OverwriteLastECM, 'Y') = 'Y' OR ISNULL(@IsLastECMEmpty, 'Y') = 'Y')
    	begin
   		select @LastECM = CostECM from bHQMT where MatlGroup = @MatlGroup and Material = @Material
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = isnull(@LastECM,'E')
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@LastECMID and IMWE.RecordType=@rectype
    	end
   
    	if @ynAvgCost = 'Y' AND (ISNULL(@OverwriteAvgCost, 'Y') = 'Y' OR ISNULL(@IsAvgCostEmpty, 'Y') = 'Y')
    	begin
   		select @AvgCost = Cost from bHQMT where MatlGroup = @MatlGroup and Material = @Material
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = isnull(@AvgCost,0)
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@AvgCostID and IMWE.RecordType=@rectype
    	end
   
    	if @ynAvgECM = 'Y' AND (ISNULL(@OverwriteAvgECM, 'Y') = 'Y' OR ISNULL(@IsAvgECMEmpty, 'Y') = 'Y')
    	begin
   		select @AvgECM = CostECM from bHQMT where MatlGroup = @MatlGroup and Material = @Material
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = isnull(@AvgECM,'E')
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@AvgECMID and IMWE.RecordType=@rectype
    	end
   
    	if @ynStdCost = 'Y' AND (ISNULL(@OverwriteStdCost, 'Y') = 'Y' OR ISNULL(@IsStdCostEmpty, 'Y') = 'Y')
    	begin
   		select @StdCost = Cost from bHQMT where MatlGroup = @MatlGroup and Material = @Material
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = isnull(@StdCost,0)
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@StdCostID and IMWE.RecordType=@rectype
    	end
   
    	if @ynStdECM = 'Y' AND (ISNULL(@OverwriteStdECM, 'Y') = 'Y' OR ISNULL(@IsStdECMEmpty, 'Y') = 'Y')
    	begin
   		select @StdECM = CostECM from bHQMT where MatlGroup = @MatlGroup and Material = @Material
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = isnull(@StdECM,'E')
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@StdECMID and IMWE.RecordType=@rectype
    	end
   
    	if @ynStdPrice = 'Y' AND (ISNULL(@OverwriteStdPrice, 'Y') = 'Y' OR ISNULL(@IsStdPriceEmpty, 'Y') = 'Y')
    	begin
   		select @StdPrice = Price from bHQMT where MatlGroup = @MatlGroup and Material = @Material
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = isnull(@StdPrice,0)
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@StdPriceID and IMWE.RecordType=@rectype
    	end
   
    	if @ynPriceECM = 'Y' AND (ISNULL(@OverwritePriceECM, 'Y') = 'Y' OR ISNULL(@IsPriceECMEmpty, 'Y') = 'Y')
    	begin
   		select @PriceECM = PriceECM from bHQMT where MatlGroup = @MatlGroup and Material = @Material
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = isnull(@PriceECM,'E')
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@PriceECMID and IMWE.RecordType=@rectype
    	end
   
    	if @ynWeightConv = 'Y' AND (ISNULL(@OverwriteWeightConv, 'Y') = 'Y' OR ISNULL(@IsWeightConvEmpty, 'Y') = 'Y')
    	begin
   		select @WeightConv = WeightConv from bHQMT where MatlGroup = @MatlGroup and Material = @Material
   
   		UPDATE IMWE
   		SET IMWE.UploadVal = isnull(@WeightConv,1)
   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   		and IMWE.Identifier=@WeightConvID and IMWE.RecordType=@rectype
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
    
        select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsHQMT]'
    
        return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsINMT] TO [public]
GO
