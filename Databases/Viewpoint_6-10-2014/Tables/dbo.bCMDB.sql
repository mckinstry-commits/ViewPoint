CREATE TABLE [dbo].[bCMDB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMTrans] [dbo].[bTrans] NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[CMTransType] [dbo].[bCMTransType] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[CMRef] [dbo].[bCMRef] NOT NULL,
[CMRefSeq] [tinyint] NOT NULL,
[Payee] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[CMGLAcct] [dbo].[bGLAcct] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[Void] [dbo].[bYN] NOT NULL,
[OldCMAcct] [dbo].[bCMAcct] NULL,
[OldActDate] [dbo].[bDate] NULL,
[OldDesc] [dbo].[bDesc] NULL,
[OldAmount] [dbo].[bDollar] NULL,
[OldCMRef] [dbo].[bCMRef] NULL,
[OldCMRefSeq] [tinyint] NULL,
[OldPayee] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OldGLCo] [dbo].[bCompany] NULL,
[OldCMGLAcct] [dbo].[bGLAcct] NULL,
[OldGLAcct] [dbo].[bGLAcct] NULL,
[OldVoid] [dbo].[bYN] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[TaxCode] [dbo].[bTaxCode] NULL,
[OldTaxCode] [dbo].[bTaxCode] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[OldTaxGroup] [dbo].[bGroup] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   CREATE   trigger [dbo].[btCMDBd] on [dbo].[bCMDB] for DELETE as
   

	/*-----------------------------------------------------------------
    *	This trigger updates bCMDT (Detail) to remove InUseBatchId 
    *	when deletion(s) are made from bCMDB (Detail Batch).
    *
    *	Rejects deletion if the following
    *	error condition exists:
    *
    *		Missing CM Transaction #
	*
	*	Modified:  MarkH 05/18/09 - Issue 133433/127603
    *
    */----------------------------------------------------------------
   
	declare @errmsg varchar(255), @numrows int, @nullcnt int

	select @numrows = @@rowcount
	set nocount on
      
	if @numrows = 0 return 
   
	/* count rows with null CM transaction */
	select @nullcnt = count(*) from deleted d , bCMDT c 
	where c.CMCo = d.Co and c.Mth = d.Mth and c.CMTrans = d.CMTrans 

	/* remove InUseBatchId from bCMDT rows pointed to by deleted batch entries */
	update bCMDT
	set InUseBatchId = null
	from bCMDT c, deleted d
	where c.CMCo = d.Co and c.Mth = d.Mth and c.CMTrans = d.CMTrans 

	/* sum  */
	if @nullcnt <> @@rowcount
	begin
		select @errmsg = 'Unable to properly update CM transaction(s) as in use!'
		goto error
	end

