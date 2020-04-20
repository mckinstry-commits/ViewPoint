CREATE TABLE [dbo].[bMSDD]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[DiscTemplate] [smallint] NOT NULL,
[Seq] [smallint] NOT NULL,
[LocGroup] [dbo].[bGroup] NOT NULL,
[FromLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Material] [dbo].[bMatl] NULL,
[UM] [dbo].[bUM] NOT NULL,
[PayDiscRate] [dbo].[bUnitCost] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSDDd] on [dbo].[bMSDD] for DELETE as
   

/*-----------------------------------------------------------------
    * Created By:  GF 03/02/2000
    * Modified By: GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
    *
    * Validates and inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   -- Audit MS Discount Template deletions
   insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSDD', ' Key: ' + convert(varchar(3),d.MSCo) + '/' 
   	+ convert(varchar(4),d.DiscTemplate) +'/' + convert(varchar(3),d.LocGroup)
       + '/' + isnull(d.FromLoc,'') + '/' + convert(varchar(3),d.MatlGroup) + '/' + isnull(d.Category,'') + '/'
       + isnull(d.Material,'') + '/' + isnull(d.UM,''),
   	d.MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   from deleted d join bMSCO p on d.MSCo=p.MSCo
   where d.MSCo=p.MSCo and p.AuditTemplates='Y'
   
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete Discount Template Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btMSDDi] on [dbo].[bMSDD] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/02/2000
    *  Modified By: GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
    *
    *  Validates MSDD columns.
    *  If Templates flagged for auditing, inserts HQ Master Audit entry.
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
   
   -- validate Discount Template
   select @validcnt = count(*) from inserted i join bMSDH c on
       c.MSCo = i.MSCo and c.DiscTemplate=i.DiscTemplate
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid MS Discount Template!'
      goto error
      end
   
   -- validate Material Group
   select @validcnt = count(*) from inserted i join bHQGP g on
       g.Grp = i.MatlGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Material Group'
   	goto error
   	end
   
   -- validate IN Location Group
   select @validcnt = count(*) from inserted i join bINLG c on
       c.INCo = i.MSCo and c.LocGroup=i.LocGroup
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid Location Group!'
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
   
   -- validate IN Location Group for Location
   select @validcnt = count(*) from inserted i join bINLM c on
       c.INCo = i.MSCo and c.Loc = i.FromLoc and c.LocGroup = i.LocGroup
   if @validcnt+@nullcnt <> @numrows
      begin
      select @errmsg = 'Invalid Location Group for From Location!'
      goto error
      end
   
   -- validate HQ Material Category
   select @validcnt = count(*) from inserted i join bHQMC c on
       c.MatlGroup = i.MatlGroup and c.Category=i.Category
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid HQ Material Category!'
      goto error
      end
   
   -- validate HQ Material
   select @validcnt = count(*) from inserted i join bHQMT c on
       c.MatlGroup = i.MatlGroup and c.Material = i.Material
   select @nullcnt = count(*) from inserted where Material is null
   if @validcnt+@nullcnt <> @numrows
      begin
      select @errmsg = 'Invalid HQ Material!'
      goto error
      end
   
   -- validate HQ Material valid for HQ Category
   select @validcnt = count(*) from inserted i join bHQMT c on
       c.MatlGroup = i.MatlGroup and c.Material = i.Material and c.Category = i.Category
   if @validcnt+@nullcnt <> @numrows
      begin
      select @errmsg = 'Invalid HQ Category assigned to HQ Material!'
      goto error
      end
   
   -- validate HQ Unit of Measure
   select @validcnt = count(*) from inserted i join bHQUM c on c.UM = i.UM
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid HQ Unit of Measure!'
      goto error
      end
   
   -- check for 'LS' unit of measure
   select @validcnt = count(*) from inserted where UM='LS'
   if @validcnt > 0
      begin
      select @errmsg = 'Invalid, unit of measure cannot be equal to (LS)'
      goto error
      end
   
   -- Audit inserts
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSDD',
       ' Key: ' + convert(char(3), i.MSCo) + '/' + convert(varchar(4),i.DiscTemplate) + '/'
       + convert(varchar(3),i.LocGroup) + '/' + isnull(i.FromLoc,'') + '/' + convert(varchar(3),i.MatlGroup) + '/'
       + isnull(i.Category,'') + '/' + isnull(i.Material,'') + '/' + isnull(i.UM,''),
       i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
       from inserted i join bMSCO c on c.MSCo = i.MSCo
       where i.MSCo = c.MSCo and c.AuditTemplates = 'Y'
   
   return
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert into MSDD!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSDDu] on [dbo].[bMSDD] for UPDATE as
   

/*--------------------------------------------------------------
    * Created By:  GF 03/02/2000
    * Modified By:	GF 12/03/2003 - issue #23147 changes for ansi nulls
    *
    *
    *  Update trigger for MSDD
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
   
   IF UPDATE(DiscTemplate)
       begin
       select @errmsg = 'Discount Template may not be updated'
       goto error
       end
   
   IF UPDATE(Seq)
       begin
       select @errmsg = 'Sequence may not be updated'
       goto error
       end
   
   -- validate Material Group
   IF UPDATE(MatlGroup)
   BEGIN
       select @validcnt = count(*) from inserted i join bHQGP g on g.Grp = i.MatlGroup
       if @validcnt <> @numrows
   	   begin
   	   select @errmsg = 'Invalid Material Group'
   	   goto error
   	   end
   END
   
   -- validate IN Location Group
   if UPDATE(LocGroup)
   BEGIN
       select @validcnt = count(*) from inserted i join bINLG c on
       c.INCo = i.MSCo and c.LocGroup=i.LocGroup
       IF @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid Location Group!'
           goto error
           end
   END
   
   -- validate IN From Location
   IF UPDATE(FromLoc)
   BEGIN
       select @validcnt = count(*) from inserted i join bINLM c on
       c.INCo = i.MSCo and c.Loc = i.FromLoc
       select @nullcnt = count(*) from inserted where FromLoc is null
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid From Location!'
           goto error
           end
   
       -- validate IN Location Group for Location
       select @validcnt = count(*) from inserted i join bINLM c on
       c.INCo = i.MSCo and c.Loc = i.FromLoc and c.LocGroup = i.LocGroup
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid Location Group for From Location!'
           goto error
           end
   END
   
   -- validate HQ Material Category
   IF UPDATE(Category)
   BEGIN
       select @validcnt = count(*) from inserted i join bHQMC c on
       c.MatlGroup = i.MatlGroup and c.Category=i.Category
       IF @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid Material Category!'
           goto error
           end
   END
   
   -- validate HQ Material
   IF UPDATE(Material)
   BEGIN
       select @validcnt = count(*) from inserted i join bHQMT c on
       c.MatlGroup = i.MatlGroup and c.Material = i.Material
       select @nullcnt = count(*) from inserted where Material is null
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid HQ Material!'
           goto error
           end
   
       -- validate HQ Material valid for HQ Category
       select @validcnt = count(*) from inserted i join bHQMT c on
       c.MatlGroup = i.MatlGroup and c.Material = i.Material and c.Category = i.Category
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid HQ Category assigned to HQ Material!'
           goto error
           end
   END
   
   -- validate HQ Unit of Measure
   IF UPDATE(UM)
   BEGIN
       select @validcnt = count(*) from inserted i join bHQUM c on c.UM = i.UM
       IF @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid HQ Unit of Measure!'
           goto error
           end
   
       select @validcnt = count(*) from inserted where UM='LS'
       if @validcnt > 0
           begin
           select @errmsg = 'Invalid, unit of measure cannot be (LS)'
           goto error
           end
   END
   
   -- Audit inserts
   IF UPDATE(LocGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSDD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Discount Template: ' + convert(varchar(4),i.DiscTemplate),
       	i.MSCo, 'C', 'Location Group', convert(varchar(3),d.LocGroup), convert(varchar(3),i.LocGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.DiscTemplate=i.DiscTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.LocGroup,'') <> isnull(i.LocGroup,'')
   
   IF UPDATE(FromLoc)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSDD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Discount Template: ' + convert(varchar(4),i.DiscTemplate),
       	i.MSCo, 'C', 'From Location',  d.FromLoc, i.FromLoc, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.DiscTemplate=i.DiscTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.FromLoc,'') <> isnull(i.FromLoc,'')
   
   IF UPDATE(MatlGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSDD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Discount Template: ' + convert(varchar(4),i.DiscTemplate),
       	i.MSCo, 'C', 'Material Group', convert(varchar(3),d.MatlGroup), convert(varchar(3),i.MatlGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.DiscTemplate=i.DiscTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.MatlGroup,'') <> isnull(i.MatlGroup,'')
   
   IF UPDATE(Category)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSDD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Discount Template: ' + convert(varchar(4),i.DiscTemplate),
   		i.MSCo, 'C', 'Category',  d.Category, i.Category, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.DiscTemplate=i.DiscTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.Category,'') <> isnull(i.Category,'')
   
   IF UPDATE(Material)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSDD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Discount Template: ' + convert(varchar(4),i.DiscTemplate),
       	i.MSCo, 'C', 'Material',  d.Material, i.Material, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.DiscTemplate=i.DiscTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.Material,'') <> isnull(i.Material,'')
   
   IF UPDATE(UM)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSDD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Discount Template: ' + convert(varchar(4),i.DiscTemplate),
       	i.MSCo, 'C', 'Unit of Measure',  d.UM, i.UM, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.DiscTemplate=i.DiscTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.UM,'')<> isnull(i.UM,'')
   
   IF UPDATE(PayDiscRate)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSDD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Discount Template: ' + convert(varchar(4),i.DiscTemplate),
       	i.MSCo, 'C', 'Pay Discount Rate', convert(varchar(10),d.PayDiscRate), convert(varchar(10), i.PayDiscRate), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.DiscTemplate=i.DiscTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.PayDiscRate,'') <> isnull(i.PayDiscRate,'')
   
   
   
   return
   
   
   error:
      select @errmsg = @errmsg + ' - cannot update into MSDD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSDD] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSDD] ON [dbo].[bMSDD] ([MSCo], [DiscTemplate], [LocGroup], [FromLoc], [MatlGroup], [Category], [Material], [UM]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biMSDDSeq] ON [dbo].[bMSDD] ([MSCo], [DiscTemplate], [Seq]) ON [PRIMARY]
GO
