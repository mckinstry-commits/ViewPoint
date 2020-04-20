SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMLocMatlValForFuelPosting]
/********************************************************
* CREATED BY: TJL  04/23/07 - Issue #27990, 6x Rewrite EMFuelPosting form
* MODIFIED BY:	TRL 02/18/09 Issue 127130 MatlInDesc will not return the EM Equip Part Code Desc or HQMatlDesc
*				TRL 02/18/09 Issue 127133 Added @EMEPhqmatl has output parameter, added isnnull's and begin ends

*
* USAGE:  Validates both Location and Material
*		  Returns MatlCode CrossRef when different, StdUM, StdUnitPrice based upon conditions'
*		  TaxCode, Offset GLAcct, and Inventory on Hand.
*		  Location and Material are so closely tied together that they share a single proc
*
* INPUT PARAMETERS:
*   	See below
*
* OUTPUT PARAMETERS:
*		See below.
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
**********************************************************/
(@emco bCompany = null, @matlgroup bGroup = 0, @seqtype varchar(1) = null, @activeopt bYN = null, @source bSource = null,
@equipment bEquip = null, @inco bCompany = null, @inloc bLoc = null, @materialin varchar(30) = null, @umin bUM = null,
@materialout bMatl output, @stdum bUM output, @stdunitprice bUnitCost output, @taxcode bTaxCode output,
@gloffsetacct bGLAcct output, @invonhand bUnits output, @materialdescout bDesc output, 
@stdumdesc bDesc output, @taxableyn bYN output,  @EMEPhqmatl bMatl output, @msg varchar(255) output)

as

set nocount on

declare @rcode int, @active bYN, @category varchar(10), @partorhqmatldesc varchar(255),
@materialindesc bDesc, @hqstdum bUM, @hqstdunitprice bUnitCost

select @rcode = 0, @gloffsetacct = null

if @emco is null
begin
	select @msg = 'Missing EM Company.', @rcode=1
	goto vspexit
end
-- Equipment might be null if user is using F3 defaults for INCo/Location.  However
-- do not warn here.  We need to allow procedure to run.  The following call to bspEMEquipPartVal
-- will fail and return an error that 'Missing Equipment' to give an indication that StdUM,
-- StdUnitPrice, TaxCode cannot be automatically defaulted without an equipment value.  But in
-- addition to this, by allowing the procedure to run, the GLOffsetAcct can still be retrieved
-- based upon other available values.
--
--if @equipment is null
--	begin
--	select @msg = 'Missing Equipment.', @rcode=1
--	goto vspexit
--	end

/* Specific INCo, Location validation */
if @seqtype = 'L'
begin
	if @inco is null
	begin
		select @msg = 'Missing IN Company.', @rcode = 1
		goto vspexit
 	end
	if IsNull(@inloc,'')= ''
 	begin
 		select @msg = 'Missing IN Location.', @rcode = 1
 		goto vspexit
 	end

	select @msg = Description, @active = Active from INLM with (nolock) 
	where INCo = @inco and Loc = @inloc
	if @@rowcount = 0
 	begin
 		select @msg = 'Not a valid IN Location.', @rcode=1
 		goto vspexit
 	end
	if @activeopt = 'Y' and @active = 'N'
 	begin
 		select @msg = 'Not an active Location.', @rcode=1
 		goto vspexit
 	end
end

/* Specific Material validation */
if @seqtype = 'M'
begin
	if @matlgroup = 0
	begin
		select @msg = 'Missing HQ Material Group.', @rcode=1
		goto vspexit
	end
	if IsNull(@materialin,'')=''
	begin
		select @msg = 'Missing Material Code.', @rcode=1
		goto vspexit
	end

	--if @source in ('EMFuel')
	--begin
	--	select @msg = Description from HQMT with (nolock)
	--	where MatlGroup = @matlgroup and Material = @materialin
	--	if @@rowcount = 0
	--	begin
	--		select @msg = 'Not a valid Material.x', @rcode = 1
	--		goto vspexit
	--	end
	--end
end
/****************************** Dependent upon both Location and Material **************************/
/* Price information returned relative to the presence of a Material.  Gets HQMatl Cross Reference if applicable,
   stdum from HQMT, stdunitprice from INMT or HQMT as appropriate, category from HQMT, 
   and TaxCode from INLM when taxable */
