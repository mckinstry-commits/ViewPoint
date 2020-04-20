CREATE TABLE [dbo].[bMSHR]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[HaulCode] [dbo].[bHaulCode] NOT NULL,
[Seq] [smallint] NOT NULL,
[LocGroup] [dbo].[bGroup] NOT NULL,
[FromLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Material] [dbo].[bMatl] NULL,
[TruckType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UM] [dbo].[bUM] NULL,
[Zone] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[HaulRate] [dbo].[bUnitCost] NOT NULL,
[MinAmt] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE  trigger [dbo].[btMSHRd] on [dbo].[bMSHR] for DELETE as
    

/*-----------------------------------------------------------------
     * Created By:  GF 03/02/2000
     * Modified By: GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
     *				 DANF 06/30/2005 - Issue #29177 - Missing isnull around From Location.
     * Validates and inserts HQ Master Audit entry.
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int
    
    select @numrows = @@rowcount
    set nocount on
    if @numrows = 0 return
    
    -- Audit MS Haul Rate deletions
    insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    select 'bMSHR', ' Key: ' + convert(varchar(3),d.MSCo) + '/' + d.HaulCode + '/'
        + convert(varchar(3),d.LocGroup) + '/' + isnull(d.FromLoc,'') + '/' + convert(varchar(3),d.MatlGroup)
        + '/' + isnull(d.Category,'') + '/' + isnull(d.Material,'') + '/' 
    	+ isnull(d.TruckType,'') + '/' + isnull(d.UM,'') + '/' + isnull(d.Zone,''),
    	d.MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
    from deleted d join bMSCO p on p.MSCo = d.MSCo
    where d.MSCo = p.MSCo and p.AuditHaulCodes='Y'
    
    
    return
    
    
    error:
    	select @errmsg = @errmsg + ' - cannot delete Haul Rate!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSHRi] on [dbo].[bMSHR] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/02/2000
    *  Modified By: GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
    *
    *  Validates MSHR columns.
    *  If Haul Codes flagged for auditing, inserts HQ Master Audit entry.
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
   
   -- validate Haul Code
   select @validcnt = count(*) from inserted i join bMSHC c on
       c.MSCo = i.MSCo and c.HaulCode=i.HaulCode
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Haul Code!'
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
   
   -- validate Truck Type
   select @validcnt = count(*) from inserted i join bMSTT t on
       t.MSCo = i.MSCo and t.TruckType = i.TruckType
   select @nullcnt = count(*) from inserted where TruckType is null
   if @validcnt + @nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid Truck Type'
           goto error
           end
   
   -- validate HQ Unit of Measure
   select @validcnt = count(*) from inserted i join bHQUM c on c.UM = i.UM
   select @nullcnt = count(*) from inserted where UM is null
   IF @validcnt + @nullcnt <> @numrows
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
   IF @validcnt + @nullcnt <> @numrows
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
   
   -- validate Zone
   select @validcnt = count(*) from inserted i where Zone is null or Zone>''
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Zone must be null or have a value!'
       goto error
       end
   
   -- Audit inserts
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSHR', ' Key: ' + convert(char(3), i.MSCo) + '/' + i.HaulCode + '/' +  convert(varchar(3),i.LocGroup)
       + '/' + isnull(i.FromLoc,'') + '/' + convert(varchar(3),i.MatlGroup) + '/' + isnull(i.Category,'') + '/'
       + isnull(i.Material,'') + '/' + isnull(i.TruckType,'') + '/' + isnull(i.UM,'') + '/' + isnull(i.Zone,''),
       i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from inserted i join bMSCO c on c.MSCo = i.MSCo
   where i.MSCo = c.MSCo and c.AuditHaulCodes = 'Y'
   
   return
   
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert into MSHR!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSHRu] on [dbo].[bMSHR] for UPDATE as
   

/*--------------------------------------------------------------
    * Created By:  GF 03/02/2000
    * Modified By: GF 10/10/2000
    *				GF 12/03/2003 - issue #23147 changes for ansi nulls
    *
    *
    *  Update trigger for MSHR
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
   
   IF UPDATE(HaulCode)
       begin
       select @errmsg = 'Haul Code may not be updated'
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
   
   -- validate Truck Type
   if UPDATE(TruckType)
   BEGIN
       select @validcnt = count(*) from inserted i join bMSTT t on
       t.MSCo = i.MSCo and t.TruckType = i.TruckType
       select @nullcnt = count(*) from inserted where TruckType is null
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid Truck Type!'
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
       select @nullcnt = count(*) from inserted where UM is null
       IF @validcnt+@nullcnt <> @numrows
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
   
   -- validate Zone
   IF UPDATE(Zone)
   BEGIN
       select @validcnt = count(*) from inserted i where Zone is null or Zone > ''
       if @validcnt <> @numrows
           begin
           select @errmsg = 'Zone must be null or have a value!'
           goto error
           end
   END
   
   -- validate HaulRate and MinAmt are not less than zero
   IF UPDATE(HaulRate)
   BEGIN
       select @validcnt = count(*) from inserted where HaulRate is not null and HaulRate<0
       if @validcnt > 0
           begin
           select @errmsg = 'Invalid haul rate, cannot be less than zero.'
           goto error
           end
   END
   IF UPDATE(MinAmt)
   BEGIN
       select @validcnt = count(*) from inserted where MinAmt is not null and MinAmt<0
       if @validcnt > 0
           begin
           select @errmsg = 'Invalid minimum amount, cannot be less than zero.'
           goto error
           end
   END
   
   -- Audit inserts
   IF UPDATE(LocGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       	i.MSCo, 'C', 'Location Group', convert(varchar(3),d.LocGroup),
       convert(varchar(3),i.LocGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.HaulCode=i.HaulCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       WHERE isnull(d.LocGroup,'') <> isnull(i.LocGroup,'')
   
   IF UPDATE(FromLoc)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       i.MSCo, 'C', 'From Location',  d.FromLoc, i.FromLoc, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.HaulCode=i.HaulCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       WHERE isnull(d.FromLoc,'') <> isnull(i.FromLoc,'')
   
   IF UPDATE(MatlGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       i.MSCo, 'C', 'Material Group', convert(varchar(3),d.MatlGroup),
       convert(varchar(3),i.MatlGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.HaulCode=i.HaulCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       WHERE isnull(d.MatlGroup,'') <> isnull(i.MatlGroup,'')
   
   IF UPDATE(Category)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       i.MSCo, 'C', 'Category',  d.Category, i.Category, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.HaulCode=i.HaulCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       WHERE isnull(d.Category,'') <> isnull(i.Category,'')
   
   IF UPDATE(Material)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       i.MSCo, 'C', 'Material',  d.Material, i.Material, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.HaulCode=i.HaulCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       WHERE isnull(d.Material,'') <> isnull(i.Material,'')
   
   IF UPDATE(UM)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       i.MSCo, 'C', 'Unit of Measure',  d.UM, i.UM, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.HaulCode=i.HaulCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       WHERE isnull(d.UM,'') <> isnull(i.UM,'')
   
   IF UPDATE(Zone)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       i.MSCo, 'C', 'Zone', d.Zone, i.Zone, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.HaulCode=i.HaulCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       WHERE isnull(d.Zone,'') <> isnull(i.Zone,'')
   
   IF UPDATE(HaulRate)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       i.MSCo, 'C', 'Haul Rate', convert(varchar(10), d.HaulRate),
       convert(varchar(10), i.HaulRate), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.HaulCode=i.HaulCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       WHERE isnull(d.HaulRate,'') <> isnull(i.HaulRate,'')
   
   IF UPDATE(MinAmt)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSHR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       i.MSCo, 'C', 'Minimum Amount', convert(varchar(10), d.MinAmt),
       convert(varchar(10), i.MinAmt), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.HaulCode=i.HaulCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       WHERE isnull(d.MinAmt,'') <> isnull(i.MinAmt,'')
   
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update into MSHR'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSHR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSHR] ON [dbo].[bMSHR] ([MSCo], [HaulCode], [LocGroup], [FromLoc], [MatlGroup], [Category], [Material], [TruckType], [UM], [Zone]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biMSHRSeq] ON [dbo].[bMSHR] ([MSCo], [HaulCode], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
