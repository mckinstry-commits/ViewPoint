CREATE TABLE [dbo].[bAPDB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[ExpMth] [dbo].[bMonth] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[APLine] [smallint] NOT NULL,
[APSeq] [tinyint] NOT NULL,
[PayType] [tinyint] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[DiscTaken] [dbo].[bDollar] NOT NULL,
[PayCategory] [int] NULL,
[TotTaxAmount] [dbo].[bDollar] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biAPDB] ON [dbo].[bAPDB] ([Co], [Mth], [BatchId], [BatchSeq], [ExpMth], [APTrans], [APLine], [APSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btAPDBd    Script Date: 8/28/99 9:36:57 AM ******/
   
   CREATE          trigger [dbo].[btAPDBd] on [dbo].[bAPDB] for DELETE as
   

/*--------------------------------------------------------------
    *	Created : EN 11/1/98
    *	Modified : GG 4/30/99
    *  Modified : kb 5/3/00 - issue #6649. When clear void out of payment batch and
    *    it was originally a processed prepaid, need to set PrePaidProcYN = 'Y'
    *				kb 7/30/2 - issue #18112 - do manual check processing
   			kb 7/31/2 - issue #18147 - update APPB from APDB instead of APTB
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
   @rcode int, @openAPDB tinyint, @apline int, @apseq int
   
   select @numrows = @@rowcount
   
   if @numrows = 0 return
   
   set nocount on
   
   select @rcode = 0
   
   
   -- back out 'deleted' amounts from Net Amount in Payment Batch Header
   declare bAPDB_delete cursor for
   select Co, Mth, BatchId, BatchSeq, APTrans, ExpMth, 
   	APLine, APSeq
       from deleted
   
   open bAPDB_delete
   select @openAPDB = 1
   
   APDBLoop:
   fetch next from bAPDB_delete into @co, @mth, @batchid, @batchseq, @aptrans, @expmth, 
   	@apline, @apseq
   
   if @@fetch_status <> 0 goto APDBLoop_end
   
   -- update amounts from Net Amount in Payment Batch Header
   update dbo.bAPPB
   set Amount = p.Amount - (d.Amount - d.DiscTaken)
   from dbo.bAPPB p
   join deleted d on d.Co = p.Co and d.Mth = p.Mth and d.BatchId = p.BatchId
   and d.BatchSeq = p.BatchSeq 
   where p.Co = @co and p.Mth = @mth and p.BatchId = @batchid and p.BatchSeq = @batchseq
   and d.APTrans = @aptrans and d.ExpMth = @expmth and d.APLine = @apline and d.APSeq = @apseq
   
   goto APDBLoop
   
   APDBLoop_end:
   	select @openAPDB = 0
   	close bAPDB_delete
   	deallocate bAPDB_delete
   
   
   return
   
   error:
   
       select @errmsg = @errmsg + ' - cannot delete Payment Batch Transaction'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   
   
   
   /****** Object:  Trigger btAPDBi    Script Date: 8/28/99 9:36:53 AM ******/
   CREATE          trigger [dbo].[btAPDBi] on [dbo].[bAPDB] for INSERT as
   

/*--------------------------------------------------------------
    *	Created : EN 8/26/98
    *	Modified : EN 8/26/98
   			kb 7/31/2 - issue #18147 - update APPB from APDB instead of APTB
    *			MV 10/17/02 - 18878 quoted identifier cleanup.
	*			MV 04/03/09 - added  & with (nolock)
    *
    *	Check that header entry in APTB exists.
    *	Validate that line APLine and APSeq exist in APTL and APTD.
    *--------------------------------------------------------------*/
   
   declare @numrows int, @errmsg varchar(255), @validcnt int, @openAPDB tinyint, 
     @co bCompany, @mth bMonth, @expmth bMonth, @batchid bBatchID, @batchseq int, 
     @trans bTrans, @apline int, @apseq int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check APTB */
	select @validcnt = count(*) from bAPTB b with (nolock) 
	join inserted i	on b.Co=i.Co and b.Mth=i.Mth and b.BatchId=i.BatchId
   	and b.BatchSeq=i.BatchSeq and b.ExpMth=i.ExpMth and b.APTrans=i.APTrans
--   select @validcnt = count(*) from bAPTB b, inserted i
--   	where b.Co=i.Co and b.Mth=i.Mth and b.BatchId=i.BatchId
--   	and b.BatchSeq=i.BatchSeq and b.ExpMth=i.ExpMth and b.APTrans=i.APTrans
   if @validcnt = 0
   	begin
   	select @errmsg = 'AP Transaction Batch entry does not exist'
   	goto error
   	end
   
   /* validate APLine in APTL */
	select @validcnt = count(*) from bAPTL g with (nolock) 
	join inserted i	on i.Co = g.APCo and i.ExpMth = g.Mth and i.APTrans = g.APTrans
		and i.APLine = g.APLine
--   select @validcnt = count(*) from bAPTL g , inserted i
--   	where i.Co = g.APCo and i.ExpMth = g.Mth and i.APTrans = g.APTrans and i.APLine = g.APLine
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'AP Transaction Line does not exist'
   	goto error
   	end
   
   /* validate APLine and APSeq in APTD */
	select @validcnt = count(*) from bAPTD g with (nolock)
	join inserted i on i.Co = g.APCo and i.ExpMth = g.Mth and i.APTrans = g.APTrans
		and i.APLine = g.APLine	and i.APSeq = g.APSeq
--   select @validcnt = count(*) from bAPTD g, inserted i
--   	where i.Co = g.APCo and i.ExpMth = g.Mth and i.APTrans = g.APTrans and i.APLine = g.APLine
--   	and i.APSeq = g.APSeq
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'AP Transaction Detail does not exist'
   	goto error
   	end
   
   -- update amounts from Net Amount in Payment Batch Header
   declare bAPDB_insert cursor for
   select Co, Mth, BatchId, BatchSeq, APTrans, ExpMth, 
   	APLine, APSeq from inserted
   
   select @openAPDB = 1
   open bAPDB_insert
   
   APDBLoop:
   
   fetch next from bAPDB_insert into @co, @mth, @batchid, @batchseq, @trans, @expmth, 
   	@apline, @apseq
   
   if @@fetch_status <> 0 goto APDBLoop_end
   
   -- update amounts from Net Amount in Payment Batch Header
   update bAPPB
   set Amount = p.Amount + (i.Amount - i.DiscTaken)
   from bAPPB p
   join inserted i on i.Co = p.Co and i.Mth = p.Mth and i.BatchId = p.BatchId
   and i.BatchSeq = p.BatchSeq 
   where p.Co = @co and p.Mth = @mth and p.BatchId = @batchid and p.BatchSeq = @batchseq
   and i.APTrans = @trans and i.ExpMth = @expmth and i.APLine = @apline and i.APSeq = @apseq
   
   goto APDBLoop
   
   APDBLoop_end:
   if @openAPDB = 1 
   	begin
   	select @openAPDB = 0
   	close bAPDB_insert
   	deallocate bAPDB_insert
     	end
   
   
   
   return
   
   error:
   
      select @errmsg = @errmsg + ' - cannot insert AP Payment Detail Batch entry'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   
   
   
   /****** Object:  Trigger btAPDBu    Script Date: 8/28/99 9:36:53 AM ******/
   CREATE          trigger [dbo].[btAPDBu] on [dbo].[bAPDB] for UPDATE as
   

/*-----------------------------------------------------------------
    *	Created : 8/26/98 EN
    *	Modified : 8/26/98 EN
   			kb 7/31/2 - issue #18147 - update APPB from APDB instead of APTB
    *			MV 10/17/02 - 18878 quoted identifier cleanup.
    *
    *	This trigger rejects update in bAPDB (Payment Detail Batch)
    *	if any of the following error conditions exist:
    *
    *		Cannot change Co
    *		Cannot change Mth
    *		Cannot change BatchId
    *		Cannot change BatchSeq
    *		Cannot change ExpMth
    *		Cannot change APTrans
    *		Cannot change APLine
    *		Cannot change APSeq
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int,
     @openAPDB tinyint, @co bCompany, @mth bMonth, @batchid bBatchID, 
     @batchseq int, @expmth bMonth, @trans bTrans, @apline int, @apseq int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* verify primary key not changed */
   select @validcnt = count(*) from deleted d 
	join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
   	and d.BatchSeq = i.BatchSeq and d.ExpMth = i.ExpMth
   	and d.APTrans = i.APTrans and d.APLine = i.APLine and d.APSeq = i.APSeq
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Primary Key'
   	goto error
   	end
   
   declare bAPDB_insert cursor for
   select Co, Mth, BatchId, BatchSeq, APTrans, ExpMth, 
   	APLine, APSeq
       from inserted
   
   select @openAPDB = 1
   open bAPDB_insert
   
   APDBLoop:
   
   fetch next from bAPDB_insert into @co, @mth, @batchid, @batchseq, @trans, @expmth, 
   	@apline, @apseq
   
   if @@fetch_status <> 0 goto APDBLoop_end
   
   -- update amounts from Net Amount in Payment Batch Header
   update bAPPB
   set Amount = p.Amount - (d.Amount - d.DiscTaken)
    + (i.Amount - i.DiscTaken)
   from bAPPB p
   join inserted i on i.Co = p.Co and i.Mth = p.Mth and i.BatchId = p.BatchId
   and i.BatchSeq = p.BatchSeq 
   join deleted d on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId 
   and i.BatchSeq = d.BatchSeq and i.APTrans = d.APTrans and i.APLine = d.APLine
   and i.APSeq = d.APSeq
   where p.Co = @co and p.Mth = @mth and p.BatchId = @batchid and p.BatchSeq = @batchseq
   and i.APTrans = @trans and i.ExpMth = @expmth and i.APLine = @apline and i.APSeq = @apseq
   
   goto APDBLoop
   
   APDBLoop_end:
   if @openAPDB = 1 
   	begin
   	select @openAPDB = 0
   	close bAPDB_insert
   	deallocate bAPDB_insert
     	end
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update AP Payment Detail Batch!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
