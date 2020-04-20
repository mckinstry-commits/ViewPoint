CREATE TABLE [dbo].[bEMLB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MeterTrans] [dbo].[bTrans] NULL,
[FromJCCo] [dbo].[bCompany] NULL,
[FromJob] [dbo].[bJob] NULL,
[ToJCCo] [dbo].[bCompany] NULL,
[ToJob] [dbo].[bJob] NULL,
[FromLocation] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ToLocation] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[DateIn] [dbo].[bDate] NULL,
[TimeIn] [smalldatetime] NULL,
[DateOut] [dbo].[bDate] NULL,
[TimeOut] [smalldatetime] NULL,
[Memo] [dbo].[bDesc] NULL,
[EstOut] [datetime] NULL,
[LastBilled] [datetime] NULL,
[OldEquipment] [dbo].[bEquip] NULL,
[OldFromJCCo] [dbo].[bCompany] NULL,
[OldFromJob] [dbo].[bJob] NULL,
[OldToJCCo] [dbo].[bCompany] NULL,
[OldToJob] [dbo].[bJob] NULL,
[OldFromLocation] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldToLocation] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldDateIn] [dbo].[bDate] NULL,
[OldTimeIn] [smalldatetime] NULL,
[OldDateOut] [dbo].[bDate] NULL,
[OldTimeOut] [smalldatetime] NULL,
[OldMemo] [dbo].[bDesc] NULL,
[OldEstOut] [datetime] NULL,
[OldLastBilled] [datetime] NULL,
[AttachedToSeq] [int] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OldNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMLB] ON [dbo].[bEMLB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMLB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    trigger [dbo].[btEMLBd] on [dbo].[bEMLB] for Delete as
/*--------------------------------------------------------------
*
*  Update trigger for EMLB
*  Created By: bc 11/23/99
*  Modified: TV 03/21/02 Delete HQAT Entries....
*				 TV 02/11/04 - 23061 added isnulls
*				TV 06/22/04 24858 - Unable to remove EM Transaction-batch stuck-cause; able to add trans again
*				GP 05/26/09 133434 - Removed HQAT code, added new insert
*--------------------------------------------------------------*/
/***  basic declares for SQL Triggers ****/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int

select @numrows = @@rowcount

if @numrows = 0 return

set nocount on

--TV 06/22/04 24858 - Unable to remove EM Transaction-batch stuck-cause; able to add trans again
update bEMLH
set InUseBatchID = null
from Deleted d
where EMCo = d.Co and Month = d.Mth and Trans = d.MeterTrans

-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
select AttachmentID, suser_name(), 'Y' 
from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
where h.UniqueAttchID not in(select t.UniqueAttchID from bEMLH t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
and d.UniqueAttchID is not null   

return

error:

select @errmsg = isnull(@errmsg,'') + ' - cannot delete Location Transfer Batch'

RAISERROR(@errmsg, 11, -1);
rollback transaction









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

  
 CREATE   trigger [dbo].[btEMLBi] on [dbo].[bEMLB] for INSERT as
 /*--------------------------------------------------------------
*  Update trigger for EMLB
*  Created By: bc 11/23/99
*  Modified:   bc 01/13/00  does not process attachments for transactions added to the batch.
*				   bspEMLB_Xfer_InsExistingTrans will take care of attachments for existing transactions in EMLH
*				  TV 02/11/04 - 23061 added isnulls
*--------------------------------------------------------------*/

/***  basic declares for SQL Triggers ****/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @rcode int
declare @emco bCompany, @mth bMonth, @batchid bBatchID, @key_seq int, @equip bEquip
/*EMLB declares*/
declare @batchtranstype char(1), @fromjcco bCompany,
@fromjob bJob, @tojcco bCompany, @tojob bJob, @fromloc bLoc, @toloc bLoc,
@datein bDate, @timein smalldatetime, @dateout bDate, @timeout smalldatetime, @memo bDesc,
@estout bDate, @iseq int, @bseq int, @seq int

declare @cnt int, @attachment bEquip, @opencursorEMLB tinyint
   
select @rcode = 0, @cnt = 0
   
select @numrows = @@rowcount

if @numrows = 0 return

set nocount on
   
/* validate batch */
select @validcnt = count(*)  from bHQBC r
JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId
if @validcnt<>@numrows
begin
	select @errmsg = 'Invalid Batch ID#'
	goto error
end

select @validcnt = count(*) from bHQBC r
JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId and not r.BatchId is null
   
if @validcnt<>@numrows
begin
	select @errmsg = 'Batch (In Use) name must first be updated.'
	goto error
end

select @validcnt = count(*) from bHQBC r
JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId and r.Status=0
if @validcnt<>@numrows
begin
	select @errmsg = 'Must be an open batch.'
	goto error
end

/* initialize variable */
select @opencursorEMLB = 0
   
/* use a cursor to process each inserted row */
/* only bring in attachments on transactions that do not yet have a transaction number,
the InsertExistingTrans bsp takes care of bringing in attachments for existing transactions */
declare bcEMLB_insert cursor for
select Co, Mth, BatchId, BatchSeq, Equipment, BatchTransType,
FromJCCo, FromJob, FromLocation, ToJCCo, ToJob, ToLocation,
DateIn, TimeIn, DateOut, TimeOut, Memo, EstOut
from inserted
where MeterTrans is null

open bcEMLB_insert
/* set open cursor flag to true */
select @opencursorEMLB = 1
   
cursor_loop:
	fetch next
	from bcEMLB_insert
	into @emco, @mth, @batchid, @key_seq, @equip, @batchtranstype,
		   @fromjcco, @fromjob, @fromloc, @tojcco, @tojob, @toloc,
		   @datein, @timein, @dateout, @timeout, @memo, @estout
   
	while (@@fetch_status = 0)
     begin
   		/* get the latest sequence number incase the first sequence has the equipment code changed and there are other sequences
		   following it that are not being updated.  we do not want duplicate sequence numbers */
		select @iseq = isnull(max(BatchSeq),0) from inserted
		where Co = @emco and Mth = @mth and BatchId = @batchid
   
		select @bseq = isnull(max(BatchSeq),0)  from EMLB
		where Co = @emco and Mth = @mth and BatchId = @batchid
   
	     select @seq = case when @iseq > @bseq then @iseq else @bseq end
   
		/* insert any attachments for new equipment */
		/* attachments in EMEM are required to share the same JCCo, Job and Location with the equipment they are assigned to */
		select @attachment = min(Equipment) from EMEM
		where EMCo = @emco and AttachToEquip = @equip
	     while @attachment is not null
		begin
			select @seq = @seq + 1
	
			insert into bEMLB (Co, Mth, BatchId, BatchSeq, Source, Equipment, BatchTransType, FromJCCo,
   			FromJob, ToJCCo, ToJob, FromLocation, ToLocation, DateIn, TimeIn, DateOut, TimeOut,
   			Memo, EstOut, AttachedToSeq)
			values(@emco, @mth, @batchid, @seq, 'EMXfer', @attachment, @batchtranstype, @fromjcco,
   	   		@fromjob, @tojcco, @tojob, @fromloc, @toloc, @datein, @timein, @dateout, @timeout,
   	   		@memo, @estout, @key_seq)
	   
			select @attachment = min(Equipment)  from bEMEM 
			where EMCo = @emco and AttachToEquip = @equip and Equipment > @attachment
		end 
	
		nextseq:
		goto cursor_loop
    end
   
select @opencursorEMLB = 0
close bcEMLB_insert
deallocate bcEMLB_insert
   
return
   
error:
   
if @opencursorEMLB = 1
begin
	close bcEMLB_insert
	deallocate bcEMLB_insert
end

select @errmsg = isnull(@errmsg,'') + ' - cannot insert Location Transfer Batch'

RAISERROR(@errmsg, 11, -1);
rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 CREATE   trigger [dbo].[btEMLBu] on [dbo].[bEMLB] for update as
 /*--------------------------------------------------------------
*
*  Update trigger for EMLB
*  Created By: bc 11/23/99
*  Modified: TV 02/11/04 - 23061 added isnulls
*
*--------------------------------------------------------------*/
/***  basic declares for SQL Triggers ****/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @rcode int
declare @emco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @equip bEquip
/*EMLB declares*/
declare @cnt int, @attachment bEquip, @fromjcco bCompany, @fromjob bJob, @fromloc bLoc, @datein bDate, @timein smalldatetime,
 @tojcco bCompany, @tojob bJob, @toloc bLoc, @dateout bDate, @timeout smalldatetime,
 @key_seq int, @key_tojcco bCompany, @key_tojob bJob, @key_toloc bLoc, @oldequip bEquip,
 @batchtranstype char(1), @trans bTrans, @iseq int, @bseq int, @new_seq int, @estout bDate, @memo bDesc,
 @attachedtoseq int

declare @opencursorEMLB tinyint

select @rcode = 0, @cnt = 0

select @numrows = @@rowcount

if @numrows = 0 return

set nocount on

/* initialize variable */
select @opencursorEMLB = 0
   
/* use a cursor to process each inserted row */
declare bcEMLB_update cursor for
select Co, Mth, BatchId, BatchSeq, Equipment, BatchTransType, MeterTrans, FromJCCo, FromJob, FromLocation, DateIn, TimeIn,
ToJCCo, ToJob, ToLocation, DateOut, TimeOut, EstOut, Memo, AttachedToSeq
from inserted

open bcEMLB_update
/* set open cursor flag to true */
select @opencursorEMLB = 1
   
cursor_loop:
   fetch next
   from bcEMLB_update
   into @emco, @mth, @batchid, @seq, @equip, @batchtranstype, @trans, @fromjcco, @fromjob, @fromloc, @datein, @timein,
        @tojcco, @tojob, @toloc, @dateout, @timeout, @estout, @memo, @attachedtoseq
   
	while (@@fetch_status = 0)
	begin
		/* if the primary equipment is changed to another value, delete any existing attachments it may have & insert new equip's attachments */
		select @oldequip = Equipment  from deleted
		where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
		if @oldequip <> @equip
		begin
			delete EMLB where Co = @emco and Mth = @mth and BatchId = @batchid and AttachedToSeq = @seq
			/* get the latest sequence number incase the first sequence has the equipment code changed and there are other sequences
			following it that are not being updated.  we do not want duplicate sequence numbers */
			select @iseq = isnull(max(BatchSeq),0) from inserted
			where Co = @emco and Mth = @mth and BatchId = @batchid
   
			 select @bseq = isnull(max(BatchSeq),0)  from EMLB
			 where Co = @emco and Mth = @mth and BatchId = @batchid
   
			select @new_seq = case when @iseq > @bseq then @iseq else @bseq end
   
			 /* insert any attachments for new equipment */
			 /* attachments in EMEM are required to share the same JCCo, Job and Location with the equipment they are assigned to */
			 select @attachment = min(Equipment) from EMEM
			 where EMCo = @emco and AttachToEquip = @equip
   
			while @attachment is not null
			begin
				select @new_seq = @new_seq + 1
        
				 insert into EMLB (Co, Mth, BatchId, BatchSeq, Source, Equipment, BatchTransType, MeterTrans, FromJCCo,
   				 FromJob, ToJCCo, ToJob, FromLocation, ToLocation, DateIn, TimeIn, DateOut, TimeOut,
   		           Memo, EstOut, AttachedToSeq)
				 values(@emco, @mth, @batchid, @new_seq, 'EMXfer', @attachment, @batchtranstype, @trans, @fromjcco,
   	   			@fromjob, @tojcco, @tojob, @fromloc, @toloc, @datein, @timein, @dateout, @timeout,
   	   			@memo, @estout, @key_seq)
   
				select @attachment = min(Equipment)  from EMEM
				where EMCo = @emco and AttachToEquip = @equip and Equipment > @attachment
			end
			goto cursor_loop
		end
		/* make sure that the equipment that was changed was a primary piece of equipment
		by checking for null in AttachedToSeq in the above select statement */
		if @attachedtoseq is null
		begin	
			/* datein and timein changes should cascade to the attachments with the same 'from' info before other processing occurs */
			update EMLB
			set DateIn = @datein, TimeIn = @timein
			where Co = @emco and Mth = @mth and BatchId = @batchid and AttachedToSeq = @seq and
			((FromJCCo = @fromjcco) or (FromJCCo is null and @fromjcco is null)) and
			((FromJob = @fromjob) or (FromJob is null and @fromjob is null)) and
			((FromLocation = @fromloc) or (FromLocation is null and @fromloc is null)) and
			(isnull(DateIn,'') <> isnull(@datein,'') or isnull(TimeIn,'') <> isnull(@timein,''))

			/* update all existing attachemnts in EMLB for this piece of equipment that have the same 'from' information */
			select @attachment = min(Equipment) from EMLB
			where Co = @emco and Mth = @mth and BatchId = @batchid and AttachedToSeq = @seq and
			((FromJCCo = @fromjcco) or (FromJCCo is null and @fromjcco is null)) and
			((FromJob = @fromjob) or (FromJob is null and @fromjob is null)) and
			((FromLocation = @fromloc) or (FromLocation is null and @fromloc is null)) and
			((DateIn = @datein) or (DateIn is null and @datein is null)) and
			((TimeIn = @timein) or (TimeIn is null or @timein is null))

			while @attachment is not null
			begin
				/* update the attachment information to match that of the primary equipment */
				update EMLB
				set ToJCCo = @tojcco, ToJob = @tojob, ToLocation = @toloc, DateOut = @dateout, TimeOut = @timeout
				where Co = @emco and Mth = @mth and BatchId = @batchid and Equipment = @attachment and AttachedToSeq = @seq

				select @attachment = min(Equipment) from EMLB
				where Co = @emco and Mth = @mth and BatchId = @batchid and AttachedToSeq = @seq and Equipment > @attachment and
				((FromJCCo = @fromjcco) or (FromJCCo is null and @fromjcco is null)) and
				((FromJob = @fromjob) or (FromJob is null and @fromjob is null)) and
				((FromLocation = @fromloc) or (FromLocation is null and @fromloc is null)) and
				((DateIn = @datein) or (DateIn is null and @datein is null)) and
				((TimeIn = @timein) or (TimeIn is null or @timein is null))
			end
		end
		/* now check to see if the updated equipment is an attachment that should be unlinked and, ultimately, unattached.
		attachments that are to be unlinked are represented programmatically as AttachedToSeq = BatchSeq (attached to itself) */
		select @tojcco = null, @tojob = null, @toloc = null, @key_tojcco = null, @key_tojob = null, @key_toloc = null

		select @key_seq = AttachedToSeq, @tojcco = ToJCCo, @tojob = ToJob, @toloc = ToLocation from EMLB
		where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and (AttachedToSeq is not null and AttachedToSeq <> @seq)
		if @@rowcount <> 0
		begin
			select @key_tojcco = ToJCCo, @key_tojob = ToJob, @key_toloc = ToLocation from EMLB
			where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq = @key_seq
			if isnull(@tojcco,0) <> isnull(@key_tojcco,0) or isnull(@tojob,'') <> isnull(@key_tojob,'') or isnull(@toloc,'') <> isnull(@key_toloc,'')
			begin
				update EMLB
				set AttachedToSeq = @seq
				where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
			end
		end
		nextseq:
		goto cursor_loop
   end
   
select @opencursorEMLB = 0
close bcEMLB_update
deallocate bcEMLB_update

return
   
error:
   
if @opencursorEMLB = 1
begin
	close bcEMLB_update
	deallocate bcEMLB_update
end

select @errmsg = isnull(@errmsg,'') + ' - cannot update Location Transfer Batch'

RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
  
 



GO
