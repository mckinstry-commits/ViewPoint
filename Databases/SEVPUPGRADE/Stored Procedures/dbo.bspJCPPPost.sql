SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCPPPost    Script Date: 8/28/99 9:36:22 AM ******/
CREATE      proc [dbo].[bspJCPPPost]
/****************************************************************************
* CREATED BY: 	LM  04/25/1997
* MODIFIED BY:  CMW 04/04/2002 - added bHQBC.Notes interface levels update (issue # 16692)
*				GF  05/19/2003 - issue #21289 problem with update JCCD when linked cost type UM <> UM
*				GF  09/09/2003 - issue #18920 - JC progress user memo update to JCCD.
*				TV             - 23061 added isnulls
*				DANF 08/28/2006 - 6.x recode
*				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*				GF 01/27/2009 - issue #132030 only check @units for validation.
*				CHS 04/29/2009 - #131939
*				GF 03/22/2010 - issue #138718 added delete from JCPPPhases and JCPPCostType when post complete
*
* USAGE:
* 	Posts JCPP batch table to JCCD
*
* INPUT PARAMETERS:
*
*
* OUTPUT PARAMETERS:
*
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(255) output)
as
set nocount on
   
declare @rcode int, @opencursor tinyint, @source bSource, @tablename char(20),
		@inuseby bVPUserName, @status tinyint, @seq int, @transtype char(2),
		@jctrans bTrans, @job bJob, @PhaseGroup tinyint, @phase bPhase,
		@costtype bJCCType, @actualdate bDate, @um bUM, @postedum bUM,
		@description bItemDesc, @units bUnits, @pctcmplt bPct, @prco bCompany, @crew varchar(10),
		@Notes varchar(256), @jccdud_flag bYN, @joins varchar(max), @where varchar(max), 
		@updates varchar(max), @sql varchar(max), @columnname varchar(30), @openusermemo tinyint,
		@batchseq int, @uniqueattchid uniqueidentifier
      
   select @rcode = 0, @opencursor = 0, @openusermemo = 0, @jccdud_flag = 'N'
    
   if @co is null
   	begin
   	select @errmsg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
      	end
   
   -- check for date posted 
   if @dateposted is null
   	begin
   	select @errmsg = 'Missing posting date!', @rcode = 1
   	goto bspexit
   	end
   
   
   -- set the user memo flags for the tables that have user memos
   if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.JCPP'))
   	begin
   	  	select @jccdud_flag = 'Y'
   		-- declare cursor on MS Ticket Batch
   		declare UserMemo cursor LOCAL FAST_FORWARD for select name
   		from syscolumns c where c.name like 'ud%' and c.id = object_id('dbo.JCPP')
   		and exists(select * from syscolumns t where t.name = c.name and t.id = object_id('dbo.JCCD'))
   
   		-- open user memo cursor
   		open UserMemo
   		select @openusermemo = 1
   
   		-- process through all entries in batch
   		UserMemo_loop:
   		fetch next from UserMemo into @columnname
   
   		if @@fetch_status = -1 goto UserMemo_end
   		if @@fetch_status <> 0 goto UserMemo_loop
   
   		if @updates is null
   	  		select @updates = 'update  JCCD set ' + isnull(@columnname,'') + ' = b.' + isnull(@columnname,'')
   		else
   			select @updates = isnull(@updates,'') + ', ' + isnull(@columnname,'') + ' = b.' + isnull(@columnname,'')
   
   		goto UserMemo_loop
   
   		UserMemo_end:
   			close UserMemo
   			deallocate UserMemo
   			select @openusermemo = 0
   		
   	end
   
   
   
   -- validate HQ Batch 
   select @source = 'JC Progres'
   exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'JCPP', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   
   if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
   	begin
   	select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
   	goto bspexit
   	end
   
   -- set HQ Batch status to 4 (posting in progress)
   update bHQBC set Status = 4, DatePosted = @dateposted
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   	goto bspexit
   	end
   
   
   
-- declare cursor on JC Projection Batch for posting
declare bcJCPP cursor LOCAL FAST_FORWARD
for select Job, PhaseGroup, Phase, CostType, UM, ActualUnits, ProgressCmplt, PRCo, Crew, ActualDate, BatchSeq, UniqueAttchID
from bJCPP where Co = @co and Mth = @mth and BatchId = @batchid

-- open cursor
open bcJCPP
select @opencursor = 1

-- loop through all rows in this batch
jcpp_posting_loop:
fetch next from bcJCPP into @job, @PhaseGroup, @phase, @costtype, @um, @units,
			@pctcmplt, @prco, @crew, @actualdate, @batchseq, @uniqueattchid

if (@@fetch_status <> 0) goto jcpp_posting_end

-- Do not create JC Cost Detail entry for no progress units or percent complete.
if isnull(@units,0) = 0 ----and isnull(@pctcmplt,0) = 0 ----#132030
	begin
	delete bJCPP where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
	goto jcpp_posting_loop
	end

begin transaction

-- get next available transaction # for JCCD
select @tablename = 'bJCCD'
exec @jctrans = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
if @jctrans = 0 goto jcpp_posting_error

-- insert JC Detail
insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
	ActualDate, JCTransType, Source, Description, PostedUnits, BatchId, InUseBatchId,
	UM, PostedUM, ActualUnits, ProgressCmplt, PRCo, Crew, UniqueAttchID)
values (@co, @mth, @jctrans, @job, @PhaseGroup, @phase, @costtype, @dateposted, 
	@actualdate, 'PE', 'JC Progres', @description, @units, @batchid, null, 
	@um, @um, @units, @pctcmplt, @prco, @crew, @uniqueattchid)
if @@rowcount = 0 goto jcpp_posting_error
   
-- update CostTrans to JCPP for user memo update
update bJCPP set CostTrans = @jctrans
where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
if @@rowcount = 0 goto jcpp_posting_error

-- update progress user memos to bJCCD
if @jccdud_flag = 'Y'
	begin
	-- build joins and where clause
	select @joins = ' from JCPP b with (nolock)'
		+ ' join JCCD with (nolock) on JCCD.JCCo = b.Co and JCCD.Mth = b.Mth and JCCD.CostTrans = b.CostTrans'
	select @where = ' where b.Co = ' + isnull(convert(varchar(3),@co),'') 
		+ ' and b.Mth = ' + CHAR(39) + isnull(convert(varchar(100),@mth),'') + CHAR(39)
		+ ' and b.CostTrans = ' + isnull(convert(varchar(10), @jctrans),'')
		+ ' and JCCD.JCCo = ' + isnull(convert(varchar(3),@co),'')
		+ ' and JCCD.Mth = ' + CHAR(39) + isnull(convert(varchar(100),@mth),'') + CHAR(39)
		+ ' and JCCD.CostTrans = ' + isnull(convert(varchar(10), @jctrans),'')
	-- create user memo update statement
	select @sql = @updates + @joins + @where
	exec (@sql)
	end

jcpp_delete:

-- remove current Transaction from batch
delete bJCPP where Co=@co and Mth=@mth and BatchId=@batchid and CostTrans=@jctrans
if @@rowcount = 0 goto jcpp_posting_error


commit transaction

goto jcpp_posting_loop


-- error occured within transaction - rollback any updates and continue
jcpp_posting_error:		
	rollback transaction
	goto jcpp_posting_loop

-- no more rows to process
jcpp_posting_end:			
-- make sure batch is empty
if exists(select 1 from bJCPP with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all JC Progress Entry batch entries were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end


----#138718
---- delete progress batch phases
delete dbo.bJCPPPhases where Co=@co and Month = @mth and BatchId=@batchid

---- delete linked batch cost types
delete dbo.bJCPPCostTypes where Co=@co and Mth = @mth and BatchId=@batchid
----#138718


-- set interface levels note string
select @Notes=Notes from bHQBC with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
select @Notes=@Notes +
       'GL Cost Interface Level set at: ' + isnull(convert(char(1), a.GLCostLevel),'') + char(13) + char(10) +
       'GL Revenue Interface Level set at: ' + isnull(convert(char(1), a.GLRevLevel),'') + char(13) + char(10) +
       'GL Close Interface Level set at: ' + isnull(convert(char(1), a.GLCloseLevel),'') + char(13) + char(10) +
       'GL Material Interface Level set at: ' + isnull(convert(char(1), a.GLMaterialLevel),'') + char(13) + char(10)
from bJCCO a with (nolock) where JCCo=@co

-- delete HQ Close Control entries
delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

-- set HQ Batch status to 5 (posted)
update bHQBC set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end



bspexit:
	if @opencursor = 1
		begin
		close bcJCPP
		deallocate bcJCPP
		end
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPPPost] TO [public]
GO
