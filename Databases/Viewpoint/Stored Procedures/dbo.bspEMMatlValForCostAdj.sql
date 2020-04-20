SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspEMMatlValForCostAdj]
/********************************************************
* CREATED BY: 	JM 4/16/02
* MODIFIED BY:	RM 08/01/02 - Return OnHand val from IN
*				GF 10/01/02 - Issue #17743 - matldesc changed from bDesc to varchar(255). Being used
*				as message value from bspEMEquipPartVal bDesc (30) not big enough.
*				GF 03/13/2003 - issue #19352 - return part hq material
*				GF 03/25/2003 - issue #20819 - do not return LS if not valid part or material allow @defum to be null
*				TV 02/11/04 - 23061 added isnulls
*				DAN SO 05/28/08 - Issue: 128003/128839 - Need to return Taxable from bHQMT
*				TRL 02/18/09 Issue 127133 Added IsNull, begen/end, nolock and added output parameter
*				TRL 07/01/09 Issue 133466 Added statement return @hqmatl output if null for not on file part codes
*				TRL 12/09/09 -Issue 134218 Added Isnull, changed GL Sub Type Validation
*
* USAGE:
*	Validates against EMEP and/or HQMT. Returns error msg if EMCO.MatlValid = 'Y' and
* 	Retrieves the StandardUM and Stocking Status from bHQMT or bEMEP for
*	a valid Material; if Material is invalid, returns UM passed in.
*
* INPUT PARAMETERS:
*   	EM Company
*   	Equipment
*   	HQ Material Group
*	Material (either HQ or EM equip no)
*	Default UM
*
* OUTPUT PARAMETERS:
*	Valid UM  (bEMEP.UM or bHQMT.StdUM)
*	Stocking Status = 'P' or 'S' where bHQMT.Stocked = 'Y' -> 'S' and 'N' -> 'P'
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
**********************************************************/
@emco bCompany = null, @equipment bEquip = null, @matlgroup bGroup=0, @material varchar(30)=null,
@defum bUM=null, @inco bCompany=null, @inloc bLoc=null, @stdum bUM output, @price bUnitCost output,
@taxcode bTaxCode output, @gloffsetacct bGLAcct output, @matldesc varchar(255) output,
@INLMTaxCodeFlag char(1) output, @invonhand bUnits = null output, @hqmatl bMatl = null output, @HQTaxableYN bYN output,
@ishqmatlyn bYN output,@msg varchar(255) output

as

set nocount on

declare	@category varchar(10), @matlvalid char(1), @numrows int, @rcode int,
@stocked bYN, @glco bCompany,  @glsubtype varchar(1) ,
@intaxcode bTaxCode, @LocalMaterial bMatl

select @rcode=0, @ishqmatlyn = 'Y'

if @emco is null
begin
	select @msg='Missing EM Company', @rcode=1
	goto bspexit
end
if IsNull(@equipment,'')=''
begin
	select @msg='Missing Equipment', @rcode=1
	goto bspexit
end
if @matlgroup= 0
begin
	select @msg='Missing HQ Material Group', @rcode=1
	goto bspexit
end
if IsNull(@material,'')=''
begin
	select @msg='Missing Part No', @rcode=1
	goto bspexit
end
if @defum = 'LS' 
begin
	select @defum = null
end

/** Begin Issue 127133 **/
-- Validate Material against EMEP and/or HQMT
exec @rcode = dbo.bspEMEquipPartVal @emco, @equipment, @matlgroup, @inco, @inloc, 
@material, null, @hqmatl output, @stdum output, @price output, @stocked output, 
@category output,@taxcode output, @matldesc output
if @rcode <> 0 
begin
	select @msg = @matldesc
	goto bspexit
end

IF exists (Select HQMatl From dbo.EMEP Where EMCo=@emco and Equipment=@equipment and MatlGroup = @matlgroup and PartNo=@material)
	BEGIN
		if not exists (Select Top 1 1 From dbo.HQMT Where MatlGroup = @matlgroup and Material=IsNull(@hqmatl,''))
			Begin
				select @ishqmatlyn = 'N'
			End
		Else
			Begin
				----------------------------
				-- PRIME TAXABLE VALUE --
				-------------------------
				SELECT @HQTaxableYN = Taxable  FROM dbo.HQMT with(nolock)
				WHERE MatlGroup = @matlgroup AND Material = @hqmatl
			End
	END
ELSE
	BEGIN
		If not exists (Select Top 1 1  From dbo.HQMT Where MatlGroup = @matlgroup and Material=IsNull(@material,''))
			Begin
				select @ishqmatlyn = 'N'
			End
		Else
			Begin
				----------------------------
				-- PRIME TAXABLE VALUE --
				-------------------------
				SELECT @HQTaxableYN = Taxable FROM dbo.HQMT with(nolock)
				WHERE MatlGroup = @matlgroup AND Material = @material
			End
	END

