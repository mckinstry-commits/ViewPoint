CREATE TABLE [dbo].[bMSJP]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Quote] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[LocGroup] [dbo].[bGroup] NOT NULL,
[FromLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Material] [dbo].[bMatl] NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[MatlPhase] [dbo].[bPhase] NULL,
[MatlCostType] [dbo].[bJCCType] NULL,
[HaulPhase] [dbo].[bPhase] NULL,
[HaulCostType] [dbo].[bJCCType] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSJPd] on [dbo].[bMSJP] for DELETE as
   

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
   select 'bMSJP', ' Key: ' + convert(varchar(3),d.MSCo) + '/' + d.Quote + '/'
       + convert(varchar(3),d.LocGroup) + '/' + isnull(d.FromLoc,'') + '/' + convert(varchar(3),d.MatlGroup)
       + '/' + isnull(d.Category,'') + '/' + isnull(d.Material,'') + '/' + convert(varchar(3),d.PhaseGroup)
       + '/' + isnull(d.MatlPhase,'') + '/' + convert(varchar(3),isnull(d.MatlCostType,0)) + '/'
       + isnull(d.HaulPhase,'') + '/' + convert(varchar(3),isnull(d.HaulCostType,0)),
   	d.MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   from deleted d join bMSCO p on p.MSCo=d.MSCo
   where d.MSCo = p.MSCo and p.AuditQuotes='Y'
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete from MSJP!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSJPi] on [dbo].[bMSJP] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/27/2000
    *  Modified By: GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
    *
    *  Validates MSJP columns.
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
   
   -- validate HQ Phase Group
   select @validcnt = count(*) from inserted i join bHQGP g on
       g.Grp = i.PhaseGroup
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Phase Group'
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
   
   -- Audit inserts
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSJP', ' Key: ' + convert(char(3), i.MSCo) + '/' + i.Quote + '/'
       + convert(varchar(3),i.LocGroup) + '/' + isnull(i.FromLoc,'') + '/' + convert(varchar(3),i.MatlGroup)
       + '/' + isnull(i.Category,'') + '/' + isnull(i.Material,'') + '/' + convert(varchar(3),i.PhaseGroup) + '/'
       + isnull(i.MatlPhase,'') + '/' + convert(varchar(3),isnull(i.MatlCostType,0)) + '/' + isnull(i.HaulPhase,'') + '/'
       + convert(varchar(3),isnull(i.HaulCostType,0)),
       i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from inserted i join bMSCO c on c.MSCo = i.MSCo
   where i.MSCo = c.MSCo and c.AuditQuotes = 'Y'
   
   
   return
   
   
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert into MSJP!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSJPu] on [dbo].[bMSJP] for UPDATE as
   

/*--------------------------------------------------------------
    * Created By:  GF 03/27/2000
    * Modified By: GF 12/03/2003 - issue #23147 changes for ansi nulls
    *
    *  Update trigger for MSJP
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
   
   -- validate Phase Group
   IF UPDATE(PhaseGroup)
   BEGIN
       select @validcnt = count(*) from inserted i join bHQGP g on g.Grp = i.PhaseGroup
       if @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid Phase Group'
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
   
   -- Audit inserts
   IF UPDATE(LocGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSJP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Location Group', convert(varchar(3),d.LocGroup), convert(varchar(3),i.LocGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.LocGroup,'') <> isnull(i.LocGroup,'')
   
   
   IF UPDATE(FromLoc)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSJP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'From Location',  d.FromLoc, i.FromLoc, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.FromLoc,'') <> isnull(i.FromLoc,'')
   
   IF UPDATE(MatlGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSJP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Material Group', convert(varchar(3),d.MatlGroup),
       convert(varchar(3),i.MatlGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.MatlGroup,'') <> isnull(i.MatlGroup,'')
   
   IF UPDATE(Category)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSJP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Category',  d.Category, i.Category, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Category,'') <> isnull(i.Category,'')
   
   IF UPDATE(Material)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSJP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Material',  d.Material, i.Material, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Material,'') <> isnull(i.Material,'')
   
   IF UPDATE(PhaseGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSJP','MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Phase Group', convert(varchar(3),d.PhaseGroup),
       convert(varchar(3),i.PhaseGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.PhaseGroup,'') <> isnull(i.PhaseGroup,'')
   
   IF UPDATE(MatlPhase)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSJP','MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Material Phase', d.MatlPhase,i.MatlPhase, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.MatlPhase,'') <> isnull(i.MatlPhase,'')
   
   IF UPDATE(MatlCostType)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSJP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Material Cost Type', convert(varchar(3),isnull(d.MatlCostType,0)),
       convert(varchar(3),i.MatlCostType), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.MatlCostType,'') <> isnull(i.MatlCostType,'')
   
   IF UPDATE(HaulPhase)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSJP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Haul Phase', d.HaulPhase,i.HaulPhase, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.HaulPhase,'') <> isnull(i.HaulPhase,'')
   
   IF UPDATE(HaulCostType)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSJP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Haul Cost Type', convert(varchar(3),isnull(d.HaulCostType,0)), convert(varchar(3),i.HaulCostType), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.HaulCostType,'') <> isnull(i.HaulCostType,'')
   
   
   return
   
   
   error:
      select @errmsg = @errmsg + ' - cannot update into MSJP'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSJP] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSJP] ON [dbo].[bMSJP] ([MSCo], [Quote], [LocGroup], [FromLoc], [MatlGroup], [Category], [Material]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biMSJPSeq] ON [dbo].[bMSJP] ([MSCo], [Quote], [Seq]) ON [PRIMARY]
GO
