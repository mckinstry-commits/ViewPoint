CREATE TABLE [dbo].[bCMDT]
(
[CMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[CMTrans] [dbo].[bTrans] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[StmtDate] [dbo].[bDate] NULL,
[CMTransType] [dbo].[bCMTransType] NOT NULL,
[SourceCo] [dbo].[bCompany] NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[PostedDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ClearedAmt] [dbo].[bDollar] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[CMRef] [dbo].[bCMRef] NOT NULL,
[CMRefSeq] [tinyint] NOT NULL,
[Payee] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CMTransferTrans] [dbo].[bTrans] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[CMGLAcct] [dbo].[bGLAcct] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[Void] [dbo].[bYN] NOT NULL,
[ClearDate] [dbo].[bDate] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Purge] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btCMDTd    Script Date: 8/28/99 9:37:05 AM ******/
   CREATE   trigger [dbo].[btCMDTd] on [dbo].[bCMDT] for DELETE as
   

/*-----------------------------------------------------------------
    *	This trigger rejects deletion from bCMDT (Details) if any of
    *	the following error conditions exist:
    *
    *		Entries to be deleted are cleared - must be purged with Statement
    *              Entries to be purged are outstanding - must be deleted from Detail Batch
    *
    *		23061 mh 3/15/04
    *		133433 JonathanP 05/28/09 - Added attachment deletion code.
    *
    *		Updates HQ Master Audit for deletions only.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   if exists(select * from deleted	where Purge = 'N' and StmtDate is not null)
   	begin
   	select @errmsg = 'Entry has been cleared, must be purged with its closed Statement'
   	goto error
   	end
   if exists(select * from deleted	where Purge = 'Y' and StmtDate is null)
   	begin
   	select @errmsg = 'Entry is has not been cleared, must be deleted from an Outstanding Entry batch.'
   	goto error
   	end
   	
   	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		select AttachmentID, suser_name(), 'Y' 
		from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
		where d.UniqueAttchID is not null    
	   	
   /* Audit CM Detail deletions - skip purges */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bCMDT', 'Mth: ' + convert(varchar(12), isnull(d.Mth, '')) + ' Trans#: ' + convert(varchar(8),isnull(d.CMTrans, '')),
   		d.CMCo, 'D', null, null, null, getdate(), SUSER_SNAME() from deleted d, bCMCO c
   		where d.CMCo = c.CMCo and c.AuditDetail = 'Y' and d.Purge = 'N'
   return         
   error:
   	select @errmsg = @errmsg + ' - cannot delete CM Transaction!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btCMDTi    Script Date: 8/28/99 9:37:06 AM ******/
   CREATE  trigger [dbo].[btCMDTi] on [dbo].[bCMDT] for insert as
   

