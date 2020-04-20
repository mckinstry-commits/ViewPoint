SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCVCOSTTYPEWithHrs    Script Date: 8/28/99 9:36:22 AM ******/
CREATE  proc [dbo].[bspJCVCOSTTYPEWithHrs]
/***********************************************************
* CREATED BY: SE   12/2/96
* MODIFIED By : SE 12/1096
*				JM 3/11/97 - added ct descr output
*				SE 11/2/97 - added Ret % from contract item
*				kb 12/12/00 - if can't get Ret % from contract item, get from JCCM
*				RM 02/28/01 - Changed Cost type to varchar(10)
*				GF 09/27/2001 - Changed validation from Subcontracts and materials to
*                       use company parameters for validation.
*				SR 07/09/02 - 17738 pass @phasegroup to bspJCVCOSTTYPE
*				DANF 09/05/02 - Added Phase Group parameter
*				TV - 23061 added isnulls
*				GF 05/16/2008 - issue #128267 if cost type validation fails set @costtype out if possible to @costtype
*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-
*
*
*
*
* USAGE:
* this is just a modification of VCOSTTYPE to return weather or not we're tra
* cking hours.
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
*    desc	    abbreviated cost type description
*    um            unit of measure from JCCH or JCPC.
*    trackhrs      Y if Tracking hours, otherwise N
*    costtypeout   Actual costtype validated
*    retainpct	    Retainage percent
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
 @retainpct bPct=null output, @msg varchar(255) output)
as
set nocount on
--   #142350 - renaming @PhaseGroup
DECLARE @rcode int,
		@pphase bPhase,
		@billflag bYN,
		@itemunitflag bYN,
		@phaseunitflag bYN,
		@item bContractItem,
		@PhaseGrp tinyint,
		@exists bYN

select @rcode = 0, @trackhours='Z'

--- phase cost type validation
exec @rcode =  bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @costtype, @override, @PhaseGrp output,
			@pphase output, @ctdesc output, @billflag output, @um output, @itemunitflag output,
			@phaseunitflag output, @exists output, @costtypeout output, @msg output
----#128267
if @rcode = 1
	begin
	---- if we have a validation error then set @costtypeout to @costtype if numeric and 0-255
	if isnumeric(@costtype) = 1
		begin
		if convert(int,convert(float,@costtype)) between 0 and 255
			begin
			select @costtypeout = convert(int,convert(float,@costtype))
			end
		end
	end

if @rcode = 0
   	begin
   	select @trackhours=TrackHours
	from bJCCT T with (nolock) join bHQCO H with (nolock) on H.HQCo=@jcco and H.PhaseGroup=T.PhaseGroup ---- , bHQCO H with (nolock) 
   	where H.HQCo=@jcco and H.PhaseGroup = T.PhaseGroup and T.CostType=@costtypeout
   
   	select @retainpct=RetainPCT from bJCCI I with (nolock) 
   	join bJCJM J with (nolock) on J.JCCo=I.JCCo and J.Contract=I.Contract
   	where J.JCCo=@jcco and J.Job=@job and I.JCCo=@jcco 
   	and I.Item = (select Item from bJCJP with (nolock) where JCCo=@jcco and Job=@job 
   						and PhaseGroup=@phasegroup and Phase=@pphase)
   	if @@rowcount = 0
   	    begin
   	    select @retainpct=isnull(RetainagePCT,0) 
   		from bJCCM I with (nolock) 
   	   	join bJCJM J with (nolock) on J.JCCo=I.JCCo and J.Contract=I.Contract
   	   	where J.JCCo=@jcco and J.Job=@job
   		end
   	end




return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCVCOSTTYPEWithHrs] TO [public]
GO
