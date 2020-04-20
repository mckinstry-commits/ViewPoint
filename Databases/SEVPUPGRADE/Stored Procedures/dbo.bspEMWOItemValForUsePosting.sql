SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspEMWOItemValForUsePosting]
/***********************************************************
* CREATED BY: JM  1-3-01 Adapted from bspEMWOItemVal to return Component and ComponentTypeCode only
*			when the WOItem's Equipment is flagged to PostCostToComp in bEMEM. Also removed unneeded return params.
*			
* MODIFIED By : TV 02/11/04 - 23061 added isnulls 
*		TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
*		TJL 12/13/06 - Issue #27979, 6x Recode EMUsePosting form.  Incorporate WOItem Status Check
*		TJL 06/05/07 - Issue #27993, 6x Recode EMWOTimeCards.  CompType should come from EMWI not EMEM
*		TJL 09/14/07 - Issue #27979, 6x Recode EMUsePosting form.  Return WO Item Equip & Comp Descriptions
*
*
* USAGE:
*  Validates an EM WorkOrder Item for an EMCo/WorkOrder and
*  returns various info. An error is returned if any of the
*  following occurs:
*	No EMCo, WO or WOItem passed
*	No WOItem found
*	No bEMWI.DateCompl not null for WOItem
*
* INPUT PARAMETERS
*  EMCo
*  WorkOrder
*  WOItem to validate
*
* OUTPUT PARAMETERS
*  @equip
*  @comp
*  @comptypecode
*  @costcode
*  @gltransacct
*  @statuswarningyn
*  @msg      error message if error occurs otherwise Description returned
*
* RETURN VALUE
*   0	Success
*   1	Failure
*
*****************************************************/
   
(@emco bCompany = null,
	@workorder varchar(10) = null,
	@woitem smallint = null,
	@equipment varchar(10) = null output,
	@comp varchar(10) = null output,
	@comptypecode varchar(10) = null output,
	@costcode bCostCode = null output,
	@gltransacct bGLAcct = null output,
	@statuswarningyn bYN = null output, 
	@equipmentdesc bDesc = null output,
	@compdesc bDesc = null output,
	@msg varchar(255) output)
   
as

set nocount on

declare @rcode int, @inhsesubflag char(1), @emgroup bGroup, @statustype char(1),
	@statuscode varchar(10), @department bDept, @wopostfinal bYN, @outsiderprct bEMCType
   
select @rcode = 0, @statuswarningyn = 'N'
   
if @emco is null
	begin
	select @msg = 'Missing EM Company!', @rcode = 1
	goto bspexit
	end
if @workorder is null
	begin
	select @msg = 'Missing WorkOrder!', @rcode = 1
	goto bspexit
	end
if @woitem is null
	begin
	select @msg = 'Missing Workorder Item!', @rcode = 1
	goto bspexit
	end
   
/* Validate WOItem. */
select @msg = i.Description, @equipment = i.Equipment, @comp = i.Component, @costcode = i.CostCode, 
	@inhsesubflag = i.InHseSubFlag, @statuscode = i.StatusCode, @emgroup = h.EMGroup,
	@wopostfinal = e.WOPostFinal, @comptypecode = i.ComponentTypeCode,
	@equipmentdesc = eq.Description, @compdesc = co.Description 
from bEMWI i with (nolock)
join bHQCO h with (nolock) on h.HQCo = i.EMCo
join bEMCO e with (nolock) on e.EMCo = i.EMCo
join bEMEM eq with (nolock) on eq.EMCo = i.EMCo and eq.Equipment = i.Equipment
left join bEMEM co with (nolock) on co.EMCo = i.EMCo and co.Equipment = i.Component
where i.EMCo = @emco and i.WorkOrder = @workorder and i.WOItem = @woitem
if @@rowcount = 0
	begin
	select @msg = 'WO Item not on file!', @rcode = 1
	goto bspexit
	end

/* Get StatusType from bEMWS. */
select @statustype = StatusType
from bEMWS with (nolock)
where EMGroup = @emgroup and StatusCode = @statuscode

if @statustype = 'F' and @wopostfinal = 'N'
   	begin
   	select @msg = 'EMCo is not flagged to allow posting to completed WO Items!', @rcode = 1
   	goto bspexit
   	end
   
/* Get info for Component from EMEM if PostCostToComp flag = 'Y' for Equipment; otherwise return nulls
   for Component and ComponentTypeCode. */
if @comp is not null
	begin
   	if (select PostCostToComp from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment) = 'N'
		begin
   		select @comptypecode = null, @comp = null, @compdesc = null
		end
	--else
		--begin
		/* TJL 06/05/07 - Issue #27993:  Get @comptypecode from EMWI above. In EMWI you cannot
		   have Component w/out CompType and visa_versa.  Therefore get CompType from EMWI at
		   same time as you get Component.  */
   		--select @comptypecode = ComponentTypeCode 
		--from bEMEM with (nolock) 
		--where EMCo = @emco and Equipment = @comp
		--end
	end

/* Get OutsideRprCT from bEMWO if bEMWI.InHseSubFlag = 'O'. */
/* NOTE:  As of 12/13/06, the value returned here never actually got used in 5x form code.
   Offset GLAcct defaults came from 'bspEMUsageGlacctDflt' exclusively.  In 6x rewrite,
   this value is no longer returned.  This could be reinvoked if someone discovers a need. */
if @inhsesubflag = 'O'
	begin
   	/* Get Outside Repair EMCostType. */
   	select @outsiderprct = OutsideRprCT 
	from bEMCO with (nolock)
	where EMCo = @emco

   	/* Get GLTransAcct for Outside Repair per EMCostType = @outsiderprct.
   	   Ref Issue 5873 1/26/00 rejection. */
   	/* Now pull GLTransAcct from EMDO or EMDG. Per DH request dont run bspEMCostTypeValForCostCode as that 
   	   will produce an error msg if the ct is not setup for the costcode. */
   	/* Step 1 - Get Department for @equipment from bEMEM. */
   	select @department = Department 
	from bEMEM with (nolock)
	where EMCo = @emco and Equipment = @equipment

   	/* Step 2 - If GLAcct exists in bEMDO, use it. */
   	select @gltransacct = GLAcct 
	from bEMDO with (nolock) 
	where EMCo = @emco and isnull(Department,'') = isnull(@department,'')
		and EMGroup = @emgroup and CostCode = @costcode

   	/* Step 3 - If GLAcct not in bEMDO, get the GLAcct in bEMDG. */
   	if @gltransacct is null or @gltransacct = ''
		begin
   		select @gltransacct = GLAcct 
		from bEMDG with (nolock) where EMCo = @emco and isnull(Department,'') = isnull(@department,'') 
   			and EMGroup = @emgroup and CostType = convert(tinyint,@outsiderprct)
		end

   	/* Step 4 - return an error if @gltransacct still not found. */
   	if @gltransacct is null or @gltransacct = ''
   		begin
   		select @msg = 'Outside Repair GLTransAcct not found in EMDO or EMDG!', @rcode = 1
   		goto bspexit
   		end
   	end
   
/* WOItem Validation is successful.  Set special warning flag. */
if @statustype = 'F' and @wopostfinal = 'Y' select @statuswarningyn = 'Y'

bspexit:
if @rcode <> 0 select @msg = isnull(@msg,'') -- + char(13) + char(10) + '[bspEMWOItemValForUsePosting]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOItemValForUsePosting] TO [public]
GO
