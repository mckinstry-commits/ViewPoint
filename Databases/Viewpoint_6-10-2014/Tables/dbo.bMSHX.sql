CREATE TABLE [dbo].[bMSHX]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Quote] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[LocGroup] [dbo].[bGroup] NOT NULL,
[FromLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Material] [dbo].[bMatl] NULL,
[TruckType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UM] [dbo].[bUM] NOT NULL,
[HaulCode] [dbo].[bHaulCode] NOT NULL,
[Override] [dbo].[bYN] NULL,
[HaulRate] [dbo].[bUnitCost] NULL,
[MinAmt] [dbo].[bDollar] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSHXd] on [dbo].[bMSHX] for DELETE as
   

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
   select 'bMSHX', ' Key: ' + convert(varchar(3),d.MSCo) + '/' + d.Quote + '/'
       + convert(varchar(3),d.LocGroup) + '/' + isnull(d.FromLoc,'') + '/' + convert(varchar(3),d.MatlGroup)
       + '/' + isnull(d.Category,'') + '/' + isnull(d.Material,'') + '/' 
   	+ isnull(d.TruckType,'') + '/' + isnull(d.UM,''),
   	d.MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   from deleted d join bMSCO p on p.MSCo = d.MSCo
   where d.MSCo = p.MSCo and p.AuditQuotes='Y'
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MSHX!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btMSHXi] on [dbo].[bMSHX] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/27/2000
    *  Modified By: GF 10/10/2000
    *				 GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
    *				 GF 03/18/2004 - issue #24038 - moved rate and minamt to bMSHO
    *
    *  Validates MSHX columns.
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
      select @errmsg = 'Invalid Quote!'
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
   select @nullcnt = count(*) from inserted where Category is null
   IF @validcnt+@nullcnt <> @numrows
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
   
   -- validate Truck Type
   select @validcnt = count(*) from inserted i join bMSTT c on
       c.MSCo = i.MSCo and c.TruckType = i.TruckType
   select @nullcnt = count(*) from inserted where TruckType is null
   if @validcnt+@nullcnt <> @numrows
       begin
       select @errmsg = 'Invalid Truck Type!'
       goto error
       end
   
   -- validate Haul Code
   select @validcnt = count(*) from inserted i join bMSHC c on
       c.MSCo = i.MSCo and c.HaulCode = i.HaulCode
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Haul Code!'
       goto error
       end
   
   -- -- -- validate Override Flag
   -- -- select @validcnt = Count(*) from inserted where Override in ('Y','N')
   -- -- if @validcnt <> @numrows
   -- --     begin
   -- --     select @errmsg = 'Invalid Override Flag!'
   -- --     goto error
   -- --     end
   -- -- 
   -- -- -- validate HaulRate is not less than zero
   -- -- select @validcnt = count(*) from inserted where HaulRate is not null and HaulRate<0
   -- -- if @validcnt > 0
   -- --     begin
   -- --     select @errmsg = 'Invalid haul rate, cannot be less than zero.'
   -- --     goto error
   -- --     end
   -- -- 
   -- -- -- validate MinAmt is not less than zero
   -- -- select @validcnt = count(*) from inserted where MinAmt is not null and MinAmt<0
   -- -- if @validcnt > 0
   -- --     begin
   -- --     select @errmsg = 'Invalid minimum amount, cannot be less than zero.'
   -- --     goto error
   -- --     end
   
   -- Audit inserts
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSHX', ' Key: ' + convert(char(3), i.MSCo) + '/' + i.Quote + '/' + convert(varchar(3),i.LocGroup)
       + '/' + isnull(i.FromLoc,'') + '/' + convert(varchar(3),i.MatlGroup) + '/' + isnull(i.Category,'') + '/'
       + isnull(i.Material,'') + '/' + isnull(i.TruckType,'') + '/' + isnull(i.UM,''),
       i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from inserted i join bMSCO c on c.MSCo = i.MSCo
   where i.MSCo = c.MSCo and c.AuditQuotes = 'Y'
   
   
   return
   
   
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert into MSHX!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE   trigger [dbo].[btMSHXu] on [dbo].[bMSHX] for UPDATE as
   

