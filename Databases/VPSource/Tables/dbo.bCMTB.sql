CREATE TABLE [dbo].[bCMTB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMTransferTrans] [dbo].[bTrans] NULL,
[FromCMCo] [dbo].[bCompany] NOT NULL,
[FromCMAcct] [dbo].[bCMAcct] NOT NULL,
[FromCMTrans] [dbo].[bTrans] NULL,
[ToCMCo] [dbo].[bCompany] NOT NULL,
[ToCMAcct] [dbo].[bCMAcct] NOT NULL,
[ToCMTrans] [dbo].[bTrans] NULL,
[CMRef] [dbo].[bCMRef] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[OldFromCMAcct] [dbo].[bCMAcct] NULL,
[OldToCMAcct] [dbo].[bCMAcct] NULL,
[OldActDate] [dbo].[bDate] NULL,
[OldAmount] [dbo].[bDollar] NULL,
[OldCMRef] [dbo].[bCMRef] NULL,
[OldDesc] [dbo].[bDesc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bCMTB] ADD
CONSTRAINT [CK_bCMTB_FromCMAcct] CHECK (([FromCMAcct]>(0) AND [FromCMAcct]<(10000)))
ALTER TABLE [dbo].[bCMTB] ADD
CONSTRAINT [CK_bCMTB_OldFromCMAcct] CHECK (([OldFromCMAcct]>(0) AND [OldFromCMAcct]<(10000) OR [OldFromCMAcct] IS NULL))
ALTER TABLE [dbo].[bCMTB] ADD
CONSTRAINT [CK_bCMTB_OldToCMAcct] CHECK (([OldToCMAcct]>(0) AND [OldToCMAcct]<(10000) OR [OldToCMAcct] IS NULL))
ALTER TABLE [dbo].[bCMTB] ADD
CONSTRAINT [CK_bCMTB_ToCMAcct] CHECK (([ToCMAcct]>(0) AND [ToCMAcct]<(10000)))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   CREATE        trigger [dbo].[btCMTBd] on [dbo].[bCMTB] for DELETE as
   

	
/*-----------------------------------------------------------------
    *	Modified: RM 06/01/04 - Fixed HQAT Delete statement
	*			  mh 05/19/09 - Issue 133433/127603
	*			  JonathanP 06/17/09 - 133433 rejection fix. Added a check to for CMTT as well. 
    *
    *
    *	This trigger updates bCMTT (Transfer Trans) to remove InUseBatchId 
    *	when deletion(s) are made from bCMTB (Detail Batch).
    *
    *	Rejects deletion if the following
    *	error condition exists:
    *
    *		Missing CM Transfer Transaction #
    *
    */----------------------------------------------------------------
   
	declare @errmsg varchar(255), @numrows int, @nullcnt int

	select @numrows = @@rowcount
	set nocount on

	if @numrows = 0 return 

	/* count rows with null CM transfer transaction */
	select @nullcnt = count(*) from deleted d, bCMTT c
	where c.CMCo = d.Co and c.Mth = d.Mth and c.CMTransferTrans = d.CMTransferTrans

	/* remove InUseBatchId from bCMTT rows pointed to by deleted batch entries */
	update bCMTT
	set InUseBatchId = null
	from bCMTT c, deleted d
	where c.CMCo = d.Co and c.Mth = d.Mth and c.CMTransferTrans = d.CMTransferTrans
   	  
	/* sum of null CM trans and updated bCMTT rows should match number of rows deleted */
	if @nullcnt <> @@rowcount
	begin
	select @errmsg = 'Unable to properly update CM Transfer Transactions'
	goto error
	end

