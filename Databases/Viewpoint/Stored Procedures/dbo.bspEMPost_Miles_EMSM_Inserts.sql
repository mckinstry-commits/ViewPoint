SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspEMPost_Miles_EMSM_Inserts]
/***********************************************************
* CREATED BY: JM 10/8/99
* MODIFIED By : MV 6/01  Issue 12769 - BatchUserMemoUpdate
*            TV/RM 02/22/02 Attachment Fix
*	GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*	JM 08/09/02 - Rewritten for new header-detail form design and new tables - ref Issue 17838
*	JM 08/14/02 - Disabled user memos
*	JM 8/15/02 - Added bEMMS.BatchSeq column
*	RM 10/03/02 - COMPLETE REWRITE for new table structure.
*   RM 11/19/02 - Corrected join on update of bEMSM 
*				  Corrected join on update of bEMSD
*
*	RM 01/29/03 - Update EMTrans for BatchUserMemoUpdate on Add records
*	TV 02/11/04 - 23061 added isnulls
*	TJL 04/09/07 - Issue #27992, 6x Rewrite:  Repaired InUseMth, InUseBatchId not cleared in bEMSD
*	TJL 08/03/07 - Issue #27792, 6x Rewrite:  Repaired Attachments not being posted to EMSM and EMSD
*	GP 05/26/09 - Issue #133434, removed HQAT code
*
*
* USAGE:
* 	Called by bspEMPost_Miles_Main to insert validated entries into bEMMS
*
* INPUT PARAMETERS
*   	EMCo        	EM Co
*   	Month       	Month of batch
*   	BatchId     	Batch ID to validate
*
* OUTPUT PARAMETERS
*   	@errmsg     	If something went wrong
*
* RETURN VALUE
*   	0   		Success
*   	1   		fail
*****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @posteddate bDate,
	@errmsg varchar(255) output)
   
   as
   
set nocount on

declare @batchseq int, @transtype char(1), @emtrans bTrans, @line int, @rcode int,
@errorstart varchar(30), @opencursor int, @itemcount int,@guid varchar(36)

select @rcode = 0

-- declare cursor on MO Header Batch
declare bcEMMH cursor for
select BatchSeq,BatchTransType,UniqueAttchID
from bEMMH
where Co = @co and Mth = @mth and BatchId = @batchid

open bcEMMH
select @opencursor = 1

-- loop through all MO Headers in the batch
posting_loop:
fetch next from bcEMMH into @batchseq,@transtype,@guid
   
if @@fetch_status <> 0 goto posting_end

select @errorstart = 'Seq#: ' + isnull(convert(varchar(6),@batchseq),'')

begin transaction
   
if @transtype = 'A'		-- new entry
	begin
	exec @emtrans = bspHQTCNextTrans 'bEMSM', @co, @mth, @errmsg output

	-- add Miles By State Header
	insert bEMSM (Co,Mth,EMTrans,Equipment,ReadingDate,BeginOdo,EndOdo,Notes,UniqueAttchID)
	select Co, Mth, @emtrans, Equipment,ReadingDate,BeginOdo,EndOdo,Notes,UniqueAttchID
	from bEMMH
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
	if @@rowcount <> 1
		begin
		select @errmsg = isnull(@errorstart,'') + ' - Unable to add Miles by State Header!'
		goto posting_error
		end
   
	-- get Item count
	select @itemcount = count(*) from bEMML
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq

	-- add Miles by State Items
	insert bEMSD (Co,Mth,EMTrans,Line,UsageDate,State,PostedDate,OnRoadLoaded,OnRoadUnLoaded,OffRoad,BatchId,Notes)
	select Co,Mth,@emtrans,Line,UsageDate,State,@posteddate,OnRoadLoaded,OnRoadUnLoaded,OffRoad,@batchid,Notes
	from bEMML
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
	if @@rowcount <> @itemcount
		begin
		select @errmsg = isnull(@errorstart,'') + ' - Unable to add Miles By State Item(s)!'
		goto posting_error
		end
   			
	--Update EMTrans for BatchUserMemoUpdate
	update bEMMH set EMTrans=@emtrans where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
	update bEMML set EMTrans=@emtrans where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
	
	end --@transtype = 'A'
   
if @transtype = 'C'	-- update existing 
	begin
	-- update  Header
	update bEMSM
	set Equipment=h.Equipment,ReadingDate=h.ReadingDate,BeginOdo=h.BeginOdo,EndOdo=h.EndOdo,
		InUseMth = null, InUseBatchId = null, Notes = h.Notes,
		UniqueAttchID = h.UniqueAttchID
	from bEMSM m
	join bEMMH h on m.Co = h.Co and m.Mth=h.Mth and m.EMTrans=h.EMTrans
	where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @batchseq
	if @@rowcount <> 1
		begin
		select @errmsg = isnull(@errorstart,'') + ' - Unable to update Miles By State Header.'
		goto posting_error
		end
   
	--Get EMTrans from Header
	select @emtrans=EMTrans 
	from  bEMMH h
	where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @batchseq

	-- get count for 'add' Items
	select @itemcount = count(*) from bEMML
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and BatchTransType = 'A'
	   -- add all 'add' Items
	/* JM 11-19-02 - Added BatchId to columns being filled */
	insert bEMSD (Co,Mth,EMTrans,Line,UsageDate,PostedDate,State,OnRoadLoaded,OnRoadUnLoaded,OffRoad, BatchId, Notes)
	select Co,Mth,@emtrans,Line,UsageDate,@posteddate,State,OnRoadLoaded,OnRoadUnLoaded,OffRoad,@batchid, Notes
	from bEMML
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and BatchTransType = 'A'
	if @@rowcount <> @itemcount
		begin
		select @errmsg = isnull(@errorstart,'') + ' - Unable to add new Miles By State Item(s)!'
		goto posting_error
		end
	--Update EMTrans for BatchUserMemoUpdate for Add Lines
	update bEMML set EMTrans=@emtrans where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
   		
	-- get count for 'change' Items
	select @itemcount = count(*) from bEMML
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and BatchTransType = 'C'

	-- update all 'change' Items
	update bEMSD
	set UsageDate=h.UsageDate,PostedDate=@posteddate,State=h.State,OnRoadLoaded=h.OnRoadLoaded,OnRoadUnLoaded=h.OnRoadUnLoaded,OffRoad=h.OffRoad,Notes=h.Notes,
	InUseMth = null, InUseBatchId = null
	from bEMSD m
	join bEMML h on m.Co = h.Co and h.Mth=m.Mth and m.EMTrans=h.EMTrans and h.Line=m.Line
	where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @batchseq
		and h.BatchTransType = 'C'
	if @@rowcount <> @itemcount
		begin
		select @errmsg = isnull(@errorstart,'') + ' - Unable to update Miles By State Item(s)!'
		goto posting_error
		end
   
	-- get count for 'deleted' Items
	select @itemcount = count(*) from bEMML
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and BatchTransType = 'D'

	-- remove all 'delete' Items
	delete bEMSD
	from bEMSD d
	join bEMML l on l.Co = d.Co and l.EMTrans=d.EMTrans and l.Mth=d.Mth and l.Line=d.Line 
	where l.Co = @co and l.Mth = @mth and l.BatchId = @batchid and l.BatchSeq = @batchseq
		and  l.BatchTransType = 'D'
	if @@rowcount <> @itemcount
		begin
		select @errmsg = isnull(@errorstart,'') + ' - Unable to delete Miles By State Item(s)!'
		goto posting_error
		end
        end
   
