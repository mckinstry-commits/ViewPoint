SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMMatlValForPartsPosting]
/********************************************************
* CREATED BY: 	TRL 10/18/07 - Copied from bspEMMatlValForFuelPosting
* MODIFIED BY:	TJL 02/05/08 - Issue #126814:  Return EMCO.MatlLastUsedYN value.
*						TRL 07/20/09 - Issue 134218 change gl subtype parameter default
* USAGE:
*	Used on EM Work Order Parts Posting
*   Validates against EMEP and/or HQMT. Returns error msg if EMCO.MatlValid = 'Y' and
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
@emco bCompany = null, 
@equipment bEquip = null,
@matlgroup bGroup=null, 
@material varchar(30)=null,
@defum bUM=null, 
@inco bCompany=null, 
@inloc bLoc=null,
@stdum bUM = null output,
@price bUnitCost = null output,
@taxcode bTaxCode = null output,
@gloffsetacct bGLAcct = null output,
@matldesc varchar(255) = null output,
@invonhand bUnits = null output,
@hqmatl bMatl = null output,
@matllastuseddate bDate output,
@msg varchar(255) output
as
set nocount on

declare @category varchar(10), @matlvalid char(1), @numrows int, @rcode int,
	@stocked bYN, @glco bCompany, @glvalmsg varchar(255),@glaccntsubtype varchar(1)
    
  
select @rcode=0, @gloffsetacct = null, @glvalmsg = null,@glaccntsubtype='I'

if @emco is null
begin
	select @msg='Missing EM Company', @rcode=1
	goto bspexit
end

if @equipment is null
begin
	select @msg='Missing Equipment', @rcode=1
	goto bspexit
end

if @matlgroup is null
begin
	select @msg='Missing HQ Material Group', @rcode=1
	goto bspexit
end

if @material is null
begin
	select @msg='Missing Part No', @rcode=1
	goto bspexit
end

if @defum is null
begin
	select @msg='Missing Default UM!', @rcode=1
	goto bspexit
end
    
-- Validate Material against EMEP and/or HQMT
exec @rcode = dbo.bspEMEquipPartVal @emco, @equipment, @matlgroup, @inco, @inloc, 
	@material, null, @hqmatl output, @stdum output, @price output, @stocked output, 
	@category output,@taxcode output, @matldesc output
if @rcode <> 0 
begin
	select @msg = @matldesc
	goto bspexit
end
 
-- verify @hqmatl not empty
if isnull(@hqmatl,'') = '' 
begin
	select @hqmatl = null
End
   	
select @stdum = isnull(@stdum,@defum), @msg = isnull(@msg,@matldesc) 
      
-- If user specified INCo and INLoc, get GLOffsetAcct from IN tables; otherwise get from HQMC or EMCO
if isnull(@inco,'') <> ''and isnull(@inloc,'') <> ''
begin
	select @invonhand = OnHand from dbo.INMT with (nolock) 
   	where INCo=@inco and Loc=@inloc and MatlGroup = @matlgroup and Material=@material 
   	
	select @gloffsetacct = EquipSalesGLAcct from dbo.INLC with (nolock)
   	where INCo = @inco and Loc = @inloc and Co = @emco and MatlGroup = @matlgroup 
	and Category = (select Category from dbo.HQMT with (nolock) where MatlGroup = @matlgroup and Material = @material)

	if isnull(@gloffsetacct,'') = ''
	begin
		 select @gloffsetacct = EquipSalesGLAcct  from dbo.INLS with (nolock) 
		where INCo = @inco and Loc = @inloc and Co = @emco
	end

	if isnull(@gloffsetacct,'') = ''
	Begin
		select @gloffsetacct = EquipSalesGLAcct from dbo.INLM with (nolock) 
		where INCo = @inco and Loc = @inloc
	end
	
	if @gloffsetacct is null
	begin
		select @msg = 'Missing GLOffsetAcct for Inventory Sales to Equip!', @rcode = 1
		goto bspexit
	end

	-- Validate the GLOffsetAcct as postable
	select @glco = GLCo 
	from dbo.INCO 
	where INCo = @inco

	exec @rcode = dbo.bspGLACfPostable @glco, @gloffsetacct, 'I', @glvalmsg output
	if @rcode <> 0
		begin
		select @msg = 'GLOffsetAcct: ' + isnull(@glvalmsg,''), @rcode = 1
		goto bspexit
		end
	end
else
	begin
		select @gloffsetacct = GLAcct  from dbo.HQMC with (nolock)
   		where MatlGroup = @matlgroup and Category = (select Category from dbo.HQMT with (nolock) where MatlGroup=@matlgroup and Material=@material)
      	if @gloffsetacct is null 
		begin
			select @gloffsetacct = MatlMiscGLAcct  from dbo.EMCO with (nolock)  where EMCo = @emco
		end
    	
		-- Validate the GLOffsetAcct as postable
		select @glco = GLCo 	from dbo.EMCO with (nolock)  where EMCo = @emco

		--Issue 134218
		select @glaccntsubtype=isnull(SubType,'') from GLAC where GLCo=@glco and GLAcct=@gloffsetacct
	
	if @glaccntsubtype <> 'E' and isnull(@glaccntsubtype,'')<>''
		begin
			select @msg = 'GLOffsetAcct: ' + isnull(convert(varchar(20),@gloffsetacct),'') + '	 has a Subledger Type: ' + isnull(@glaccntsubtype,'') + '. Must = E or null!',@rcode=1
			goto bspexit
		end
		
		exec @rcode = dbo.bspGLACfPostable @glco, @gloffsetacct, @glaccntsubtype, @glvalmsg output
		if @rcode <> 0
		begin
			select @msg = 'GLOffsetAcct: ' + isnull(@glvalmsg,''), @rcode = 1
			goto bspexit
		end	
	end

/* Material validation has been successful at this point.  We will now retrieve a "Matl/Part last 
   used date" from EMCD.  This value is display/informational only and there is no need to error
   if for some reason the value cannot be retrieved.  This value will sometimes be displayed on
   forms APEntry, APUnapproved, POEntry, and EMWOPartsPosting. */
select @matllastuseddate = max(ActualDate) from EMCD with (nolock) 
where EMCo = @emco and Equipment = @equipment and Material = @material

bspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMMatlValForPartsPosting] TO [public]
GO