-- If no StdUM found in bHQMT, return default UM passed in.
if IsNull(@stdum,'')=''
begin
	select @stdum=@defum
end

If IsNull(@hqmatl, '')<> ''
begin
	--Replace @material with @hqmatl when exits
	select @material=@hqmatl
end
/** End Issue 127133 **/

/* If bspEMEquipPartVal has returned a null Desc in @msg, assign the incoming @material so
it won't blank out the input on the form. */
--if @msg is null select @msg = @material

/* If user specified INCo and INLoc, get GLOffsetAcct from IN tables; otherwise get from HQMC or EMCO */
IF @inco is not null and isnull(@inloc,'') <> '' 
	BEGIN
		select @invonhand = OnHand from dbo.INMT with(nolock) where INCo=@inco and Loc=@inloc and MatlGroup=@matlgroup and Material = @material

		/* Get OffsetGLAcct = EquipSalesGLAcct from INLC or INLS or INLM or error. */
		select @gloffsetacct = EquipSalesGLAcct from dbo.INLC with(nolock) where INCo = @inco and Loc = @inloc 	and Co = @emco and MatlGroup = @matlgroup 
		and Category = (select Category from dbo.HQMT with(nolock) where MatlGroup = @matlgroup and Material = @material)
	
		if IsNull(@gloffsetacct,'')=''
		begin
			select @gloffsetacct = EquipSalesGLAcct from dbo.INLS with(nolock)where INCo = @inco and Loc = @inloc and Co = @emco
		end
	
		if IsNull(@gloffsetacct,'')=''
		begin
			select @gloffsetacct = EquipSalesGLAcct from dbo.INLM with(nolock)where INCo = @inco and Loc = @inloc
		end

		if IsNull(@gloffsetacct,'')=''
		begin
			select @msg = 'Missing GLOffsetAcct for Inventory Sales to Equip!', @rcode = 1
			goto bspexit
		end
		/* Validate the GLOffsetAcct as postable */
		select @glco = GLCo from dbo.INCO with(nolock)where INCo = @inco
		exec @rcode = dbo.bspGLACfPostable @glco, @gloffsetacct, 'I', @msg output
		if @rcode <> 0
		begin
			select @msg = 'GLOffsetAcct: ' + isnull(@msg,''), @rcode = 1
			goto bspexit
		end
	END
ELSE
	BEGIN
		/* Get GLOffsetAcct from bHQMC by Category */
 		select @gloffsetacct = GLAcct from dbo.HQMC with(nolock) where MatlGroup = @matlgroup and Category = (select Category from dbo.HQMT with(nolock) where MatlGroup=@matlgroup and Material=@material)
 		/* If not returned, get bEMCO.MatlMiscGLAcct. Note that Fuel Posting form will not allow bEMCO.MatlMiscGLAcct to be null. */
 		if IsNull(@gloffsetacct,'')=''
		begin
			select @gloffsetacct = MatlMiscGLAcct from dbo.EMCO with(nolock) where EMCo = @emco
		end
		/* Validate the GLOffsetAcct as postable */
		select @glco = GLCo from bEMCO where EMCo = @emco

		/*Issue 134218 Start */
		select @glsubtype=isnull(SubType,'') from GLAC where GLCo=@glco and GLAcct=@gloffsetacct
		
		if @glsubtype <> 'E' and isnull(@glsubtype,'')<>''
		begin
			select @msg = 'GLOffsetAcct: ' + isnull(convert(varchar(20),@gloffsetacct),'') + '	 has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must = E or null!',@rcode=1
			goto bspexit
		end
		
		exec @rcode = dbo.bspGLACfPostable @glco, @gloffsetacct, @glsubtype, @msg output
		if @rcode <> 0
		begin
			select @msg = 'GLOffsetAcct: ' + isnull(@msg,''), @rcode = 1
			goto bspexit
		end	
		/*Issue 134218 End */
	END

----------------------------
-- Issue: 128003 - Part 2 --
--------------------------------
-- CHECK FOR TAXABLE MATERIAL --
--------------------------------
IF @HQTaxableYN = 'Y'
BEGIN
	if @inco is not null and IsNull(@inloc,'') <> ''
	begin
		select @intaxcode = TaxCode from dbo.INLM with(nolock) where INCo = @inco and Loc = @inloc
		if IsNull(@intaxcode,'')=''
		begin
			select @INLMTaxCodeFlag = 1
		end
	end
END
----------------------------


/*Issue 133466*/
if isnull(@hqmatl,'') = ''
begin
	select @hqmatl=@material
end

bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspEMMatlValForCostAdj] TO [public]
GO
