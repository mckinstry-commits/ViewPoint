CREATE TABLE [dbo].[bAPPT]
(
[APCo] [dbo].[bCompany] NOT NULL,
[PayType] [tinyint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PayCategory] [int] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biAPPT] ON [dbo].[bAPPT] ([APCo], [PayType]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPPT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPPTd    Script Date: 8/28/99 9:36:55 AM ******/
   CREATE  trigger [dbo].[btAPPTd] on [dbo].[bAPPT] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: GG 02/27/98
    *  Modified: GG 02/27/98
    *			MV 10/17/02 - 18878 quoted identifier cleanup. 
    *
    * Validates and inserts HQ Master Audit entry.  Rollsback deletion if
    * Payable Type exists in any AP Transaction lines.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   /* check for paytype as expense, job or retainage paytype in APCO */
   if exists (select * from deleted d
   join bAPCO c on c.APCo = d.APCo and (c.ExpPayType = d.PayType or c.JobPayType = d.PayType
   or c.SubPayType = d.PayType or c.RetPayType = d.PayType))
      begin
      select @errmsg = 'In use in company setup'
      goto error
      end
   /* check for paytype in bAPTL */
   IF EXISTS(SELECT * FROM deleted d
   JOIN bAPTL l ON l.APCo = d.APCo and l.PayType = d.PayType)
      BEGIN
      SELECT @errmsg = 'In use in AP Transactions'
      goto error
      END
   /* check for paytype in bAPRL */
   IF EXISTS(SELECT * FROM deleted d
   JOIN bAPRL l ON l.APCo = d.APCo and l.PayType = d.PayType)
      BEGIN
      SELECT @errmsg = 'In use in Recurring Invoice'
      goto error
      END
   /* Audit AP Payable Type deletions */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bAPPT','Payable Type:' + convert (varchar(3),d.PayType),
             d.APCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	JOIN bAPCO c ON d.APCo=c.APCo
           where c.AuditPayTypes = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Payable Type!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   
   
   /****** Object:  Trigger dbo.btAPPTi    Script Date: 8/28/99 9:36:55 AM ******/
   CREATE  trigger [dbo].[btAPPTi] on [dbo].[bAPPT] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: GG 02/27/98
    *  Modified: GG 02/27/98
    *			MV 10/17/02 - 18878 quoted identifier cleanup. 
    *
    * Validates AP Co# and GL Account.
    * If Pay Types flagged for auditing, inserts HQ Master Audit entry .
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int
   set nocount on
   SELECT @numrows = @@rowcount

   IF @numrows = 0 return
   SET nocount on
   /* validate GL Account  */
   SELECT @validcnt = count(*) FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLAcct
       where a.Active = 'Y' and a.AcctType <> 'H' and a.AcctType <> 'M'
       	and (a.SubType = 'P' or a.SubType is null)
   IF @validcnt <> @numrows
	BEGIN
   	SELECT @errmsg = 'Invalid GL Account'
   	GOTO error
   	END
   /* Audit inserts */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bAPPT',' Payable Type: ' + convert(varchar(3),i.PayType), i.APCo, 'A',
   		NULL, NULL, NULL, getdate(), SUSER_SNAME() FROM inserted i
   		join bAPCO c on c.APCo = i.APCo
   		where i.APCo = c.APCo and c.AuditPayTypes = 'Y'
   return
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert AP Payable Type!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btAPPTu    Script Date: 8/28/99 9:36:56 AM ******/
   CREATE  trigger [dbo].[btAPPTu] on [dbo].[bAPPT] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: GG 02/27/98
    *  Modified: EN 8/3/98
    *			MV 10/17/02 - 18878 quoted identifier. 
    *
    * Validates GL Account.
    * Cannot change primary key - APCo and Payable Type
    * If Pay Types flagged for auditing, inserts HQ Master Audit entries.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* check for key changes */
   select @validcnt = count(*) from deleted d
       join inserted i on d.APCo = i.APCo and d.PayType = i.PayType
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change AP Company or Payable Type'
   	goto error
   	end
   /* validate GL Account  */
   if update(GLCo) or update(GLAcct)
       begin
       SELECT @validcnt = count(*) FROM bGLAC a
   	   JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLAcct
           where a.AcctType <> 'H' and a.AcctType <> 'M' and a.Active = 'Y'
           	and (a.SubType = 'P' or a.SubType is null)
       IF @validcnt <> @numrows
   	   BEGIN
   	   SELECT @errmsg = 'Invalid GL Account'
   	   GOTO error
   	   END
       end
   /* Insert records into HQMA for changes made to audited fields */
   insert into bHQMA select 'bAPPT', 'Payable Type: ' + convert(char(3),i.PayType), i.APCo, 'C',
   	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.PayType = i.PayType
       join APCO a on a.APCo = i.APCo
   	where d.Description <> i.Description and a.AuditPayTypes = 'Y'
   insert into bHQMA select 'bAPPT', 'Payable Type: ' + convert(char(3),i.PayType), i.APCo, 'C',
   	'GL Company', convert(char(3),d.GLCo), Convert(char(3),i.GLCo), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on d.APCo = i.APCo and d.PayType = i.PayType
       join APCO a on a.APCo = i.APCo
   	where d.GLCo <> i.GLCo and a.AuditPayTypes = 'Y'
   insert into bHQMA select 'bAPPT', 'Payable Type: ' + convert(char(3),i.PayType), i.APCo, 'C',
   	'GL Account', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.PayType = i.PayType
       join APCO a on a.APCo = i.APCo
   	where d.GLAcct <> i.GLAcct and a.AuditPayTypes = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot update AP Payable Type!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