IF isnull(@materialin, '') <> ''
	BEGIN
		
		/* Get Material values based upon EMEP reference, Location and other various flag settings */
		exec @rcode = dbo.bspEMEquipPartVal @emco, @equipment, @matlgroup, @inco, @inloc, 
		@materialin, null, @EMEPhqmatl output, @hqstdum output, @hqstdunitprice output, null,
		@category output, @taxcode output, @partorhqmatldesc output					
		if @rcode <> 0 
		begin
			/* If not successful, return error message.  This is essentially more indepth validation errors. */
			select @msg = @partorhqmatldesc		--Error Message
			--goto vspexit						--Do not exit!  Error message is displayed but we still need GLOffsetAcct
		end
		/*Issue 127133 moved.  This will return the correct matl descripiton if the EM Equipment Part Code value exist 
		in HQ Materials.
		Get Material Code Description for the default FuelMatlCode value before being processed by bspEMEquipPartVal
		possibly changed. */
		select @materialindesc = Description from HQMT with (nolock)
		where MatlGroup = @matlgroup and Material = @materialin
		
		if IsNull(@EMEPhqmatl,'')=''
		begin
			select @partorhqmatldesc = null
		end
		/* Continue on - Set output values */
		select @materialout = isnull(@EMEPhqmatl, @materialin)		--@EMEPhqmatl is null when @materialin not in EMEP or is but has no reference to HQMT
		select @materialdescout = isnull(@partorhqmatldesc, @materialindesc)
		select @stdum = isnull(@hqstdum, @umin)						--@hqstdum is null only if @materialin not in EMEP or HQMT and EMCO.MatlValid = N
		select @stdumdesc = Description	from HQUM where UM = @stdum	--UM description must be updated manually on form (not using StdDefaultByField)
		select @stdunitprice = isnull(@hqstdunitprice, 0)
	END
ELSE
	BEGIN
		select @materialout = null
		select @materialdescout = null
		select @stdum = null
		select @stdumdesc = null
		select @stdunitprice = 0
	END

/* GL Offset Account and Inventory OnHand information returned relative to the presence of Location */
IF @inco is not null and isnull(@inloc,'') <> ''
	BEGIN
	 	select @invonhand = OnHand from INMT with (nolock) 
   		where INCo = @inco and Loc = @inloc and MatlGroup = @matlgroup and Material = @materialout

		select @gloffsetacct = EquipSalesGLAcct from INLC with (nolock)
   		where INCo = @inco and Loc = @inloc and Co = @emco and MatlGroup = @matlgroup 
		and Category = (select Category from HQMT with (nolock) where MatlGroup = @matlgroup and Material = @materialout)
		if isnull(@gloffsetacct,'') = ''
		begin
			select @gloffsetacct = EquipSalesGLAcct from INLS with (nolock) 
			where INCo = @inco and Loc = @inloc and Co = @emco
			if isnull(@gloffsetacct,'') = ''
			begin
				select @gloffsetacct = EquipSalesGLAcct from INLM with (nolock) 
				where INCo = @inco and Loc = @inloc
				if @gloffsetacct is null
				begin
					select @msg = 'Missing GLOffsetAcct for Inventory Sales to Equipment.', @rcode = 1
					goto vspexit
				end
			end
		end
	END
ELSE
	BEGIN
		select @gloffsetacct = GLAcct from HQMC with (nolock) where MatlGroup = @matlgroup 
		and Category = (select Category from HQMT with (nolock) where MatlGroup = @matlgroup and Material = @materialout)
 		if isnull(@gloffsetacct,'') = ''
			begin
			select @gloffsetacct = MatlMiscGLAcct from EMCO with (nolock) where EMCo = @emco
		end
	END

/* We know what Material code is being used at this point of user input.  Get the HQMT.Taxable flag */
select @taxableyn = Taxable from HQMT where MatlGroup = @matlgroup and Material = @materialout


if isnull(@EMEPhqmatl ,'') = ''
begin
	select @EMEPhqmatl =@materialin
end

vspexit:

if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

SET QUOTED_IDENTIFIER ON

GO
GRANT EXECUTE ON  [dbo].[vspEMLocMatlValForFuelPosting] TO [public]
GO
