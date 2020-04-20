SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspPOSLItemValForPMOL]
/***********************************************************
* CREATED BY:	JG	06/21/2011	TK-06041 - Added for PMOL
* MODIFIED BY:	
*				JG	06/29/2011	TK-06041 - Added Purchase Units/Amount
*				GF 7/27/2011 - TK-07144 changed to varchar(30)
*
* USAGE:
* Called from PMPCOSItemDetail form
*
* INPUT PARAMETERS
*   @PMCo			PM Co to validate against
*	@Phase			Phase
*	@CostType		CostType
*   @SL				Subcontract
*   @PO				Purchase Order
*   @ItemIN			Item to validate
*
* OUTPUT PARAMETERS
*	@ItemPhase			Phase
*	@ItemCostType		Cost Type
*	@ItemMaterial		Material
*	@ItemUM				UM
*	@ItemUnits			Units
*	@ItemUnitCost		Unit Cost
*   @ItemECM			ECM
*	@ItemAmount			Amount
*	@ItemExistsYN		PO/SL Item exists?
*	@ItemInterfacedYN	Item interfaced in PMMF/PMSL?
*	@ItemDesc			Item Description
*	@ItemReceiving		Item Receiving flag
*   @msg				error message IF error occurs otherwise Description of PO
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@PMCo bCompany = NULL, @Phase bPhase = NULL, @CostType bJCCType = NULL,
 @SL VARCHAR(30) = NULL, @PO VARCHAR(30) = NULL, @ItemIN VARCHAR(6) = NULL, 
 ----Outputs
 @ItemPhase bPhase = NULL output, @ItemCostType bJCCType = NULL output,
 @ItemMaterial bMatl = NULL OUTPUT, @ItemUM bUM = NULL output,
 @ItemUnits bUnits = NULL OUTPUT,
 @ItemUnitCost bUnitCost = NULL output, @ItemECM bECM = NULL output, 
 @ItemAmount bDollar = NULL OUTPUT,
 @ItemExistsYN bYN = 'N' output, @ItemInterfacedYN bYN = 'N' output, 
 @ItemDesc bItemDesc = '' output, 
 @msg varchar(255) output)

AS
SET NOCOUNT ON

DECLARE	@rcode				INT
		, @ItemPMExistsYN	bYN
	
	SELECT @rcode = 0, @ItemPMExistsYN = 'N'

	---------------------
	-- VALIDATE VALUES --
	---------------------
	IF @PMCo IS NULL
		BEGIN
			SELECT @msg = 'Missing PO Company!', @rcode = 1
			GOTO vspexit
		END

	IF @PO IS NULL AND @SL IS NULL
		BEGIN
			SELECT @msg = 'Missing PO/SL!', @rcode = 1
			GOTO vspexit
		END

	IF @ItemIN IS NULL
		BEGIN
			SELECT @msg = 'Missing PO Item!', @rcode = 1
			GOTO vspexit
		END


	------------------
	-- PRIME VALUES --
	------------------
	SET @ItemExistsYN = 'N'
	SET @ItemInterfacedYN = 'N'
	SET @ItemPMExistsYN = 'N'
	SET @ItemIN = LTRIM(RTRIM(@ItemIN))
	
	
	IF @PO IS NOT NULL
	BEGIN
	
	EXEC	@rcode = [dbo].[vspPOItemValForPMPOCO]
			@Seq = NULL,
			@POCo = @PMCo,
			@PO = @PO,
			@POCONum = NULL,
			@POItemIN = @ItemIN,
			@POItemOut = NULL,
			@ItemMaterialGroup = NULL,
			@ItemMaterial = @ItemMaterial OUTPUT,
			@ItemPhase = @ItemPhase OUTPUT,
			@ItemCostType = @ItemCostType OUTPUT,
			@ItemUM = @ItemUM OUTPUT,
			@ItemUnits = @ItemUnits OUTPUT,
			@ItemUnitCost = @ItemUnitCost OUTPUT,
			@ItemECM = @ItemECM OUTPUT,
			@ItemAmount = @ItemAmount OUTPUT,
			@ItemTaxType = NULL,
			@ItemTaxCode = NULL,
			@ItemTaxGroup = NULL,
			@ItemPOExistsYN = @ItemExistsYN OUTPUT,
			@ItemPMIntFacedYN = @ItemInterfacedYN OUTPUT,
			@ItemPMExistsYN = @ItemPMExistsYN OUTPUT,
			@ItemPOItemDesc = @ItemDesc OUTPUT,
			@ItemReceiving = NULL,
			@msg = @msg OUTPUT
	
	END
	ELSE IF @SL IS NOT NULL
	BEGIN
	
	EXEC	@rcode = [dbo].[vspSLItemValForPMSCO]
			@Seq = NULL,
			@SLCo = @PMCo,
			@Subcontract = @SL,
			@SubCO = NULL,
			@SLItemIN = @ItemIN,
			@SLItem = NULL,
			@ItemType = NULL,
			@ItemPhase = @ItemPhase OUTPUT,
			@ItemCostType = @ItemCostType OUTPUT,
			@ItemUM = @ItemUM OUTPUT,
			@ItemUnits = @ItemUnits OUTPUT,
			@ItemUnitCost = @ItemUnitCost OUTPUT,
			@ItemAmount = @ItemAmount OUTPUT,
			@ItemWCPct = NULL,
			@ItemSMPct = NULL,
			@ItemTaxType = NULL,
			@ItemTaxCode = NULL,
			@ItemTaxGroup = NULL,
			@ItemSLExistsYN = @ItemExistsYN OUTPUT,
			@ItemPMIntFacedYN = @ItemInterfacedYN OUTPUT,
			@ItemPMExistsYN = @ItemPMExistsYN OUTPUT,
			@ItemPOItemDesc = @ItemDesc,
			@msg = @msg OUTPUT
	
	END
	
	IF @ItemPMExistsYN = 'Y' 
	BEGIN
		SET @ItemExistsYN = 'Y'
	END
		
	
	IF @ItemExistsYN = 'Y'
	BEGIN
		IF @Phase IS NOT NULL OR @CostType IS NOT NULL
		BEGIN
		
			IF @Phase IS NOT NULL AND @Phase <> @ItemPhase
			BEGIN
				SELECT @msg = 'Invalid Phase: ' + @Phase + ' for existing PM/SL Item: ' + @ItemIN + '.', @rcode = 1
			END
			
			IF @CostType IS NOT NULL AND @CostType <> @ItemCostType
			BEGIN
				SELECT @msg = 'Invalid CostType: ' + CONVERT(VARCHAR,@CostType) + ' for existing PM/SL Item: ' + @ItemIN + '.', @rcode = 1
			END
		
		END
	END
	
	


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPOSLItemValForPMOL] TO [public]
GO
