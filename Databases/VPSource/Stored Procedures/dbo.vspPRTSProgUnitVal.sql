SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure dbo.vspPRTSProgUnitVal
	/******************************************************
	* CREATED BY:	MarkH 
	* MODIFIED By: 
	*
	* Usage:	If Progress units is not null or not zero call Cost Type validation
	*			without the override flag.  If the job has locked phases then phase and 
	*			cost type must exist on the job.
	*	
	*
	* Input params:
	*	
	*		@prco - PR Company
	*		@jcco - JC Company
	*		@job - Job
	*		@phasegroup - Phase Group
	*		@phase - Phase
	*		@costtype - Cost type
	*		@progunits - Progress Units
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @costtype bJCCType,
	@progunits bUnits, @msg varchar(100) output)

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	--If Progress units is null there is nothing to validate.
	if isnull(@progunits,0) <> 0
	begin
		goto vspexit
	end

	--If Progress Units are not null then both Phase and CostType must be on the Job if 
	--Locked Phases is on.  Call bspJCVCOSTTYPE
	exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @costtype, 'N', null, null,
	null, null, null, null, null, null, null, @msg output

	 
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRTSProgUnitVal] TO [public]
GO