/******************************************************************************
    * Created: ??
    * Modified: GG 03/13/02 - corrected batch validation logic
    *			 GF 08/08/2003 - issue #21933 - speed improvements
    *			23061 mh 3/15/04
				AR 12/1/2010  - #142311 - adding foreign keys, removing trigger look ups
    *
    *	This trigger rejects inserts in bCMDT (Details) if any
    *      of the following error conditions exist:
    *
    *           Invalid CM Company
    *           Invalid CM Account
    *           Statement Date or Cleared Date not null, Cleared Amt not zero
    *           Invalid BatchId - must match Source
    *           CM Reference and Seq not unique by CM Company, CM Account, and Type
    *           Transfer transaction specified with wrong Type
    *           Invalid CM GL Account - all entries - Sub Ledger type must be 'C' or null
    *           Invalid posted GL Account - CM Source, except Transfers - Sub Ledger type must be null
    *           InUseBatchId is not null
    *
    *	Add bHQMA if AuditDetail in bCMCO is 'Y'
    *
    ********************************************************************************/
   declare @errmsg varchar(255), @numrows int, @validcnt int, @notnullcnt int,
   		@nonpostacct tinyint, @subtype tinyint, @inactive tinyint, @acct bGLAcct
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   -- validate Statement Date - must be null
   if exists(select 1 from inserted where StmtDate is not null)
   	begin
   	select @errmsg = 'Statement Date must be null'
   	goto error
   	end
   
   -- validate Cleared Amount - must be 0
   if exists(select 1 from inserted where ClearedAmt <> 0)
   	begin
   	select @errmsg = 'Cleared Amount must be 0.00'
   	goto error
   	end
   
   -- validate HQ Batch
   select @validcnt = count(*) from bHQBC b with (nolock)
   join inserted i on b.Co = i.SourceCo and b.Mth = i.Mth and b.BatchId = i.BatchId
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid HQ Batch'
   	goto error
   	end
   

   /* check for Transfer Transaction
   if exists(select * from inserted where CMTransType = 3 and CMTransferTrans is null)
   	begin
   	select @errmsg = 'Transfers must have Transfer transaction'
   	goto error
   	end
   *** not checked because of conflicts with bCMTT */
   
   if exists(select 1 from inserted where CMTransType <> 3 and CMTransferTrans is not null)
   	begin
   	select @errmsg = 'Only Transfers may have Transfer transactions'
   	goto error
   	end
   
   -- all entries must have a valid CM GL Account
   select @validcnt = count(*),
   	   @nonpostacct = sum(case when g.AcctType in ('H','M') then 1 else 0 end),
   	   @subtype = sum(case when g.SubType not in ('C', null) then 1 else 0 end),
   	   @inactive = sum(case when g.Active = 'N' then 1 else 0 end),
   	   @acct = max(g.GLAcct)
   from bGLAC g with (nolock), inserted i where g.GLCo = i.GLCo and g.GLAcct = i.CMGLAcct
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid CM GL Account'
   	goto error
   	end
   if @nonpostacct <> 0
   	begin
   	select @errmsg = 'CM GL Account ' + isnull(@acct,'') + ' cannot be a Heading or Memo account'
   	goto error
   	end
   if @subtype <> 0
   	begin
   	select @errmsg = 'CM GL Account Sub Ledger type must be (C) or null'
   	goto error
   	end
   if @inactive <> 0
   	begin
   	select @errmsg = 'CM GL Account is inactive'
   	goto error
   	end
   
   -- check Posted GL Account - should not be null for CM sources, except Transfers
   if exists(select 1 from inserted where GLAcct is null and Source like 'CM%' and CMTransType <> 3)
   	begin
   	select @errmsg = 'Missing posted GL Account'
   	goto error
   	end
   
   if exists(select 1 from inserted where GLAcct is not null and (Source not like 'CM%' or CMTransType = 3))
   	begin
   	select @errmsg = 'Should not include posted GL Account'
   	goto error
   	end
   
   -- validate posted GL Account
   select @notnullcnt = count(*) from inserted where GLAcct is not null
   select @validcnt = count(*),
   	   @nonpostacct = IsNull(sum(case when g.AcctType in ('H','M') then 1 else 0 end),0),
   	   @subtype = IsNull(sum(case when g.SubType is not null then 1 else 0 end),0),
   	   @inactive = IsNull(sum(case when g.Active = 'N' then 1 else 0 end),0)
   from bGLAC g with (nolock), inserted i where g.GLCo = i.GLCo and g.GLAcct = i.GLAcct
   if @validcnt <> @notnullcnt
   	begin
   	select @errmsg = 'Invalid posted GL Account'
   	goto error
   	end
   if @nonpostacct <> 0
   	begin
   	select @errmsg = 'Posted GL Account cannot be a Heading or Memo account'
   	goto error
   	end
   if @subtype <> 0
   	begin
   	select @errmsg = 'Posted GL Account Sub Ledger type must be null'
   	goto error
   	end
   if @inactive <> 0
   	begin
   	select @errmsg = 'Posted GL Account is inactive'
   	goto error
   	end
   
   -- check Cleared Date - must be null
   if exists(select 1 from inserted where ClearDate is not null)
   	begin
   	select @errmsg = 'Cleared Date must be null'
   	goto error
   	end
   
   -- check InUseBatchId - must be null
   if exists(select 1 from inserted where InUseBatchId is not null)
   	begin
   	select @errmsg = 'In Use Batch ID must be null'
   	goto error
   	end
   
   
   -- Audit CM Detail Transaction inserts
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bCMDT', 'Mth: ' + convert(varchar(12),isnull(i.Mth,'')) + ' Trans#: ' + convert(varchar(8),isnull(i.CMTrans, '')),
   	i.CMCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i, bCMCO c with (nolock)
   	where i.CMCo = c.CMCo and c.AuditDetail = 'Y'
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert CM Detail Transaction!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
  
  /****** Object:  Trigger dbo.btCMDTu    Script Date: 8/28/99 9:38:20 AM ******/
     CREATE         trigger [dbo].[btCMDTu] on [dbo].[bCMDT] for UPDATE as
     


