SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        procedure [dbo].[vspPRTCEquipVal]
  /************************************************************************
  * CREATED:	EN 1/10/06
  * MODIFIED:	TRL 08/13/2008 - 126196 check to see Equipment code is being Changed
  *
  * Purpose of Stored Procedure
  *
  *  Call either bspPREquipValUsage to validate equipment for a job timecard or bspPREquipValNoComponent
  *  to validate for a mechanic timecard.
  *
  * INPUT PARAMETERS
  *	@type		'J' if validating a job timecard equipment, else 'M'
  *	@emco		EM Company
  *	@equip		Equipment
  *	@checkactive
  *	@jccoposted	JC Company
  *	@jobposted	Job
  *
  * OUTPUT PARAMETERS
  *	@usgcosttype Usage Cost Type
  *	@revcode	Equipment Revenue Code 
  *	@class 		Equipment Class
  *	@msg		Description or Error msg 
  *
  * RETURN VALUE:
  * 	0 	    Success
  *	1 & message Failure
  *************************************************************************/

	(@type char(1), @emco bCompany, @equip bEquip, @checkactive bYN = null, @jccoposted bCompany = null, @jobposted bJob = null,
    @usgcosttype bJCCType = null output, @revcode bRevCode = null output, 
	@class bClass = null output, @msg varchar(255) output)

  as
  set nocount on
 
    declare @rcode tinyint, @category varchar(23), @odoreading bHrs, @hrreading bHrs, @jcco bCompany, @job bJob, @phasegrp bGroup,
		@postcosttocomp bYN, @jobflag bYN, @prco bCompany, @employee bEmployee, @equipdesc bDesc, @desc bDesc

    select @rcode = 0, @category=null, @odoreading=null, @hrreading=null, @jcco=null, @job=null, @phasegrp=null,
		@postcosttocomp=null, @jobflag=null, @prco=null, @employee=null
 
	-- Return if Equipment Change in progress for New Equipment Code, 126196.
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
	If @rcode = 1
	begin
		  goto bspexit
	end

	if @type='J'
		begin
		exec @rcode = bspPREquipValUsage @emco, @equip, @checkactive, @jccoposted, @jobposted, @category output, @odoreading output, 
						@hrreading output, @jcco output, @job output, @usgcosttype output, @phasegrp output, @postcosttocomp output, 
						@jobflag output, @prco output, @employee output, @revcode output, @class output, @equipdesc output, 
						@errmsg=@msg output
		end

	if @type='M'
		begin
		exec @rcode = bspPREquipValNoComponent @emco, @equip, @desc output, @msg output
  		end
  
 
  bspexit:
  
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRTCEquipVal] TO [public]
GO
