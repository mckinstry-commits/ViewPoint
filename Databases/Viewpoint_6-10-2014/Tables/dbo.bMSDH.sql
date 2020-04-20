CREATE TABLE [dbo].[bMSDH]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[DiscTemplate] [smallint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSDHd] on [dbo].[bMSDH] for DELETE as
   

/*-----------------------------------------------------------------
    * Created By:  GF 02/20/2000
    * Modified By:
    *
    * Validates and inserts HQ Master Audit entry.  Rolls back
    * deletion if one of the following conditions is met.
    *
    *
    * No detail records in MS Discount Template detail MSDD.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   -- check MSDD - Discount Template Detail
   select @validcnt = count(*) from bMSDD join deleted d 
   	on d.MSCo = bMSDD.MSCo and d.DiscTemplate = bMSDD.DiscTemplate
   if @validcnt > 0
      begin
      select @errmsg = 'Discount Template Detail on file'
      goto error
      end
   
   -- Audit MS Discount Template deletions
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bMSDH','Discount Template:' + convert (varchar(4),d.DiscTemplate), d.MSCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM deleted d JOIN bMSCO c ON d.MSCo=c.MSCo
   where c.AuditTemplates = 'Y'
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MS Discount Template!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btMSDHi] on [dbo].[bMSDH] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 02/20/2000
    *  Modified By:
    *
    *  Validates MS Company.
    *  If Discount Templates flagged for auditing,
    *  inserts HQ Master Audit entry .
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- validate MS Company
   select @validcnt = count(*) from inserted i join bMSCO c on c.MSCo = i.MSCo
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid MS company!'
      goto error
      end
   
   /* Audit inserts */
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bMSDH','Discount Template: ' + convert(varchar(4),i.DiscTemplate), i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM inserted i join bMSCO c on c.MSCo = i.MSCo
   where i.MSCo = c.MSCo and c.AuditTemplates = 'Y'
   
   return
   
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert MS Discount Template!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSDHu] on [dbo].[bMSDH] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created By:  GF 02/24/2000
    * Modified By:	GF 12/03/2003 - issue #23147 changes for ansi nulls
    *
    *
    * Validates and inserts HQ Master Audit entry.
    *
    * Cannot change Primary key - MS Company, Discount Template
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   
   if @numrows = 0 return
   set nocount on
   
   -- check for key changes
   select @validcnt = count(*) from deleted d join inserted i on d.MSCo = i.MSCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change MS Company'
   	goto error
   	end
   
   -- check for key changes
   select @validcnt = count(*) from deleted d
       join inserted i on d.MSCo = i.MSCo and d.DiscTemplate = i.DiscTemplate
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change MS Discount Template'
   	goto error
   	end
   
   -- Insert records into HQMA for changes made to audited fields
   IF UPDATE(Description)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSDH','MS Co#: ' + convert(char(3), i.MSCo) + ' Discount Template: ' + convert(char(4), i.DiscTemplate),
   		i.MSCo, 'C','Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.DiscTemplate=i.DiscTemplate
   	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
   	where isnull(d.Description,'') <> isnull(i.Description,'')
   
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update MS Discount Template Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSDH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSDH] ON [dbo].[bMSDH] ([MSCo], [DiscTemplate]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
