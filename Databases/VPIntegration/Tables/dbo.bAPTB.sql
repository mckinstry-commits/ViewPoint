CREATE TABLE [dbo].[bAPTB]
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
[Retainage] [dbo].[bDollar] NOT NULL,
[PrevPaid] [dbo].[bDollar] NOT NULL,
[PrevDisc] [dbo].[bDollar] NOT NULL,
[Balance] [dbo].[bDollar] NOT NULL,
[DiscTaken] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btAPTBd    Script Date: 8/28/99 9:36:57 AM ******/
   
   CREATE     trigger [dbo].[btAPTBd] on [dbo].[bAPTB] for DELETE as
   

/*--------------------------------------------------------------
    *	Created : EN 11/1/98
    *	Modified : GG 4/30/99
    *  Modified : kb 5/3/00 - issue #6649. When clear void out of payment batch and
    *    it was originally a processed prepaid, need to set PrePaidProcYN = 'Y'
    *				kb 7/30/2 - issue #18112 - do manual check processing
    *				kb 7/31/2 - issue #18147 - update APPB from APDB instead of APTB
    *				mv 10/18/02 - 18878 quoted identifier cleanup.
	*				MV 04/03/09 - #133073 - (nolock), new joins
    *
    *
    *	Reject if Payment Batch Detail exists for the Payment Batch Transaction
    *
    * Adjusts Net Amounnt in Payment Batch Header
    *
    *	Unlocks Transaction Header (set InUseMth and InUseBatchId = null) if
    * no longer referenced by the Payment Batch
    *--------------------------------------------------------------*/
   
   declare @numrows int, @errmsg varchar(255), @co bCompany, @mth bMonth, @batchid bBatchID,
   @batchseq int, @expmth bMonth, @aptrans bTrans, @opencursor tinyint, @void bYN,
   @rcode int
   
   select @numrows = @@rowcount
   
   if @numrows = 0 return
   
   set nocount on
   
   select @rcode = 0
   
   --  check AP Payment Batch Detail
