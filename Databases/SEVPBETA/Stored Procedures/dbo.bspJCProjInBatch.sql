SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCProjInBatch    Script Date: 8/28/99 9:33:01 AM ******/
CREATE proc [dbo].[bspJCProjInBatch]
/***********************************************************
* CREATED BY:	GF 02/17/99
* MODIFIED By:  GF 10/01/2001 - Changed warning message that future projections exist for job.
*				GF 07/31/2002 - Issue #18150 - Only check projection batches.
*				TV - 23061 added isnulls
*				GF 01/14/2009 - issue #131828 allow job in multiple open projection batches in same month
*
* USAGE:
* 	Checks for Current Job in JC Batches.
*
*
* INPUT PARAMETERS
*   JCCo, Job, BatchId, Month, Actual Date, error msg
*
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Phase
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany=0, @job bJob=null, @batch bBatchID=0,
 @mth bMonth, @actualdate datetime, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @query varchar(250), @vbatchid bBatchID, @vmonth bMonth, @vlastdate datetime

select @rcode = 0

if @jcco = 0
	begin
	select @msg = 'Missing JC Company#!', @rcode = 1
	goto bspexit
	end

if @job is null
	begin
	select @msg = 'Missing Job!', @rcode = 1
	goto bspexit
	end

if @mth is null
	begin
	select @msg = 'Missing Month!', @rcode = 1
	goto bspexit
	end

if @actualdate is null
	begin
	select @msg = 'Missing Actual Date!', @rcode = 1
	goto bspexit
	end

---- get batch info
select @vmonth=Mth, @vbatchid=BatchId
from JCPB with (nolock)
where Co=@jcco and Job=@job and (Mth<>@mth or (BatchId<>@batch and Mth=@mth))
if @@rowcount <> 0
	begin
	select @msg='Job ' + isnull(@job,'') + ' exists in a Projection batch! '
	select @msg=@msg + ' month: ' + isnull(convert(varchar(30),@vmonth),'')
	select @msg=@msg + ' batch: ' + isnull(convert(varchar(10),@vbatchid),''), @rcode=1
	goto bspexit
	end

---- get cost header info
select @vlastdate=null
select @vlastdate=max(LastProjDate)
from JCCH with (nolock)
where JCCo=@jcco and Job=@job and LastProjDate>=@actualdate
if @vlastdate is not null
	begin
	if DATEPART(yy,@vlastdate)>DATEPART(yy,@mth)
		begin
		select @msg='Job ' + isnull(@job,'') + ' has future projections - will be deleted when batch is posted!', @rcode=2
		goto bspexit
		end
	if DATEPART(mm,@vlastdate)>DATEPART(mm,@mth) and DATEPART(yy,@vlastdate)=DATEPART(yy,@mth)
		begin
		select @msg='Job ' + isnull(@job,'') + ' has future projections - will be deleted when batch is posted!', @rcode=2
		goto bspexit
		end
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCProjInBatch] TO [public]
GO
