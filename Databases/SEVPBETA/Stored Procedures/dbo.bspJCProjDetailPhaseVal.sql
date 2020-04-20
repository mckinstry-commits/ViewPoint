SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCProjDetailPhaseVal    Script Date: 09/21/2004 ******/
CREATE   procedure [dbo].[bspJCProjDetailPhaseVal]
/***********************************************************
* CREATED BY:	GF 09/21/2004
* MODIFIED By :
*
*
*
*
*
*
* USAGE: Verify that the phase exists for the job with exact match. No valid part phase validation.
*	Used in JC Projection Detail Form at phase validation. Returns cost values to dispaly in labels.
*
* INPUT PARAMETERS
*    @jcco         Job Cost Company
*    @job          Valid job
*    @phase        Phase to validate
*    @phasegroup   group to validate against PhaseGroup in HQCO
*
* OUTPUT PARAMETERS
*	@actualcost			Total JCCD.ActualCost
*	@currestcost		Total JCCD.CurrEstCost
*	@totalcmtdcost		Total JCCD.TotalCmtdCost
*	@remcmtdcost		Total JCCD.RemCmtdCost
*	@msg				Phase description, or error message.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = null, @job bJob = null, @phase bPhase = null, @phasegroup tinyint,
 @actualcost bDollar output, @estcost bDollar output, @totalcmtdcost bDollar output, 
 @remaincmtdcost bDollar output, @msg varchar(255) = null output)
as
set nocount on

declare @rcode int

select @rcode = 0, @actualcost = 0, @estcost = 0, @totalcmtdcost = 0, @remaincmtdcost = 0

if @jcco is null
	begin
	select @msg = 'Missing JC Company!', @rcode = 1
	goto bspexit
	end

if @job is null
	begin
	select @msg = 'Missing Job!', @rcode = 1
	goto bspexit
	end

if @phase is null
	begin
	select @msg = 'Missing Phase!', @rcode = 1
	goto bspexit
	end

---- validate phase exists for Job - exact match
select @msg = Description from JCJP with (nolock)
where JCCo = @jcco and Job = @job and Phase = @phase
if @@rowcount = 0
	begin
	select @msg = 'Phase ' + isnull(@phase,'') + ' not on file for job!', @rcode = 1
	goto bspexit
	end

---- get sum of cost values from bJCCD for display in JC Projections Detail Screen
select @actualcost = sum(ActualCost), @estcost = sum(EstCost),
		@totalcmtdcost = sum(TotalCmtdCost), @remaincmtdcost = sum(RemainCmtdCost)
from JCCD with (nolock) where JCCo=@jcco and Job=@job and Phase=@phase



bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCProjDetailPhaseVal] TO [public]
GO
