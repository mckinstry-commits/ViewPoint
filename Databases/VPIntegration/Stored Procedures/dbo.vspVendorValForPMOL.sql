SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
   CREATE proc [dbo].[vspVendorValForPMOL]
/***********************************************************
* Created By:	JG	06/20/2011
* Modified By:	JG	06/22/2011  - TK-06041 - Removed return of POCO and SubCO
*				JG  06/23/2011  TK-06041 - Add phase/ct to filter items
*				JG	06/23/2011	TK-06041 - Using the Vendor validation - bspAPVendorValForPMPO
*				JG	06/29/2011	TK-06041 - Added Purchase Units/Amount
*				JG	07/13/2011	TK-00000 - Changed from Orig values to Cur values
*				GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
*
* Usage:
*	Used by PMOL to validate the entry by either Sort Name or number.
* 	Checks Active flag and Vendor Type, based on options passed as input params.
*
* Input params:
*	@apco		AP company
*	@vendgroup	Vendor Group
*	@vendor		Vendor sort name or number
*	@jcco       JC Company
*	@job        Job
*
* Output params:
* @vendorout	Vendor number
* @holdyn		Vendor Hold Flag
* @taxcode		Vendor tax Code
* @active		Vendor Active Flag
* @msg			Vendor Name or error message
*
* Return code:
*	0 = success, 1 = failure
*****************************************************/
   (@jcco bCompany = null, @job bJob = null, @apco bCompany, @phase bPhase = NULL, 
    @costtype bJCCType = NULL, @vendgroup bGroup = null, @vendor varchar(15) = null,
    ----OUTPUTS
    @SL VARCHAR(30) OUTPUT, @PO varchar(30) OUTPUT, @POSLItem bItem OUTPUT, @MaterialCode bMatl OUTPUT,
    @UM bUM OUTPUT, @Units bUnits OUTPUT, @UnitCost bUnitCost OUTPUT, @PurchaseAmount bDollar OUTPUT,
    @Phase bPhase OUTPUT, @CostType bJCCType OUTPUT, @ECM bECM OUTPUT,
    @msg varchar(255) output) 
   as
   set nocount on
   
   declare @rcode int, @SLCount INT, @POCount INT, @DetailCount INT, @Item1 bItem, @Item2 bItem
   
   select @rcode = 0, @SLCount = 0, @POCount = 0, @DetailCount = 0
   
   -- check required input params
   if @vendgroup is null
   	begin
   	select @msg = 'Missing Vendor Group.', @rcode = 1
   	goto bspexit
   	end
   
   if @vendor is null
   	begin
   	select @msg = 'Missing Vendor.', @rcode = 1
   	goto bspexit
   	end
   
   EXEC	@rcode = [dbo].[bspAPVendorValForPMPO]
		@apco = @apco,
		@vendorgroup = @vendgroup,
		@vendor = @vendor,
		@activeopt = 'Y',
		@typeopt = 'X',
		@vendorout = NULL,
		@payterms = NULL,
		@holdyn = NULL,
		@holdcode = NULL,
		@taxcode = NULL,
		@vendorfirm = NULL,
		@msg = @msg OUTPUT
		
   IF @rcode <> 0
   BEGIN
	GOTO bspexit
   END
   
   ----Grab valid SL/PO and Item data
   SELECT @SLCount = 0, @POCount = 0
   
   --Get count of SL and PO header records
   SELECT @SLCount = COUNT(1) FROM dbo.SLHD WHERE JCCo = @jcco AND Job = @job AND VendorGroup = @vendgroup AND Vendor = @vendor AND Approved = 'Y' AND Status IN (0,3)
   SELECT @POCount = COUNT(1) FROM dbo.POHD WHERE JCCo = @jcco AND Job = @job AND VendorGroup = @vendgroup AND Vendor = @vendor AND Approved = 'Y' AND Status IN (0,3)
   
   --Check if only 1 SL or PO was found
   IF (@SLCount = 1 AND @POCount = 0) OR (@POCount = 1 AND @SLCount = 0)
   BEGIN
		IF @SLCount = 1
		BEGIN
			SELECT @SL = SL 
			FROM dbo.SLHD 
			WHERE JCCo = @jcco AND Job = @job AND VendorGroup = @vendgroup AND Vendor = @vendor
			
			
			SELECT @SLCount = 0, @DetailCount = 0
			
			--Get count of SL items
			SELECT DISTINCT @Item1 = SLItem 
			FROM dbo.SLIT 
			WHERE JCCo = @jcco AND Job = @job AND SL = @SL  AND Phase = ISNULL(@phase,Phase) AND JCCType = ISNULL(@costtype,JCCType)
			SELECT @SLCount = @@ROWCOUNT
			
			SELECT DISTINCT @Item2 = SLItem 
			FROM dbo.PMSL 
			WHERE PMCo = @jcco AND Project = @job AND SL = @SL  AND Phase = ISNULL(@phase,Phase) AND CostType = ISNULL(@costtype,CostType)
			SELECT @DetailCount = @@ROWCOUNT
			
			SELECT @SLCount, @DetailCount
			
			--Return values if SL Item is unique
			IF ((@SLCount = 1 AND @DetailCount = 1) AND (@Item1 = @Item2)) OR (@SLCount = 1 AND @DetailCount = 0)
			BEGIN
				SELECT @POSLItem = SLItem, @UM = UM, @Units = CurUnits, @UnitCost = CurUnitCost, @PurchaseAmount = CurCost, @Phase = Phase, @CostType = JCCType 
				FROM dbo.SLIT 
				WHERE JCCo = @jcco AND Job = @job AND SL = @SL AND Phase = ISNULL(@phase,Phase) AND JCCType = ISNULL(@costtype,JCCType)
			END
			ELSE IF (@DetailCount = 1 AND @SLCount = 0)
			BEGIN
				SELECT @POSLItem = SLItem, @UM = UM, @Units = @Units, @UnitCost = UnitCost, @PurchaseAmount = Amount, @Phase = Phase, @CostType = CostType 
				FROM dbo.PMSL 
				WHERE PMCo = @jcco AND Project = @job AND SL = @SL AND Phase = ISNULL(@phase,Phase) AND CostType = ISNULL(@costtype,CostType) 
			END
		END		
		
		ELSE IF @POCount = 1
		BEGIN
			SELECT @PO = PO 
			FROM dbo.POHD 
			WHERE JCCo = @jcco AND Job = @job AND VendorGroup = @vendgroup AND Vendor = @vendor
			
			SELECT @POCount = 0, @DetailCount = 0
			
			--Get count of PO items
			SELECT DISTINCT @Item1 = POItem 
			FROM dbo.POIT 
			WHERE JCCo = @jcco AND Job = @job AND PO = @PO  AND Phase = ISNULL(@phase,Phase) AND JCCType = ISNULL(@costtype,JCCType)
			SELECT @POCount = @@ROWCOUNT
			
			SELECT DISTINCT @Item2 = POItem 
			FROM dbo.PMMF 
			WHERE PMCo = @jcco AND Project = @job AND PO = @PO  AND Phase = ISNULL(@phase,Phase) AND CostType = ISNULL(@costtype,CostType)
			SELECT @DetailCount = @@ROWCOUNT
			
			--Return values if PO Item is unique
			IF ((@POCount = 1 AND @DetailCount = 1) AND (@Item1 = @Item2)) OR (@POCount = 1 AND @DetailCount = 0)
			BEGIN
				SELECT @POSLItem = POItem, @UM = UM, @Units = CurUnits, @UnitCost = CurUnitCost, @PurchaseAmount = CurCost, @MaterialCode = Material, @Phase = Phase, @CostType = JCCType, @ECM = CurECM 
				FROM dbo.POIT 
				WHERE JCCo = @jcco AND Job = @job AND PO = @PO AND Phase = ISNULL(@phase,Phase) AND JCCType = ISNULL(@costtype,JCCType)
			END
			ELSE IF (@DetailCount = 1 AND @POCount = 0)
			BEGIN
				SELECT @POSLItem = POItem, @UM = UM, @Units = @Units, @UnitCost = UnitCost, @PurchaseAmount = Amount, @MaterialCode = MaterialCode, @Phase = Phase, @CostType = CostType, @ECM = ECM 
				FROM dbo.PMMF 
				WHERE PMCo = @jcco AND Project = @job AND PO = @PO AND Phase = ISNULL(@phase,Phase) AND CostType = ISNULL(@costtype,CostType)
			END
		END	
   END
   
   
   bspexit:
       if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVendorValForPMOL] TO [public]
GO
