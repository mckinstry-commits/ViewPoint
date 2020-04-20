SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspJCVCOSTTYPE_GlacctDflt]
/***********************************************************
* CREATED BY:	DC   02/7/07
* MODIFIED By:
*				GF 05/16/2008 - issue #138097 if cost type validation fails set @costtype out if possible to @costtype
*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
*
*
*
* USAGE:
* SLAddItem - In 5.x bspJCVCOSTTYPEWithHrs is used as the validation
*				procedure for Cost Type.  In code in the lost focus of 
*				Cost Type it calls another procedure that returns
*				the default GL Account.  I combined those too sp calls
*				into this one sp.
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
*    desc			abbreviated cost type description
*    um				unit of measure from JCCH or JCPC.
*    costtypeout	Actual costtype validated
*    retainpct	    Retainage percent
*	 GLAcct			Default GL Account
*    msg			cost type abbreviation, or error message. *
*    It will validate by first checking in JCCT then JCCH
*
*    This uses bspVJCCOSTTYPE to validate Cost Type, then
*		calls bspJCCAGlacctDflt to get the default GLAccount
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @job bJob = null, @phasegroup bGroup = null, @phase bPhase = null,
@costtype varchar(10), @override bYN = 'N', @ctdesc varchar(60)=null output,
@um bUM output, @costtypeout bJCCType =null output, @retainpct bPct=null output, 
@glacct bGLAcct output, @glcostoverride bYN output, @msg varchar(255) output)

as
set nocount on
-- #142350 - renaming  @PhaseGroup
DECLARE @rcode int,
		@pphase bPhase,
		@billflag bYN,
		@itemunitflag bYN,
		@phaseunitflag bYN,
		@item bContractItem,
		@PhaseGrp tinyint,
		@exists bYN

select @rcode = 0   


---- validate job, phase, cost type
exec @rcode =  bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @costtype, @override, @PhaseGrp output, @pphase output,
    @ctdesc output, @billflag output, @um output, @itemunitflag output, @phaseunitflag output, @exists output,
    @costtypeout output, @msg output
----#138097
if @rcode = 1
	begin
	---- if we have a validation error then set @costtypeout to @costtype if numeric and 0-255
	if isnumeric(@costtype) = 1
		begin
		if convert(int,convert(float,@costtype)) between 0 and 255
			begin
			select @costtypeout = convert(int,convert(float,@costtype))
			end
		goto bspexit
		end
	end
	
if @rcode = 0
	begin
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

	--Get Default GL Account
	exec @rcode = bspJCCAGlacctDflt @jcco, @job, @phasegroup, @phase, @costtype, @override, @glacct output, @msg output

	select @glcostoverride = GLCostOveride from bJCCO where JCCo = @jcco

	end


	

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCVCOSTTYPE_GlacctDflt] TO [public]
GO
