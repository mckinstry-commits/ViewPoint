SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************************************/
CREATE    proc [dbo].[vspJCProgInitBatch]
/***************************************************************************
* CREATED BY: 	DANF 04/17/2006
* MODIFIED BY:	GF 03/06/2008 - issue #127346
*				GF 06/24/2008 - issue #128770 add check for JCCD ActualDate <= @actualdate
*				GF 04/10/2009 - issue #133206 preformance improvements
*
* USAGE:
* 	Fills batch in JC Progress entry
*
* INPUT PARAMETERS:
*	Company, Month, BatchId, Job, Actual Date
*
*
* OUTPUT PARAMETERS:
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@jcco bCompany = null, @month bMonth = null, @batchid bBatchID = null, @job bJob = null, 
 @phasegroup bGroup = null, @actualdate bDate = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @CursorOpen int, @complete int, @phase bPhase, @costtype bJCCType,
		@um bUM, @batchseq int, @plugged bYN, @total bDollar, @projected bDollar,
		@estimate bDollar, @progresscmplt bPct, @lastco tinyint, @lastmth bMonth, @lastbatchid bBatchID

select @rcode = 0

if @jcco is null
	begin
	select @msg = 'Missing Batch Company!', @rcode = 1
	goto bspexit
	end

if @month is null
	begin
	select @msg = 'Missing Batch Month!', @rcode = 1
	goto bspexit
	end

if @batchid = 0
	begin
	select @msg='Missing Batch Id Number!', @rcode = 1
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

if @actualdate = 0
	begin
	select @msg='Missing Actual Date!', @rcode = 1
	goto bspexit
	end


---- Start Processing
declare JCPPCursor cursor LOCAL FAST_FORWARD for
select h.Phase, h.CostType, h.UM, h.Plugged
from dbo.bJCCH h WITH (NOLOCK)
join dbo.bJCJP j with (nolock) on h.JCCo=j.JCCo and h.Job=j.Job and h.PhaseGroup=j.PhaseGroup and h.Phase=j.Phase
where h.JCCo = @jcco and h.Job = @job and h.PhaseGroup = @phasegroup and j.ActiveYN='Y'
---- Do not add records that already exist in the batch.
and not exists(select top 1 1 from dbo.bJCPP p with (nolock) where h.JCCo = p.Co and h.Job = p.Job
			and h.PhaseGroup = p.PhaseGroup and h.Phase=p.Phase and h.CostType = p.CostType
			and Mth = @month and BatchId = @batchid)
---- Do not add link cost type records that will be add via the insert tigger.
and not exists (select top 1 1  from dbo.bJCPPCostTypes s with (nolock) 
			left join JCCH c with (nolock) on h.JCCo=c.JCCo and h.Job=c.Job
			and h.PhaseGroup=c.PhaseGroup and h.Phase=c.Phase and s.LinkProgress=c.CostType
			where s.Co = h.JCCo and s.Mth = @month and s.BatchId = @batchid
			and s.PhaseGroup=h.PhaseGroup and s.CostType=h.CostType and s.LinkProgress is not null
			and c.UM is not null)



open JCPPCursor
select @CursorOpen = 1, @complete = 0


fetch next from JCPPCursor into @phase, @costtype, @um, @plugged
select @complete = @@fetch_status

---- while cursor is not empty
while @complete = 0
BEGIN

	----if @jcco <> isnull(@lastco,0) or @month <> isnull(@lastmth,'') or @batchid <> isnull(@lastbatchid,0)
	----	begin
	----	exec dbo.vspJCProgressLinkCostTypes @jcco, @phasegroup, @month, @batchid
	----	select @lastco=@jcco, @lastmth=@month, @lastbatchid=@batchid
	----	end

	---- first check if phase cost type exists in bJCPP. skip if exists
	if exists(select top 1 1 from dbo.bJCPP with (nolock) where Co=@jcco and Mth=@month and BatchId=@batchid
			and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype)
		begin
		goto next_phase_costtype
		end

	---- get totals from JCCD
	select @total = isnull(sum(ActualUnits),0), 
			@projected =isnull(sum(ProjUnits),0), 
			@estimate = isnull(sum(EstUnits),0) 
	from dbo.bJCCD JCCD with (nolock)	
	where @jcco=JCCD.JCCo and @job=JCCD.Job and @phasegroup=JCCD.PhaseGroup and @phase=JCCD.Phase
	and @costtype=JCCD.CostType and @um=JCCD.UM and JCCD.ActualDate <= @actualdate ----#128770

	---- check to make sure values are not null
	if @total is null select @total = 0
	if @projected is null select @projected = 0
	if @estimate is null select @estimate = 0
	if @plugged is null select @plugged = 'N'

	---- calculate percent complete
	If @plugged = 'Y' 
		begin
		If @projected <> 0
			begin 
			if ABS(@total / @projected) <= 99.9999
				begin
				set @progresscmplt = ABS(@total / @projected)
				end
			else
				begin
				set @progresscmplt = 99.9999
				end
			end
		Else
			begin
			set @progresscmplt = 0
			end
		end
	Else
		begin
		If @estimate <> 0
			begin
			if ABS(@total / @estimate) <= 99.9999
				begin
				set @progresscmplt = ABS(@total / @estimate)
				end
			else
				begin
				set @progresscmplt = 99.9999
				end
			end
		Else
			begin
			set @progresscmplt = 0
			end
		end

	---- get next batch sequence
	select @batchseq = isnull(max(BatchSeq),0)+1 
	from dbo.bJCPP j with (nolock)
	where j.Co = @jcco and j.Mth = @month and j.BatchId = @batchid
	if @batchseq is null set @batchseq = 1

	---- Check JCPP to see if exists
--if not exists(select 1 from bJCPP with (nolock) where Co=@jcco and Mth=@month and BatchId=@batchid
--		and BatchSeq=@batchseq)
--	begin
		insert into bJCPP (Co, Mth, BatchId, Job, PhaseGroup, Phase, CostType, UM,
				ActualUnits, ProgressCmplt, PRCo, Crew, ActualDate, CostTrans, BatchSeq)
		select @jcco, @month, @batchid, @job, @phasegroup, @phase, @costtype, @um, 
				0,@progresscmplt, null, null, @actualdate, null, @batchseq
	--end


next_phase_costtype:
	fetch next from JCPPCursor into @phase, @costtype, @um, @plugged
	select @complete = @@fetch_status
    
END



if @CursorOpen = 1
	begin
	close JCPPCursor
	deallocate JCPPCursor	
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCProgInitBatch] TO [public]
GO
