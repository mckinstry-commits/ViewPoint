SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************************/
CREATE procedure [dbo].[bspEMLBPost_Xfer]
/***********************************************************
* CREATED BY: 	bc 06/11/99
* MODIFIED By : bc 01/04/00
*             bc 09/19/00 - added file attachment code
*             MV 06/06/01 - Issue 12769 - added BatchUserMemoUpdate
*             bc 10/24/01 - Attachments were not being posted because the deletion of the primary equipmemnt
*             was not being resrticted to transactions that have AttachedToEquip = null.  # 15031
*             JM 01/15/02 - Added code to update new Notes column for both add and change transactions.
*             TV/RM 02/22/02 Attachment fix
*             CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*			GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*             TV 12/04/03 issue 18616 Reindexing
*			TV 02/11/04 - 23061 added isnulls
*			GF 01/13/2008 - issue #126725 combine Notes update with insert statement.
*			GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*			GP 05/26/09 - Issue 133434, removed HQAT code
*			TRL 10/28/09 - Issue 133628 add IsNull's and dbo.'
*			ECV 06/16/11 - Issue 143284 Fix update of Notes when there is a Change record in the batch.
*
* USAGE:	posts transfer to EMLH
*		    the destination update to EMEM is in the EMLH triggers
*          unattaches attachments if they are transferred away from primary piece of equipment.  designated by AttachedToSeq = BatchSeq
*
* INPUT PARAMETERS:
*   @co             EM Co#
*   @mth            Batch Month
*   @batchid        Batch Id
*   @dateposted     Posting date
*
* OUTPUT PARAMETERS
*   @errmsg         error message if something went wrong
*
* RETURN VALUE:
*   0               success
*   1               fail
*****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(255) output)

as

set nocount on

declare @rcode int, @opencursor tinyint, @status tinyint, @errorstart varchar(20),
@msg varchar(60), @source varchar(10), @Notes varchar(256)

declare @seq int, @batchtranstype char(1), @trans bTrans, @equip bEquip, @fromjcco bCompany,
@fromjob bJob, @tojcco bCompany, @tojob bJob, @fromloc bLoc, @toloc bLoc, @datein bDate,
@timein smalldatetime, @dateout bDate, @timeout smalldatetime,@memo bDesc, @estout datetime,
@attach_seq int, @attach_trans bTrans, @unattach bYN, @attachedtoseq int,
@guid uniqueIdentifier

select @rcode = 0, @opencursor = 0

---- check for Posting Date
if @dateposted is null
begin
	select @errmsg = 'Missing posting date!', @rcode = 1
	goto bspexit
end

---- validate HQ Batch
exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'EMXfer', 'EMLB', @errmsg output, @status output
if @rcode <> 0
begin
	goto bspexit
end

if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
begin
	select @errmsg = 'Invalid Batch status -  must be Valid - OK to post or Posting in progress!', @rcode = 1
	goto bspexit
end

---- set HQ Batch status to 4 (posting in progress)
update dbo.HQBC 
set Status = 4, DatePosted = @dateposted
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
end

/* declare cursor on EM Batch */
declare bcEMLB cursor for
select BatchSeq,Source,Equipment,BatchTransType,MeterTrans,FromJCCo,FromJob,
ToJCCo,ToJob,FromLocation,ToLocation,DateIn,TimeIn,DateOut,TimeOut,
Memo,EstOut,AttachedToSeq,UniqueAttchID
from dbo.EMLB 
where Co = @co and Mth = @mth and BatchId = @batchid
order by Co, Mth, BatchId, Equipment, DateIn, TimeIn

/* open EM Batch cursor */
open bcEMLB
select @opencursor = 1

/* loop through all rows in EM Batch cursor */
em_posting_loop:

select @attachedtoseq = null

fetch next from bcEMLB into @seq, @source,@equip, @batchtranstype, @trans, @fromjcco, @fromjob,
@tojcco, @tojob, @fromloc, @toloc, @datein, @timein, @dateout, @timeout,
@memo, @estout, @attachedtoseq, @guid

if @@fetch_status = -1 goto em_posting_end
if @@fetch_status <> 0 goto em_posting_loop

select @errorstart = 'Seq# ' + isnull(convert(varchar(6),@seq),'')

---- start a transaction, commit after all lines have been processed
begin transaction

