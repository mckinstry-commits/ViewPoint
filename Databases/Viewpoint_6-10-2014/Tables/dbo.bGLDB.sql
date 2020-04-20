CREATE TABLE [dbo].[bGLDB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[GLTrans] [dbo].[bTrans] NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[GLRef] [dbo].[bGLRef] NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bTransDesc] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[OldGLAcct] [dbo].[bGLAcct] NULL,
[OldActDate] [dbo].[bDate] NULL,
[OldDesc] [dbo].[bTransDesc] NULL,
[OldAmount] [dbo].[bDollar] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[InterCo] [dbo].[bCompany] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btGLDBd    Script Date: 8/28/99 9:37:29 AM ******/
   CREATE trigger [dbo].[btGLDBd] on [dbo].[bGLDB] for DELETE as
   

/*-----------------------------------------------------------------
    * Created: ??
    * Modified: GG 03/12/03 - #20660 - removed rowcount check 
    *			 GF 03/29/2005 - #27453 - performance improvement for deleting attachments
    *			GP 05/14/2009 - 133435 Removed HQAT delete, added new insert
    *
    *
    *
    *	Delete trigger on GL Detail Batch (bGLDB)
    *
    *	Remove InUseBatchId from existing transactions as they are deleted from the batch
    *
    *	Delete Attachments linked to batch entries, but not linked to existing transactions,
    *	as the batch entries are deleted.
    *
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on 
   
   -- remove InUseBatchId from GL transactions deleted from the batch
   update bGLDT
   set InUseBatchId = null
   from bGLDT g
   join deleted d on g.GLCo = d.Co and g.Mth = d.Mth and g.GLTrans = d.GLTrans
   -- #20660 - don't count # of rows updated	  
   
   -- -- -- --delete HQAT entries if not exists in GLDT
   -- -- -- delete bHQAT 
   -- -- -- from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
   -- -- -- where h.UniqueAttchID not in(select t.UniqueAttchID from bGLDT t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
   
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
	select AttachmentID, suser_name(), 'Y' 
	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
	where h.UniqueAttchID not in(select t.UniqueAttchID from bGLDT t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
		and d.UniqueAttchID is not null   
   
   
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete GL Detail Batch entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLDBi    Script Date: 8/28/99 9:37:29 AM ******/
   CREATE   trigger [dbo].[btGLDBi] on [dbo].[bGLDB] for INSERT as
   