--   if exists(select * from APDB c, deleted d where c.Co = d.Co and c.Mth = d.Mth
--       and c.BatchId = d.BatchId and c.BatchSeq = d.BatchSeq and c.ExpMth = d.ExpMth and c.APTrans = d.APTrans)
       if exists(select * from dbo.APDB c (nolock) join deleted d on c.Co = d.Co and c.Mth = d.Mth
       and c.BatchId = d.BatchId and c.BatchSeq = d.BatchSeq and c.ExpMth = d.ExpMth and c.APTrans = d.APTrans)
		begin
    	select @errmsg = 'Entries exist in AP Payment Batch Detail'
    	goto error
    	end
   
   if @numrows = 1
    	select @co = Co, @mth = Mth, @batchid = BatchId, @batchseq = BatchSeq, @expmth = ExpMth,
           @aptrans = APTrans from deleted
   else
       begin
    	/* use a cursor to process each deleted row */
    	declare bAPTB_delete cursor for select Co, Mth, BatchId, BatchSeq, ExpMth, APTrans from deleted
    	open bAPTB_delete
       select @opencursor = 1
    	fetch next from bAPTB_delete into @co, @mth, @batchid, @batchseq, @expmth, @aptrans
    	if @@fetch_status <> 0
    		begin
    		select @errmsg = 'Cursor error'
    		goto error
    		end
    	end
   
       select @void=VoidYN from dbo.bAPPB (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
         and BatchSeq = @batchseq
       if @void = 'Y'
           begin
           update bAPTH set PrePaidProcYN='Y' from dbo.bAPTH where APCo = @co and Mth = @mth
             and APTrans = @aptrans and PrePaidYN = 'Y'
           end
   delete_check:   -- unlock AP Trans Header unless this trans in still in the Payment Batch
   if not exists(select * from dbo.bAPTB (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
           and ExpMth = @expmth and APTrans = @aptrans)
       begin
       update dbo.bAPTH
       set InUseBatchId = null, InUseMth = null
       where APCo = @co and Mth = @expmth and APTrans = @aptrans
       if @@rowcount <> 1
           begin
           select @errmsg = 'Unable to unlock AP Transaction Header'
           goto error
           end
       end
   
   	--do processing for manual checks
   	if exists(select 1 from dbo.bAPPB (nolock) where Co = @co and Mth = @mth  
   	  and BatchId = @batchid and BatchSeq = @batchseq and ChkType = 'M')
   		begin
   		exec @rcode = bspAPManualCheckProcess @co, @expmth, @batchid,
   		  @batchseq, @errmsg output
   		if @rcode <> 0
   			begin
   			goto error
   			end
   		end
   
   if @numrows > 1
    	begin
       fetch next from bAPTB_delete into @co, @mth, @batchid, @batchseq, @expmth, @aptrans
    	if @@fetch_status = 0
    	    goto delete_check
    	else
           begin
    		close bAPTB_delete
    		deallocate bAPTB_delete
           select @opencursor = 0
    		end
    	end
   
   return
   
   error:
       if @opencursor = 1
    		begin
    		close bAPTB_delete
    		deallocate bAPTB_delete
    		end
   
       select @errmsg = @errmsg + ' - cannot delete Payment Batch Transaction'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   /****** Object:  Trigger btAPTBi    Script Date: 8/28/99 9:36:57 AM ******/
   
     CREATE  trigger [dbo].[btAPTBi] on [dbo].[bAPTB] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: EN 10/29/98
    *  Modified: 04/22/99 GG  (SQL 7.0)
    *			GG 09/05/01 - fixed cursor fetch and bAPPB.Amount update
    *			kb 7/30/2 - issue #18112 - do manual check processing
    *			kb 7/31/2 - issue #18147 - update APPB from APDB instead of APTB
    *			GG 08/28/02 - #18395 if void, skip manual check process
	*			MV 04/03/09 - #133073 - (nolock)
    *
    * Updates Amount in Payment Batch Header (bAPPB).
    * Lock AP Transaction Header (update InUseMth and InUseBatchId in bAPTH).
    */----------------------------------------------------------------
   declare @numrows int, @errmsg varchar(255), @co bCompany, @mth bMonth, @batchid bBatchID,
   	@batchseq int, @trans bTrans, @expmth bMonth, @gross bDollar, @retg bDollar, @prevpaid bDollar,
   	@balance bDollar, @prevdisc bDollar, @disctaken bDollar, @amt bDollar,
   	@rcode int, @chktype char(1), @void bYN
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   select @rcode = 0
   
   if @numrows = 1
   	select @co = Co, @mth = Mth, @batchid = BatchId, @batchseq = BatchSeq, @trans = APTrans,
   		@expmth = ExpMth, @gross = Gross, @retg = Retainage, @prevpaid = PrevPaid,
   		@balance = Balance, @prevdisc = PrevDisc, @disctaken = DiscTaken
       from inserted
   else
     	begin
     	--  use a cursor to process each inserted row
     	declare bAPTB_insert cursor for
       select Co, Mth, BatchId, BatchSeq, APTrans, ExpMth, Gross, Retainage, PrevPaid, Balance,
   		PrevDisc, DiscTaken
       from inserted
   
     	open bAPTB_insert
     	fetch next from bAPTB_insert into @co, @mth, @batchid, @batchseq, @trans, @expmth, @gross,
   		@retg, @prevpaid, @balance, @prevdisc, @disctaken
     	if @@fetch_status <> 0
           begin
     		select @errmsg = 'Cursor error'
     		goto error
     		end
     	end
   
   insert_check:
   
   	-- lock AP Transaction Header
   	update bAPTH
   	set InUseBatchId = @batchid, InUseMth = @mth
   	where APCo = @co and Mth = @expmth and APTrans = @trans
   	if @@rowcount <> 1
       	begin
     		select @errmsg = 'Unable to flag AP transaction as ''In Use''.'
     		goto error
     		end
   
   	-- validate Payment Batch header
   	select @chktype = ChkType, @void = VoidYN
   	from bAPPB (nolock)
   	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Missing Payment Batch Header.'
   		goto error
   		end
   
   	--do processing for manual checks
   	if @chktype = 'M' and @void = 'N'	-- #18395 if void, skip manual check process
   		begin
   		exec @rcode = bspAPManualCheckProcess @co, @expmth, @batchid, @batchseq, @errmsg output
   		if @rcode <> 0 goto error
   		end
   
   if @numrows > 1
   	begin
     	fetch next from bAPTB_insert into @co, @mth, @batchid, @batchseq, @trans, @expmth, @gross,
   		@retg, @prevpaid, @balance, @prevdisc, @disctaken
     	if @@fetch_status = 0
     		goto insert_check
     	else
     		begin
     		close bAPTB_insert
     		deallocate bAPTB_insert
     		end
     	end
   
    return
   
    error:
         select @errmsg = @errmsg +  ' - cannot insert AP Payment Batch Transaction!'
         RAISERROR(@errmsg, 11, -1);
         rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btAPTBu    Script Date: 8/28/99 9:36:57 AM ******/
   CREATE      trigger [dbo].[btAPTBu] on [dbo].[bAPTB] for UPDATE as
   

/*-----------------------------------------------------------------
    *	Created : 10/30/98 EN
    *	Modified : 04/22/99 GG
   			kb 7/31/2 - issue #18147 - update APPB from APDB instead of APTB
    *			MV 10/18/02 - 18878 quoted identifier cleanup
    *
    *	This trigger rejects update in bAPTB (Payment Trans Batch)
    *	if any of the following error conditions exist:
    *
    *		Cannot change Co
    *		Cannot change Mth
    *		Cannot change BatchId
    *		Cannot change BatchSeq
    *		Cannot change ExpMth
    *		Cannot change APTrans
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* verify primary key not changed */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
   	and d.BatchSeq = i.BatchSeq and d.ExpMth = i.ExpMth
   	and d.APTrans = i.APTrans
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Primary Key'
   	goto error
   	end
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update Payment Transaction Batch!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biAPTB] ON [dbo].[bAPTB] ([Co], [Mth], [BatchId], [BatchSeq], [ExpMth], [APTrans]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPTB] ([KeyID]) ON [PRIMARY]
GO
