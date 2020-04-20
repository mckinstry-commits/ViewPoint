CREATE TABLE [dbo].[bAPCT]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[ExpMth] [dbo].[bMonth] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[APRef] [dbo].[bAPReference] NULL,
[Description] [dbo].[bDesc] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[Gross] [dbo].[bDollar] NOT NULL,
[Paid] [dbo].[bDollar] NOT NULL,
[Remaining] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biAPCT] ON [dbo].[bAPCT] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPCTd    Script Date: 8/28/99 9:36:53 AM ******/
   CREATE  trigger [dbo].[btAPCTd] on [dbo].[bAPCT] for DELETE as 
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), 
          @validcnt int, @co bCompany, @mth bMonth, @batchid bBatchID,
          @trans bTrans, @rcode tinyint, @errtext varchar(60), @status tinyint
   
   /*-------------------------------------------------------------- 
    *	Created : EN 8/25/98
    *	Modified : EN 8/25/98
    *			 MV 10/17/02 - 18878 quoted identifiers.
    *
    *	Reject if APCD exists.
    *	Unlock APTH (update InUseMth and InUseBatchId)
    *--------------------------------------------------------------*/
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check AP Clear Distributions */
   if exists(select * from bAPCD c, deleted d where c.Co = d.Co and c.Mth = d.Mth
   	  and c.BatchId = d.BatchId and c.BatchSeq = d.BatchSeq)
   	begin
   	 select @errmsg = 'Entries exist in AP Clear Distributions for this entry'
   	 goto error
   	end
   
   /* unlock existing APTH */
   update bAPTH
   set InUseBatchId=null, InUseMth=null from bAPTH t, deleted d
   where t.APCo=d.Co and t.Mth=d.ExpMth and t.APTrans=d.APTrans
   	
   if @@rowcount = 0
   	begin
   	 select @errmsg = 'Unable to flag AP transaction as ''In Use''.'
   	 goto error
   	end
   
   		
   return
   
   error:
   
      select @errmsg = @errmsg + ' - cannot delete Clear Transaction'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
    
CREATE trigger [dbo].[btAPCTi] on [dbo].[bAPCT] for INSERT as 
/*-------------------------------------------------------------- 
* Created: EN 8/24/98
* Modified: kb 1/4/99
* 			MV 10/17/02 - 18878 quoted identifier
* 	 		DANF 03/15/05 - #27294 - Remove scrollable cursor.
*			MV 08/24/06 - #121887 - check for hold detail
*			GG 07/25/07 - #120561 - remove bHQCC insert, cleanup
*			MV 04/02/09 - #133073 - cursor review/modifications
*
* Insert trigger for AP Clear Transaction batch
*
*	Validate batch info in HQBC
*	Lock AP transaction header in APTH (update InUseMth and InUseBatchId)
*--------------------------------------------------------------*/   
 
declare @numrows int, @errmsg varchar(255), @expmth bMonth, @validcnt int, @co bCompany,
	@mth bMonth, @batchid bBatchID, @trans bTrans, @rcode tinyint, @errtext varchar(60),
	@status tinyint, @glco bCompany
    
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


