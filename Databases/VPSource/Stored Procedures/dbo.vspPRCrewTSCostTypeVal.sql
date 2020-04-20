SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRCrewTSCostTypeVal]
	/******************************************************
	* CREATED BY:	mh 6/27/2008 
	* MODIFIED By:   mh 11/20/09 - Issue 136502.  Essentially this is an extension of 
	*			issue 132377.  If there are no progress units being posted then we do not care if 
	*			there is a cost type.  
	*			mh 11/24/09 - Backed out issue 136502.  Moved to vspPRTSEntryLockVal.
	*
	* Usage:	Validates PhaseCostType for PRRH using bspJCVCOSTTYPE in addition
	*			to PRRQ (Equipment) using the CostType from EMEM
	*	
	*
	* Input params:
	*	
	*			@prco - Payroll Company
	*			@crew - Crew
	*			@postdate - Timesheet Post Date
	*			@sheetnum - Timesheet number
	*			@jcco - Job Company
	*			@job - Job
	*			@phasegroup - PhaseGroup
	*			@proposedPhase - New or Changed Phase
	*			@proposedCostType - New or Changed Cost Type
	*			@override 
	*			@whichphase - Which phase is being changed (Phase 1-8)
	*
	*
	* Output params:
	*
	*			@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
	(@prco bCompany, @jcco bCompany = null, @job bJob = null, @lockedphases bYN, @phasegroup bGroup, @phase bPhase, 
	@costtype varchar(10) = null, @progunits bUnits, @costtypeout bJCCType output, @um bUM = null output, 
	@msg varchar(255) output)

	as 
	set nocount on

	declare @rcode int, @override char(1)

	select @override = 'N'

	select @rcode = 0

	if isnull(@progunits,0) = 0 or @lockedphases = 'N'
	begin
		select @override = 'P'
	end

	exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @costtype, @override, null, null,
	null, null, @um output, null, null, null, @costtypeout output, @msg output

	
	vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPRCrewTSCostTypeVal] TO [public]
GO
