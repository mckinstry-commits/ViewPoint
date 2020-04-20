SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE         procedure [dbo].[bspEMLB_Xfer_InsExistingTrans]
/***********************************************************
* CREATED BY: 	bc 04/02/99
* MODIFIED By:	bc 11/11/99  wrote the attachment section
*				danf 08/07/00 removed @inuseby as it was not being used and had a dropped data type of bUserName.
*				MV 7/3/01   Issue 12769 BatchUserMemoInsertExisting
*				JM 01/15/02 - Added code to update new Notes column in EMLB from EMLH
*				TV 05/29/02 - insert UniqueAttchID into Batch Table
*				TV 02/11/04 - 23061 added isnulls
*				TV 06/22/04 - 24858 - Unable to remove EM Transaction-batch stuck-cause; able to add trans again
*				CHS 03/04/08 - #125370 Prompt before adding attachments
*				GF 01/04/2013 TK-20579 update EMLH.InUseBatchID for attachments to keep from being pulled into batch more than once
*
*
* Xfer:
* This procedure is used by the EM Posting program to pull existing
* transactions from bEMRD into bEMLB for editing.
*
* Checks batch info in bHQBC
* Adds entry to next available Seq# in bEMLB
*
* bEMLB insert trigger will update InUseBatchId in bEMRD
*
* INPUT PARAMETERS
*   Co         EM Co to pull from
*   Mth        Month of batch
*   BatchId    Batch ID to insert transaction into
*   EMTrans    EM Transaction to pull
*	Source
*	
*
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @emtrans bTrans, 
@source bSource,	@addattachments bYN, @errmsg varchar(200) output

as

set nocount on

declare @rcode int, @status tinyint,
@dtsource bSource, @inusebatchid bBatchID, @seq int, @errtext varchar(60), @source_desc bSource,
@equip bEquip, @transdate bDate, @transtime smalldatetime, @jcco bCompany, @job bJob, @loc bLoc,
@attachment bEquip, @key_seq int

select @rcode = 0
/* validate HQ Batch */
exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'EMXfer', 'EMLB', @errtext output, @status output
if @rcode <> 0
begin
	select @errmsg = @errtext, @rcode = 1
	goto bspexit
end

if @status <> 0
begin
	select @errmsg = 'Invalid Batch status -  must be Open!', @rcode = 1
	goto bspexit
end

/* all Invoices's can be pulled into a batch as long as it's InUseFlag is set to null */
select @inusebatchid = InUseBatchID from bEMLH where EMCo=@co and Month=@mth and Trans=@emtrans
if @@rowcount = 0
begin
	select @errmsg = 'The EM Tranasction :' + isnull(convert(varchar(6),@emtrans),'') + ' cannot be found.' , @rcode = 1
	goto bspexit
end
if @inusebatchid is not null
begin
	select @source_desc=Source from bHQBC
	where Co=@co and BatchId=@inusebatchid  and Mth=@mth
	if @@rowcount<>0
		begin
			select @errmsg = 'Transaction already in use by ' +
			 isnull(convert(varchar(2),DATEPART(month, @mth)),'') + '/' +
			 isnull(substring(convert(varchar(4),DATEPART(year, @mth)),3,4),'') +
			' batch # ' + isnull(convert(varchar(6),@inusebatchid),'') + ' - ' + 'Batch Source: ' + isnull(@source_desc,''), @rcode = 1
			goto bspexit
		end
	else
		begin
			select @errmsg='Transaction already in use by another batch!', @rcode=1
			goto bspexit
		end
end

/* get next available sequence # for this batch */
select @seq = isnull(max(BatchSeq),0)+1 from bEMLB where Co = @co and Mth = @mth and BatchId = @batchid

/* add Transaction to batch */
insert into bEMLB (Co,Mth,BatchId,BatchSeq, Source,Equipment,BatchTransType,MeterTrans,FromJCCo,FromJob,ToJCCo,ToJob,
FromLocation,ToLocation,DateIn,TimeIn,DateOut,TimeOut,Memo,EstOut,
OldEquipment,OldFromJCCo,OldFromJob,OldToJCCo,OldToJob,
OldFromLocation,OldToLocation,OldDateIn,OldTimeIn,OldDateOut,OldTimeOut,OldMemo,OldEstOut,UniqueAttchID)
Select 	EMCo,@mth,@batchid,@seq,'EMXfer',Equipment,'C',Trans,FromJCCo,FromJob,ToJCCo,ToJob,
FromLocation,ToLocation,DateIn,TimeIn,DateOut,TimeOut,Memo,EstOut,
Equipment,FromJCCo,FromJob,ToJCCo,ToJob,
FromLocation,ToLocation,DateIn,TimeIn,DateOut,TimeOut,Memo,EstOut,UniqueAttchID
from bEMLH
where EMCo=@co and Month=@mth and Trans=@emtrans
if @@rowcount <> 1
begin
	select @errmsg = 'Unable to add entry to EM Transfer Batch!', @rcode = 1
	goto bspexit
