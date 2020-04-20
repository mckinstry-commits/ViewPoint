SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCProgressNextCostType]
/****************************************************************************
 * Created By:	DANF 05/04/2006
 * Modified By:	
 *
 *
 * USAGE:
 * Used to return the next Cost Type to Progress Entry.
 *
 * INPUT PARAMETERS:
 * JC Company, Job, Phase Group, Phase, Cost Type, Month, Batch Id
 *
 * OUTPUT PARAMETERS:
 * Next Phase, Message 
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
( @co bCompany = null, @job bJob = null, @phasegroup bGroup = null, @phase bPhase = null
 ,@costtype bJCCType = null,@mth bMonth = null, @batchid bBatchID = null, @nextcostype bJCCType output, @msg varchar(255) output )
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

  if @co is null
      begin
      select @msg = 'Missing Company!', @rcode = 1
      goto bspexit
      end
  if @job is null
      begin
      select @msg = 'Missing Job!', @rcode = 1
      goto bspexit
      end
  if @phasegroup is null
      begin
      select @msg = 'Missing Phase Group!', @rcode = 1
      goto bspexit
      end
   if @mth is null
      begin
      select @msg = 'Missing Batch Month!', @rcode = 1
      goto bspexit
      end
   if @batchid = 0
      begin
      select @msg='Missing Batch Id Number!', @rcode = 1
      goto bspexit
      end

	select top 1 @nextcostype = CostType from JCCH h with (nolock)
	where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and isnull(Phase,'') > = isnull(@phase,'') and isnull(CostType,0) > isnull(@costtype,0)
	and not exists (select top 1 1 from JCPP p with (nolock)
					where h.JCCo=p.Co and h.Job=p.Job and h.PhaseGroup=p.PhaseGroup and h.Phase= p.Phase and h.CostType = p.CostType)

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCProgressNextCostType] TO [public]
GO
