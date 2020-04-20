SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMUsePostingEquipVal    Script Date:  ******/
CREATE procedure [dbo].[vspEMUsePostingEquipVal]
   
/***********************************************************
* CREATED BY:  TJL 12/19/06 - Issue #27979, 6x Rewrite EMUsePosting.  Based on bspEMEquipValUsage
*								Added output for EquipAttachmentsYN when Attachements exist.
* MODIFIED By : TJL 12/19/07 - Issue #124391, Rev Equip Status must be A or D
*				TRL 08/13/2008 - 126196 check to see Equipment code is being Changed
*
* USAGE:
*	Validates EMEM.Equipment and returns flags needed for EMUsePosting form interface.
*
*
* INPUT PARAMETERS
*	@emco		EM Company
*	@equip		Equipment to be validated
* 	@checkactive send in a 'Y' or 'N'
*
* OUTPUT PARAMETERS
*	ret val		EMEM column
*	-------		-----------
*	@category		Category
*	@odoreading 	OdoReading
*	@hrreading 		HourReading
*	@jcco 			JCCo
*	@job 			Job
*	@jcct			Cost type
*	@phasegrp 		PhaseGrp
*	@postcosttocomp PostCostToComp
*	@jobflag		Restrict to current job from EMCM
*	@prco			PRCo
*	@employee		Operator from EMEM
* 	@class			used for payroll purposes
*	@equipattachmentsyn		Equip Attachments exist for this piece of Equipment
*	@errmsg			Description or Error msg if error
**********************************************************/
   
(@emco bCompany, @equip bEquip, @checkactive bYN,
	@category bCat = null output, @odoreading bHrs = null output, @hrreading bHrs = null output,
	@jcco bCompany = null output, @job bJob = null output, @usgcosttype bJCCType = null output,
	@phasegrp bGroup = null output, @postcosttocomp bYN = null output, @jobflag bYN = null output,
	@prco bCompany = null output, @employee bEmployee = null output, @revcode bRevCode = null output,
	@class bClass = null output, @equipattachmentsyn bYN = 'N' output,
	@errmsg varchar(255) output)
   
as
set nocount on
declare @rcode int, @msg varchar(60), @status char(1), @type char(1)
select @rcode = 0, @equipattachmentsyn = 'N'
   
if @emco is null
	begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto vspexit
	end
if @equip is null
	begin
	select @errmsg = 'Missing Equipment!', @rcode = 1
	goto vspexit
	end
   
-- Return if Equipment Change in progress for New Equipment Code, 126196.
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @errmsg output
If @rcode = 1
begin
	  goto vspexit
end

/* Validate equipment and retrieve EMEM flags */
exec @rcode = dbo.bspEMEquipValWithInfo @emco, @equip, @type=@type output, @category=@category output,
	@odoreading=@odoreading output,	@hrreading=@hrreading output, @jcco=@jcco output, @job=@job output,
	@usgcosttype=@usgcosttype output, @phasegrp=@phasegrp output, @postcosttocomp = @postcosttocomp output, @msg=@errmsg output
if @rcode <> 0 goto vspexit
   
select @prco = PRCo, @employee = Operator, @status = Status, @revcode = RevenueCode
from bEMEM
where EMCo = @emco and Equipment = @equip
   
if @jcco is null select @jcco = JCCo from EMCO where EMCo = @emco
   
if @checkactive='Y'
	begin
	if @status <> 'A' and @status <> 'D'
		begin
		select @errmsg = 'Equipment may not be InActive.', @rcode = 1
		goto vspexit
		end
	end
   
if @type = 'C'
	begin
	select @errmsg = 'Invalid entry.  Cannot be a component!', @rcode = 1
	goto vspexit
	end

/* Look for Equipments attached to this Equipment */
if exists(select top 1 1 from bEMEM with (nolock) where EMCo = @emco and AttachToEquip = @equip and Status = 'A')
	begin
	select @equipattachmentsyn = 'Y'
	end
   
/* Snag a flag. DDFI is going to validate this category for us anyway. */
exec @rcode = dbo.bspEMCategoryVal @emco, @category, @jobflag output, @msg = @msg output
if @rcode <> 0
	begin
	/* the category is displayed in a label so if there is an error, display it in the same place */
	select @category = @msg
	goto vspexit
	end
   
select @class = PRClass
from bEMCM
where EMCo = @emco and Category = @category
   
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMUsePostingEquipVal] TO [public]
GO
