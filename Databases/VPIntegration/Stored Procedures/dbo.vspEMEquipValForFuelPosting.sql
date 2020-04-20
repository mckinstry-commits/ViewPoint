SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMEquipValForFuelPosting]
/****************************************************************************
* CREATED BY: 	TJL 04/25/07 - Issue #27990, 6x Recode EMFuelPosting, modified from bspEMEquipValForFuelPosting
* MODIFIED BY:  TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
*				TRL 02/18/2009 Issue 127133 add materailin parameter to avoid validation error 
*				when INCo Matl group is different from EM Co Material Group.
* USAGE:
*	Used by EMFuelPosting form to validate Equipment entered by user and return
*   various default info to the form.
*
* INPUT PARAMETERS:
*
*
* OUTPUT PARAMETERS:
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@emco bCompany = null, @equipment bEquip = null, @emgroup bGroup = null, 
@matlgroup bGroup = 0, @inco bCompany = null, @inloc bLoc = null,@materialin bMatl =null,
@costcode bCostCode output, @costtype bEMCType output, @gltransacct bGLAcct output, @fuelmatlcodedflt bMatl output,
@materialout bMatl output, @stdum bUM output, @stdunitprice bUnitCost output,  @materialdescout bDesc output, @stdumdesc bDesc output,
@replacedhourreading bHrs output, @previoushourmeter bHrs output, @previoustotalhourmeter bHrs output, @replacedodoreading bHrs output,
@previousodometer bHrs output, @previoustotalodometer bHrs output, 
@perecm bECM output, @fueltype varchar(1) output, @taxableyn bYN output, @errmsg varchar(255) output)
   
as

set nocount on

declare @rcode int, @department varchar(10), @status char(1), @type char(1), @fuelmatlcodedfltdesc bDesc,
@ememcostcode bCostCode, @emcocostcode bCostCode, @ememcosttype bEMCType, @emcocosttype bEMCType,
@EMEPhqmatl bMatl, @partorhqmatldesc varchar(255), @hqstdum bUM, @hqstdunitprice bUnitCost, @emcomatlgroup bGroup

select @rcode = 0, @perecm = 'E'
   
if @emco is null
begin
	select @errmsg = 'Missing EM Company.', @rcode = 1
	goto vspexit
end
if IsNull(@equipment,'')=''
begin
	select @errmsg = 'Missing Equipment.', @rcode = 1
	goto vspexit
end
if @emgroup is null
begin
	select @errmsg = 'Missing EM Group.', @rcode = 1
	goto vspexit
end
   
--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equipment, @errmsg output
If @rcode = 1
begin
	  goto vspexit
end

/* Basic validation - Get various info from bEMEM for @equipment. */
select @errmsg = e.Description, @fuelmatlcodedflt= e.FuelMatlCode, @ememcostcode = e.FuelCostCode,
@ememcosttype = e.FuelCostType, @previoushourmeter = e.HourReading, @previousodometer = e.OdoReading,
@replacedhourreading = e.ReplacedHourReading, @replacedodoreading = e.ReplacedOdoReading,
@status = e.Status, @type = e.Type, @department = e.Department, @fueltype = e.FuelType,
@emcocostcode = c.FuelCostCode, @emcocosttype = c.FuelCostType, @emcomatlgroup=o.MatlGroup
from EMEM e with (nolock) 
join EMCO c with (nolock) on c.EMCo = e.EMCo
join HQCO o with (nolock) on o.HQCo = e.EMCo
where e.EMCo = @emco and e.Equipment = @equipment
if @@rowcount = 0
begin
	select @errmsg = 'Invalid Equipment - not on file in Equip Master.', @rcode = 1
	goto vspexit
end

if @type = 'C'
begin
	select @errmsg = 'Invalid Equipment - cannot be a Component.', @rcode = 1
	goto vspexit
end

if @status = 'I'
begin
	select @errmsg = 'Equipment Status cannot be set Inactive.', @rcode = 1
	goto vspexit
end

