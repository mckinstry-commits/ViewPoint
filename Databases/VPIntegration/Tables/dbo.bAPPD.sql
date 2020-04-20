CREATE TABLE [dbo].[bAPPD]
(
[APCo] [dbo].[bCompany] NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMRef] [dbo].[bCMRef] NOT NULL,
[CMRefSeq] [tinyint] NOT NULL,
[EFTSeq] [smallint] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[APRef] [dbo].[bAPReference] NULL,
[Description] [dbo].[bDesc] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[Gross] [dbo].[bDollar] NOT NULL,
[Retainage] [dbo].[bDollar] NOT NULL,
[PrevPaid] [dbo].[bDollar] NOT NULL,
[PrevDiscTaken] [dbo].[bDollar] NOT NULL,
[Balance] [dbo].[bDollar] NOT NULL,
[DiscTaken] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[TotTaxAmount] [dbo].[bDollar] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPPDd    Script Date: 8/28/99 9:36:55 AM ******/
   CREATE  trigger [dbo].[btAPPDd] on [dbo].[bAPPD] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 9/11/98
    *  Modified: kb 11/4/98
    *			MV 10/17/02 - 18878 quoted identifier cleanup.
    *
    * Adds entry to HQ Master Audit if APCO.AuditPay = 'Y' and
    *	APPH.PurgeYN = 'N'.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   /* Audit AP Vendor Compliance Code deletions */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bAPPD','Key: ' + convert(varchar(3), d.CMCo)
   		 + '/' + convert(varchar(4), d.CMAcct)
   		 + '/' + convert(varchar(1),d.PayMethod)
   		 + '/' + convert(varchar(10),d.CMRef)
   		 + '/' + convert(varchar(1),d.CMRefSeq)
   		 + '/' + convert(varchar(4),d.EFTSeq)
   		 + '/' + convert(varchar(8),d.Mth)
   		 + '/' + convert(varchar(6),d.APTrans),
             d.APCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	JOIN bAPCO c ON d.APCo = c.APCo
   	JOIN bAPPH h ON d.APCo = h.APCo and d.CMCo = h.CMCo and d.CMAcct = h.CMAcct
   		and d.PayMethod = h.PayMethod and d.CMRef = h.CMRef
   		and d.CMRefSeq = h.CMRefSeq and d.EFTSeq = h.EFTSeq
           where c.AuditPay = 'Y' and h.PurgeYN = 'N'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Payment Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btAPPDi    Script Date: 8/28/99 9:36:55 AM ******/
   CREATE trigger [dbo].[btAPPDi] on [dbo].[bAPPD] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: EN 09/10/98
    *  Modified: kb 11/4/98
    *
    * Reject if header in bAPPH does not exist.
    * Validates AP Trans.
    * If Pay History flagged for auditing, inserts HQ Master Audit entry .
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int
   set nocount on
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   SET nocount on
   /* check Payment Header */
   SELECT @validcnt = count(*) FROM bAPPH h
   	JOIN inserted i ON h.APCo = i.APCo and h.CMCo = i.CMCo and h.CMAcct = i.CMAcct
   		and h.PayMethod = i.PayMethod and h.CMRef = i.CMRef
   		and h.CMRefSeq = i.CMRefSeq and h.EFTSeq = i.EFTSeq
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Payment Header does not exist'
   	GOTO error
   	END
   /* validate AP Trans  */
   SELECT @validcnt = count(*) FROM bAPTH a
   	JOIN inserted i ON a.APCo = i.APCo and a.Mth = i.Mth and a.APTrans = i.APTrans
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid AP Transaction'
   	GOTO error
   	END
   /* Audit inserts */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bAPPD','Key: ' + convert(char(3), i.CMCo)
   		 + '/' + convert(char(4), i.CMAcct)
   		 + '/' + convert(char(1),i.PayMethod)
   		 + '/' + convert(varchar(10),i.CMRef)
   		 + '/' + convert(char(1),i.CMRefSeq)
   		 + '/' + convert(varchar(4),i.EFTSeq)
   		 + '/' + convert(char(8),i.Mth)
   		 + '/' + convert(varchar(6),i.APTrans), i.APCo, 'A',
   		NULL, NULL, NULL, getdate(), SUSER_SNAME() FROM inserted i
   		join bAPCO c on c.APCo = i.APCo
   		where i.APCo = c.APCo and c.AuditPay = 'Y'
   return
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert AP Payment Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btAPPDu    Script Date: 8/28/99 9:36:55 AM ******/
   CREATE  trigger [dbo].[btAPPDu] on [dbo].[bAPPD] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 9/11/98
    *  Modified: kb 11/4/98
    *		    MV 10/17/02 - 18878 quoted identifier cleanup. 	
    *
    * Cannot change primary key - APCo, CMCo, CMAcct, PayMethod,
    *	CMRef, CMRefSeq, EFTSeq, Mth, APTrans
    * If Pay History flagged for auditing, inserts HQ Master Audit entries.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* check for key changes */
   select @validcnt = count(*) from deleted d
       join inserted i on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
       	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
       	and d.EFTSeq = i.EFTSeq and d.Mth = i.Mth and d.APTrans = i.APTrans
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change key information.'
   	goto error
   	end
   /* Insert records into HQMA for changes made to audited fields */
   insert into bHQMA select 'bAPPD', 'Key: ' + convert(char(3), i.CMCo)
   		 + '/' + convert(char(4), i.CMAcct)
   		 + '/' + convert(char(1),i.PayMethod)
   		 + '/' + convert(varchar(10),i.CMRef)
   		 + '/' + convert(char(1),i.CMRefSeq)
   		 + '/' + convert(varchar(4),i.EFTSeq)
   		 + '/' + convert(char(8),i.Mth)
   		 + '/' + convert(varchar(6),i.APTrans), i.APCo, 'C',
   	'AP Ref', d.APRef, i.APRef, getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
       	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
       	and d.EFTSeq = i.EFTSeq and d.Mth = i.Mth and d.APTrans = i.APTrans
       join APCO a on a.APCo = i.APCo
   	where d.APRef <> i.APRef and a.AuditPay = 'Y'
   insert into bHQMA select 'bAPPD', 'Key: ' + convert(char(3), i.CMCo)
   		 + '/' + convert(char(4), i.CMAcct)
   		 + '/' + convert(char(1),i.PayMethod)
   		 + '/' + convert(varchar(10),i.CMRef)
   		 + '/' + convert(char(1),i.CMRefSeq)
   		 + '/' + convert(varchar(4),i.EFTSeq)
   		 + '/' + convert(char(8),i.Mth)
   		 + '/' + convert(varchar(6),i.APTrans), i.APCo, 'C',
   	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
       	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
       	and d.EFTSeq = i.EFTSeq and d.Mth = i.Mth and d.APTrans = i.APTrans
       join APCO a on a.APCo = i.APCo
   	where d.Description <> i.Description and a.AuditPay = 'Y'
   insert into bHQMA select 'bAPPD', 'Key: ' + convert(char(3), i.CMCo)
   		 + '/' + convert(char(4), i.CMAcct)
   		 + '/' + convert(char(1),i.PayMethod)
   		 + '/' + convert(varchar(10),i.CMRef)
   		 + '/' + convert(char(1),i.CMRefSeq)
   		 + '/' + convert(varchar(4),i.EFTSeq)
   		 + '/' + convert(char(8),i.Mth)
   		 + '/' + convert(varchar(6),i.APTrans), i.APCo, 'C',
   	'InvDate', d.InvDate, i.InvDate, getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
       	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
       	and d.EFTSeq = i.EFTSeq and d.Mth = i.Mth and d.APTrans = i.APTrans
       join APCO a on a.APCo = i.APCo
   	where d.InvDate <> i.InvDate and a.AuditPay = 'Y'
   insert into bHQMA select 'bAPPD', 'Key: ' + convert(char(3), i.CMCo)
   		 + '/' + convert(char(4), i.CMAcct)
   		 + '/' + convert(char(1),i.PayMethod)
   		 + '/' + convert(varchar(10),i.CMRef)
   		 + '/' + convert(char(1),i.CMRefSeq)
   		 + '/' + convert(varchar(4),i.EFTSeq)
   		 + '/' + convert(char(8),i.Mth)
   		 + '/' + convert(varchar(6),i.APTrans), i.APCo, 'C',
   	'Gross', convert(varchar(16),d.Gross), convert(varchar(16),i.Gross), getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
       	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
       	and d.EFTSeq = i.EFTSeq and d.Mth = i.Mth and d.APTrans = i.APTrans
       join APCO a on a.APCo = i.APCo
   	where d.Gross <> i.Gross and a.AuditPay = 'Y'
   insert into bHQMA select 'bAPPD', 'Key: ' + convert(char(3), i.CMCo)
   		 + '/' + convert(char(4), i.CMAcct)
   		 + '/' + convert(char(1),i.PayMethod)
   		 + '/' + convert(varchar(10),i.CMRef)
   		 + '/' + convert(char(1),i.CMRefSeq)
   		 + '/' + convert(varchar(4),i.EFTSeq)
   		 + '/' + convert(char(8),i.Mth)
   		 + '/' + convert(varchar(6),i.APTrans), i.APCo, 'C',
   	'Retainage', convert(varchar(16),d.Retainage), convert(varchar(16),i.Retainage), getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
       	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
       	and d.EFTSeq = i.EFTSeq and d.Mth = i.Mth and d.APTrans = i.APTrans
       join APCO a on a.APCo = i.APCo
   	where d.Retainage <> i.Retainage and a.AuditPay = 'Y'
   insert into bHQMA select 'bAPPD', 'Key: ' + convert(char(3), i.CMCo)
   		 + '/' + convert(char(4), i.CMAcct)
   		 + '/' + convert(char(1),i.PayMethod)
   		 + '/' + convert(varchar(10),i.CMRef)
   		 + '/' + convert(char(1),i.CMRefSeq)
   		 + '/' + convert(varchar(4),i.EFTSeq)
   		 + '/' + convert(char(8),i.Mth)
   		 + '/' + convert(varchar(6),i.APTrans), i.APCo, 'C',
   	'PrevPaid', convert(varchar(16),d.PrevPaid), convert(varchar(16),i.PrevPaid), getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
       	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
       	and d.EFTSeq = i.EFTSeq and d.Mth = i.Mth and d.APTrans = i.APTrans
       join APCO a on a.APCo = i.APCo
   	where d.PrevPaid <> i.PrevPaid and a.AuditPay = 'Y'
   insert into bHQMA select 'bAPPD', 'Key: ' + convert(char(3), i.CMCo)
   		 + '/' + convert(char(4), i.CMAcct)
   		 + '/' + convert(char(1),i.PayMethod)
   		 + '/' + convert(varchar(10),i.CMRef)
   		 + '/' + convert(char(1),i.CMRefSeq)
   		 + '/' + convert(varchar(4),i.EFTSeq)
   		 + '/' + convert(char(8),i.Mth)
   		 + '/' + convert(varchar(6),i.APTrans), i.APCo, 'C',
   	'PrevDiscTaken', convert(varchar(16),d.PrevDiscTaken), convert(varchar(16),i.PrevDiscTaken), getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
       	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
       	and d.EFTSeq = i.EFTSeq and d.Mth = i.Mth and d.APTrans = i.APTrans
       join APCO a on a.APCo = i.APCo
   	where d.PrevDiscTaken <> i.PrevDiscTaken and a.AuditPay = 'Y'
   insert into bHQMA select 'bAPPD', 'Key: ' + convert(char(3), i.CMCo)
   		 + '/' + convert(char(4), i.CMAcct)
   		 + '/' + convert(char(1),i.PayMethod)
   		 + '/' + convert(varchar(10),i.CMRef)
   		 + '/' + convert(char(1),i.CMRefSeq)
   		 + '/' + convert(varchar(4),i.EFTSeq)
   		 + '/' + convert(char(8),i.Mth)
   		 + '/' + convert(varchar(6),i.APTrans), i.APCo, 'C',
   	'Balance', convert(varchar(16),d.Balance), convert(varchar(16),i.Balance), getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
       	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
       	and d.EFTSeq = i.EFTSeq and d.Mth = i.Mth and d.APTrans = i.APTrans
       join APCO a on a.APCo = i.APCo
   	where d.Balance <> i.Balance and a.AuditPay = 'Y'
   insert into bHQMA select 'bAPPD', 'Key: ' + convert(char(3), i.CMCo)
   		 + '/' + convert(char(4), i.CMAcct)
   		 + '/' + convert(char(1),i.PayMethod)
   		 + '/' + convert(varchar(10),i.CMRef)
   		 + '/' + convert(char(1),i.CMRefSeq)
   		 + '/' + convert(varchar(4),i.EFTSeq)
   		 + '/' + convert(char(8),i.Mth)
   		 + '/' + convert(varchar(6),i.APTrans), i.APCo, 'C',
   	'DiscTaken', convert(varchar(16),d.DiscTaken), convert(varchar(16),i.DiscTaken), getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
       	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
       	and d.EFTSeq = i.EFTSeq and d.Mth = i.Mth and d.APTrans = i.APTrans
       join APCO a on a.APCo = i.APCo
   	where d.DiscTaken <> i.DiscTaken and a.AuditPay = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot update Payment Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biAPPD] ON [dbo].[bAPPD] ([APCo], [CMCo], [CMAcct], [PayMethod], [CMRef], [CMRefSeq], [EFTSeq], [Mth], [APTrans]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPPD] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bAPPD].[CMAcct]'
GO
