SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/****** Object:  Stored Procedure dbo.vspPOItemLineJCCmtdCostUpdate  ******/
CREATE procedure [dbo].[vspPOItemLineJCCmtdCostUpdate]
/************************************************************************
 * Created By:	GF 08/16/2011 TK-07438 TK-07439 TK-07440
 * Modified By:	GF 01/05/2011 TK-11551 missed a change to bUnitCost from bRate
 *				DAN SO 04/25/2012 TK-14139 - Committed Costs for ItemType 6 = SM PO w/Job
 *				GF TK-14983 the JCCD actual date is the order date when not null
 *
 *
 *
 *
 * PURPOSE:
 * To create JCCD transaction entries for JC committed cost lines.
 * Will be fired from the insert, update, and delete triggers for POItemLine table.
 * Insert:  For each new line we will create JC transactions.
 *			Line one is then updated, so the update trigger will then create old/new
 *			JC transactions for line one.
 * Update:	For each line changed, JC transaction will be created for old/new values
 *			and then line one is updated with old/new values.
 * Delete:	For each line deleted we will create JC Transactions to back out values,
 *			Line one is then updated, so the update trigger will then create old/new
 *			JC transactions for line one.
 *
 * Thir procedure will creat when needed JC transactions for:
 *	1. Tax Phase and Cost Type when posting separately from the line phase cost type.
 *	2. Remaining???
 *
 * Called from PO Item Line insert, update, and delete triggers currently.
 *
 *
 * INPUT PARAMETERS:
 * @OldNewFlag, @Month, @PostToCo, @Job, @PhaseGroup, @Phase, @JCCType,
 * @POItemLine, @JCUM, @PostedDate, @TaxGroup, @TaxType, @TaxCode,
 * @TaxPhase, @TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv, @CurUnits,
 * @CurCost, @CurTax, @RemTax, @JCCmtdTax, @JCRemCmtdTax,
 * @OldCmtdRemCost, @OldCmtdRemUnits, @JCTransType, 
 * @SMCo, @SMWorkOrder, @SMScope
 *
 *
 *
 * RETURNS:
 *	0 - Success 
 *	1 - Failure
 *
 *************************************************************************/