--	--delete HQAT record if not exists CMTT
--	delete bHQAT 
--	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
--	where not exists(select top 1 1 from bCMTT t where t.UniqueAttchID=d.UniqueAttchID)
   
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
	select AttachmentID, suser_name(), 'Y' 
	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
	where h.UniqueAttchID not in(select t.UniqueAttchID from bCMDT t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID) and
		  h.UniqueAttchID not in(select t.UniqueAttchID from bCMTT t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
	and d.UniqueAttchID is not null       
   	
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete CM Transfer Batch entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btCMTBi    Script Date: 8/28/99 9:37:07 AM ******/
   CREATE   trigger [dbo].[btCMTBi] on [dbo].[bCMTB] for INSERT as
   

/*-----------------------------------------------------------------
    * Created: ??
    * Modified: GG 06/12/01 - Added BatchTransType validation, allow CMTransferTrans
    *                          update to 'A' entries (updated during batch posting #12769)
    * 		 	  DANF 03/15/05 - #27294 - Remove scrollable cursor.
    *
    *	This trigger rejects insertion in bCMTB (Transaction Batch) if
    *	any of the following error conditions exist:
    *
    * 		Invalid Batch ID#
    *		Batch associated with another source or table
    *		Batch in use by someone else
    *		Batch status not 'open'
    *
    *		Reference to a CM transfer trans that doesn't exist
    *		CM transfer trans already in use by a batch
    *		CM transfer trans created from a source other than CM
    *
    *	use bspCMTBVal to fully validate all entries in a CMTB batch
    *	prior to posting.
    *
    *	Updates InUseBatchId in bCMTT for existing transactions.
    *
    * 	Adds entry to HQ Close Control as needed.
    *
    *----------------------------------------------------------------*/
   declare @batchid bBatchID, @errmsg varchar(255), @co bCompany,
   	@inuseby bVPUserName, @mth bMonth, @numrows int, @seq int,
   	@source bSource, @status tinyint, @tablename char(20),
   	@cmtransfertrans bTrans, @inusebatchid bBatchID, @fromglco bCompany,
       @toglco bCompany, @fromcmco bCompany, @tocmco bCompany, @batchtranstype char(1),
       @errtext varchar(255), @rcode int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   if @numrows = 1
   	select @co = Co, @mth = Mth, @batchid = BatchId, @seq = BatchSeq, @batchtranstype = BatchTransType,
           @cmtransfertrans = CMTransferTrans, @fromcmco = FromCMCo, @tocmco = ToCMCo
       from inserted
   else
   	begin
   	/* use a cursor to process each inserted row */
   	declare bCMTB_insert cursor local fast_forward for select Co, Mth, BatchId, BatchSeq, BatchTransType,
   		CMTransferTrans, FromCMCo, ToCMCo
       from inserted
   
   	open bCMTB_insert
   	fetch next from bCMTB_insert into @co, @mth, @batchid, @seq, @batchtranstype, @cmtransfertrans,
           @fromcmco, @tocmco
   
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   insert_check:
       exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'CM Trnsfr', 'CMTB', @errtext output, @status output
       if @rcode <> 0
   	   begin
          select @errmsg = @errtext
          goto error
      	   end
       if @status <> 0
   	   begin
   	   select @errmsg = 'Must be an open batch'
   	   goto error
   	   end
   
        -- validate Batch Transaction Type
       if @batchtranstype not in ('A','C','D')
           begin
           select @errmsg = 'Invalid Batch transaction type, must be (A, C, or D).'
           goto error
           end
       if @batchtranstype = 'A' and @cmtransfertrans is not null -- CM Transfer Trans must be null when inserted, can be updated later.
           begin
           select @errmsg = 'CM Transfer Transaction # must be null with all (A) entries.'
           goto error
           end
       if @batchtranstype in ('C','D') and @cmtransfertrans is null
           begin
           select @errmsg = 'CM Transfer Transaction # is required for all (C and D) entries.'
           goto error
           end
   
   	/* validate existing CM trans - if one is referenced */
   	if @cmtransfertrans is not null
   		begin
   		select @inusebatchid = InUseBatchId
   		from bCMTT where CMCo = @co and Mth = @mth and CMTransferTrans = @cmtransfertrans
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'CM transaction not found'
   			goto error
   			end
   		if @inusebatchid is not null
   			begin
   			select @errmsg = 'CM transaction in use by another Batch'
   			goto error
   			end
   
   		-- update CM transaction as 'in use'  - update trigger on bCMTT will lock 'from' and 'to' trans in bCMDT
   		update bCMTT
   		set InUseBatchId = @batchid
   		where CMCo = @co and Mth = @mth and CMTransferTrans = @cmtransfertrans
   		if @@rowcount <> 1
   			begin
   			select @errmsg = 'Unable to update CM Transfer Detail as (In Use)'
   			goto error
   			end
   		end
   
       -- add entries to HQ Close Control as needed
   	select @fromglco = GLCo from bCMCO where CMCo = @fromcmco
       if not exists(select * from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @fromglco)
           begin
   		insert bHQCC (Co, Mth, BatchId, GLCo)
   		values (@co, @mth, @batchid, @fromglco)
   		end
   
   	select @toglco=GLCo from bCMCO where CMCo = @tocmco
     	if not exists(select * from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @toglco)
   		begin
   		insert bHQCC (Co, Mth, BatchId, GLCo)
   		values (@co, @mth, @batchid, @toglco)
   		end
   
   	if @numrows > 1
   		begin
   		fetch next from bCMTB_insert into @co, @mth, @batchid, @seq, @batchtranstype, @cmtransfertrans,
               @fromcmco, @tocmco
   		if @@fetch_status = 0
   			goto insert_check
   		else
   			begin
   			close bCMTB_insert
   			deallocate bCMTB_insert
   			end
   		end
   
   return
   
   
   error:
   	if @numrows > 1
   		begin
   		close bCMTB_insert
   		deallocate bCMTB_insert
   		end
   
       select @errmsg = @errmsg + ' - cannot insert CM Detail Batch entry!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btCMTBu    Script Date: 8/28/99 9:37:07 AM ******/
   CREATE  trigger [dbo].[btCMTBu] on [dbo].[bCMTB] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created: ??
    * Modified: GG 06/12/01 - Added BatchTransType validation, allow CMTransferTrans
    *                          update to 'A' entries (updated during batch posting #12769)
    *
    *	This trigger rejects update in bCMTB (Transfer Batch) if any
    *	of the following error conditions exist:
    *
    *	Cannot change Company, Mth, BatchId, or Seq
    *	If CM trans has changed - set InUseBatchId to null on old trans
    *	and update with current batch on new.
    *
    *	Check that a new CM trans is eligible to be added to this batch.
    *
    *	Add HQCC (Close Control) if needed.
    *
    *----------------------------------------------------------------*/
   declare @batchid bBatchID, @errmsg varchar(255), @co bCompany, @mth bMonth,
   	@newcmtransfertrans bTrans, @numrows int, @oldcmtransfertrans bTrans, @validcount int,
   	@seq int, @inusebatchid bBatchID, @opencursor tinyint, @newbatchtranstype char(1),
       @oldbatchtranstype char(1), @newfromcmco bCompany, @oldfromcmco bCompany,
       @newtocmco bCompany, @oldtocmco bCompany
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   select @opencursor = 0	/* initialize open cursor flag */
   
   /* check for key changes */
   select @validcount = count(*)  from deleted d, inserted i
   	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Batch Sequence #'
   	goto error
   	end
   
   if @numrows = 1
   	select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @seq = i.BatchSeq,
           @newbatchtranstype = i.BatchTransType, @oldbatchtranstype = d.BatchTransType,
   		@newcmtransfertrans = i.CMTransferTrans, @oldcmtransfertrans = d.CMTransferTrans,
           @newfromcmco = i.FromCMCo, @oldfromcmco = d.FromCMCo, @newtocmco = i.ToCMCo,
           @oldtocmco = d.ToCMCo
   	from deleted d, inserted i
   	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   else
   	begin
   	/* use a cursor to process each updated row */
   	declare bCMTB_update cursor for select d.Co, d.Mth, d.BatchId, d.BatchSeq,
           NewBatchTransType = i.BatchTransType, OldBatchTransType = d.BatchTransType,
   		NewCMTransferTrans = i.CMTransferTrans, OldCMTransferTrans = d.CMTransferTrans,
           NewFromCMCo = i.FromCMCo, OldFromCMCo = d.FromCMCo, NewToCMCo = i.ToCMCo,
           OldToCMCo = d.ToCMCo
   	from deleted d, inserted i
   	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   
       open bCMTB_update
   	select @opencursor = 1	/* set open cursor flag */
   
   	fetch next from CMDB_update into @co, @mth, @batchid, @seq, @newbatchtranstype, @oldbatchtranstype,
           @newcmtransfertrans, @oldcmtransfertrans, @newfromcmco, @oldfromcmco, @newtocmco, @oldtocmco
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   update_check:
       if @newbatchtranstype not in ('A','C','D')
           begin
           select @errmsg = 'Batch transaction type must be (A, C, or D).'
           goto error
           end
       if @newbatchtranstype <> @oldbatchtranstype
           begin
           if @newbatchtranstype = 'A' or @oldbatchtranstype = 'A'
               begin
               select @errmsg = 'Cannot change Batch transaction type to or from (A).'
               goto error
               end
           end
       if @newbatchtranstype in ('C','D')
           begin
   	    if isnull(@newcmtransfertrans,0) <> @oldcmtransfertrans    -- allow CM Transfer Trans to be updated on 'A' entries
      	        begin
   		    select @errmsg = 'Cannot change CM Transfer Transaction Number. You must delete the record and re-add it.'
   		    goto error
   	        end
           -- check for From or To CM Company change
           if @oldfromcmco <> @newfromcmco
               begin
               select @errmsg = 'Cannot change (from) company on existing Transfers.'
               goto error
               end
           if @oldtocmco <> @newtocmco
               begin
               select @errmsg = 'Cannot change (to) company on existing Transfers.'
               goto error
               end
           end
   
      if @numrows > 1
   		begin
   		fetch next from bCMTB_update into @co, @mth, @batchid, @seq, @newbatchtranstype, @oldbatchtranstype,
               @newcmtransfertrans, @oldcmtransfertrans, @newfromcmco, @oldfromcmco, @newtocmco, @oldtocmco
   		if @@fetch_status = 0
   			goto update_check
   		else
   			begin
   			close bCMTB_update
   			deallocate bCMTB_update
   			end
   		end
   
   return
   
   error:
   	if @opencursor = 1
   		begin
   		close bCMTB_update
   		deallocate bCMTB_update
   		end
   
   	select @errmsg = @errmsg + ' - cannot update CM Transfer Batch Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bCMTB] ADD CONSTRAINT [PK_bCMTB_KeyID] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biCMTB] ON [dbo].[bCMTB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bCMTB].[FromCMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bCMTB].[ToCMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bCMTB].[OldFromCMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bCMTB].[OldToCMAcct]'
GO