--	--delete HQAT entry when CMDT record not exists
--	delete bHQAT 
--	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
--	where h.UniqueAttchID not in(select t.UniqueAttchID from bCMDT t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)

	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
	select AttachmentID, suser_name(), 'Y' 
	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
	where h.UniqueAttchID not in(select t.UniqueAttchID from bCMDT t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
	and d.UniqueAttchID is not null     
	
	return
   
	error:
   	select @errmsg = @errmsg + ' - cannot delete CM Detail Batch entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btCMDBi    Script Date: 8/28/99 9:37:05 AM ******/
   CREATE   trigger [dbo].[btCMDBi] on [dbo].[bCMDB] for INSERT as
   

/*-----------------------------------------------------------------
    * Created: ??
    * Modified: GG 06/12/01 - Added BatchTransType validation
    *	 	 	  DANF 03/15/05 - #27294 - Remove scrollable cursor.
				AR 12/1/2010  - #142311 - adding foreign keys, removing trigger look ups
    *
    *	This trigger rejects insertion in bCMDB (Detail Batch) if
    *	any of the following error conditions exist:
    *
    * 		Invalid Batch ID#
    *		Batch associated with another source or table
    *		Batch in use by someone else
    *		Batch status not 'open'
    *
    *		Reference to a CM trans that doesn't exist
    *		CM trans already in use by a batch
    *		CM trans created from a source other than CM
    *
    *	use bspCMDBVal to fully validate all entries in a CMDB batch
    *	prior to posting.
    *
    *	Updates InUseBatchId in bCMDT for existing transactions.
    *
    * 	Adds entry to HQ Close Control as needed.
    *
    *----------------------------------------------------------------*/
   declare @batchid bBatchID, @errmsg varchar(255), @co bCompany, @inuseby bVPUserName,
       @mth bMonth, @numrows int, @seq int, @source bSource, @status tinyint, @tablename char(20),
   	@cmtrans bTrans, @dtsource bSource, @glco bCompany,	@inusebatchid bBatchID,
       @batchtranstype char(1), @rcode int, @errtext varchar(255)
   
   select @numrows = @@rowcount
   set nocount on
   
   if @numrows = 0 return
   
   if @numrows = 1
   	select @co = Co, @mth = Mth, @batchid = BatchId, @seq = BatchSeq,
   		@batchtranstype = BatchTransType, @cmtrans = CMTrans, @glco=GLCo from inserted
   else
   	begin
   	/* use a cursor to process each inserted row */
   	declare bCMDB_insert cursor local fast_forward for select Co, Mth, BatchId, BatchSeq,
   		BatchTransType, CMTrans, GLCo from inserted
   	open bCMDB_insert
   	fetch next from bCMDB_insert into @co, @mth, @batchid, @seq, @batchtranstype, @cmtrans, @glco
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   insert_check:
       -- validate Batch
       exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'CM Entry', 'CMDB', @errtext output, @status output
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
   
       if @batchtranstype = 'A' and @cmtrans is not null -- CM Trans must be null when inserted, can be updated later.
           begin
           select @errmsg = 'CM Transaction # must be null with all (A) entries.'
           goto error
           end
       if @batchtranstype in ('C','D') and @cmtrans is null
           begin
           select @errmsg = 'CM Transaction # is required for all (C and D) entries.'
           goto error
           end
   
   	/* validate existing CM trans - if one is referenced */
   	if @cmtrans is not null
   		begin
   		select @dtsource = Source, @inusebatchid = InUseBatchId
   		from bCMDT where CMCo = @co and Mth = @mth and CMTrans = @cmtrans
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
   		if substring(@dtsource,1,2) <> 'CM'
   			begin
   			select @errmsg = 'CM transaction was created with another source'
   			goto error
   			end
   
   		/* update CM transaction as 'in use' */
   		update bCMDT
   		set InUseBatchId = @batchid
   		where CMCo = @co and Mth = @mth and CMTrans = @cmtrans
   		if @@rowcount <> 1
   			begin
   			select @errmsg = 'Unable to update CM Detail as (In Use)'
   			goto error
   			end
   		end
   
       /* add entry to HQ Close Control as needed */
     	if not exists(select * from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
   		begin
   		insert bHQCC (Co, Mth, BatchId, GLCo)
   		values (@co, @mth, @batchid, @glco)
   		end
   
   	if @numrows > 1
   		begin
   		fetch next from bCMDB_insert into @co, @mth, @batchid, @seq, @batchtranstype, @cmtrans, @glco
   		if @@fetch_status = 0
   			goto insert_check
   		else
   			begin
   			  close bCMDB_insert
   			  deallocate bCMDB_insert
   			end
   		end
   
   return
   
   
   error:
   	if @numrows > 1
   		begin
   		close bCMDB_insert
   		deallocate bCMDB_insert
   		end
   
   
       	select @errmsg = @errmsg + ' - cannot insert CM Detail Batch entry!'
   
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btCMDBu    Script Date: 8/28/99 9:37:05 AM ******/
   CREATE  trigger [dbo].[btCMDBu] on [dbo].[bCMDB] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created: ??
    * Modified: GG 06/12/01 - added BatchTransType validation, allow CMTrans update
    *                          to 'A' entries, and removed cursor logic (#12769)
				AR 12/1/2010  - #142311 - adding foreign keys, removing trigger look ups
    *
    *  Update trigger for CM Detail Batch table
    *
    *----------------------------------------------------------------*/
   
   declare  @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   /* check for key changes */
   select @validcnt = count(*)  from deleted d, inserted i
   	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Batch Sequence #'
   	goto error
   	end
   
   -- check for change
   select @validcnt = count(*) from deleted d, inserted i
   where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
       and (d.BatchTransType = 'A' and i.BatchTransType in ('C','D'))
   if @validcnt > 0
       begin
       select @errmsg = 'Cannot change Batch Transaction Type from (A to C or D)'
       goto error
       end
   select @validcnt = count(*) from deleted d, inserted i
   where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
       and (i.BatchTransType = 'A' and d.BatchTransType in ('C','D'))
   if @validcnt > 0
    	begin
    	select @errmsg = 'Cannot change Batch Transaction Type from (C or D to A)'
    	goto error
    	end
   
   -- check CM Transaction
   select @validcnt = count(*) from deleted d, inserted i
   where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
       and i.BatchTransType in ('C','D') and ((i.CMTrans <> d.CMTrans) or i.CMTrans is null or d.CMTrans is null)
   if @validcnt > 0
       begin
       select @errmsg = 'Cannot change CM Transaction # on (C or D) entries'
       goto error
       end
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update CM Transaction Batch Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bCMDB] WITH NOCHECK ADD CONSTRAINT [CK_bCMDB_BatchTransType] CHECK (([BatchTransType]='D' OR [BatchTransType]='C' OR [BatchTransType]='A'))
GO
ALTER TABLE [dbo].[bCMDB] WITH NOCHECK ADD CONSTRAINT [CK_bCMDB_CMAcct] CHECK (([CMAcct]>(0) AND [CMAcct]<(10000)))
GO
ALTER TABLE [dbo].[bCMDB] WITH NOCHECK ADD CONSTRAINT [CK_bCMDB_OldCMAcct] CHECK (([OldCMAcct]>(0) AND [OldCMAcct]<(10000) OR [OldCMAcct] IS NULL))
GO
ALTER TABLE [dbo].[bCMDB] WITH NOCHECK ADD CONSTRAINT [CK_bCMDB_OldVoid] CHECK (([OldVoid]='Y' OR [OldVoid]='N' OR [OldVoid] IS NULL))
GO
ALTER TABLE [dbo].[bCMDB] WITH NOCHECK ADD CONSTRAINT [CK_bCMDB_Void] CHECK (([Void]='Y' OR [Void]='N'))
GO
ALTER TABLE [dbo].[bCMDB] ADD CONSTRAINT [PK_bCMDB_KeyID] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biCMDB] ON [dbo].[bCMDB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
