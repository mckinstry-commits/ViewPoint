CREATE TABLE [dbo].[bGLRB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OrigMonth] [dbo].[bMonth] NOT NULL,
[OrigGLTrans] [dbo].[bTrans] NOT NULL,
[OrigDate] [dbo].[bDate] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[GLRef] [dbo].[bGLRef] NOT NULL,
[Description] [dbo].[bTransDesc] NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btGLRBd    Script Date: 8/28/99 9:37:31 AM ******/
   CREATE   trigger [dbo].[btGLRBd] on [dbo].[bGLRB] for DELETE as
   

/*-----------------------------------------------------------------
    *	This trigger updates bGLDT (Detail) to remove InUseBatchId 
    *	when deletion(s) are made from bGLRB (Reversal Batch).
    *      It updates the original transaction
    *
    *	Rejects deletion if the following
    *	error condition exists:
    *
    *		Missing GL Transaction #
    *
    * Modified By:	GP 05/14/09 - Issue 133435 Removed HQAT delete, added insert
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   set nocount on
   
   /* update GL Transaction Detail */
   update bGLDT
   	set InUseBatchId = null
   	from bGLDT g, deleted d
   	where g.GLCo = d.Co and g.Mth = d.OrigMonth and g.GLTrans = d.OrigGLTrans
   select @validcnt = @@rowcount
   
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Unable to update GL Detail Transactions'
   	goto error
   	end
   
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
    from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
    where h.UniqueAttchID not in(select t.UniqueAttchID from bGLDT t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
		and d.UniqueAttchID is not null    
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete GL Reversal Batch entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btGLRBi    Script Date: 8/28/99 9:37:32 AM ******/
   CREATE  trigger [dbo].[btGLRBi] on [dbo].[bGLRB] for INSERT as
/************************************************************************
* CREATED:	
* MODIFIED:	AR 2/7/2011  - #143291 - adding foreign keys and check constraints, removing trigger look ups
*
* Purpose:    This trigger rejects insertion in bGLRB (Reversal Batch) if 
*	any of the following error conditions exist:
*
* 		Invalid Batch ID#
*		Batch associated with another source or table
*		Batch in use by someone else
*		Batch status not 'open'
*
*		Reference to a GL trans that doesn't exist
*		GL trans already in use by a batch
*		
*	use bspGLDBVal to fully validate all entries in a GLDB batch
*	prior to posting.
*
*	Updates InUseBatchId in bGLDT for original transactions.
* 
* 	Adds entry to HQ Close Control as needed.

* returns 1 and error msg if failed
*
*************************************************************************/   

declare @batchid bBatchID, @errmsg varchar(255), @co bCompany,
   	@inuseby bVPUserName, @mth bMonth, @origmonth bMonth, @numrows int, @seq int,
   	@source bSource, @status tinyint, @tablename char(20),
   	@origgltrans bTrans, @dtadj bYN, @dtsource bSource,
   	@inusebatchid bBatchID, @adj bYN
   	
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   if @numrows = 1
   	select @co = Co, @mth = Mth, @origmonth=OrigMonth, @batchid = BatchId, @seq = BatchSeq,
   		@origgltrans = OrigGLTrans from inserted
   
   else
   	begin
   	/* use a cursor to process each inserted row */
   	declare bGLRB_insert cursor for select Co, Mth, OrigMonth, BatchId, BatchSeq,
   		OrigGLTrans from inserted
   	open bGLRB_insert
   	fetch next from bGLRB_insert into @co, @mth, @origmonth, @batchid, @seq, @origgltrans
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   insert_check:
   	/* validate Batch  */
   	select @source = Source, @tablename = TableName, @inuseby = InUseBy,
   		@status = Status from bHQBC 
   
   		where Co = @co and Mth = @mth and BatchId = @batchid
   	--#143291 - handled by FK now
   	if @source <> 'GL Rev'
   		begin
   		select @errmsg = 'Batch associated with another source'
   
   		goto error
   		end
   	if @tablename <> 'GLRB'
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
   	if @origgltrans is not null
   		begin
			 SELECT @inusebatchid = InUseBatchId
			 FROM   dbo.bGLDT
			 WHERE  GLCo = @co
					AND Mth = @origmonth
					AND GLTrans = @origgltrans
   				--#142311 - replacing with FK
			 IF @inusebatchid IS NOT NULL 
				BEGIN
					SELECT  @errmsg = 'Reversing GL transaction in use by another Batch'
					GOTO error
				END
		   -- Mark  Begin problem
   
   		/* update GL transaction as 'in use' */
   		update bGLDT
   		set InUseBatchId = @batchid
   			where GLCo = @co and Mth = @origmonth and GLTrans = @origgltrans
   		if @@rowcount <> 1
   			begin
   			select @errmsg = 'Unable to update reversing GL Detail as (In Use)'
   			goto error
   			end
   		end
   -- End Problem
   		
   	/* add entry to HQ Close Control as needed */
   	if not exists(select * from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @co)
   		begin
   		insert bHQCC (Co, Mth, BatchId, GLCo)
   		values (@co, @mth, @batchid, @co)
   		end
   
   	if @numrows > 1
   		begin
   		fetch next from bGLRB_insert into @co, @mth, @origmonth, @batchid, @seq, @origgltrans 
   		if @@fetch_status = 0
   			goto insert_check
   		else
   			begin
   			close bGLRB_insert
   			deallocate bGLRB_insert
   			end
   		end		
   	
   return
   
   	
   error:
   	if @numrows > 1
   		begin
   		close bGLRB_insert
   		deallocate bGLRB_insert
   		end
   	
   
       	select @errmsg = @errmsg + ' - cannot insert GL Reversal Batch entry!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bGLRB] ADD CONSTRAINT [PK_bGLRB] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLRB] ON [dbo].[bGLRB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLRB] WITH NOCHECK ADD CONSTRAINT [FK_bGLRB_bHQBC_CoMthBatchId] FOREIGN KEY ([Co], [Mth], [BatchId]) REFERENCES [dbo].[bHQBC] ([Co], [Mth], [BatchId])
GO
ALTER TABLE [dbo].[bGLRB] WITH NOCHECK ADD CONSTRAINT [FK_bGLRB_bGLDT_GLCoMthGLTrans] FOREIGN KEY ([Co], [OrigMonth], [OrigGLTrans]) REFERENCES [dbo].[bGLDT] ([GLCo], [Mth], [GLTrans])
GO
