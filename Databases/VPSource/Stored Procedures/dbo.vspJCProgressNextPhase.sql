SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCProgressNextPhase]
/****************************************************************************
 * Created By:	DANF 05/04/2006
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to return the next Phase to Progress Entry.
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
( @co bCompany = null, @job bJob = null, @phasegroup bGroup = null, @phase bPhase = null,
  @costtype bJCCType = null,@mth bMonth = null, @batchid bBatchID = null, @method char(1) = null, 
  @nextphase bPhase output, @nextcosttype bJCCType output, @msg varchar(255) output )
as
set nocount on

declare @rcode int

select @rcode = 0, @nextphase = '', @nextcosttype = '', @msg = ''

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
   if @method = null
		  begin
		  select @msg='Missing method!', @rcode = 1
		  goto bspexit
		  end

   if @method = 'N'
		begin
		select top 1 @nextphase = Phase, @nextcosttype = CostType from JCCH h with (nolock)
		where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and  
		--convert(char(20),Phase) > convert(char(20),isnull(@phase,' ')) 
		convert(char(20),Phase) + substring( '   ', 1, 3 - len(rtrim (convert(varchar(3), CostType)))) + convert(varchar(3), CostType) > convert(char(20),@phase) + substring( '   ', 1, 3 - len(rtrim (convert(varchar(3), @costtype)))) + convert(varchar(3), @costtype)
		and not exists (select top 1 1 from JCPP p with (nolock)
						where h.JCCo=p.Co and h.Job=p.Job and h.PhaseGroup=p.PhaseGroup and h.Phase= p.Phase and h.CostType = p.CostType and
						p.Mth = @mth and p.BatchId = @batchid)
		order by convert(char(20),Phase) + substring( '   ', 1, 3 - len(rtrim (convert(varchar(3), CostType)))) + convert(varchar(3), CostType) ASC
		if @@rowcount = 0
			begin
			select @nextphase=@phase, @nextcosttype = @costtype
			end
		end

   if @method = 'L'
		begin
		select top 1 @nextphase = Phase, @nextcosttype = CostType from JCCH h with (nolock)
		where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and
		--convert(char(20),Phase) < convert(char(20),@phase) 
		convert(char(20),Phase) + substring( '   ', 1, 3 - len(rtrim (convert(varchar(3), CostType)))) + convert(varchar(3), CostType) < convert(char(20),@phase) + substring( '   ', 1, 3 - len(rtrim (convert(varchar(3), @costtype)))) + convert(varchar(3), @costtype)
		and not exists (select top 1 1 from JCPP p with (nolock)
						where h.JCCo=p.Co and h.Job=p.Job and h.PhaseGroup=p.PhaseGroup and h.Phase= p.Phase and h.CostType = p.CostType and
						p.Mth = @mth and p.BatchId = @batchid)
		order by Phase Desc, CostType Desc
		--order by convert(char(20),Phase) + substring( '   ', 1, 3 - len(rtrim (convert(varchar(3), CostType)))) + convert(varchar(3), CostType) DESC
		if @@rowcount = 0
			begin
			select @nextphase=@phase, @nextcosttype = @costtype
			end
		end

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCProgressNextPhase] TO [public]
GO
