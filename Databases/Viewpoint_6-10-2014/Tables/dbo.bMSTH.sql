CREATE TABLE [dbo].[bMSTH]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[PriceTemplate] [smallint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[EffectiveDate] [dbo].[bDate] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btMSTHd] on [dbo].[bMSTH] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 02/26/2000
    *  Modified By:
    *
    * Validates and inserts HQ Master Audit entry.  Rolls back
    * deletion if one of the following conditions is met.
    *
    *
    * No detail records in MS Price Template detail MSTP.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   -- check MSTP - Price Template Detail
   select @validcnt = count(*)
   from bMSTP, deleted d
   where bMSTP.MSCo=d.MSCo and bMSTP.PriceTemplate=d.PriceTemplate
   if @validcnt > 0
      begin
      select @errmsg = 'Price Template Detail on file'
      goto error
      end
   
   -- Audit MS Discount Template deletions
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bMSTH','Price Template:' + convert (varchar(4),d.PriceTemplate),
       d.MSCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM deleted d JOIN bMSCO c ON d.MSCo=c.MSCo
   where c.AuditTemplates = 'Y'
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MS Price Template!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btMSTHi] on [dbo].[bMSTH] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 02/26/2000
    *  Modified By:
    *
    *  Validates MS Company.
    *  If Price Templates flagged for auditing,
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
   
   -- Audit inserts 
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bMSTH','Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM inserted i join bMSCO c on c.MSCo = i.MSCo
   where i.MSCo = c.MSCo and c.AuditTemplates = 'Y'
   
   return
   
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert MS Price Template!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSTHu] on [dbo].[bMSTH] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 02/26/2000
    *  Modified By: GG 08/09/02 - #17811 - added EffectiveDate, fix check for key changes
    *
    * Validates and inserts HQ Master Audit entry.
    *
    * Cannot change Primary key - MS Company, Price Template
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for key changes
   select @validcnt = count(*) from deleted d
       join inserted i on d.MSCo = i.MSCo and d.PriceTemplate = i.PriceTemplate
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change MS Price Template'
   	goto error
   	end
   
   -- Insert records into HQMA for changes made to audited fields
   IF UPDATE(Description)
   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
      	select 'bMSTH','MS Co#: ' + convert(char(3), i.MSCo) + ' Price Template: ' + convert(char(4), i.PriceTemplate),
      		i.MSCo, 'C','Description', d.Description, i.Description, getdate(), SUSER_SNAME()
      	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.PriceTemplate=i.PriceTemplate
      	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
      	where isnull(d.Description,'')<>isnull(i.Description,'')
   
   IF UPDATE(EffectiveDate)
   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
      	select 'bMSTH','MS Co#: ' + convert(char(3), i.MSCo) + ' Price Template: ' + convert(char(4), i.PriceTemplate),
      		i.MSCo, 'C','EffectiveDate', d.EffectiveDate, i.EffectiveDate, getdate(), SUSER_SNAME()
      	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.PriceTemplate=i.PriceTemplate
      	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
      	where isnull(d.EffectiveDate,'') <> isnull(i.EffectiveDate,'')
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update MS Price Template Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSTH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSTH] ON [dbo].[bMSTH] ([MSCo], [PriceTemplate]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
