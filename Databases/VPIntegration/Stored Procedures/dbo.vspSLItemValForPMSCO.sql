SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--CREATE PROC [dbo].[vspSLItemValForPMSCO]
CREATE proc [dbo].[vspSLItemValForPMSCO]
/***********************************************************
* CREATED BY:	DAN SO 01/24/2011
* MODIFIED BY:	GF 03/11/2011 TK-01445
*				DAN SO 04/12/2011 - TK-03815 - return SLItemDescription since @msg gets overwritten in form
*				GF 06/13/2011 TK-06053
*				JG	06/21/2011	TK-06041 - Removed requirement of @SubCO
*				JG	06/29/2011	TK-06041 - Added Purchase Units/Amount
*				GF 11/02/2011 TK-09613 if changing existing detail must be for job assigned to SCO.
* 
*
* USAGE:
* Copy of bspSLItemValForPM - needed most of the same information with a little extra.
* Called from PM Subcontract Change Order Item form 
*
* INPUT PARAMETERS
*	@Seq			PMMF Sequence
*   @SLCo			SL Co to validate against
*   @Subcontract	Contract
*   @SLItemIN		Item to validate
*
* OUTPUT PARAMETERS
*	@SLItem			output SL item
*	@ItemType		Item Type - Regular/Change/BackCharge/Addon
*	@ItemPhase		Phase
*	@ItemCostType	Cost Type
*	@ItemUnits		# of Units
*	@ItemUM			UM
*	@ItemUnits		Units
*	@ItemUnitCost	Unit Cost
*	@ItemAmount		Amount
*	@ItemTaxType	Tax Type
*	@ItemTaxCode	Tax Code
*	@ItemTaxGroup	Tax Group
*	@ItemWCPct		WC Retainage %
*	@ItemSMPct		SM Retainage %
*	@ItemExistsYN	Item Exists?
*	@ItemIntFacedYN	Item interfaced in PMSL?
*	@ItemSLItemDesc Item Description (TK-03815)
*	@ItemReceiving	Item Receiving flag
*   @msg			error message IF error occurs otherwise Description of SL
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@Seq INT = NULL, @SLCo bCompany = 0, @Subcontract varchar(30) = NULL,
 @SubCO SMALLINT = NULL, @SLItemIN VARCHAR(6) = NULL, @SLItem SMALLINT = NULL OUTPUT,
 @ItemType tinyint = null output, @ItemPhase bPhase = null output,
 @ItemCostType bJCCType = null output, @ItemUM bUM = null output, @ItemUnits bUnits = NULL OUTPUT,
 @ItemUnitCost bUnitCost = null output, @ItemAmount bDollar = NULL OUTPUT,
 @ItemWCPct bPct = null output,
 @ItemSMPct bPct = null output, @ItemTaxType tinyint = null output,
 @ItemTaxCode bTaxCode = null output, @ItemTaxGroup bGroup = null output,
 @ItemSLExistsYN bYN = 'N' output, @ItemPMIntFacedYN bYN = 'N' output,
 @ItemPMExistsYN bYN = 'N' output, @ItemPOItemDesc bItemDesc = '' output,
 @msg varchar(255) output)

AS
SET NOCOUNT ON

DECLARE @rcode	INT, @PM_Item SMALLINT, @SL_Item SMALLINT,
		@PMSL_POCONum	SMALLINT,
		@PMSL_Seq		INT,
		@KeyID			BIGINT,
		----TK-09613
		@SLIT_JCCo bCompany, @SLIT_Job bJob,
		@SCO_JCCo bCompany, @SCO_Job bJob

------------------
-- PRIME VALUES --
------------------
SET @ItemSLExistsYN = 'N'
SET @ItemPMExistsYN = 'N'
----TK-06053
SET @ItemPMIntFacedYN = 'N'
SET @rcode = 0

---------------------
-- VALIDATE VALUES --
---------------------
IF @SLCo is null
	BEGIN
		SELECT @msg = 'Missing SL Company!', @rcode = 1
		GOTO vspexit
	END

IF @Subcontract is null
	BEGIN
		SELECT @msg = 'Missing SL!', @rcode = 1
		GOTO vspexit
	END

----TK-06041
--IF @SubCO is null
--	BEGIN
--		SELECT @msg = 'Missing Subcontract Change Order!', @rcode = 1
--		GOTO vspexit
--	END

IF @SLItemIN is null
	BEGIN
		SELECT @msg = 'Missing SL Item!', @rcode = 1
		GOTO vspexit
	END


SET @SLItemIN = LTRIM(RTRIM(@SLItemIN))
---- first check to see if we are going to generate next SL Item (+,N)
IF UPPER(@SLItemIN) NOT IN ('+','N')
	BEGIN
	---- verify item is numeric
	IF ISNUMERIC(@SLItemIN) <> 1
	--IF dbo.bfIsInteger(@SLItemIN) = 1
		BEGIN
			SELECT @msg = 'Invalid SL Item: ' + ISNULL(@SLItemIN,'') + ' , must be numeric.', @rcode = 1
			GOTO vspexit
		END
	ELSE
		BEGIN
		---- set output item to input item
		SET @SLItem = @SLItemIN
		END
	END
ELSE
	BEGIN
	---- we are going to generate next item
	---- get max item from PMSL
	select @PM_Item = max(SLItem)
	from dbo.PMSL with (nolock) where SLCo=@SLCo and SL=@Subcontract ----AND SLItem > 0
	if @@rowcount = 0 or @PM_Item is null
		begin
		SET @PM_Item = 0
		END
		
	---- get max item from SLIT
	select @SL_Item = max(SLItem)
	from dbo.SLIT with (nolock) where SLCo=@SLCo and SL=@Subcontract ----AND SLItem > 0
	if @@rowcount = 0 or @SL_Item is null
		begin
		SET @SL_Item = 0
		END
		
	---- take highest of either	PM or SL item
	if @PM_Item >= @SL_Item select @SLItem = @PM_Item
	if @SL_Item > @PM_Item select @SLItem = @SL_Item
	SET @SLItem = @SLItem + 1
	
	END


---- get SCO data TK-09613
IF @SubCO IS NOT NULL
	BEGIN
	SELECT @SCO_JCCo = PMCo, @SCO_Job = Project
	FROM dbo.PMSubcontractCO
	WHERE SLCo = @SLCo
		AND SL = @Subcontract
		AND SubCO = @SubCO
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @msg = 'Invalid Subcontract Change Order.', @rcode = 1
		GOTO vspexit
		END
	END


-----------------------------------
-- GET SLIT AND PMSL INFORMATION --
-----------------------------------
----TK-06053
-- GET SLIT INFORMATION --
SELECT	@ItemType = ItemType, @ItemPhase = Phase, @ItemCostType = JCCType, 
		@ItemUM = UM, @ItemUnits = CurUnits, @ItemUnitCost = CurUnitCost, @ItemAmount = CurCost,
		@ItemWCPct = WCRetPct, @ItemTaxType = TaxType, @ItemTaxCode = TaxCode, @ItemTaxGroup = TaxGroup,
		@ItemSMPct = SMRetPct, @ItemPOItemDesc = Description, @msg = Description,
		-----TK-09613
		@SLIT_JCCo = JCCo, @SLIT_Job = Job
FROM	dbo.SLIT WITH (NOLOCK)
WHERE	SLCo = @SLCo AND SL = @Subcontract AND SLItem = @SLItem
IF @@ROWCOUNT = 0
	BEGIN
	---- set SL exists flag
	SET @ItemSLExistsYN = 'N'
	---- find the first occurance for the SL item in PMSL
	SELECT TOP 1 @PMSL_Seq = Seq
	FROM dbo.PMSL
	WHERE SLCo = @SLCo AND SL = @Subcontract AND SLItem = @SLItem
	GROUP BY SLCo, SL, SLItem, Seq
	IF @@ROWCOUNT = 0
		BEGIN
		---- new item
		GOTO vspexit
		END
	ELSE
		BEGIN
		---- check PMSL for existing item record
		SELECT	@ItemType = SLItemType, @ItemPhase = Phase, @ItemCostType = CostType, 
				@ItemUM = UM, @ItemUnits = Units, @ItemUnitCost = UnitCost, @ItemAmount = Amount,
				@ItemWCPct = WCRetgPct, @ItemTaxType = TaxType, @ItemTaxCode = TaxCode, 
				@ItemTaxGroup = TaxGroup, @ItemSMPct = SMRetgPct, @ItemPOItemDesc = SLItemDescription,
				@msg = SLItemDescription,
				-----TK-09613
				@SLIT_JCCo = PMCo, @SLIT_Job = Project
		FROM dbo.PMSL
		WHERE SLCo = @SLCo AND SL = @Subcontract AND SLItem = @SLItem AND Seq=@PMSL_Seq
		----WHERE	KeyID = @KeyID
		---- ITEM TYPE MUST BE 1 - ORIGINAL OR 2 - CHANGE ORDRE
		IF @ItemType NOT IN (1,2)
			BEGIN
			SELECT @msg='Item type is invalid, must be (1)-Regular or (2)-Change.', @rcode=1
			GOTO vspexit
			END
		----TK-09613
		---- SCO item must be in same JC company
		IF @SCO_JCCo IS NOT NULL AND @SLIT_JCCo <> @SCO_JCCo
			BEGIN
			SELECT @msg = 'Invalid subcontract item. Assigned to different JC Company.', @rcode=1
			GOTO vspexit
			END
		------ SCO item must be in same job
		--IF @SCO_Job IS NOT NULL AND @SLIT_Job <> @SCO_Job
		--	BEGIN
		--	SELECT @msg = 'Invalid subcontract item. Assigned to different Project.', @rcode=1
		--	GOTO vspexit
		--	END
		---- if the first sequence in PMMF for PO Item is this record then editable
		IF @PMSL_Seq = @Seq
			BEGIN
			SET @ItemPMExistsYN = 'N'
			GOTO vspexit
			END
		ELSE
			BEGIN
			---- set exists flag
			SET @ItemPMExistsYN = 'Y'
			GOTO vspexit
			END
		END
	END

---- SLIT item Type must be 1 - ORIGINAL OR 2 - CHANGE ORDER
IF @ItemType NOT IN (1,2)
	BEGIN
	SELECT @msg='Item type is invalid, must be (1)-Regular or (2)-Change.', @rcode=1
	GOTO vspexit
	END

----TK-09613
---- SCO item must be in same JC company
IF @SCO_JCCo IS NOT NULL AND @SLIT_JCCo <> @SCO_JCCo
	BEGIN
	SELECT @msg = 'Invalid subcontract item. Assigned to different JC Company.', @rcode=1
	GOTO vspexit
	END
------ SCO item must be in same job
--IF @SCO_Job IS NOT NULL AND @SLIT_Job <> @SCO_Job
--	BEGIN
--	SELECT @msg = 'Invalid subcontract item. Assigned to different Project.', @rcode=1
--	GOTO vspexit
--	END
	
	
SET @ItemSLExistsYN = 'Y'
		
----TK-06053


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLItemValForPMSCO] TO [public]
GO
