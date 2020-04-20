CREATE TABLE [dbo].[bJCIB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[TransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ItemTrans] [dbo].[bTrans] NULL,
[Contract] [dbo].[bContract] NULL,
[Item] [dbo].[bContractItem] NULL,
[ActDate] [dbo].[bDate] NULL,
[JCTransType] [char] (2) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bTransDesc] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLTransAcct] [dbo].[bGLAcct] NULL,
[GLOffsetAcct] [dbo].[bGLAcct] NULL,
[ReversalStatus] [tinyint] NULL,
[OrigMth] [dbo].[bMonth] NULL,
[OrigItemTrans] [dbo].[bTrans] NULL,
[BilledUnits] [dbo].[bUnits] NULL,
[BilledAmt] [dbo].[bDollar] NULL,
[OldContract] [dbo].[bContract] NULL,
[OldItem] [dbo].[bContractItem] NULL,
[OldActDate] [smalldatetime] NULL,
[OldJCTransType] [char] (2) COLLATE Latin1_General_BIN NULL,
[OldDescription] [dbo].[bTransDesc] NULL,
[OldGLCo] [dbo].[bCompany] NULL,
[OldGLTransAcct] [dbo].[bGLAcct] NULL,
[OldGLOffsetAcct] [dbo].[bGLAcct] NULL,
[OldReversalStatus] [tinyint] NULL,
[OldBilledUnits] [dbo].[bUnits] NULL,
[OldBilledAmt] [dbo].[bDollar] NULL,
[ARCo] [dbo].[bCompany] NULL,
[OldARCo] [dbo].[bCompany] NULL,
[ARInvoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldARInvoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ARCheck] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldARCheck] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[ToJCCo] [dbo].[bCompany] NULL,
[OldToJCCo] [dbo].[bCompany] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

/****** Object:  Trigger dbo.btJCIBd    Script Date: 8/28/99 9:37:44 AM ******/
CREATE   trigger [dbo].[btJCIBd] on [dbo].[bJCIB] for DELETE as
   

