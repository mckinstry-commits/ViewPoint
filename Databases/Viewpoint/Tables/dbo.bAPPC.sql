CREATE TABLE [dbo].[bAPPC]
(
[APCo] [dbo].[bCompany] NOT NULL,
[PayCategory] [int] NOT NULL,
[ExpPayType] [tinyint] NULL,
[JobPayType] [tinyint] NULL,
[SubPayType] [tinyint] NULL,
[RetPayType] [tinyint] NULL,
[DiscOffGLAcct] [dbo].[bGLAcct] NULL,
[DiscTakenGLAcct] [dbo].[bGLAcct] NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[GLCo] [tinyint] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SMPayType] [tinyint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bAPPC] ADD 
CONSTRAINT [PK_bAPPC] PRIMARY KEY CLUSTERED  ([APCo], [PayCategory]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPPC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE    trigger [dbo].[btAPPCd] on [dbo].[bAPPC] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: MV 03/04/04 
    *  Modified: 
    *
    * Validates and rolls back deletion if
    * Pay Category exists in any AP Transaction lines.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* check for pay category in APCO */
   if exists (select * from deleted d
   	join bAPCO c on c.APCo = d.APCo and d.PayCategory=c.PayCategory)
      begin
      select @errmsg = 'In use in company setup'
      goto error
      end
   /* check for pay category in bAPTD */
   if exists (SELECT * FROM deleted d
   	join bAPTD c on c.APCo = d.APCo and d.PayCategory=c.PayCategory)
      BEGIN
      SELECT @errmsg = 'In use in AP Transactions'
      goto error
      END
   /* check for paytype in bAPRL */
   if exists (SELECT * FROM deleted d
   join bAPRL c on c.APCo = d.APCo and d.PayCategory=c.PayCategory)
      BEGIN
      SELECT @errmsg = 'In use in Recurring Invoice'
      goto error
      END
   /* check for pay category in bAPUL*/
   if exists(SELECT * FROM deleted d
   	join bAPUL c on c.APCo = d.APCo and d.PayCategory=c.PayCategory)
      BEGIN
      SELECT @errmsg = 'In use in Unapproved Invoice'
      goto error
      END
   /* check for pay category in bPOIT */
   if exists (SELECT * FROM deleted d
   	join bPOIT c on c.POCo = d.APCo and d.PayCategory=c.PayCategory)
      BEGIN
      SELECT @errmsg = 'In use in PO Items'
      goto error
      END
   
   /* Audit AP Payable Category deletions */
   insert into bHQMA select 'bAPPC', 'Payable Category: ' + convert(char(10),d.PayCategory), d.APCo, 'D',
   	NULL, NULL, NULL, getdate(), SUSER_SNAME()
   	from deleted d
       join APCO a on a.APCo = d.APCo
   	where a.AuditPayTypes = 'Y'
   
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Payable Category!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   CREATE     trigger [dbo].[btAPPCi] on [dbo].[bAPPC] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: MV 03/04/04
    *  Modified: 
    *			
    *
    * Validates AP Co#.
    * If Pay Types/Pay Category flagged for auditing, inserts HQ Master Audit entry .
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int
   
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   SET nocount on
   /* validate AP Company  */
   if not exists (SELECT * FROM bAPCO a
   	JOIN inserted i ON a.APCo = i.APCo)
   	BEGIN
   	SELECT @errmsg = 'Invalid AP Company'
   	GOTO error
   	END
   /* validate GL Company  */
   if not exists (SELECT * FROM bGLCO a
   	JOIN inserted i ON a.GLCo = i.GLCo) 
   	BEGIN
   	SELECT @errmsg = 'Invalid GL Company'
   	GOTO error
   	END
   /* Audit insert */
   insert into bHQMA select 'bAPPC', 'Payable Category: ' + convert(char(10),i.PayCategory), i.APCo, 'A',
   	NULL, NULL, NULL, getdate(), SUSER_SNAME()
   	from inserted i
       join APCO a on a.APCo = i.APCo
   	where a.AuditPayTypes = 'Y'
   
   return
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert AP Payable Category!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE    trigger [dbo].[btAPPCu] on [dbo].[bAPPC] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: MV 03/04/04
    *  Modified: 
    *			
    *
    * 
    * Cannot change primary key - APCo and PayCategory.
    * Add to audit file if auditing Pay Type.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* check for key changes */
   select @validcnt = count(*) from deleted d
       join inserted i on d.APCo = i.APCo and d.PayCategory = i.PayCategory
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change AP Company or Payable Category'
   	goto error
   	end
   
   /* Insert records into HQMA for changes made to audited fields */
   insert into bHQMA select 'bAPPC', 'Payable Category: ' + convert(char(10),i.PayCategory), i.APCo, 'C',
   	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.PayCategory = i.PayCategory
       join APCO a on a.APCo = i.APCo
   	where d.Description <> i.Description and a.AuditPayTypes = 'Y'
   insert into bHQMA select 'bAPPC', 'Payable Category: ' + convert(char(3),i.PayCategory), i.APCo, 'C',
   	'Expense Pay Type', isnull(convert(char(3),d.ExpPayType),''), isnull(convert(char(3),i.ExpPayType),''), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on d.APCo = i.APCo and d.PayCategory = i.PayCategory
       join APCO a on a.APCo = i.APCo
   	where d.ExpPayType <> i.ExpPayType and a.AuditPayTypes = 'Y'
   insert into bHQMA select 'bAPPC', 'Payable Category: ' + convert(char(3),i.PayCategory), i.APCo, 'C',
   	'Job Pay Type', isnull(convert(char(3),d.JobPayType),''), isnull(convert(char(3),i.JobPayType),''), getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.PayCategory = i.PayCategory
       join APCO a on a.APCo = i.APCo
   	where d.JobPayType <> i.JobPayType and a.AuditPayTypes = 'Y'
   insert into bHQMA select 'bAPPC', 'Payable Category: ' + convert(char(3),i.PayCategory), i.APCo, 'C',
   	'Sub Pay Type', isnull(convert(char(3),d.SubPayType),''), isnull(convert(char(3),i.SubPayType),''), getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.PayCategory = i.PayCategory
       join APCO a on a.APCo = i.APCo
   	where d.SubPayType <> i.SubPayType and a.AuditPayTypes = 'Y'
   insert into bHQMA select 'bAPPC', 'Payable Category: ' + convert(char(3),i.PayCategory), i.APCo, 'C',
   	'Ret Pay Type', isnull(convert(char(3),d.RetPayType),''), isnull(convert(char(3),i.RetPayType),''), getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.PayCategory = i.PayCategory
       join APCO a on a.APCo = i.APCo
   	where d.RetPayType <> i.RetPayType and a.AuditPayTypes = 'Y'
   insert into bHQMA select 'bAPPC', 'Payable Category: ' + convert(char(10),i.PayCategory), i.APCo, 'C',
   	'Discount Offered GL Acct', d.DiscOffGLAcct, i.DiscOffGLAcct, getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.PayCategory = i.PayCategory
       join APCO a on a.APCo = i.APCo
   	where d.DiscOffGLAcct <> i.DiscOffGLAcct and a.AuditPayTypes = 'Y'
   insert into bHQMA select 'bAPPC', 'Payable Category: ' + convert(char(10),i.PayCategory), i.APCo, 'C',
   	'Discount Taken GL Acct', d.DiscTakenGLAcct, i.DiscTakenGLAcct, getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.PayCategory = i.PayCategory
       join APCO a on a.APCo = i.APCo
   	where d.DiscTakenGLAcct <> i.DiscTakenGLAcct and a.AuditPayTypes = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot update AP Payable Category!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
