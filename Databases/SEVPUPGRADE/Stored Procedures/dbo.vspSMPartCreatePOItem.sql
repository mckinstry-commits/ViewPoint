SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







/* =============================================
-- Author:		Jeremiah Barkley
-- Create date: 3/23/2011
-- Description:	Create a new PO Item for a given SM Work Order.
--				Outputs the new PO Item number in the POItem parameter.
--Modified:   TL  03/30/2012 TK-13604 Added SMJCCostType as parameter and variables SMPhaseGroup,SMPhase for POIT update.
=============================================*/
CREATE PROCEDURE [dbo].[vspSMPartCreatePOItem]
	@SMCo AS bCompany,
	@WorkOrder AS bigint,
	@Scope AS int,
	@POCo AS bCompany,
	@PONumber AS varchar(20),
	@MaterialGroup AS bGroup,
	@Part AS bMatl,
	@Description as bItemDesc,
	@PartUM AS bUM,
	@Quantity AS bUnits, 
	@CostPerUnit AS bUnitCost,
	@CostECM AS bECM,
	@CostTotal AS bDollar,
	@GLCo AS bCompany,
	@GLAccount AS bGLAcct,
	@PostedDate AS bDate,
	@SMJCCostType AS bJCCType,
	@POItem AS bItem OUTPUT,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	-- Validation should be completed by the form at this point
	
	-- Generate a PO Item #
	SELECT TOP 1 @POItem = ISNULL(MAX(POItem), 0) + 1 FROM dbo.POIT WHERE POCo = @POCo AND PO = @PONumber 
	
	DECLARE @PayCategoryYN bYN, @PayTypeYN bYN, @SMPayType tinyint, @UserProfilePayCategory int, @APCOPayCategory int,
			@errmsg varchar(255), @PayCategory int, @PayType tinyint, @SMPhaseGroup bGroup, @SMPhase bPhase
			
	-- Determine the Pay Category and Type if needed
	EXEC dbo.vspPOCommonInfoGetForPOEntry @POCo, NULL, NULL, NULL, @PayCategoryYN OUTPUT, NULL, NULL,
			NULL, NULL, NULL, NULL, NULL, @PayTypeYN OUTPUT, NULL, NULL, @SMPayType OUTPUT,
			@UserProfilePayCategory OUTPUT, @APCOPayCategory OUTPUT, NULL, NULL, @errmsg OUTPUT
	
	IF EXISTS(SELECT 1 FROM dbo.SMWorkOrder WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Job IS NOT NULL)
	BEGIN
		SELECT @SMPhaseGroup = PhaseGroup, @SMPhase = Phase 
		FROM dbo.SMWorkOrderScope		
		WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope
		IF @SMPhase IS NULL
		BEGIN
			SET @msg = 'Work Order Scope is missing Phase for PO Item'
			RETURN 1
		END
	END

	IF (@PayTypeYN = 'Y' AND @PayCategoryYN = 'Y')
	BEGIN
	
		IF (@PayCategoryYN = 'Y')
		BEGIN
			IF (@UserProfilePayCategory IS NOT NULL)
			BEGIN
				SET @PayCategory = @UserProfilePayCategory
			END
			ELSE
			BEGIN
				SET @PayCategory = @APCOPayCategory
			END
			
			IF (@PayCategory IS NOT NULL)
			BEGIN
				EXEC dbo.bspAPPayCategoryVal @POCo, @PayCategory, NULL, NULL, NULL, NULL, @PayType OUTPUT, NULL, NULL, @errmsg
			END
		END
		ELSE
		BEGIN
			SET @PayType = @SMPayType
		END
	END
	
	IF (@POItem > 0)
	BEGIN
		INSERT INTO dbo.POIT
		(
			POCo,
			PO,
			POItem,
			ItemType,
			MatlGroup,
			Material,
			[Description],
			UM,
			RecvYN,
			PostToCo,
			GLCo,
			GLAcct,
			OrigUnits,
			OrigUnitCost,
			OrigECM,
			OrigCost,
			OrigTax,
			CurUnits,
			CurUnitCost,
			CurECM,
			CurCost,
			CurTax,
			RecvdUnits,
			RecvdCost,
			BOUnits,
			BOCost,
			TotalUnits,
			TotalCost,
			TotalTax,
			InvUnits,
			InvCost,
			InvTax,
			RemUnits,
			RemCost,
			RemTax,
			PostedDate,
			JCCmtdTax,
			JCRemCmtdTax,
			TaxRate,
			GSTRate,
			PayCategory,
			PayType,
			SMCo,
			SMWorkOrder,
			SMScope,
			SMPhaseGroup,
			SMPhase,
			SMJCCostType
		)
		VALUES
		(
			@POCo,
			@PONumber,
			@POItem,
			6, -- SM Type
			@MaterialGroup,
			@Part,
			@Description,
			@PartUM,
			'Y',
			@SMCo,	-- PostToCo
			@GLCo,
			@GLAccount,
			@Quantity,
			@CostPerUnit,
			@CostECM,
			@CostTotal,
			0,
			@Quantity,
			@CostPerUnit,
			@CostECM,	--CurECM
			@CostTotal,	--CurCost
			0,	--CurTax
			0,	--RecvdUnits
			0,	--RecvdCost
			@Quantity,	-- BO Units
			CASE WHEN @PartUM = 'LS' THEN @CostTotal ELSE 0 END,	-- BO Cost
			0,	--TotalUnits
			0,	--TotalCost
			0,	
			0,
			0,
			0,
			0,
			0,
			0,
			@PostedDate,
			0,
			0,
			0,
			0,
			@PayCategory,
			@PayType,
			@SMCo,
			@WorkOrder,
			@Scope,
			@SMPhaseGroup,
			@SMPhase,
			@SMJCCostType
		)
	END
	ELSE
	BEGIN
		SET @msg = 'Unable to generate a new PO Item Number for the purchase order.'
		RETURN 1
	END

	RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMPartCreatePOItem] TO [public]
GO
