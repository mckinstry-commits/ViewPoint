SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCJMVal    Script Date: 2/12/97 3:25:05 PM ******/
CREATE  proc [dbo].[bspJCJMValForProj]
/***********************************************************
* CREATED BY:	GF	03/03/03 - copy of bspJCJMVal for projections
* MODIFIED By:	TV - 23061 added isnulls
*				DANF - 6.X
*				GF 12/12/2007 - issue #25569 use separate post to closed job flags in JCCo enhancement
*				GF 02/06/2008 - issue #127033 added job description to output params
*				GF 03/27/2008 - issue #126993 added first/last item, phase output params
*				GF 01/14/2009 - issue #131828 allow job in open projection batches in same month
*				CHS	01/21/2009 - issue #26087
*				GF 04/19/2009 - issue #129898 projection worksheet detail
*				GF 03/10/2010 - issue #135227 - job roles enhancement
*				GF 01/18/2011 - issue #142957 need to consider job role when setting beg/end phase and item
*
*
*
*
* USAGE:
* validates JC Job
* and returns contract and Contract Description
* an error is returned if any of the following occurs
* no job passed, no job found in JCJM, no contract found in JCCM
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against 
*   Job    Job to validate
*
* OUTPUT PARAMETERS
*   @contract returns the contract for this job.  
*   @contractdesc returns the contract desc for this contract
*	@hrspermanday returns hours per man day number from JCJM                    
*   @msg      error message if error occurs otherwise Description of Job
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@jcco bCompany = 0, @job bJob = null, @batch bBatchID=0, @mth bMonth, @actualdate bDate,
 @contract bContract = null output,@contractdesc bItemDesc = null output, @hrspermanday bUnits = null output,
 @projminpct bPct = null output, @wcode int = 0 output, @wmsg varchar(500) = null output,
 @jobdesc bItemDesc = null output, @begitem bContractItem = null output, @enditem bContractItem = null output,
 @begphase bPhase = null output, @endphase bPhase = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int , @jobstatus tinyint, @vbatchid bBatchID, @vmonth bMonth, @vlastdate bDate,
		@allowjobinmultibatch bYN, @projresdetopt bYN, @role_phases_exists bYN,
		@user bVPUserName, @user_role varchar(20)

select @rcode = 0, @wcode = 0, @wmsg = '',  @contract='', @contractdesc='', @hrspermanday = 0,
		@allowjobinmultibatch = 'N', @projresdetopt = 'N', @role_phases_exists = 'N'

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

---- get job and contract info #131828
select @msg = j.Description, @contract=j.Contract, @contractdesc=isnull(c.Description,''), 
		@hrspermanday = j.HrsPerManDay, @projminpct = j.ProjMinPct, @jobstatus = j.JobStatus,
		@jobdesc = j.Description, @allowjobinmultibatch = a.ProjJobInMultiBatch,
		@projresdetopt = a.ProjResDetOpt
from JCJM j with (nolock)
join JCCO a with (nolock) on j.JCCo = a.JCCo
left join JCCM c with (nolock) on j.JCCo = c.JCCo and j.Contract=c.Contract 
where j.JCCo = @jcco and j.Job = @job
if @@rowcount = 0
	begin
	select @msg = 'Job not on file, or no associated contract!' , @rcode = 1
	goto bspexit
	end

---- check for pending status
if @jobstatus = 0
	begin
	select @msg = 'Job is pending, cannot do projections.', @rcode = 1
	goto bspexit
	end

---- validate posting to job depending on status
exec @rcode = dbo.vspJCJMClosedStatusVal @jcco, @job, @msg output
if @rcode <> 0 goto bspexit

---- #135527 check for phases that exists for the job, user, projection process
select @user = InUseBy from dbo.HQBC with (nolock)
where Co=@jcco and Mth=@mth and BatchId=@batch
if @@rowcount = 0 set @user = null
---- get the role for this user from JCJPRoles if phases are assigned to the Cost Projections
if @user is not null
	begin
	select @user_role=r.Role from dbo.JCJobRoles r with (nolock)
	left join dbo.JCJPRoles p with (nolock) on p.JCCo=r.JCCo and p.Job=r.Job and p.Role=r.Role and p.Process='C'
	where r.JCCo=@jcco and r.Job=@job and p.Process='C' and r.VPUserName=@user
	and p.JCCo=@jcco and p.Job=@job
	if @@rowcount = 0 set @user_role = null
	end

---- #131828
---- check for job in a projection batch for a different month first
select @vmonth=Mth, @vbatchid=BatchId
from JCPB with (nolock)
where Co=@jcco and Job=@job and Mth <> @mth
if @@rowcount <> 0
	begin
	select @msg='Job: ' + isnull(@job,'') + ' exists in a Projection batch for a different month!'
	select @msg=@msg + ' Batch Month: ' + isnull(convert(varchar(20),@vmonth),'')
	select @msg=@msg + ' Batch Id: ' + isnull(convert(varchar(10),@vbatchid),''), @rcode=1
	goto bspexit
	end

---- now use the company flag to decide if job is allowed on multiple batches in the same month
if @allowjobinmultibatch = 'N'
	begin
	select @vmonth=Mth, @vbatchid=BatchId
	from JCPB with (nolock)
	where Co=@jcco and Job=@job and Mth = @mth and BatchId <> @batch
	if @@rowcount <> 0
		begin
		select @msg= 'Job: ' + isnull(@job,'') + ' exists in a Projection batch for the current month'
		select @msg= @msg + ' and the option to allow jobs in multiple batches is set to no.'
		select @msg= @msg + ' Batch Month: ' + isnull(convert(varchar(20),@vmonth),'')
		select @msg= @msg + ' Batch Id: ' + isnull(convert(varchar(10),@vbatchid),''), @rcode=1
		goto bspexit
		end
	end
else
	begin
	---- create warning that batch is already in an open projection batch for the month
	select @vmonth=Mth, @vbatchid = BatchId
	from JCPB with (nolock)
	where Co=@jcco and Job=@job and Mth = @mth and BatchId <> @batch
	if @@rowcount <> 0
		begin
		---- now check for projection worksheet detail exists in JCPR, do not allow in multiple batches
		if @projresdetopt = 'Y'
			begin
			if exists(select top 1 1 from JCPR with (nolock) where JCCo=@jcco and Job=@job
						and isnull(InUseBatchId,0) <> @batch)
				begin
				select @msg= 'Job: ' + isnull(@job,'') + ' exists in a Projection batch for the current month'
				select @msg= @msg + ' and projection worksheet detail exists.'
				select @msg= @msg + ' Batch Month: ' + isnull(convert(varchar(20),@vmonth),'')
				select @msg= @msg + ' Batch Id: ' + isnull(convert(varchar(10),@vbatchid),''), @rcode=1
				goto bspexit
				end
			end
		select @wmsg= isnull(@wmsg,'') + 'Warning: Job: ' + isnull(@job,'') + ' is in another open projection batch for the current month!', @wcode=2
		end
	end

---- now warn that future projections will be deleted
select @vlastdate=null
select @vlastdate=max(LastProjDate) from bJCCH with (nolock)
where JCCo=@jcco and Job=@job and LastProjDate>=@actualdate
if @vlastdate is not null
	begin
	if year(@vlastdate) > year(@mth) ----(yy,@vlastdate)>DATEPART(yy,@mth)
		begin
		select @wmsg= isnull(@wmsg,'') + 'Job :' + isnull(@job,'') + ' has future projections - will be deleted when batch is posted!', @wcode=2
		goto bspexit
		end
	if month(@vlastdate) > month(@mth) and year(@vlastdate) > year(@mth) ----DATEPART(mm,@vlastdate)>DATEPART(mm,@mth) and DATEPART(yy,@vlastdate)=DATEPART(yy,@mth)
		begin
		select @wmsg= isnull(@wmsg,'') + 'Job ' + isnull(@job,'') + ' has future projections - will be deleted when batch is posted!', @wcode=2
		goto bspexit
		end
	end

---- need to find beginning and ending phase/contract item need to consider job roles.
----#142957
IF @user_role IS NULL
	BEGIN
	---- get first item
	select @begitem=min(Item) from bJCCI with (nolock) where JCCo=@jcco and Contract=@contract
	---- get last item
	select @enditem=max(Item) from bJCCI with (nolock) where JCCo=@jcco and Contract=@contract
	---- get first phase
	select @begphase=min(Phase) from bJCJP with (nolock) where JCCo=@jcco and Job=@job
	---- get last phase
	select @endphase=max(Phase) from bJCJP with (nolock) where JCCo=@jcco and Job=@job
	END
ELSE
	BEGIN
	---- phase
	SELECT @begphase=MIN(Phase) FROM dbo.vJCJPRoles WHERE JCCo=@jcco AND Job=@job AND Process = 'C' AND Role = @user_role
	SELECT @endphase=MAX(Phase) FROM dbo.vJCJPRoles WHERE JCCo=@jcco AND Job=@job AND Process = 'C' AND Role = @user_role
	---- item
	IF @begphase IS NOT NULL
		BEGIN
		SELECT @begitem = Item FROM dbo.bJCJP where JCCo=@jcco and Job=@job AND Phase=@begphase
		END
	IF @endphase IS NOT NULL
		BEGIN
		SELECT @enditem = Item FROM dbo.bJCJP where JCCo=@jcco and Job=@job AND Phase=@endphase
		END
	END
----#142957

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCJMValForProj] TO [public]
GO