if @batchtranstype = 'A'	    /* new EM transaction */
	begin
	---- NON-ATTACHMENT SECTION
	---- first check to see is it's an attachment or not. post non-attached equipment here
	if @attachedtoseq is null
	Begin
		---- get next available Transaction # for EMLH
		exec @trans = dbo.bspHQTCNextTrans 'bEMLH', @co, @mth, @msg output
		if @trans = 0
		begin
			select @errmsg = isnull(@errorstart,'') + ' ' + isnull(@msg,''), @rcode = 1
			goto em_posting_error
		end

		---- add EM Transaction
		insert bEMLH(EMCo,Month,BatchID, Equipment, Trans, FromJCCo, FromJob, ToJCCo, ToJob, FromLocation,
		ToLocation, DateIn, TimeIn, DateOut, TimeOut, Memo, EstOut, UniqueAttchID,
		Notes)
		select @co, @mth, @batchid, @equip, @trans, @fromjcco, @fromjob, @tojcco, @tojob,
		@fromloc, @toloc, @datein, @timein, @dateout, @timeout, @memo, @estout, @guid,
		Notes 
		from dbo.EMLB with (nolock) 
		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq

		---- Update the batch record with the trans#
		Update dbo.EMLB 
		set MeterTrans = @trans
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq

		---- call bspBatchUserMemoUpdate to update user memos in bEMLH before deleting the batch record
		if @batchtranstype in ('A','C')
		Begin
			exec @rcode = dbo.bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'EM LocXfer', @errmsg output
			if @rcode <> 0
			begin
				select @errmsg = 'Unable to update User Memo in EMLH.', @rcode = 1
				goto em_posting_error
		end
	end
	
	-- delete the batch seq of the primary piece of equipment
	delete dbo.EMLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	if @@rowcount = 0
	begin
		select @errmsg = isnull(@errorstart,'') + ' Unable to remove EM batch sequence.', @rcode = 1
		goto em_posting_error
	end
End

/* ATTACHMENT ADD SECTION */
/* add attachments, if any, right here so the AttachToTrans can be synchronized */
/* the 'spin through records technique' is only done for new transactions */
select @attach_seq = min(BatchSeq) from dbo.EMLB with(nolock)
where Co = @co and Mth = @mth and BatchId = @batchid and AttachedToSeq = @seq

while @attach_seq is not null
begin
	exec @attach_trans = dbo.bspHQTCNextTrans 'bEMLH', @co, @mth, @msg output
	if @attach_trans = 0
	begin
		select @errmsg = isnull(@errorstart,'') + ' ' + isnull(@msg,''), @rcode = 1
		goto em_posting_error
	end

	---- if the attachment is to be unattached, do it here and set the AttachedToTrans value = null for EMLH
	if @attach_seq = @seq
	begin
		select @trans = null
		---- unattach the equipment in EMEM
		update dbo.EMEM 
		set AttachToEquip = null, AttachPostRevenue = 'N'
		where EMCo = @co and Equipment = @equip
	end

	select @equip = Equipment, @fromjcco = FromJCCo, @fromjob = FromJob,
	@tojcco = ToJCCo, @tojob = ToJob, @fromloc = FromLocation, @toloc = ToLocation,
	@datein = DateIn, @timein = TimeIn, @dateout = DateOut, @timeout = TimeOut,
	@memo = Memo, @estout = EstOut
	from dbo.EMLB with(nolock)
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @attach_seq

	insert dbo.EMLH(EMCo, Month, BatchID, Equipment, Trans, FromJCCo, FromJob, ToJCCo, ToJob,
	FromLocation, ToLocation, DateIn, TimeIn, DateOut, TimeOut, Memo, EstOut, AttachedToTrans,
	UniqueAttchID, Notes)
	select @co, @mth, @batchid, @equip, @attach_trans, @fromjcco, @fromjob, @tojcco, @tojob,
	@fromloc, @toloc, @datein, @timein, @dateout, @timeout, @memo, @estout, @trans, @guid,
	Notes 
	from dbo.EMLB with (nolock) 
	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@attach_seq

	--Update the batch record with the trans# for bspBatchUserMemoUpdate joins
	Update dbo.EMLB 
	set MeterTrans = @attach_trans
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @attach_seq

	---- call bspBatchUserMemoUpdate to update user memos in bEMLH before deleting the batch record
	if @batchtranstype in ('A', 'C')
	begin
		exec @rcode = dbo.bspBatchUserMemoUpdate @co, @mth, @batchid, @attach_seq, 'EM LocXfer', @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = 'Unable to update Attachment User Memo in EMLH.', @rcode = 1
			goto em_posting_error
		end
	end

	--delete attachment record
	delete dbo.EMLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @attach_seq
	if @@rowcount = 0
	begin
		select @errmsg = isnull(@errorstart,'') + ' Unable to remove EM batch attachment sequence.', @rcode = 1
		goto em_posting_error
	end

	select @attach_seq = min(BatchSeq) 	from dbo.EMLB 
	where Co = @co and Mth = @mth and BatchId = @batchid and AttachedToSeq = @seq and BatchSeq > @attach_seq