/*-----------------------------------------------------------------
*	This trigger updates bJCID (Item Detail) to remove InUseBatchId
*	when deletion(s) are made from bJCIB (Item Adj Batch).
*
*	Modified:	CHS 05/15/2009 - Issue #133437
*
*	Rejects deletion if the following
*	error condition exists:
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
     /* remove rows from bJCIA for new entries only */
    delete bJCIA
    	from bJCIA c
       join deleted d on c.JCCo = d.Co and c.Mth = d.Mth and c.BatchId = d.BatchId and c.BatchSeq = d.BatchSeq
       join bHQBC e on e.Co = d.Co and e.Mth = d.Mth and e.BatchId = d.BatchId
       where e.Status <> 4
   
   /* remove InUseBatchId from bJCID rows pointed to by deleted batch entries */
   update bJCID
   	set InUseBatchId = null
   	from bJCID c, deleted d
   	where c.JCCo = d.Co and c.Mth = d.Mth and c.ItemTrans = d.ItemTrans
   
   /* remove InUseBatchId for reversals */
   update bJCID
   	set InUseBatchId = null
   	from bJCID c, deleted d
   	where c.JCCo = d.Co and c.Mth = d.OrigMth and c.ItemTrans = d.OrigItemTrans
   
  
	-- Issue #133437
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
			  select AttachmentID, suser_name(), 'Y' 
				  from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
				  where h.UniqueAttchID not in(select t.UniqueAttchID from bJCID t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
				  and d.UniqueAttchID is not null    
 
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete JC Item Detail Batch entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btJCIBi    Script Date: 8/28/99 9:38:23 AM ******/
   CREATE   trigger [dbo].[btJCIBi] on [dbo].[bJCIB] for INSERT as
   

declare @batchid bBatchID, @errmsg varchar(255), @co bCompany,
    	@inuseby bVPUserName, @mth bMonth, @numrows int, @seq int,
    	@transsource bSource, @status tinyint, @tablename char(20),
    	@itemtrans bTrans, @dtsource bSource, @glco bCompany,
    	@InUseBatchId bBatchID, @errtext varchar(60), @rcode tinyint,
    	@reversalstatus tinyint, @origmth bMonth, @origitemtrans bTrans
    	
    /*-----------------------------------------------------------------
    * 		 	  DANF 03/15/05 - #27294 - Remove scrollable cursor.
     *	This trigger rejects insertion in bJCIB (Item Adj Batch) if 
     *	any of the following error conditions exist:
     *
     * 		Invalid Batch ID#
     *		Batch associated with another source or table
     *		Batch in use by someone else
     *		Batch status not 'open'
     *
     *		APRef to a JCID trans that doesn't exist
     *		JCID trans already in use by a batch
     *		JCID trans created from a source other than JC
     *		
     *	use bspJCIBVal to fully validate all entries in a JCIB batch
     *	prior to posting.
     *
     *	Updates InUseBatchId in bJCID for existing transactions.
     *	Updates InUseBatchId of reversal trans if adding reversal
     * 
     * 	Adds entry to HQ Close Control as needed.
     *
     *		Modified; TV - 23061 added isnulls
     *----------------------------------------------------------------*/
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
    if @numrows = 1
    	select @co = Co, @mth = Mth, @batchid = BatchId, @seq = BatchSeq,
    		@itemtrans = ItemTrans, @glco=GLCo, @reversalstatus=ReversalStatus,
    		@origmth = OrigMth, @origitemtrans=OrigItemTrans from inserted
    else
    	begin
    	/* use a cursor to process each inserted row */
    	declare bJCIB_insert cursor local fast_forward for select Co, Mth, BatchId, BatchSeq,
    		ItemTrans, GLCo, ReversalStatus, OrigMth, OrigItemTrans from inserted
    	open bJCIB_insert
    	fetch next from bJCIB_insert into @co, @mth, @batchid, @seq, @itemtrans, @glco, 
    		@reversalstatus, @origmth, @origitemtrans		
    
    	if @@fetch_status <> 0
    		begin
    		select @errmsg = 'Cursor error'
    		goto error
    		end
   
    	end
    
    insert_check:
    /* validate HQ Batch */
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'JC RevAdj', 'JCIB', @errtext output, @status output
    if @rcode <> 0
    	begin
        	select @errmsg = @errtext, @rcode = 1
        	goto error
       	end
    if @status <> 0
    	begin
    	select @errmsg = 'Must be an open batch'
    	goto error
    	end
    
    	/* validate existing JC trans - if one is APRefd */
    	if @itemtrans is not null
    		begin
    		select @dtsource = TransSource, @InUseBatchId = InUseBatchId
    			from bJCID where JCCo = @co and Mth = @mth and ItemTrans = @itemtrans
    
    		if @@rowcount = 0
    			begin
    			select @errmsg = 'JC Item Detail transaction not found'
    			goto error
    			end
    		if @InUseBatchId is not null
    			begin
    			select @errmsg = 'JC Item Detail transaction in use by another Batch'
    			goto error
    			end
    
    		if @dtsource <> 'JC RevAdj'
    			begin
    			select @errmsg = 'JC transaction was created with another source'
    			goto error
    			end
     
    		/* update JC transaction as 'in use' */
    		update bJCID
    		set InUseBatchId = @batchid
    			where JCCo = @co and Mth = @mth and ItemTrans = @itemtrans
    		if @@rowcount <> 1
    			begin
    			select @errmsg = 'Unable to update JC Item Detail as (In Use)'
    			goto error
    			end
    		end
    
    	/* validate existing JC trans - if one is APRefd */
    	if @reversalstatus = 2
    		begin
      		  select @dtsource = TransSource, @InUseBatchId = InUseBatchId
    			from bJCID where JCCo = @co and Mth = @origmth and ItemTrans = @origitemtrans
    		  if @@rowcount = 0
    			begin
    			select @errmsg = 'Original Item Detail transaction ' + isnull(convert(varchar(10), @origmth),'') 
    				+ ':' + isnull(convert(varchar(5), @origitemtrans),'') + ' for reversal not found'
    			goto error
    			end
    		if @InUseBatchId is not null
    			begin
    			select @errmsg = 'Original Item Detail transaction for reversal is in use by another Batch'
    			goto error
    			end
    		if @dtsource <> 'JC RevAdj'
    			begin
    			select @errmsg = 'Original Item Detail transaction for reversal was created with another source'
    			goto error
    			end
     
    		/* update JC transaction as 'in use' */
    		update bJCID
    		set InUseBatchId = @batchid
    			where JCCo = @co and Mth = @origmth and ItemTrans = @origitemtrans
    		if @@rowcount <> 1
    			begin
    			select @errmsg = 'Unable to update original Item Detail transaction as (In Use)'
    
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
    		  fetch next from bJCIB_insert into @co, @mth, @batchid, @seq, @itemtrans, @glco, 
       		  @reversalstatus, @origmth, @origitemtrans		
    		  if @@fetch_status = 0
    			goto insert_check
    		else
    			begin
    			  close bJCIB_insert
    			  deallocate bJCIB_insert
    			end
    		end		
    	
    return
    
    	
    error:
    	if @numrows > 1
    		begin
    		close bJCIB_insert
    		deallocate bJCIB_insert
    		end
    	
    
        	select @errmsg = @errmsg + ' - cannot insert JC Item Detail Batch entry!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction
    
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJCIB] ON [dbo].[bJCIB] ([Co], [Mth], [BatchId], [BatchSeq], [TransType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCIB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