declare @batchid bBatchID, @errmsg varchar(255), @co bCompany,
   	@inuseby bVPUserName, @mth bMonth, @numrows int, @seq int,
   	@source bSource, @status tinyint, @tablename char(20),
   	@gltrans bTrans, @dtadj bYN, @dtsource bSource,
   	@inusebatchid bBatchID, @adj bYN, @interco bCompany, @jrnl bJrnl, @ref bGLRef, @ActDate bDate, @amount bDollar
   	
   /*-----------------------------------------------------------------
    *	MODIFIED:	
    *	This trigger rejects insertion in bGLDB (Detail Batch) if 
    *	any of the following error conditions exist:
    *		DANF 03/20/04 - Fixed missing comma after GLRef in cursor.
			AMR 02/10/2011 - adding FKs to replace trigger code
    *
    * 		Invalid Batch ID#
    *		Batch associated with another source or table
    *		Batch in use by someone else
    *		Batch status not 'open'
    *
    *		Reference to a GL trans that doesn't exist
    *		GL trans already in use by a batch
    *		GL trans created from a source other than GL
    *		GL trans posted with an adjustment flag not equal to current batch. 
    *		
    *	use bspGLDBVal to fully validate all entries in a GLDB batch
    *	prior to posting.
    *
    *	Updates InUseBatchId in bGLDT for existing transactions.
    * 
    * 	Adds entry to HQ Close Control as needed.
    *
    *----------------------------------------------------------------*/
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   if @numrows = 1
   	select @co = Co, @mth = Mth, @batchid = BatchId, @seq = BatchSeq, @jrnl= Jrnl , @ref = GLRef, 
   		@gltrans = GLTrans, @interco = InterCo, @ActDate = ActDate, @amount = Amount from inserted
   else
   	begin
   	/* use a cursor to process each inserted row */
   	declare bGLDB_insert cursor for select Co, Mth, BatchId, BatchSeq, Jrnl, GLRef,
   		GLTrans, InterCo, ActDate, Amount from inserted
   	open bGLDB_insert
   	fetch next from bGLDB_insert into @co, @mth, @batchid, @seq, @jrnl, @ref, @gltrans, @interco, @ActDate, @amount
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   insert_check:
   	/* validate Batch  */
   	select @source = Source, @tablename = TableName, @inuseby = InUseBy,
   		@status = Status, @adj = Adjust from bHQBC 
   		where Co = @co and Mth = @mth and BatchId = @batchid
	-- 143291 - using FK now
   	if @source <> 'GL Jrnl'
   		begin
   		select @errmsg = 'Batch associated with another source'
   
   		goto error
   		end
   	if @tablename <> 'GLDB'
   		begin
   		select @errmsg = 'Batch associated with another table'
   		goto error
   		end
   	if @inuseby is null
   		begin
   		select @errmsg = 'Batch (In Use) name must first be updated'
   		goto error
   		end
   	if @inuseby <> SUSER_SNAME()
   		begin
   		select @errmsg = 'Batch already in use by ' + @inuseby
   		goto error
   		end
   	if @status <> 0
   		begin
   		select @errmsg = 'Must be an open batch'
   		goto error
   		end
   
   	/* validate existing GL trans - if one is referenced */
   	if @gltrans is not null
   		BEGIN	
   			select @dtadj = Adjust, @dtsource = Source, @inusebatchid = InUseBatchId
   			from bGLDT where GLCo = @co and Mth = @mth and GLTrans = @gltrans
   			if @@rowcount = 0
   			begin
   			select @errmsg = 'GL transaction not found'
   			goto error
   			end		
   		if @inusebatchid is not null
   			begin
   			select @errmsg = 'GL transaction in use by another Batch'
   			goto error
   			end
   		if substring(@dtsource,1,2) <> 'GL'
   			begin
   			select @errmsg = 'GL transaction was created with another source'
   			goto error
   			end
   		if @dtadj <> @adj
   			begin
   			if @dtadj = 'Y'
   				begin
   				select @errmsg = 'GL transaction was posted in an adjustment period'
   				end
   			if @dtadj = 'N'
   				begin
   				select @errmsg = 'GL transaction was not posted in an adjustment period'
   				end
   			goto error
   			end
    
   		/* update GL transaction as 'in use' */	
   			update bGLDT
   			set InUseBatchId = @batchid
   			where GLCo = @co and Mth = @mth and GLTrans = @gltrans
   			if @@rowcount <> 1
   			begin
   			select @errmsg = 'Unable to update GL Detail as (In Use)'
   			goto error
   			end
   		
   	END -- end for if GLTrans is not null
   
    
   		
   	/* add entry to HQ Close Control as needed */
   	if not exists(select * from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @co)
   		begin
   		insert bHQCC (Co, Mth, BatchId, GLCo)
   		values (@co, @mth, @batchid, @co)
   		end
   	
   
   	if @numrows > 1
   		begin
   		fetch next from bGLDB_insert into @co, @mth, @batchid, @seq, @jrnl, @ref, @gltrans, @interco, @ActDate, @amount
   		if @@fetch_status = 0
   			goto insert_check
   		else
   			begin
   			close bGLDB_insert
   			deallocate bGLDB_insert
   			end
   		end		
   	
   return
   
   	
   error:
   	if @numrows > 1
   		begin
   		close bGLDB_insert
   		deallocate bGLDB_insert
   		end
   	
   
       	select @errmsg = @errmsg + ' - cannot insert GL Detail Batch entry!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE  trigger [dbo].[btGLDBu] on [dbo].[bGLDB] for UPDATE 
   /*-----------------------------------------------------------------
   * Created: ??
   * Modified: GG 12/04/02 - #19372 - cleanup validation, removed cursor
   *
   *	Update trigger for GL Detail Batch
   *		
   *----------------------------------------------------------------*/
   as
   
   