if @numrows = 1
	select @co = Co, @mth = Mth, @batchid = BatchId	--, @trans = APTrans, @expmth = ExpMth, @glco = GLCo
	from inserted i
	join bAPCO a (nolock) on i.Co = a.APCo
	/* validate HQ Batch */
	exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'AP Clear', 'APCT', @errtext output, @status output
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
else
	begin
	/* use a cursor to process each inserted row */
	declare bAPCT_insert cursor local fast_forward for
	select i.Co, i.Mth, i.BatchId	--, i.APTrans, i.ExpMth, a.GLCo 
	from inserted i
	join bAPCO a (nolock) on i.Co = a.APCo
	 
	open bAPCT_insert
	fetch next from bAPCT_insert into @co, @mth, @batchid --, @trans, @expmth, @glco
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
    
	insert_check:
		/* validate HQ Batch */
		exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'AP Clear', 'APCT', @errtext output, @status output
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

    	fetch next from bAPCT_insert into @co, @mth, @batchid --, @trans, @expmth
    	if @@fetch_status = 0
    		goto insert_check
    	 else
    		begin
    		close bAPCT_insert
    		deallocate bAPCT_insert
    		end
	end	
    
	/* check for holdcodes */
	if exists(select * from bAPHD h (nolock) 
		join inserted i on h.APCo=i.Co and h.Mth=i.ExpMth and h.APTrans=i.APTrans)
		begin
		select @errmsg = 'Transaction has hold detail, cannot add to clear batch.', @rcode = 1
        goto error
		end
	--	if exists(select * from bAPHD (nolock) where APCo=@co and Mth=@expmth and APTrans=@trans)
	--		begin
	--		select @errmsg = 'Transaction has hold detail, cannot add to clear batch.', @rcode = 1
	--        goto error
	--		end
    
      
    /* lock existing APTH */
--	select @validcnt = count(*) from inserted
    update bAPTH
	set InUseBatchId=i.BatchId, InUseMth=i.Mth
	from bAPTH h join inserted i on h.APCo=i.Co and h.Mth=i.ExpMth and h.APTrans=i.APTrans
    if @@rowcount = 0
		begin
    	select @errmsg = 'Unable to flag AP transaction as ''In Use''.' 
    	goto error
    	end

    
    		
return
    
error:
	if @numrows > 1
		begin
    	close bAPCT_insert
    	deallocate bAPCT_insert
		end
    	
	select @errmsg = @errmsg + ' - cannot insert Clear Transaction'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btAPCTu    Script Date: 8/28/99 9:36:53 AM ******/
   CREATE   trigger [dbo].[btAPCTu] on [dbo].[bAPCT] for UPDATE as
    

/*-----------------------------------------------------------------
     *	Created : 8/25/98 EN
     *	Modified : 8/25/98 EN
     * 			 10/17/02 MV - 18878 quoted identifier cleanup.
	 *				08/24/06 - #121887 - check for hold detail
     *
     *	This trigger rejects update in bAPCT (Clear Transactions)
     *	if any of the following error conditions exist:
     *
     *		Cannot change Co
     *		Cannot change Mth
     *		Cannot change BatchId
     *		Cannot change BatchSeq
     *
     *	Also, if APTrans changes, unlock the old entry and lock the new one.
     *		
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int
    
    select @numrows = @@rowcount
    if @numrows = 0 return 
    
    set nocount on
    
    /* verify primary key not changed */
    select @validcnt = count(*) from deleted d, inserted i
    	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
    if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change Primary Key'
    	goto error
    	end
	
	/* check for holdcodes */
	if exists(select * from bAPHD h, inserted i where h.APCo=i.Co and h.Mth=i.Mth and h.APTrans=i.APTrans)
		begin
		select @errmsg = 'Transaction has hold detail, cannot add to clear batch.'
        	goto error
		end
    
    /* if APTrans changes, unlock old APTH and lock new */
    select @validcnt=count(*) from deleted d, inserted i
    	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and
    		d.BatchSeq = i.BatchSeq and d.APTrans <> i.APTrans
    if @numrows <> @validcnt
    	begin
    	 update bAPTH
    	 set InUseBatchId=null, InUseMth=null from bAPTH t, deleted d
    		where t.APCo=d.Co and t.Mth=d.Mth and t.APTrans=d.APTrans
    		
    	 update bAPTH
    	 set InUseBatchId=i.BatchId, InUseMth=i.Mth from bAPTH t, inserted i
    		where t.APCo=i.Co and t.Mth=i.Mth and t.APTrans=i.APTrans
    	end
    	
    		
    return
    
    error:
    	select @errmsg = @errmsg + ' - cannot update Clear Transactions!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction
   
   
   
   
  
 




GO