/*--------------------------------------------------------------
    * Created By:  GF 03/27/2000
    * Modified By: GF 10/10/2000
    *				GF 12/03/2003 - issue #23147 changes for ansi nulls
    *				GF 03/18/2004 - issue #24038 - moved rate and minamt to bMSHO
    *
    *
    *  Update trigger for MSHX
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
           select @errmsg = 'Invalid Location!'
           goto error
           end
   
       -- validate IN Location Group for Location
       select @validcnt = count(*) from inserted i join bINLM c on
       c.INCo = i.MSCo and c.Loc = i.FromLoc and c.LocGroup = i.LocGroup
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid Location Group for Location!'
           goto error
           end
   END
   
   -- validate HQ Material Category
   IF UPDATE(Category)
   BEGIN
       select @validcnt = count(*) from inserted i join bHQMC c on
       c.MatlGroup = i.MatlGroup and c.Category=i.Category
       select @nullcnt = count(*) from inserted where Category is null
       IF @validcnt+@nullcnt <> @numrows
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
   
   -- validate Truck Type
   IF UPDATE(TruckType)
   BEGIN
       select @validcnt = count(*) from inserted i join bMSTT c on
       c.MSCo = i.MSCo and c.TruckType = i.TruckType
       select @nullcnt = count(*) from inserted where TruckType is null
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid Truck Type!'
           goto error
           end
   END
   
   -- validate Haul Code
   IF UPDATE(HaulCode)
   BEGIN
       select @validcnt = count(*) from inserted i join bMSHC c on
       c.MSCo = i.MSCo and c.HaulCode = i.HaulCode
       if @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid Haul Code!'
           goto error
           end
   END
   
   -- -- -- validate Override Flag
   -- -- IF UPDATE(Override)
   -- -- BEGIN
   -- --     select @validcnt = Count(*) from inserted where Override in ('Y','N')
   -- --     if @validcnt <> @numrows
   -- --         begin
   -- --         select @errmsg = 'Invalid Override Flag!'
   -- --         goto error
   -- --         end
   -- -- END
   -- -- 
   -- -- -- validate HaulRate is not less than zero
   -- -- IF UPDATE(HaulRate)
   -- -- BEGIN
   -- --     select @validcnt = count(*) from inserted where HaulRate is not null and HaulRate<0
   -- --     if @validcnt > 0
   -- --         begin
   -- --         select @errmsg = 'Invalid haul rate, cannot be less than zero.'
   -- --         goto error
   -- --         end
   -- -- END
   -- -- 
   -- -- -- validate MinAmt is not less than zero
   -- -- IF UPDATE(MinAmt)
   -- -- BEGIN
   -- --     select @validcnt = count(*) from inserted where MinAmt is not null and MinAmt<0
   -- --     if @validcnt > 0
   -- --         begin
   -- --         select @errmsg = 'Invalid minimum amount, cannot be less than zero.'
   -- --         goto error
   -- --         end
   -- -- END
   
   
   -- Audit updates
   IF UPDATE(LocGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Location Group', convert(varchar(3),d.LocGroup),
       convert(varchar(3),i.LocGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.LocGroup,'') <> isnull(i.LocGroup,'') 
   
   IF UPDATE(FromLoc)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Location',  d.FromLoc, i.FromLoc, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.FromLoc,'') <> isnull(i.FromLoc,'') 
   
   IF UPDATE(MatlGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Material Group', convert(varchar(3),d.MatlGroup),
       convert(varchar(3),i.MatlGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.MatlGroup,'') <> isnull(i.MatlGroup,'') 
   
   IF UPDATE(Category)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Category',  d.Category, i.Category, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Category,'') <> isnull(i.Category,'') 
   
   IF UPDATE(Material)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Material',  d.Material, i.Material, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Material,'') <> isnull(i.Material,'') 
   
   IF UPDATE(TruckType)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Truck Type',  d.TruckType, i.TruckType, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.TruckType,'') <> isnull(i.TruckType,'') 
   
   IF UPDATE(UM)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Unit of Measure',  d.UM, i.UM, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.UM,'') <> isnull(i.UM,'') 
   
   -- -- IF UPDATE(Override)
   -- --     INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   -- -- 	SELECT 'bMSHX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
   -- --     i.MSCo, 'C', 'Material', d.Override, i.Override, getdate(), SUSER_SNAME()
   -- --     FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
   -- --     JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
   -- --     WHERE isnull(d.Override,'') <> isnull(i.Override,'') 
   -- -- 
   -- -- IF UPDATE(HaulRate)
   -- --     INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   -- -- 	SELECT 'bMSHX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
   -- --     i.MSCo, 'C', 'Haul Rate', convert(varchar(13),d.HaulRate),
   -- --     convert(varchar(13), i.HaulRate), getdate(), SUSER_SNAME()
   -- --     FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
   -- --     JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
   -- --     WHERE isnull(d.HaulRate,'') <> isnull(i.HaulRate,'') 
   -- -- 
   -- -- IF UPDATE(MinAmt)
   -- --     INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   -- -- 	SELECT 'bMSHX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
   -- --     i.MSCo, 'C', 'Minimum Amount', convert(varchar(13),d.MinAmt),
   -- --     convert(varchar(13), i.MinAmt), getdate(), SUSER_SNAME()
   -- --     FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
   -- --     JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
   -- --     WHERE isnull(d.MinAmt,'') <> isnull(i.MinAmt,'') 
   
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update into MSHX'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
ALTER TABLE [dbo].[bMSHX] WITH NOCHECK ADD CONSTRAINT [CK_bMSHX_Override] CHECK (([Override]='Y' OR [Override]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSHX] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSHX] ON [dbo].[bMSHX] ([MSCo], [Quote], [LocGroup], [FromLoc], [MatlGroup], [Category], [Material], [TruckType], [UM]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biMSHXSeq] ON [dbo].[bMSHX] ([MSCo], [Quote], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
