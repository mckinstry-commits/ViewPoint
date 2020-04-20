CREATE TABLE [dbo].[bCMTT]
(
[CMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[CMTransferTrans] [dbo].[bTrans] NOT NULL,
[FromCMCo] [dbo].[bCompany] NOT NULL,
[FromCMAcct] [dbo].[bCMAcct] NOT NULL,
[FromCMTrans] [dbo].[bTrans] NULL,
[ToCMCo] [dbo].[bCompany] NOT NULL,
[ToCMAcct] [dbo].[bCMAcct] NOT NULL,
[ToCMTrans] [dbo].[bTrans] NULL,
[CMRef] [dbo].[bCMRef] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[DatePosted] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Batchid] [dbo].[bBatchID] NOT NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Purge] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biCMTT] ON [dbo].[bCMTT] ([CMCo], [Mth], [CMTransferTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bCMTT] WITH NOCHECK ADD
CONSTRAINT [FK_bCMTT_bCMCO_CMCo] FOREIGN KEY ([CMCo]) REFERENCES [dbo].[bCMCO] ([CMCo])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btCMTTd    Script Date: 8/28/99 9:37:07 AM ******/
   CREATE  trigger [dbo].[btCMTTd] on [dbo].[bCMTT] for DELETE as
   	
   

/*-----------------------------------------------------------------
    *	This trigger requires that both the transfer 'to' and 'from'
    *	CMDT entries be deleted first.
    *
    *	To delete a Transfer, both bCMDT entries must exist, and neither cleared
    *	when pulled into bCMTB.  The process proc, bspCMTBPost, will delete the
    *	bCMDT entries before deleting the Transfer.
    *
    *	To purge a Transfer, both bCMDT entries should have been cleared,
    *	and deleted when the closed Statement was purged.
    *
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int
   	
   select @numrows = @@rowcount
   set nocount on
   
   if @numrows = 0 return 
   
   /* check for 'from' CM Detail transaction */
   if exists(select * from bCMDT c, deleted d
   		where c.CMCo = d.FromCMCo and c.Mth = d.Mth and c.CMTrans = d.FromCMTrans)
   	begin
   	select @errmsg = 'Transfer (from) transaction exists.'
   	goto error
   	end
   
   /* check for 'to' CM Detail transaction */
   if exists(select * from bCMDT c, deleted d
   		where c.CMCo = d.ToCMCo and c.Mth = d.Mth and c.CMTrans = d.ToCMTrans)
   	begin
   	select @errmsg = 'Transfer (to) transaction exists.'
   	goto error
   	end
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete CM Transfer!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btCMTTi    Script Date: 8/28/99 9:37:08 AM ******/
   CREATE    trigger [dbo].[btCMTTi] on [dbo].[bCMTT] for INSERT as
   

/*--------------------------------------------------------------
    * Created: ??
    * Modified: GG 06/12/01 - Added CM Co# and Account validation
    * 		 	  DANF 03/15/05 - #27294 - Remove scrollable cursor.
				AR 12/1/2010  - #142311 - adding foreign keys, removing trigger look ups
    *
    *  Insert trigger for CMTT
    *
    *	23061 mh 3/15/04
    *
    *--------------------------------------------------------------*/
   declare @cmco bCompany, @mth bMonth, @cmtransfertrans bTrans, @fromcmco bCompany, @fromcmacct bCMAcct,
       @fromcmtrans bTrans, @tocmco bCompany, @tocmacct bCMAcct, @tocmtrans bTrans, @cmref bCMRef
   
   declare @numrows int, @emsg varchar(255), @cursoropen tinyint
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   select @cursoropen = 0
   
   if @numrows = 1
       Select @cmco=CMCo, @mth=Mth, @cmtransfertrans=CMTransferTrans, @fromcmco=FromCMCo,
           @fromcmacct=FromCMAcct, @fromcmtrans=FromCMTrans, @tocmco=ToCMCo, @tocmacct=ToCMAcct,
           @tocmtrans=ToCMTrans, @cmref=CMRef
       from inserted
   else
       begin
       /* use a cursor to process each inserted row */
       declare bCMTT_update cursor local fast_forward for
       select CMCo, Mth, CMTransferTrans, FromCMCo, FromCMAcct, FromCMTrans, ToCMCo, ToCMAcct,
           ToCMTrans, CMRef
       from inserted
   
       select @cursoropen = 1
       open bCMTT_update
   
       fetch next from bCMTT_update into @cmco, @mth, @cmtransfertrans, @fromcmco, @fromcmacct,
           @fromcmtrans, @tocmco, @tocmacct, @tocmtrans, @cmref
   
       if @@fetch_status <> 0
           begin
           select @emsg = 'Cursor error'
           goto error
           end
       end
   
   update_check:
       if not exists(select * from bCMAC where CMCo = @fromcmco and CMAcct = @fromcmacct)
           begin
           select @emsg = 'Invalid (From) CM Account: ' + convert(varchar(6),isnull(@fromcmacct, ''))
           goto error
           end
       if not exists(select * from bCMAC where CMCo = @tocmco and CMAcct = @tocmacct)
           begin
           select @emsg = 'Invalid (To) CM Account: ' + convert(varchar(6),isnull(@tocmacct, ''))
           goto error
           end
       if @fromcmco = @tocmco and @fromcmacct = @tocmacct
           begin
           select @emsg = 'Transfer (from) and (to) CM Accounts cannot be equal.'
           goto error
           end
   
     if @numrows > 1
        begin
         fetch next from bCMTT_update into
               @cmco, @mth, @cmtransfertrans, @fromcmco, @fromcmacct,
               @fromcmtrans, @tocmco, @tocmacct, @tocmtrans, @cmref
   
         if @@fetch_status = 0
            goto update_check
         else
            begin
             close bCMTT_update
             deallocate bCMTT_update
             select @cursoropen = 0
            end
        end
   
   return
   
   
   error:
      if @cursoropen= 1
         begin
          close bCMTT_update
   
          deallocate bCMTT_update
   
         end
      select @emsg=@emsg + ' - cannot insert CM Transfer Transaction.'
      RAISERROR(@emsg, 11, -1)
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btCMTTu    Script Date: 8/28/99 9:37:08 AM ******/
   CREATE  trigger [dbo].[btCMTTu] on [dbo].[bCMTT] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created:
    * Modified: 04/22/99 GG    (SQL 7.0)
    *           GG 06/12/01 - Added key change, From and To CM Co#, and CM Account validation
    *
    *	This trigger updates bCMTD (Detail) to remove InUseBatchId
    *	when changes are made to bCMTT (Transfer Transactions).
    *
    *
    */----------------------------------------------------------------
   declare @numrows int, @validcnt int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- check for key changes
   select @validcnt = count(*) from deleted d, inserted i
   where d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTransferTrans = i.CMTransferTrans
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Company, Month, or Transfer Transaction #'
   	goto error
   	end
   
   -- check for From and To CM Co# changes
   select @validcnt = count(*) from deleted d, inserted i
   where d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTransferTrans = i.CMTransferTrans
       and d.FromCMCo = i.FromCMCo and d.ToCMCo = i.ToCMCo
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change transfer (From) or (To) CM Company #'
   	goto error
   	end
   
   -- validate From and To CM Accounts
   select @validcnt = count(*)
   from bCMAC a
   join inserted i on a.CMCo = i.FromCMCo and a.CMAcct = i.FromCMAcct
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid (From) CM Account'
       goto error
       end
   select @validcnt = count(*)
   from bCMAC a
   join inserted i on a.CMCo = i.ToCMCo and a.CMAcct = i.ToCMAcct
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid (To) CM Account'
       goto error
       end
   if exists(select * from inserted where FromCMCo = ToCMCo and FromCMAcct = ToCMAcct)
       begin
       select @errmsg = 'Transfer (From) and (To) CM Accounts cannot be equal.'
       goto error
       end
   
   -- lock 'From' transactions
   update bCMDT set InUseBatchId = i.InUseBatchId
   from inserted i, bCMDT T
   where T.CMCo=i.FromCMCo and T.Mth=i.Mth and T.CMTrans=i.FromCMTrans
   
   -- lock 'To' transactions
   update bCMDT set InUseBatchId = i.InUseBatchId
   from inserted i, bCMDT T
   where T.CMCo=i.ToCMCo and T.Mth=i.Mth and T.CMTrans=i.ToCMTrans
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update CM Transfer Transactions!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bCMTT] WITH NOCHECK ADD CONSTRAINT [CK_bCMTT_ToCMAcctFromCMAcct] CHECK (([ToCMAcct]<>[FromCMAcct] OR [ToCMCo]<>[FromCMCo]))
GO
ALTER TABLE [dbo].[bCMTT] ADD CONSTRAINT [PK_bCMTT_KeyID] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO

EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bCMTT].[FromCMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bCMTT].[ToCMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bCMTT].[Purge]'
GO
