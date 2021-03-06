SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspJCVCOSTTYPEForEst]
   /***********************************************************
     * Created By:	GF	11/15/2001
     * Modified By:	GF	06/13/2002 - Fix for cost type description. issue #17553
     *				SR 07/09/02 - 17738 pass @phasegroup to bspJCVCOSTTYPE
     *              DANF 09/05/02 - 17738 Added Phase Group as parameter
     *				GF 09/30/2003 - issue #22550 need to return bill flag to JCJPEST form
     *				TV - 23061 added isnulls
	 *				GF 12/11/2007 - issue #25569 - validate for closed jobs using JCCO flags
	 *				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-
	 *
	 *
     * USAGE:
     * this is just a modification of VCOSTTYPE used in JCJPEST.
     *
     * PM Modification:
     * Override flag may be set to 'P'.  This will cause the Cost Type to only be validated in
     * JCCT and if in JCCH, will not care if it is inactive.  It will also act like lock phases override is 'Y'.
     * Override flag may be set to 'S'. Used from PMSubcontract and PMSLItems to validate cost type to JCCH
     *                                  using the PM company subcontract option. If 1 works like locked phases.
     * Override flag may be set to 'M'. Used from PMMaterial and PMPOItems to validate cost type to JCCH
     *                                  using the PM company material option. If 1 works like locked phases.
     *
     *
     * INPUT PARAMETERS
     *    co         Job Cost Company
     *    job        Valid job
     *    phasegroup Phase Group
     *    phase      phase to validate
     *    costtype   cost type to validate(either CT or CT Abbrev)
     *    override   optional if set to 'Y' will override 'lock phases' flag from JCJM
     *
     * OUTPUT PARAMETERS
     *    desc	    	abbreviated cost type description
     *    um            unit of measure from JCCH or JCPC.
     *    trackhrs      Y if Tracking hours, otherwise N
     *    costtypeout   Actual costtype validated
     *    retainpct	    Retainage percent
     *	  SourceStatus	Status of Phase/CostType from JCCH
     *    msg           cost type abbreviation, or error message. *
     *    It will validate by first checking in JCCT then JCCH
     *
     *    This uses bspVJCCOSTTYPE to validate Cost Type, then
     *
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
   (@jcco bCompany = 0, @job bJob = null, @phasegroup bGroup = null, @phase bPhase = null,
     @costtype varchar(10), @override bYN = 'N', @ctdesc varchar(60)=null output,
     @um bUM output, @trackhours bYN ='N' output, @costtypeout bJCCType =null output,
     @sourcestatus char(1) output, @billflag char(1) output, @msg varchar(255) output)
as
set nocount on
--#142350 renaming @PhaseGroup
	DECLARE @rcode int,
			@pphase bPhase,
			@itemunitflag bYN,
			@phaseunitflag bYN,
			@item bContractItem,
			@PhaseGrp tinyint,
			@exists bYN

select @rcode = 0, @trackhours='Z', @sourcestatus = 'J'

if isnull(@costtype,'') = '' or isnull(@costtype,'') = 'NEW' goto bspexit
    
exec @rcode =  bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @costtype, @override, @PhaseGrp output, @pphase output,
		@ctdesc output, @billflag output, @um output, @itemunitflag output, @phaseunitflag output, @exists output,
		@costtypeout output, @msg output
if @rcode = 0
	begin
	-- cost type info
	select @trackhours=TrackHours, @ctdesc=Description, @msg=Description
	from bJCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@costtypeout
	-- cost header info
	select @sourcestatus=SourceStatus
	from bJCCH with (nolock) where JCCo=@jcco and Job=@job and Phase=@phase and CostType=@costtypeout
	
	---- validate job status, cannot add to soft, hard closed jobs if JCCO flag does not allow
	if not exists(select top 1 1 from JCCH where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup
						and Phase=@phase and CostType=@costtypeout)
		begin
		exec @rcode = dbo.vspJCJMClosedStatusVal @jcco, @job, @msg output
		end
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCVCOSTTYPEForEst] TO [public]
GO