end  --attachment section for this piece of equipment

commit transaction
goto em_posting_loop
end

---- update existing transaction
if @batchtranstype = 'C'
begin
	select @unattach = 'N'

	if @attachedtoseq is not null and @attachedtoseq = @seq
	---- if the attachment is to be unattached, do it here and set the AttachedToTrans value = null for EMLH
	begin
		select @unattach = 'Y'
		update dbo.EMEM 
		set AttachToEquip = null, AttachPostRevenue = 'N'
		where EMCo = @co and Equipment = @equip
	end

	update dbo.EMLH 
	set Equipment = @equip, FromJCCo = @fromjcco, FromJob = @fromjob,
	ToJCCo = @tojcco, ToJob = @tojob, FromLocation = @fromloc, ToLocation = @toloc, DateIn = @datein,
	TimeIn = @timein, DateOut = @dateout, TimeOut = @timeout, Memo = @memo, EstOut = @estout,
	AttachedToTrans = (select case @unattach when 'Y' then null else AttachedToTrans end),
	UniqueAttchID = @guid
	where EMCo = @co and Month = @mth and Trans = @trans
	if @@rowcount = 0
	begin
		select @errmsg = isnull(@errorstart,'') + ' Unable to update existing EM Transaction.', @rcode = 1
		goto em_posting_error
	end

	---- update notes seperately
	update d
	set Notes = b.Notes
	from dbo.EMLH d join dbo.EMLB b on d.EMCo=b.Co and d.Month=b.Mth and d.Trans=b.MeterTrans
	where b.Co=@co and b.Mth=@mth and b.MeterTrans=@trans and b.Notes is not null

	--************** BatchUserMemoUpdate Section ****************
	--call bspBatchUserMemoUpdate to update user memos in bEMLH before deleting the batch record
	if @batchtranstype in ('A', 'C')
	begin
		exec @rcode = dbo.bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'EM LocXfer', @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = 'Unable to update User Memo in EMLH.', @rcode = 1
			goto em_posting_error
		end
	end

	---- remove current Transaction from batch
	delete dbo.EMLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	if @@rowcount = 0
	begin
		select @errmsg = isnull(@errorstart,'') + ' Unable to remove EM batch sequence.', @rcode = 1
		goto em_posting_error
	end
commit transaction
goto em_posting_loop
end


---- delete existing transaction
if @batchtranstype = 'D'
begin
	---- remove EM Transaction
	delete dbo.EMLH where EMCo = @co and Month = @mth and Trans = @trans
	if @@rowcount = 0
	begin
		select @errmsg = isnull(@errorstart,'') + ' Unable to remove EM Transaction.', @rcode = 1
		goto em_posting_error
	end

	---- remove current Transaction from batch
	delete dbo.EMLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	if @@rowcount = 0
	begin
		select @errmsg = isnull(@errorstart,'') + ' Unable to remove EM batch sequence.', @rcode = 1
		goto em_posting_error
	end
commit transaction
goto em_posting_loop
end

em_posting_error:
rollback transaction
goto bspexit

em_posting_end:
if @opencursor=1
begin
close bcEMLB
deallocate bcEMLB
select @opencursor = 0
end


---- set interface levels note string
select @Notes=Notes from dbo.HQBC
where Co = @co and Mth = @mth and BatchId = @batchid
if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)

select @Notes=@Notes +
'GL Adjustments Interface Level set at: ' + isnull(convert(char(1), a.AdjstGLLvl),'') + char(13) + char(10) +
'GL Usage Interface Level set at: ' + isnull(convert(char(1), a.UseGLLvl),'') + char(13) + char(10) +
'GL Parts Interface Level set at: ' + isnull(convert(char(1), a.MatlGLLvl),'') + char(13) + char(10)
from dbo.EMCO a where EMCo=@co

---- delete HQ Close Control entries
delete dbo.HQCC where Co = @co and Mth = @mth and BatchId = @batchid
---- set HQ Batch status to 5 (posted)
update dbo.HQBC
set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
end



bspexit:
if @opencursor = 1
begin
close bcEMLB
deallocate bcEMLB
end

return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMLBPost_Xfer] TO [public]
GO
