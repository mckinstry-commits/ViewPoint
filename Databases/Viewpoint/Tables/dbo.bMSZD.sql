CREATE TABLE [dbo].[bMSZD]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Quote] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[FromLoc] [dbo].[bLoc] NOT NULL,
[Zone] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biMSZD] ON [dbo].[bMSZD] ([MSCo], [Quote], [FromLoc]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSZD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE   trigger [dbo].[btMSZDd] on [dbo].[bMSZD] for DELETE as
   

/*-----------------------------------------------------------------
    * Created By:  GF 03/27/2000
    * Modified By: GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
    *
    * Validates and inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   -- Audit deletions
   insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSZD', ' Key: ' + convert(varchar(3),d.MSCo) + '/' + d.Quote +'/' + isnull(d.FromLoc,''),
   	d.MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   from deleted d join bMSCO p on p.MSCo = d.MSCo
   where d.MSCo = p.MSCo and p.AuditQuotes='Y'
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete from MSZD!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE trigger [dbo].[btMSZDi] on [dbo].[bMSZD] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/27/2000
    *  Modified By: GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
    *
    *  Validates MSZD columns.
    *  If Quotes flagged for auditing, inserts HQ Master Audit entry.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @nullcnt int, @validcnt int, @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- validate MS Company
   select @validcnt = count(*) from inserted i join bMSCO c
       on c.MSCo = i.MSCo
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid MS company!'
      goto error
      end
   
   -- validate Quote
   select @validcnt = count(*) from inserted i join bMSQH c on
       c.MSCo = i.MSCo and c.Quote=i.Quote
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid MS Quote!'
      goto error
      end
   
   -- validate IN From Location
   select @validcnt = count(*) from inserted i join bINLM c on
       c.INCo = i.MSCo and c.Loc = i.FromLoc
   select @nullcnt = count(*) from inserted where FromLoc is null
   if @validcnt+@nullcnt <> @numrows
      begin
      select @errmsg = 'Invalid From Location!'
      goto error
      end
   
   -- Audit inserts
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSZD',
       ' Key: ' + convert(char(3), i.MSCo) + '/' + i.Quote + '/' + isnull(i.FromLoc,''),
       i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
       from inserted i join bMSCO c on c.MSCo = i.MSCo
       where i.MSCo = c.MSCo and c.AuditQuotes = 'Y'
   
   return
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert into MSZD!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSZDu] on [dbo].[bMSZD] for UPDATE as
   

/*--------------------------------------------------------------
    * Created By:  GF 03/27/2000
    * Modified By:
    *
    *  Update trigger for MSZD
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int, @nullcnt int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for key changes
   IF UPDATE(MSCo)
       begin
       select @errmsg = 'MSCo may not be updated'
       goto error
       end
   
   IF UPDATE(Quote)
       begin
       select @errmsg = 'Quote may not be updated'
       goto error
       end
   
   IF UPDATE(FromLoc)
       begin
       select @errmsg = 'From Location may not be updated'
       goto error
       end
   
   -- validate IN From Location
   IF UPDATE(FromLoc)
   BEGIN
       select @validcnt = count(*) from inserted i join bINLM c on
       c.INCo = i.MSCo and c.Loc = i.FromLoc
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid From Location!'
           goto error
           end
   END
   
   -- Audit inserts
   IF UPDATE(Zone)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSZD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       	i.MSCo, 'C', 'Zone', d.Zone, i.Zone, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote and d.FromLoc=i.FromLoc
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Zone,'') <> isnull(i.Zone,'')
   
   
   return
   
   
   error:
      select @errmsg = @errmsg + ' - cannot update into MSZD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
  
 



GO