/***************************************************************
* Created: ??
* Modified: GG 5/19/00 - Issue 6865 - added biCMDTCMRefUnique index to enforce CM Ref/RefSeq uniqueness
*                      - Rewritten to improve validation
*            GG 7/20/00 - fixed Working Balance update to bCMST
*            DanF 7/31/00 - Fixed clear date of 1/1/100
*            DANF 03/27/02 - Do not validate GL accounts if they do not change.
*			mh 23061 3/15/04
*			mh 29761 9/20/05 - Arithmetic overflow error.  Need to expand conversion of Amount and Cleared 
*							 Amount from varchar(12) to varchar(20)
*			mh 124423 9/27/07 - Issue 124423
*		AR 12/1/2010  - #142311 - adding foreign keys, removing trigger look ups
*			CHS 04/22/2011	- B-03437 - add TaxCode column		
*
*	Update trigger on CM Detail
***************************************************************/
     declare @numrows int, @validcnt int, @validcnt1 int, @errmsg varchar(255), @opencursor tinyint
   
     -- CMDT declares
     declare @cmco bCompany, @oldcmacct bCMAcct, @newcmacct bCMAcct, @oldstmtdate bDate, @newstmtdate bDate,
     @oldamount bDollar, @newamount bDollar, @oldvoid bYN, @newvoid bYN
   
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on

	--If updating the Purge flag, we do not want to execute the remaining code - Issue 124423
	if update(Purge)
	begin
		return
	end
   
     --check for changes to primary key
     select @validcnt = count(*) from deleted d, inserted i
     	where d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     if @numrows <> @validcnt
     	begin
     	select @errmsg = 'Cannot change CM Co#, Month, or CM Trans#'
     	goto error
     	end
  
     -- check for changes to Trans Type, Source Co#, or Source
     select @validcnt = count(*) from inserted i
         join deleted d on i.CMCo = d.CMCo and i.Mth = d.Mth and i.CMTrans = d.CMTrans
         where i.CMTransType = d.CMTransType and i.SourceCo = d.SourceCo and i.Source = d.Source
     if @numrows <> @validcnt
     	begin
     	select @errmsg = 'Cannot change CM Trans Type, Source Co#, or Source'
     	goto error
     	end
     --check for change to Amount if Cleared
     if exists(select * from inserted i
             join deleted d on i.CMCo = d.CMCo and i.Mth = d.Mth and i.CMTrans = d.CMTrans
             where i.StmtDate is not null and i.Amount <> d.Amount)
         begin
         select @errmsg = 'Cannot change Amount on a Cleared entry'
         goto error
         end
     --check for Cleared Amts on an uncleared entry
     if exists(select * from inserted i
             join deleted d on i.CMCo = d.CMCo and i.Mth = d.Mth and i.CMTrans = d.CMTrans
             where i.StmtDate is null and i.ClearedAmt <> 0)
         begin
         select @errmsg = 'Cleared Amount must be 0.00 until entry is assigned a Statement Date'
         goto error
         end
     --check for change to Void status if Cleared
     if exists(select * from inserted i
             join deleted d on i.CMCo = d.CMCo and i.Mth = d.Mth and i.CMTrans = d.CMTrans
             where i.StmtDate is not null and i.Void <> d.Void)
         begin
         select @errmsg = 'Cannot change Void status on Cleared entry'
         goto error
         end
     --validate Statement Date
     select @validcnt = count(*) from inserted where StmtDate is not null
     select @validcnt1 = count(*) from inserted i
         join bCMST s on i.CMCo = s.CMCo and i.CMAcct = s.CMAcct and i.StmtDate = s.StmtDate
     if @validcnt <> @validcnt1
         begin
         select @errmsg = 'Invalid Statement Date'
         goto error
         end
     --check that Statement is Open on newly Cleared entries
     if exists(select * from inserted i
         join deleted d on i.CMCo = d.CMCo and i.Mth = d.Mth and i.CMTrans = d.CMTrans
         join bCMST s on i.CMCo = s.CMCo and i.CMAcct = s.CMAcct and i.StmtDate = s.StmtDate
         where i.StmtDate is not null and d.StmtDate is null and s.Status <> 0)
         begin
         select @errmsg = 'New cleared entries can only be assigned an Open Statement Date'
         goto error
         end
     --check for change in Statement Dates
     if exists(select * from inserted i
         join deleted d on i.CMCo = d.CMCo and i.Mth = d.Mth and i.CMTrans = d.CMTrans
         where i.StmtDate is not null and d.StmtDate is not null and (i.StmtDate <> d.StmtDate))
         begin
         select @errmsg = 'Cannot change Statement Date on a cleared entry'
         goto error
         end
     --check that Transfer Trans have cross reference trans
     if exists(select * from inserted where CMTransType = 3 and CMTransferTrans is null)
         begin
         select @errmsg = 'Transfer entries must reference a Transfer transaction'
         goto error
         end
     --check that non Transfer Trans have null cross reference trans
     if exists(select * from inserted where CMTransType <> 3 and CMTransferTrans is not null)
         begin
         select @errmsg = 'Adjustment, Checks, Deposits, and EFTs cannot reference a Transfer transaction'
         goto error
         end
     --validate Posted GL Account
     if update(GLAcct)
       begin
       select @validcnt = count(*) from inserted where GLAcct is null
       select @validcnt1 = count(*) from inserted i
         join bGLAC a on i.GLCo = a.GLCo and i.GLAcct = a.GLAcct
         where a.AcctType not in ('H','M') and a.SubType is null and a.Active = 'Y'
       if @validcnt + @validcnt1 <> @numrows
         begin
         select @errmsg = 'Posted GL Account is invalid'
         goto error
         end
        end
     --validate CM Acct GL Account
     if update(CMGLAcct)
        begin
        select @validcnt = count(*) from inserted i
         join bCMCO c on i.CMCo = c.CMCo
         join bGLAC a on c.GLCo = a.GLCo and i.CMGLAcct = a.GLAcct
         where a.AcctType not in ('H','M') and (a.SubType is null or a.SubType = 'C') and a.Active = 'Y'
        if @validcnt <> @numrows
         begin
         select @errmsg = 'CM GL Account is invalid'
         goto error
         end
        end
   --passed validation - update Statement Working Balance
   declare bCMDT_update cursor for select i.CMCo, d.CMAcct, i.CMAcct,
       d.StmtDate, i.StmtDate, d.Amount, i.Amount, d.Void, i.Void
   from deleted d
   join inserted i on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
   
   open bCMDT_update
   select @opencursor = 1
   
   CMDT_loop:
       fetch next from bCMDT_update into @cmco, @oldcmacct, @newcmacct, @oldstmtdate, @newstmtdate,
           @oldamount, @newamount, @oldvoid, @newvoid
   
       if @@fetch_status <> 0 goto CMDT_end
   
       --back out 'old'
       if @oldamount <> 0 and @oldvoid = 'N' and @oldstmtdate is not null
           begin
           update bCMST
           set WorkBal = WorkBal - @oldamount
           where CMCo = @cmco and CMAcct = @oldcmacct and StmtDate = @oldstmtdate
           end
   
       --add in 'new'
       if @newamount <> 0 and @newvoid = 'N' and @newstmtdate is not null
           begin
           update bCMST
           set WorkBal = WorkBal + @newamount
           where CMCo = @cmco and CMAcct = @newcmacct and StmtDate = @newstmtdate
           end
   
       goto CMDT_loop  -- get next entry
   
       CMDT_end:
           close bCMDT_update
     		deallocate bCMDT_update
     		select @opencursor = 0
   
     -- Insert records into HQMA for changes made to audited fields
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), i.Mth) + ' CMTrans: ' + convert(varchar(6), i.CMTrans),
         i.CMCo, 'C', 'CMAcct', convert(varchar(6),isnull(d.CMAcct, '')), convert(varchar(6),isnull(i.CMAcct, '')), getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where d.CMAcct <> i.CMAcct and c.AuditDetail = 'Y'
   
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth, '')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans, '')),
         i.CMCo, 'C', 'StmtDate', convert(varchar(8),d.StmtDate), convert(varchar(8),i.StmtDate), getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where d.StmtDate <> i.StmtDate and c.AuditDetail = 'Y'
   
     --cannot change CMTransType, SourceCo, or Source - no need to audit
   
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth, '')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans, '')),
         i.CMCo, 'C', 'ActDate', convert(varchar(8),d.ActDate), convert(varchar(8),i.ActDate), getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where d.ActDate <> i.ActDate and c.AuditDetail = 'Y'
   
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth, '')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans, '')),
         i.CMCo, 'C', 'PostedDate', convert(varchar(8),d.PostedDate), convert(varchar(8),i.PostedDate), getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where d.PostedDate <> i.PostedDate and c.AuditDetail = 'Y'
   
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth, '')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans, '')),
         i.CMCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where isnull(d.Description,'') <> isnull(i.Description,'') and c.AuditDetail = 'Y'
   
   -- begin 29761
   /*
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth,'')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans,'')),
         i.CMCo, 'C', 'Amount', convert(varchar(12),d.Amount), convert(varchar(12),i.Amount), getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where d.Amount <> i.Amount and c.AuditDetail = 'Y'
   */
   
   
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth,'')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans,'')),
         i.CMCo, 'C', 'Amount', convert(varchar(20),d.Amount), convert(varchar(20),i.Amount), getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where d.Amount <> i.Amount and c.AuditDetail = 'Y'
   
   
   /*
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth,'')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans,'')),
         i.CMCo, 'C', 'ClearedAmt', convert(varchar(12),d.ClearedAmt), convert(varchar(12),i.ClearedAmt), getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where d.ClearedAmt <> i.ClearedAmt and c.AuditDetail = 'Y'
   */
  
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth,'')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans,'')),
         i.CMCo, 'C', 'ClearedAmt', convert(varchar(20),d.ClearedAmt), convert(varchar(20),i.ClearedAmt), getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where d.ClearedAmt <> i.ClearedAmt and c.AuditDetail = 'Y'
  
  --end 29761 
  
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth,'')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans,'')),
         i.CMCo, 'C', 'BatchId', convert(varchar(6),d.BatchId), convert(varchar(6),i.BatchId), getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where d.BatchId <> i.BatchId and c.AuditDetail = 'Y'
   
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth,'')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans,'')),
         i.CMCo, 'C', 'CMRef', d.CMRef, i.CMRef, getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where d.CMRef <> i.CMRef and c.AuditDetail = 'Y'
   
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth,'')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans,'')),
         i.CMCo, 'C', 'CMRefSeq', convert(varchar(3),d.CMRefSeq), convert(varchar(3),i.CMRefSeq), getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where d.CMRefSeq <> i.CMRefSeq and c.AuditDetail = 'Y'
   
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth,'')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans,'')),
         i.CMCo, 'C', 'Payee', d.Payee, i.Payee, getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where isnull(d.Payee,'') <> isnull(i.Payee,'') and c.AuditDetail = 'Y'
   
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth,'')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans,'')),
   
         i.CMCo, 'C', 'GLAcct', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where isnull(d.GLAcct,'') <> isnull(i.GLAcct,'') and c.AuditDetail = 'Y'
   
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth,'')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans,'')),
         i.CMCo, 'C', 'Void', d.Void, i.Void, getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where d.Void <> i.Void and c.AuditDetail = 'Y'
   
     insert bHQMA select 'bCMDT', ' Mth: ' + convert(char(8), isnull(i.Mth,'')) + ' CMTrans: ' + convert(varchar(6), isnull(i.CMTrans,'')),
         i.CMCo, 'C', 'CleartDate', convert(varchar(8),d.ClearDate), convert(varchar(8),i.ClearDate), getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where isnull(d.ClearDate,'1/1/00') <> isnull(i.ClearDate,'1/1/00') and c.AuditDetail = 'Y'
     
     
	insert bHQMA 
	select 'bCMDT', 
		' Mth: ' + convert(char(8), 
		isnull(i.Mth,'')) + ' CMTrans: ' + convert(varchar(6), 
		isnull(i.CMTrans,'')),
        i.CMCo, 
        'C', 
        'TaxCode', 
        convert(varchar(8),
        d.TaxCode), 
        convert(varchar(8),
        i.TaxCode), 
        getdate(), 
        SUSER_SNAME()
     from inserted i
     join deleted d on d.CMCo = i.CMCo and d.Mth = i.Mth and d.CMTrans = i.CMTrans
     join bCMCO c on c.CMCo = i.CMCo
     where isnull(d.TaxCode,'1/1/00') <> isnull(i.TaxCode,'1/1/00') and c.AuditDetail = 'Y'
          
   
   if @opencursor = 1
       begin
     	close bCMDT_update
     	deallocate bCMDT_update
   	end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update CM Detail Transaction!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  
  
 





GO
CREATE UNIQUE NONCLUSTERED INDEX [biCMDTCMRefUnique] ON [dbo].[bCMDT] ([CMCo], [CMAcct], [CMTransType], [CMRef], [CMRefSeq]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biCMDT] ON [dbo].[bCMDT] ([CMCo], [Mth], [CMTrans]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biCMDTCMRef] ON [dbo].[bCMDT] ([CMRef]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bCMDT] WITH NOCHECK ADD CONSTRAINT [FK_bCMDT_bCMAC_CMCoCMAcct] FOREIGN KEY ([CMCo], [CMAcct]) REFERENCES [dbo].[bCMAC] ([CMCo], [CMAcct])
GO
ALTER TABLE [dbo].[bCMDT] WITH NOCHECK ADD CONSTRAINT [FK_bCMDT_bHQBC_SourceCoBatchID] FOREIGN KEY ([SourceCo], [Mth], [BatchId]) REFERENCES [dbo].[bHQBC] ([Co], [Mth], [BatchId])
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bCMDT].[CMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bCMDT].[Void]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bCMDT].[Purge]'
GO