declare @errmsg varchar(255), @numrows int,	@validcnt int
    
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
    
    
   /* check for key changes */ 
   select @validcnt = count(*)
   from deleted d
   join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Batch Sequence #'
    	goto error
    	end
   -- check Batch Transaction Type
   if update(BatchTransType)
    	begin
    	select @validcnt = count(*) from inserted i where i.BatchTransType in ('A','C','D')
    	if @validcnt <> @numrows
    	 	begin
    	 	select @errmsg = 'Batch Transaction Type must be ''A'',''C'', or ''D'''
    	 	goto error
    	 	end
    	-- check for change
    	select @validcnt = count(*) from deleted d, inserted i
    	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
    	    and (d.BatchTransType = 'A' and i.BatchTransType in ('C','D'))
    	if @validcnt > 0
    	    begin
    	    select @errmsg = 'Cannot change Batch Transaction Type from ''A'' to ''C'' or ''D'''
    	    goto error
    	    end
    	select @validcnt = count(*) from deleted d, inserted i
    	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
    	    and (i.BatchTransType = 'A' and d.BatchTransType in ('C','D'))
    	if @validcnt > 0
    	 	begin
    	 	select @errmsg = 'Cannot change Batch Transaction Type from ''C'' or ''D'' to ''A'''
    	 	goto error
    	 	end
    	end
   -- check GL Transaction, change allowed on 'add' needed for user memo updates
   if update(GLTrans)
   	begin
    	select @validcnt = count(*)
    	from deleted d
    	join inserted i on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId and i.BatchSeq = d.BatchSeq
    	where i.BatchTransType in ('C','D') and (i.GLTrans <> d.GLTrans or i.GLTrans is null or d.GLTrans is null)
    	if @validcnt <> 0
    	    begin
    	    select @errmsg = 'Cannot change GL Transaction # on ''C'' or ''D'' entries'
    	    goto error
    	    end
    	end
    /* if change or delete, cannot change InterCo, Journal, or Reference */
    if update(InterCo) or update(Jrnl) or update(GLRef)
    	begin
    	select @validcnt = count(*)
    	from deleted d
    	join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
    	where i.BatchTransType in ('C','D') and (d.Jrnl <> i.Jrnl or d.GLRef <> i.GLRef
   		or isnull(d.InterCo,0) <> isnull(i.InterCo,0))
    	 if @validcnt > 0
    	 	begin
    	 	select @errmsg = 'Cannot change To Company, Journal, or Reference on ''C'' or ''D'' entries'
    	 	goto error
    	 	end
    	end
   
   return
    
   error:
    	select @errmsg = @errmsg + ' - cannot update GL Transaction Batch Detail!'
    	RAISERROR(@errmsg, 11, -1);
    
    	rollback transaction
    
    
    
   
   
   
  
 



GO
ALTER TABLE [dbo].[bGLDB] ADD CONSTRAINT [PK_bGLDB] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=100) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biGLDBBatchSeq] ON [dbo].[bGLDB] ([BatchSeq], [Co], [Mth], [BatchId]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLDB] ON [dbo].[bGLDB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biGLDBInterCo] ON [dbo].[bGLDB] ([InterCo], [GLAcct]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLDB] WITH NOCHECK ADD CONSTRAINT [FK_bGLDB_bHQBC_CoMthBatchId] FOREIGN KEY ([Co], [Mth], [BatchId]) REFERENCES [dbo].[bHQBC] ([Co], [Mth], [BatchId])
GO
ALTER TABLE [dbo].[bGLDB] NOCHECK CONSTRAINT [FK_bGLDB_bHQBC_CoMthBatchId]
GO