if @transtype = 'D'		-- Delete Header and all Items
	begin
	-- count # of Items for this batch seq
	select @itemcount = count(*) from bEMML
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq

	delete bEMSD from bEMSD d join bEMML l on l.Co = d.Co and l.Mth=d.Mth and l.EMTrans=d.EMTrans and l.Line=d.Line 
	where l.Co = @co and l.Mth=@mth and l.BatchId=@batchid and l.BatchSeq=@batchseq	-- remove Items
	if @@rowcount <> @itemcount
		begin
		select @errmsg = isnull(@errorstart,'') + ' - Unable to delete all Item(s)!'
		goto posting_error
		end

	delete bEMSM from bEMSM m join bEMMH h on m.Co=h.Co and m.Mth=h.Mth and m.EMTrans=h.EMTrans
	where h.Co = @co and h.Mth=@mth and h.BatchId=@batchid and h.BatchSeq=@batchseq	-- remove Header
	if @@rowcount <> 1
		begin
		select @errmsg = isnull(@errorstart,'') + ' - Unable to delete Header!'
		goto posting_error
		end
	end
	   
-- update HQ Attachment info
if @transtype in ('A','C')
	begin
	if @guid is not null
		begin
		exec @rcode = bspHQRefreshIndexes null, null, @guid, null
		end
	end

--Post any User Memos
exec @rcode = dbo.bspBatchUserMemoUpdate @co, @mth, @batchid, @batchseq,
	'EM MilesByState', @errmsg output
   
if @rcode <> 0
goto posting_error
   
   
exec @rcode = dbo.bspBatchUserMemoUpdate @co, @mth, @batchid, @batchseq,
	'EM MilesByState Lines', @errmsg output		

if @rcode <> 0
goto posting_error
   
commit transaction
   
goto posting_loop

posting_error:		--error occured within transaction - rollback any updates and exit
rollback transaction
select @rcode = 1
   
posting_end:
if @opencursor = 1
	begin
	close bcEMMH
	deallocate bcEMMH
	select @opencursor = 0
	end
   
if @rcode<>0 goto bspexit

/* Delete batch detail records */
delete from bEMML where Co = @co and Mth = @mth and BatchId = @batchid

/* Delete batch header records */
delete from bEMMH where Co = @co and Mth = @mth and BatchId = @batchid

/* Make sure batch is empty. */
if exists(select * from bEMMH H inner JOIN bEMML L on H.BatchSeq = L.BatchSeq and H.BatchId = L.BatchId AND H.Mth = L.Mth AND H.Co = L.Co
where H.Co = @co and H.Mth = @mth and H.BatchId = @batchid)
	begin
	select @errmsg = 'Not all EM Miles batch entries were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end

bspexit:
if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMPost_Miles_EMSM_Inserts]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMPost_Miles_EMSM_Inserts] TO [public]
GO
