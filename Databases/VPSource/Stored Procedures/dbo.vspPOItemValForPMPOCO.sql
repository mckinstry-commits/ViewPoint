SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspPOItemValForPMPOCO]
/***********************************************************
* CREATED BY:	DAN SO	04/04/2011
* MODIFIED BY:	JG		05/20/2011	TK-05335 - Modified for removal of seq field and changing
*									POItem to key field.
*				JG	05/24/2011  TK-05335 - Removed changes.
*				TRL 06/08/2011  TK-05860 - Added ECM output parameter
*				GF  06/14/2011  TK-06053
*				JG	06/21/2011	TK-06041 - Removed requirement of @POCONum
*				JG	06/29/2011	TK-06041 - Added Purchase Units/Amount
*				JG	07/15/2011	TK-06765 - Had to add some logic to change '+' to just +.
*				GF 7/27/2011 - TK-07144 changed to varchar(30)
*
*
* USAGE:
* Copy of vspSLItemValForPMSCO
* Called from PM PO Change Order Item form 
*
* INPUT PARAMETERS
*	@Seq			PMMF Sequence
*   @POCo			PO Co to validate against
*   @PO				Purchase Order
*	@POCONum		PO Change Order number
*   @POItemIN		POItem to validate
*
* OUTPUT PARAMETERS
*	@POItemOut			output PO item
*	@ItemType			Item Type 
*	@ItemMaterialGroup	Material Group
*	@ItmeMaterial		Material
*	@ItemPhase			Phase
*	@ItemCostType		Cost Type
*	@ItemUnits			# of Units
*	@ItemUM				UM
*	@ItemUnits			Units
*	@ItemUnitCost		Unit Cost
*   @ItemECM			ECM
*	@ItemAmount			Amount
*	@ItemTaxType		Tax Type
*	@ItemTaxCode		Tax Code
*	@ItemTaxGroup		Tax Group
*	@ItemPOExistsYN		PO Item exists?
*	@ItemPMIntfacedYN	Item interfaced in PMMF?
*	@ItemPMExistsYN		PM Item exists?
*	@ItemPOItemDesc		Item Description
*	@ItemReceiving		Item Receiving flag
*   @msg				error message IF error occurs otherwise Description of PO
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@Seq INT = NULL, @POCo bCompany = 0, @PO VARCHAR(30) = NULL, @POCONum smallint = NULL,
 @POItemIN varchar(6) = NULL, @POItemOut bItem = NULL output,
 @ItemMaterialGroup bGroup = NULL output, @ItemMaterial bMatl = NULL output,
 @ItemPhase bPhase = NULL output, @ItemCostType bJCCType = NULL output,
 @ItemUM bUM = NULL output, @ItemUnits bUnits = NULL OUTPUT, @ItemUnitCost bUnitCost = NULL output,
 @ItemECM bECM = NULL output, @ItemAmount bDollar = NULL OUTPUT, @ItemTaxType tinyint = NULL output,
 @ItemTaxCode bTaxCode = NULL output, @ItemTaxGroup bGroup = NULL output,
 @ItemPOExistsYN bYN = 'N' output, @ItemPMIntFacedYN bYN = 'N' output,
 @ItemPMExistsYN bYN = 'N' output, @ItemPOItemDesc bItemDesc = '' output,
 @ItemReceiving bYN = 'N' OUTPUT, @msg varchar(255) output)

AS
SET NOCOUNT ON

DECLARE @rcode			INT, 
		@PO_Item		SMALLINT,
		@PM_Item		SMALLINT,
		@ItemType		TINYINT	,
		@PMMF_POCONum	SMALLINT,
		@PMMF_Seq		INT,
		@KeyID			BIGINT

	SET @rcode = 0

	---------------------
	-- VALIDATE VALUES --
	---------------------
	IF @POCo IS NULL
		BEGIN
			SELECT @msg = 'Missing PO Company!', @rcode = 1
			GOTO vspexit
		END

	IF @PO IS NULL
		BEGIN
			SELECT @msg = 'Missing PO!', @rcode = 1
			GOTO vspexit
		END

	--IF @POCONum IS NULL
	--	BEGIN
	--		SELECT @msg = 'Missing PO Change Order!', @rcode = 1
	--		GOTO vspexit
	--	END

	IF @POItemIN IS NULL
		BEGIN
			SELECT @msg = 'Missing PO Item!', @rcode = 1
			GOTO vspexit
		END


	------------------
	-- PRIME VALUES --
	------------------
	SET @ItemPOExistsYN = 'N'
	SET @ItemPMExistsYN = 'N'
	----TK-06053
	SET @ItemPMIntFacedYN = 'N'
	SET @POItemIN = LTRIM(RTRIM(@POItemIN))
	IF (@POItemIN = '''+''')  SET @POItemIN = '+'
	
	---- first check to see if we are going to generate next PO Item (+,N)
	IF UPPER(@POItemIN) NOT IN ('+','N')
		BEGIN
		---- verify item is numeric
		IF ISNUMERIC(@POItemIN) <> 1
			BEGIN
				SELECT @msg = 'Invalid PO Item: ' + ISNULL(@POItemIN,'') + ' , must be numeric.', @rcode = 1
				GOTO vspexit
			END
		ELSE
			BEGIN
			---- set output item to input item
			SET @POItemOut = @POItemIN
			END
		END
	ELSE
		BEGIN
			---- we are going to generate next item
			---- get max item from PMMF
			select @PM_Item = max(POItem)
			from dbo.PMMF with (nolock) where POCo=@POCo and PO=@PO AND POItem > 0
			IF @@rowcount = 0 or @PM_Item is null
				BEGIN
					SET @PM_Item = 0
				END
				
			---- get max item from POIT
			select @PO_Item = max(POItem)
			from dbo.POIT with (nolock) where POCo=@POCo and PO=@PO AND POItem > 0
			if @@rowcount = 0 or @PO_Item is null
				BEGIN
					SET @PO_Item = 0
				END
				
			---- take highest of either	PM or PO item
			if @PM_Item >= @PO_Item select @POItemOut = @PM_Item
			if @PO_Item > @PM_Item select @POItemOut = @PO_Item
			SET @POItemOut = @POItemOut + 1
		
		END


-----------------------------------
-- GET POIT AND PMMF INFORMATION --
-----------------------------------
----TK-06053
-- GET POIT INFORMATION --
	SET @ItemPOExistsYN = 'Y'
	SELECT	@ItemMaterialGroup = MatlGroup, @ItemMaterial = Material,
			@ItemPhase = Phase, @ItemCostType = JCCType, 
			@ItemUM = UM, @ItemUnits = CurUnits, @ItemUnitCost = CurUnitCost,@ItemECM=CurECM,
			@ItemAmount = CurCost,
			@ItemTaxType = TaxType, @ItemTaxCode = TaxCode, @ItemTaxGroup = TaxGroup,
			@ItemPOItemDesc = Description, @msg = Description,
			@ItemReceiving = RecvYN
	FROM	dbo.POIT WITH (NOLOCK)
	WHERE	POCo = @POCo AND PO = @PO AND POItem = @POItemOut
    IF @@ROWCOUNT = 0
		BEGIN
		---- set po exists flag
		SET @ItemPOExistsYN = 'N'
		---- find the first occurance for the PO item in PMMF
		SELECT TOP 1 @PMMF_Seq = Seq ----, @KeyID = KeyID
		FROM dbo.PMMF
		WHERE POCo = @POCo AND PO = @PO AND POItem = @POItemOut AND MaterialOption = 'P'
		GROUP BY POCo, PO, POItem, Seq ----, KeyID
		IF @@ROWCOUNT = 0
			BEGIN
			---- new item
			GOTO vspexit
			END
		ELSE
			BEGIN
			---- get existing PMMF info
			SELECT	@ItemMaterialGroup = MaterialGroup, @ItemMaterial = MaterialCode,
					@ItemPhase = Phase, @ItemCostType = CostType, @ItemUM = UM,
					@ItemUnits = Units,
					@ItemUnitCost = UnitCost, @ItemECM = ECM, @ItemAmount = Amount,
					@ItemTaxType = TaxType,
					@ItemTaxCode = TaxCode, @ItemTaxGroup = TaxGroup,
					@ItemPOItemDesc = MtlDescription, @msg = MtlDescription,
					@ItemReceiving = RecvYN, @PMMF_POCONum = POCONum,
					@PMMF_Seq = Seq
			FROM	dbo.PMMF
			WHERE POCo=@POCo AND PO=@PO AND POItem=@POItemOut AND Seq=@PMMF_Seq
			--WHERE	KeyID = @KeyID
			---- if the first sequence in PMMF for PO Item is this record then editable
			IF @PMMF_Seq = @Seq
				BEGIN
				SET @ItemPMExistsYN = 'N'
				GOTO vspexit
				END
			ELSE
				BEGIN
				---- set exists flag
				SET @ItemPMExistsYN = 'Y'
				END
			END
		END
			

----TK-06053 END

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPOItemValForPMPOCO] TO [public]
GO