(@OldNewFlag CHAR(3) = NULL, @Month bMonth = NULL, @PostToCo bCompany = NULL, 
 @Job bJob = NULL, @PhaseGroup bGroup = NULL, @Phase bPhase = NULL, 
 @JCCType bJCCType = NULL, @POItemLine INT = NULL, @JCUM bUM = NULL,
 @PostedDate bDate = NULL, @TaxGroup INT = NULL, @TaxType TINYINT = NULL,
 @TaxCode bTaxCode = NULL, @TaxPhase bPhase = NULL, @TaxCT bJCCType = NULL,
 @TaxJCUM bUM = NULL, @POITKeyID BIGINT = NULL, @JCUMConv bUnitCost = 0,
 @CurUnits bUnits = 0, @CurCost bDollar = 0, @CurTax bDollar = NULL,
 @RemTax bDollar = NULL, @JCCmtdTax bDollar = NULL, @JCRemCmtdTax bDollar = NULL,
 @OldCmtdRemCost bDollar = 0, @OldCmtdRemUnits bUnits = 0, @JCTransType VARCHAR(10) = NULL,
 -- TK-14139 --
 @SMCo bCompany = NULL, @SMWorkOrder INT = NULL, @SMScope INT = NULL, 
 @ErrMsg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

declare @rcode INT, @POCo bCompany, @PO VARCHAR(30), @POItem bItem,
		@Description bItemDesc, @VendorGroup bGroup, @Vendor bVendor,
		@MatlGroup bGroup, @Material bMatl, @UM bUM, @CmtdUnits bUnits,
		@CmtdCost bDollar, @CmtdRemUnits bUnits, @CmtdRemCost bDollar,
		@RemUnits bUnits, @ErrorStart VARCHAR(255), @JCTrans bTrans
		-----TK-14983
		,@OrdDate bDate
			
---- inititalize variables
SET @rcode = 0

SELECT @ErrorStart = 'Job: ' + isnull(@Job,'') + ' Phase: ' + isnull(@Phase,'') + ' CostType: ' + dbo.vfToString(@JCCType)	
	
IF @CurTax IS NULL SET @CurTax = 0
IF @RemTax IS NULL SET @RemTax = 0
IF @JCCmtdTax IS NULL SET @JCCmtdTax = 0
IF @JCRemCmtdTax IS NULL SET @JCRemCmtdTax = 0
IF @JCTransType IS NULL SET @JCTransType = 'PO Dist'
	
	
IF @OldNewFlag = 'NEW'
	BEGIN
	SET @CmtdUnits = @CurUnits * @JCUMConv 
	SET @CmtdCost  = @CurCost
	SET @CmtdRemUnits = @CurUnits * @JCUMConv
	SET @CmtdRemCost  = @CurCost - @OldCmtdRemCost
	SET @RemUnits = @CurUnits - @OldCmtdRemUnits
	END
ELSE
	BEGIN
	SET @CmtdUnits = -1 * (@CurUnits * @JCUMConv)
	SET @CmtdCost  = -1 * @CurCost
	SET @CmtdRemUnits = -1 * ((@CurUnits - @OldCmtdRemUnits) * @JCUMConv)
	SET @CmtdRemCost  = -1 * (@CurCost - @OldCmtdRemCost)
	SET @RemUnits = -1 * @CurUnits
	SET @CurUnits = -1 * @CurUnits 
	SET @CurCost  = -1 * @CurCost
	SET @CurTax   = -1 * @CurTax
	SET @RemTax   = -1 * @RemTax
	SET @JCCmtdTax = -1 * @JCCmtdTax
	SET @JCRemCmtdTax = -1 * @JCRemCmtdTax
	END

---- get POIT information
SELECT  @POCo = POCo, @PO = PO, @POItem = POItem,
		@Description = Description, @MatlGroup = MatlGroup,
		@Material = Material, @UM = UM
FROM dbo.bPOIT
WHERE KeyID = @POITKeyID
IF @@ROWCOUNT = 0
	BEGIN
	SET @ErrMsg = 'Error retrieving POIT Item information for JC Committed cost update '
	SET @rcode = 1
	GOTO vspexit
	END
	
---- get PO information
SELECT @VendorGroup = VendorGroup, @Vendor = Vendor
		----TK-14983
		,@OrdDate = OrderDate
FROM dbo.bPOHD
WHERE POCo = @POCo AND PO = @PO
IF @@ROWCOUNT = 0
	BEGIN
	SET @ErrMsg = 'Error retrieving POHD Header information for JC Committed cost update '
	SET @rcode = 1
	GOTO vspexit
	END


---- NEW values are based upon Current values (Meaning based upon Total values in some cases where Total values are 
---- different than the Original value that is being modified by this transaction change.  Therefore the NEW value
---- is a composite of the Total value and the Changed value to this transaction.  The variables being set below take
---- this into consideration but the end result is that we are setting NEW values into JC Distribution Table
---- A Regular PO currently being changed uses @currentunits because this value factors in the 
---- possibility that the Total amounts may not be the same as this transaction original value
---- when it was first posted.  Therefore we use @currentunits rather than @origunits etc. (See above setting of @current...)


---- add a single entry if tax is not redirected 
IF (isnull(@TaxPhase,'') = isnull(@Phase,'') and isnull(@TaxCT,0) = isnull(@JCCType,0))
	BEGIN
	

	---- create JCCD entry when we have somthing to post
	IF (@CurUnits <> 0 OR @RemUnits <> 0 OR @CmtdUnits <> 0 OR @CmtdCost <> 0
		OR @JCCmtdTax <> 0 OR @JCRemCmtdTax <> 0 OR @CmtdRemUnits <> 0
		OR @CmtdRemCost <> 0)
		BEGIN
		
		---- get next available transaction # for JCCD
		exec @JCTrans = dbo.bspHQTCNextTrans 'bJCCD', @PostToCo, @Month, @ErrMsg output
		if @JCTrans = 0 
			BEGIN
			SELECT @ErrMsg = @ErrorStart + ' - ' + ISNULL(@ErrMsg,''), @rcode = 1
			GOTO vspexit
			END

		---- insert JCCD
		INSERT dbo.bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
				ActualDate, JCTransType, Description, Source, PostedUM, PostedUnits, 
				PostTotCmUnits, PostRemCmUnits, UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits,
				RemainCmtdCost, VendorGroup, Vendor, APCo, PO, POItem, MatlGroup, Material,
				TotalCmtdTax, RemCmtdTax, POItemLine,
				-- TK-14139 --
				SMCo, SMWorkOrder, SMScope)
		SELECT @PostToCo, @Month, @JCTrans, @Job, @PhaseGroup, @Phase, @JCCType, @PostedDate
				----TK-14983
				,ISNULL(@OrdDate, @PostedDate)
				,'PO', @Description, 
				CASE WHEN @JCTransType IS NULL THEN 'PO Entry' ELSE @JCTransType END,
				@UM, 0, @CurUnits, @RemUnits, @JCUM, @CmtdUnits, @CmtdCost + @JCCmtdTax,
				@CmtdRemUnits, @CmtdRemCost + @JCRemCmtdTax,
				@VendorGroup, @Vendor, @POCo, @PO, @POItem, @MatlGroup, @Material,
				@JCCmtdTax, @JCRemCmtdTax, @POItemLine,
				-- TK-14139 --
				@SMCo, @SMWorkOrder, @SMScope
		if @@rowcount = 0
			BEGIN
			SELECT @ErrMsg = @ErrorStart + ' - Error inserting JC Cost Detail.', @rcode = 1
			goto vspexit
			END	
		END						 
	END
ELSE
	BEGIN
	---- tax is re-directed add two entries to JCCD
	IF @CurTax <> 0 OR @RemTax <> 0 OR @JCCmtdTax <> 0 OR @JCRemCmtdTax <> 0
		BEGIN

		---- get next available transaction # for JCCD
		exec @JCTrans = dbo.bspHQTCNextTrans 'bJCCD', @PostToCo, @Month, @ErrMsg output
		if @JCTrans = 0 
			BEGIN
			SELECT @ErrMsg = @ErrorStart + ' - ' + ISNULL(@ErrMsg,''), @rcode = 1
			GOTO vspexit
			END
		
		---- insert JCCD for re-directed tax
		INSERT dbo.bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
				ActualDate, JCTransType, Description, Source, PostedUM, PostedUnits, 
				PostTotCmUnits, PostRemCmUnits, UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits,
				RemainCmtdCost, VendorGroup, Vendor, APCo, PO, POItem, MatlGroup, Material,
				TotalCmtdTax, RemCmtdTax, POItemLine,
				-- TK-14139 --
				SMCo, SMWorkOrder, SMScope)
		SELECT @PostToCo, @Month, @JCTrans, @Job, @PhaseGroup, @TaxPhase, @TaxCT, @PostedDate
				----TK-14983
				,ISNULL(@OrdDate, @PostedDate)
				,'PO', @Description, 
				CASE WHEN @JCTransType IS NULL THEN 'PO Entry' ELSE @JCTransType END,
				@UM, 0, 0, 0, @TaxJCUM, 0, @CurTax, 0, @RemTax, 
				@VendorGroup, @Vendor, @POCo, @PO, @POItem,
				@MatlGroup, @Material, @JCCmtdTax, @JCRemCmtdTax, @POItemLine,
				-- TK-14139 --
				@SMCo, @SMWorkOrder, @SMScope
		if @@rowcount = 0
			BEGIN
			SELECT @ErrMsg = @ErrorStart + ' - Error inserting JC Cost Detail.', @rcode = 1
			goto vspexit
			END	
		END
		

	---- create JCCD entry when we have somthing to post
	IF (@CurUnits <> 0 OR @RemUnits <> 0 OR @CmtdUnits <> 0 OR @CurCost <> 0
		OR @CmtdRemUnits <> 0 OR @CmtdRemCost <> 0)
		BEGIN
		
		---- add entry for phase cost type less re-directed tax
		---- get next available transaction # for JCCD
		exec @JCTrans = dbo.bspHQTCNextTrans 'bJCCD', @PostToCo, @Month, @ErrMsg output
		if @JCTrans = 0 
			BEGIN
			SELECT @ErrMsg = @ErrorStart + ' - ' + ISNULL(@ErrMsg,''), @rcode = 1
			GOTO vspexit
			END

		---- insert JCCD
		INSERT dbo.bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
				ActualDate, JCTransType, Description, Source, PostedUM, PostedUnits, 
				PostTotCmUnits, PostRemCmUnits, UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits,
				RemainCmtdCost, VendorGroup, Vendor, APCo, PO, POItem, MatlGroup, Material,
				TotalCmtdTax, RemCmtdTax, POItemLine,
				-- TK-14139 --
				SMCo, SMWorkOrder, SMScope)
		SELECT @PostToCo, @Month, @JCTrans, @Job, @PhaseGroup, @Phase, @JCCType, @PostedDate
				----TK-14983
				,ISNULL(@OrdDate, @PostedDate)
				,'PO', @Description, 
				CASE WHEN @JCTransType IS NULL THEN 'PO Entry' ELSE @JCTransType END,
				@UM, 0, @CurUnits, @RemUnits, @JCUM, @CmtdUnits, @CurCost,
				@CmtdRemUnits, @CmtdRemCost, @VendorGroup, @Vendor, @POCo, @PO, @POItem,
				@MatlGroup, @Material, 0, 0, @POItemLine,
				-- TK-14139 --
				@SMCo, @SMWorkOrder, @SMScope
		if @@rowcount = 0
			BEGIN
			SELECT @ErrMsg = @ErrorStart + ' - Error inserting JC Cost Detail.', @rcode = 1
			goto vspexit
			END	

		END

	END






vspexit:
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspPOItemLineJCCmtdCostUpdate] TO [public]
GO
