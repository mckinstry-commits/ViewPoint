SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPMPCOValForPO]
/***********************************************************
 * CREATED By:	Dan So 06/07/2011 - TK-05850
 * MODIFIED BY: GF 06/17/2011 TK-00000
 *				JG 06/21/2011 TK-06041 - Return values for PO entry
 *				JG 06/21/2011 TK-06041 - Removed POCO return
 *				JG 06/23/2011 TK-06041 - Add phase/ct to filter items
 *				JG 06/29/2011 TK-06041 - Added Purchase Units/Amount
 *				JG 07/13/2011 TK-00000 - Changed from Orig values to Cur values
 *				GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
 *				JG 02/21/2012 TK-12755 - Modified the check for Phases and Cost types when the stored value is null.
 *				JayR 10/16/2012 TK-16099 - Fix overlapping variable issue
 *
 * USAGE:
 * validates PO, returns PO Description
 * an error is returned if any of the following occurs
 *
 * INPUT PARAMETERS
 *   POCo  PO Co to validate against
 *   PO to validate
 *   Project
 *   Vendor Group
 *   Vendor
 *
 * OUTPUT PARAMETERS
 * @nextitem		Next sequential PO Item from POIT/PMMF
 * @povendor		vendor assigned to subcontract
 * @POExistsYN		Does the PO Exist?
 * @msg      error message if error occurs otherwise Description of PO, Vendor, Vendor group, and Vendor Name
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@pmco bCompany = 0, @poco bCompany = 0, @po varchar(30) = NULL, @project bJob = null, 
	@phase_lower bPhase = NULL, @costtype bJCCType = NULL, @vendor bVendor = null,
	@vendorgroup bGroup, @nextitem bItem output, @povendor bVendor output,
	@status tinyint = NULL output, 
	----TK-06041
	@POSLItem bItem OUTPUT, @MaterialCode bMatl OUTPUT,
	@UM bUM OUTPUT, @Units bUnits OUTPUT, @UnitCost bUnitCost OUTPUT, @Amount bDollar OUTPUT,
	@Phase bPhase OUTPUT, @CostType bJCCType OUTPUT, @ECM bECM OUTPUT,
	@msg varchar(255) output)
as
set nocount on

declare @rcode int, @povendorgroup bGroup, @maxpmpo bItem, @maxpoit bItem,
		----TK-00000
		@Approved CHAR(1), @POCount INT,
		@DetailCount INT, @Item1 bItem, @Item2 bItem

select @rcode = 0, @status = 0, @maxpmpo = 0, @maxpoit = 0, @nextitem = 0

if @poco is null
   	begin
   	select @msg = 'Missing PO Company!', @rcode = 1
   	goto vspexit
   	end

if @po is null
   	begin
   	select @msg = 'Missing PO!', @rcode = 1
   	goto vspexit
   	end

if @project is null
   	begin
   	select @msg = 'Missing Project!', @rcode = 1
   	goto vspexit
   	end

if @vendorgroup is null
   	begin
   	select @msg = 'Missing Vendor Group!', @rcode = 1
   	goto vspexit
   	end


select @msg=Description, @povendor=Vendor, @povendorgroup=VendorGroup,
----TK-00000
		@Approved = Approved, @status=Status
from dbo.POHD with (nolock) where POCo=@poco and PO=@po
if @@rowcount <> 0
	begin
	---- check to see if vendor entered matches the vendor in PM if we have a vendor
	if @povendorgroup <> @vendorgroup
		begin
		select @msg = 'Vendor Group from PO Header (POHD) does not match the PM Vendor Group.', @rcode = 1
		goto vspexit
		end
	if isnull(@vendor, @povendor) <> @povendor
		begin
		select @msg = 'Vendor entered does not match vendor in PO. ', @rcode = 1
		goto vspexit
		end
	---- check purchase order status allow only(0,3) - open or pending
	if @status not in (0,3)
		begin
		select @msg = 'Purchase Order must be Open or Pending!', @rcode = 1
		goto vspexit
		END
		---- check approved flag TK-00000
	IF @Approved <> 'Y'
		BEGIN
		SET @rcode = 1
		SET @msg = 'Purchase Order must be Approved'
		GOTO vspexit
		END
	end
else
	begin
	select @msg = 'Purchase Order is invalid!', @rcode = 1
	goto vspexit
	end

-- -- -- get maximum PO Item from PMMF
select @maxpmpo = max(POItem) from PMMF with (nolock) where POCo=@poco and PO=@po
if @maxpmpo is null select @maxpmpo = 0
-- -- -- get maximum PO Item from POIT
select @maxpoit = max(POItem) from POIT with (nolock) where POCo=@poco and PO=@po
if @maxpoit is null select @maxpoit = 0
-- -- -- set @nextitem to larger of two plus one
if @maxpmpo > @maxpoit
	select @nextitem = @maxpmpo + 1
else
	select @nextitem = @maxpoit + 1


----TK-06041

	SELECT @POCount = 0, @DetailCount = 0
	
	--Get count of PO items
	SELECT DISTINCT  @Item1 = POItem 
	FROM dbo.POIT 
	WHERE JCCo = @poco AND Job = @project AND PO = @po 
		AND dbo.vfIsEqual(Phase, ISNULL(@phase_lower, Phase)) & 
			dbo.vfIsEqual(JCCType, ISNULL(@costtype, JCCType)) = 1
	SELECT @POCount = @@ROWCOUNT
	
	SELECT DISTINCT @Item2 = POItem 
	FROM dbo.PMMF 
	WHERE PMCo = @pmco AND Project = @project AND PO = @po 
		AND dbo.vfIsEqual(Phase, ISNULL(@phase_lower, Phase)) & 
			dbo.vfIsEqual(CostType, ISNULL(@costtype, CostType)) = 1
	SELECT @DetailCount = @@ROWCOUNT
	
	--Return values if PO Item is unique
	IF ((@POCount = 1 AND @DetailCount = 1) AND (@Item1 = @Item2)) OR (@POCount = 1 AND @DetailCount = 0)
	BEGIN
		SELECT @POSLItem = POItem, @UM = UM, @Units = CurUnits, @UnitCost = CurUnitCost, @ECM = CurECM, @Amount = CurCost, @MaterialCode = Material, @Phase = Phase, @CostType = JCCType
		FROM dbo.POIT 
		WHERE JCCo = @poco AND Job = @project AND PO = @po
			AND dbo.vfIsEqual(Phase, ISNULL(@phase_lower, Phase)) & 
				dbo.vfIsEqual(JCCType, ISNULL(@costtype, JCCType)) = 1
	END
	ELSE IF (@DetailCount = 1 AND @POCount = 0)
	BEGIN
		SELECT @POSLItem = POItem, @UM = UM, @UnitCost = UnitCost, @ECM = ECM, @Amount = Amount, @MaterialCode = MaterialCode, @Phase = Phase, @CostType = CostType
		FROM dbo.PMMF 
		WHERE PMCo = @pmco AND Project = @project AND PO = @po
			AND dbo.vfIsEqual(Phase, ISNULL(@phase_lower, Phase)) & 
				dbo.vfIsEqual(CostType, ISNULL(@costtype, CostType)) = 1
	END

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOValForPO] TO [public]
GO