end

--update notes seperately
update bEMLB
set Notes = d.Notes 
from bEMLB b
join bEMLH d on d.EMCo=b.Co and d.Month=b.Mth and d.Trans=b.MeterTrans
where d.EMCo=@co and d.Month=@mth and d.Trans=@emtrans

--TV 06/22/04 24858 - Unable to remove EM Transaction-batch stuck-cause; able to add trans again
--update inuse batchID
update bEMLH 
set InUseBatchID = @batchid
from bEMLB b
join bEMLH d on d.EMCo=b.Co and d.Month=b.Mth and d.Trans=b.MeterTrans
where d.EMCo=@co and d.Month=@mth and d.Trans=@emtrans


/* BatchUserMemoInsertExisting - update the user memo in the batch record */
exec @rcode =  dbo.bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'EM LocXfer', 0,
@errmsg output
if @rcode <> 0
begin
	select @errmsg = 'Unable to update User Memo attachments in EMLB', @rcode = 1
	goto bspexit
end

---- CHS 03/04/08 #125370
if @addattachments = 'Y'
begin
	---Addition of associated Attachments removed per Issue 16022 (Rejection Seciton)
	----add any attachments of this equipment into the batch that share the most recent history in bEMLH 
	select @key_seq = @seq
	select @equip = Equipment, @transdate = DateIn, @transtime = TimeIn, @jcco = ToJCCo, @job = ToJob, @loc = ToLocation from bEMLH
	where EMCo = @co and Month = @mth and Trans = @emtrans and AttachedToTrans is null
	if @@rowcount <> 0
		begin
		select @attachment = min(Equipment)
		from dbo.bEMLH
		where EMCo = @co and Month = @mth and AttachedToTrans = @emtrans and
			 ((DateIn is null and @transdate is null) or (DateIn = @transdate)) and
			 ((TimeIn is null and @transtime is null) or (TimeIn = @transtime)) and
			 ((ToJCCo is null and @jcco is null) or (ToJCCo = @jcco)) and
			 ((ToJob is null and @job is null) or (ToJob = @job)) and
			 ((ToLocation is null and @loc is null) or (ToLocation = @loc))

		while @attachment is not null
		begin
			select @seq = @seq + 1

			insert into bEMLB (Co,Mth,BatchId,BatchSeq,Source,Equipment,BatchTransType,MeterTrans,FromJCCo,FromJob,ToJCCo,ToJob,
				FromLocation,ToLocation,DateIn,TimeIn,DateOut,TimeOut,Memo,EstOut,AttachedToSeq,
				OldEquipment,OldFromJCCo,OldFromJob,OldToJCCo,OldToJob,
				OldFromLocation,OldToLocation,OldDateIn,OldTimeIn,OldDateOut,OldTimeOut,OldMemo,OldEstOut)

			select  EMCo,@mth,@batchid,@seq,'EMXfer',Equipment,'C',Trans,FromJCCo,FromJob,ToJCCo,ToJob,
				 FromLocation,ToLocation,DateIn,TimeIn,DateOut,TimeOut,Memo,EstOut,@key_seq,
				 Equipment,FromJCCo,FromJob,ToJCCo,ToJob,
				 FromLocation,ToLocation,DateIn,TimeIn,DateOut,TimeOut,Memo,EstOut
			from bEMLH
			where EMCo = @co and Month = @mth and Equipment = @attachment and AttachedToTrans = @emtrans

			----BatchUserMemoInsertExisting - update the user memo in the batch record 
			exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'EM LocXfer', 0,@errmsg output
			if @rcode <> 0
			begin
				select @errmsg = 'Unable to update User Memo attachments in EMLB', @rcode = 1
				goto bspexit
			end

			----TK-20579 update InUseBatchID in EMLH for attachment
			UPDATE dbo.bEMLH SET InUseBatchID = @batchid
			from dbo.bEMLH
			where EMCo = @co 
				AND [Month] = @mth 
				AND Equipment = @attachment 
				AND AttachedToTrans = @emtrans

			---- next attachment
			select @attachment = min(Equipment) from bEMLH
			where EMCo = @co and Month = @mth and AttachedToTrans = @emtrans and Equipment > @attachment and
				((DateIn is null and @transdate is null) or (DateIn = @transdate)) and
				((TimeIn is null and @transtime is null) or (TimeIn = @transtime)) and
				((ToJCCo is null and @jcco is null) or (ToJCCo = @jcco)) and
				((ToJob is null and @job is null) or (ToJob = @job)) and
				((ToLocation is null and @loc is null) or (ToLocation = @loc))
		end
	end
end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMLB_Xfer_InsExistingTrans] TO [public]
GO