/* Set other output values */
select @costcode = isnull(@ememcostcode, @emcocostcode)
select @costtype = isnull(@ememcosttype, @emcocosttype)
select @previoustotalhourmeter = isnull(@previoushourmeter, 0) + isnull(@replacedhourreading, 0)
select @previoustotalodometer = isnull(@previousodometer, 0) + isnull(@replacedodoreading, 0)
   
/* Price information relative to the Fuel Material Code usually gets returned and set as a result
of Material validation when the Material default is set in the form. 
Material validation (runs bspEMEquipPartVal) and will return HQMatl Cross Reference if applicable,
stdum from HQMT, stdunitprice from INMT or HQMT as appropriate, category from HQMT, 
and TaxCode from INLM when taxable.  

However in one condition where user has entered equipment once already and has returned and changed
the equipment value and if the Fuel Material Code is the same for both then Material validation
would not run as stated above.  Therefore we must get any values that are dependent on Equipment.
The code that follows will probably run twice (Once here and once in Matl validation but this
cannot be avoided. */

/*Issue 127133 need to prevent Equiment Validation error when 
IN Co MatlGroup is from EM Co Matl Group*/
If IsNull(@materialin,'') = '' and @matlgroup=@emcomatlgroup
begin
	select @materialin = @fuelmatlcodedflt 
end

IF isnull(@materialin, '') <> ''
	BEGIN
		/* Get Material values based upon EMEP reference, Location and other various flag settings */
		exec @rcode = dbo.bspEMEquipPartVal @emco, @equipment, @matlgroup, @inco, @inloc, 
		@materialin, null, @EMEPhqmatl output, @hqstdum output, @hqstdunitprice output, null,
		null, null, @partorhqmatldesc output					
		if @rcode <> 0 
		begin
			/* If not successful, return error message.  This is essentially more indepth validation errors. */
			select @errmsg = @partorhqmatldesc		--Error Message
			--goto vspexit							--Do not exit!  Error message is displayed but we still need GLTransAcct
		end
		/* Get Material Code Description for the default FuelMatlCode value before being processed by bspEMEquipPartVal
		possibly changed. */
		select @fuelmatlcodedfltdesc = Description	from HQMT with (nolock)
		where MatlGroup = @matlgroup and Material = @materialin

		if IsNull(@EMEPhqmatl,'') = '' 
		begin
			select @EMEPhqmatl = null
		end
		if IsNull(@EMEPhqmatl,'')=''
		begin
			select @partorhqmatldesc = null
		End

		/* Continue on - Set output values */
		select @materialout = isnull(@EMEPhqmatl, @materialin)	--@EMEPhqmatl is null when @fuelmatlcodedflt not in EMEP or is, but has no reference to HQMT
		select @materialdescout = isnull(@partorhqmatldesc, @fuelmatlcodedfltdesc)
		select @stdum = @hqstdum									--@hqstdum is null only if @fuelmatlcode not in EMEP or HQMT and EMCO.MatlValid = N
		select @stdumdesc = Description	from HQUM with(nolock) where UM = @stdum	--UM description must be updated manually on form (not using StdDefaultByField)
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

/* GLOffsetAcct default will also be returned by the same Material validation when Material default
   changes.  Otherwise GLOffsetAcct is not dependent upon an Equipment value. */
   
/* Get GLTransAcct default */ 
select @gltransacct = GLAcct from EMDO with (nolock) 
where EMCo = @emco and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostCode = @costcode
if isnull(@gltransacct, '') = ''
begin
	select @gltransacct = GLAcct from EMDG with (nolock) 
	where EMCo = @emco and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostType = @costtype
end

/* We know what Material code is being used at this point of user input.  Get the HQMT.Taxable flag */
select @taxableyn = Taxable from HQMT with(nolock)
where MatlGroup = @matlgroup and Material = @materialout

vspexit:
if @rcode <> 0 select @errmsg = isnull(@errmsg, '')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipValForFuelPosting] TO [public]
GO
