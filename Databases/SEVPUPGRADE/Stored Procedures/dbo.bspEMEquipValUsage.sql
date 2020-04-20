SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMEquipValUsage    Script Date: 8/28/99 9:34:27 AM ******/
CREATE procedure [dbo].[bspEMEquipValUsage]

/***********************************************************
* CREATED BY: bc 1/4/99
* MODIFIED By : kb 3/16/99
*		bc 05/10/01 - if the EMEM.JCCo is null, retrieve the default from EMCO.JCCo
*		TV 02/11/04 - 23061 added isnulls
*		TJL 12/19/07 - Issue #124391, Rev Equip Status must be A or D
*		TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
*	
* USAGE:
*	Validates EMEM.Equipment and returns flags needed for EM Usage form interface,
*	If equipment needs to be active send flag @checkactive = 'Y' and the status must be 'A'.
*
* INPUT PARAMETERS
*	@emco		EM Company
*	@equip		Equipment to be validated
* 	@checkactive send in a 'Y' or 'N'
*
* OUTPUT PARAMETERS
*	ret val		EMEM column
*	-------		-----------
*	@category	Category
*	@odoreading 	OdoReading
*	@hrreading 	HourReading
*	@jcco 		JCCo
*	@job 		Job
*	@jcct		Cost type
*	@phasegrp 	PhaseGrp
*	@postcosttocomp PostCostToComp
*	@jobflag	Restrict to current job from EMCM
*	@prco		PRCo
*	@employee	Operator from EMEM
* 	@class		used for payroll purposes
*	@errmsg		Description or Error msg if error
**********************************************************/
   
(@emco bCompany,
@equip bEquip,
@checkactive bYN,
@category bCat = null output,
@odoreading bHrs = null output,
@hrreading bHrs = null output,
@jcco bCompany = null output,
@job bJob = null output,
@usgcosttype bJCCType = null output,
@phasegrp bGroup = null output,
@postcosttocomp bYN = null output,
@jobflag bYN = null output,
@prco bCompany = null output,
@employee bEmployee = null output,
@revcode bRevCode = null output,
@class bClass = null output,
@errmsg varchar(255) output)

as
set nocount on
declare @rcode int, @msg varchar(60), @status char(1), @type char(1)
select @rcode = 0
   
if @emco is null
	begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto bspexit
	end

if @equip is null
	begin
	select @errmsg = 'Missing Equipment!', @rcode = 1
	goto bspexit
	end

/* validate equipment and retrieve emem flags */
exec @rcode = dbo.bspEMEquipValWithInfo @emco, @equip, @type=@type output, @category=@category output,
	@odoreading=@odoreading output,	@hrreading=@hrreading output, @jcco=@jcco output, @job=@job output,
	@usgcosttype=@usgcosttype output, @phasegrp=@phasegrp output, @postcosttocomp = @postcosttocomp output, @msg=@errmsg output
if @rcode <> 0 goto bspexit

--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @errmsg output
If @rcode = 1
begin
	  goto bspexit
end

select @prco = PRCo, @employee = Operator, @status = Status, @revcode = RevenueCode
from EMEM with (nolock)
where EMCo = @emco and Equipment = @equip

if @jcco is null select @jcco = JCCo from EMCO where EMCo = @emco

if @checkactive='Y'
	begin
	if @status <>'A' and @status <> 'D'
		begin
		select @errmsg = 'Equipment may not be InActive.', @rcode = 1
		goto bspexit
		end
	end
   
if @type = 'C'
	begin
	select @errmsg = 'Invalid entry.  Cannot be a component!', @rcode = 1
	goto bspexit
	end
   
/* Snag a flag. DDFI is going to validate this category for us anyway. */
exec @rcode = dbo.bspEMCategoryVal @emco, @category, @jobflag output, @msg=@msg output
if @rcode <> 0
	begin
	/* the category is displayed in a label so if there is an error, display it in the same place */
	select @category = @msg
	goto bspexit
	end

select @class = PRClass
from EMCM with (nolock)
where EMCo = @emco and Category = @category

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValUsage] TO [public]
GO
