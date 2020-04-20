SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCBatchDelete    Script Date: 8/28/99 9:34:59 AM ******/
CREATE      proc [dbo].[bspJCBatchDelete]

/***********************************************************
* CREATED BY: 	JM   12/14/98
* MODIFIED By : bc 06/30/99  	got rid of 'goto bspexit' in all the source if...thens so as not to ignore the status change
*				and deleted a debug statement
*                        : Dan F 05/23/00 Added JC MatUse Source 
*				TV - 23061 added isnulls
*				DANF 03/09/2005 Issue 23336 Added Revenue Projections
*			  	DANF 06/22/2005 - Issue # 28787 Update last run information to Allocation Code.
*
*
* USAGE:
* 	Deletes records in JC Batch files per Source passed in
*	and sets Batch Status in bHQBC to 6 ('Canceled').
*
* INPUT PARAMETERS
*	JCCo		Valid JC Company
*	Month		Valid Batch Month
*	BatchId		Valid Batch ID
*	Source		'JC CostAdj', 'JC RevAdj', 'JC Close'
*
* OUTPUT PARAMETERS
*	@msg      error message if error occurs 
*
* RETURN VALUE
*	0         Success
*	1         Failure
*****************************************************/ 
(@jcco bCompany, @mth bMonth, @batchid bBatchID, @source varchar(20),
 @errmsg varchar(60) output)
as
set nocount on
   
declare @rcode int, @status tinyint, @alloccode tinyint
   
set @rcode = 0

/* Verify all params passed. */
if @jcco is null
	begin
	select @errmsg = 'Missing JC Company!', @rcode = 1
	goto bspexit
	end
if @mth is null
	begin
	select @errmsg = 'Missing Batch Month!', @rcode = 1
	goto bspexit
	end
if @batchid is null
	begin
	select @errmsg = 'Missing Batch ID!', @rcode = 1
	goto bspexit
	end
if @source is null
	begin
	select @errmsg = 'Missing Source!', @rcode = 1
	goto bspexit
	end
if @source not in ('JC CostAdj','JC RevAdj', 'JC Close','JC MatUse','JC RevProj')
	begin
	select @errmsg = 'Invalid Source!', @rcode = 1
	goto bspexit
	end
   	
   	
/* Make sure batch is not in posting process. */
select @status=Status
from dbo.HQBC with (nolock) 
where Co=@jcco and Mth=@mth and BatchId=@batchid
if @@rowcount=0 
	begin
	select @errmsg='Invalid batch!', @rcode=1
	goto bspexit
	end
if @status=1 /* Validation in progress. */
	begin
	select @errmsg='Cannot clear - Batch Validation in progress!', @rcode=1
	goto bspexit
	end
if @status=4 /* Posting in progress. */
	begin
	select @errmsg='Cannot clear - Batch Posting in progress!', @rcode=1
	goto bspexit
	end

/* Delete from tables to which records are added in validation procedure for
  each @source. */
if @source = 'JC CostAdj' or @source = 'JC MatUse' 
	begin
   	--First reset the AllocCode processed dates to previous values
   	select @alloccode = AllocCode
   	from dbo.bJCCB 
   	where Co = @jcco and Mth = @mth and BatchId = @batchid
   	if @alloccode is not null
   		begin
   		update dbo.bJCAC 
   			set LastPosted = PrevPosted,
   				LastMonth = PrevMonth,
   				LastBeginDate = PrevBeginDate,
   				LastEndDate = PrevEndDate,
   				PrevPosted = null,
   				PrevMonth = null,
   				PrevBeginDate = null,
   				PrevEndDate = null
   		where JCCo = @jcco and AllocCode = @alloccode
   		end 
   
   	delete dbo.bJCCB where Co=@jcco and Mth=@mth and BatchId=@batchid
   	delete dbo.bJCDA where JCCo=@jcco and Mth=@mth and BatchId=@batchid
   	delete dbo.bJCIN where JCCo=@jcco and Mth=@mth and BatchId=@batchid
   	end

if @source = 'JC RevAdj'
   	begin
   	delete dbo.bJCIA where JCCo=@jcco and Mth=@mth and BatchId=@batchid
   	delete dbo.bJCIB where Co=@jcco and Mth=@mth and BatchId=@batchid
   	end
   	
if @source = 'JC Close'
   	begin
   	update c set InBatchMth = null, InUseBatchId = null
	from JCCM c
	inner join JCXB JCXB
	on JCXB.Co=c.JCCo and JCXB.Contract=c.Contract

   	delete dbo.bJCXA where Co=@jcco and Mth=@mth and BatchId=@batchid
   	delete dbo.bJCXB where Co=@jcco and Mth=@mth and BatchId=@batchid
   	end
   	
if @source = 'JC RevProj'
   	begin
   	delete dbo.bJCIR where Co=@jcco and Mth=@mth and BatchId=@batchid
   	end
   	

/* Set flag in bHQBC to 'Canceled'. */
update dbo.bHQBC set Status=6 
where Co=@jcco and Mth=@mth and BatchId=@batchid




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCBatchDelete] TO [public]
GO
