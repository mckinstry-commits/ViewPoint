CREATE TABLE [dbo].[bMSPR]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[PayCode] [dbo].[bPayCode] NOT NULL,
[Seq] [smallint] NOT NULL,
[LocGroup] [dbo].[bGroup] NOT NULL,
[FromLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Material] [dbo].[bMatl] NULL,
[TruckType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[Truck] [dbo].[bTruck] NULL,
[UM] [dbo].[bUM] NULL,
[Zone] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PayRate] [dbo].[bUnitCost] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[MinAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bMSPR_MinAmt] DEFAULT ((0.00))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSPRd] on [dbo].[bMSPR] for DELETE as
   

/*-----------------------------------------------------------------
    * Created By:  GF 03/03/2000
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
   select 'bMSPR', ' Key: ' + convert(varchar(3),d.MSCo) + '/' + isnull(d.PayCode,'') + '/'
       + convert(varchar(3),d.LocGroup) + '/' + isnull(d.FromLoc,'') + '/' + convert(varchar(3),d.MatlGroup)
       + '/' + isnull(d.Category,'') + '/' + isnull(d.Material,'') + '/' + isnull(d.TruckType,'') + '/'
       + convert(varchar(3),d.VendorGroup) + '/' + isnull(convert(varchar(6),d.Vendor),'') + '/'
       + isnull(d.Truck,'') + '/' + isnull(d.UM,'') + '/' + isnull(d.Zone,''),
   	d.MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   from deleted d join bMSCO p on p.MSCo = d.MSCo
   where d.MSCo = p.MSCo and p.AuditPayCodes='Y'
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete Pay Rate!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSPRi] on [dbo].[bMSPR] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/03/2000
    *  Modified By: GF 10/10/2000
    *				 GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
    *
    *  Validates MSPR columns.
    *  If Pay Codes flagged for auditing, inserts HQ Master Audit entry.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @nullcnt int, @validcnt int, @numrows int
   
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
   
   -- validate Pay Code
   select @validcnt = count(*) from inserted i join bMSPC c on
       c.MSCo = i.MSCo and c.PayCode=i.PayCode
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Pay Code!'
       goto error
       end
   
   -- validate Material Group
   select @validcnt = count(*) from inserted i join bHQGP g on g.Grp = i.MatlGroup
   if @validcnt <> @numrows
       begin
   	select @errmsg = 'Invalid Material Group'
   	goto error
   	end
   
   -- validate vendor group
   select @validcnt = count(*) from inserted i join bHQGP g on g.Grp = i.VendorGroup
   if @validcnt <> @numrows
       begin
   	select @errmsg = 'Invalid Vendor Group'
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
   
   -- validate AP Vendor
   select @validcnt = count(*) from inserted i join bAPVM c on
       c.VendorGroup = i.VendorGroup and c.Vendor=i.Vendor
   select @nullcnt = count(*) from inserted where Vendor is null
   IF @validcnt + @nullcnt <> @numrows
       begin
       select @errmsg = 'Invalid AP Vendor!'
       goto error
       end
   
   -- validate Vendor Truck
   select @validcnt = count(*) from inserted i join bMSVT c on
       c.VendorGroup=i.VendorGroup and c.Vendor=i.Vendor and c.Truck=i.Truck
   select @nullcnt = count(*) from inserted where Truck is null
   if @validcnt+@nullcnt <> @numrows
       begin
       select @errmsg = 'Invalid Vendor Truck!'
       goto error
       end
   
   -- Audit inserts
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSPR', ' Key: ' + convert(char(3), i.MSCo) + '/' + i.PayCode + '/' +  convert(varchar(3),i.LocGroup)
       + '/' + isnull(i.FromLoc,' ') + '/' + convert(varchar(3),i.MatlGroup) + '/' + isnull(i.Category,' ') + '/'
       + isnull(i.Material,' ') + '/' + isnull(i.TruckType,' ') + '/' + convert(varchar(3),i.VendorGroup) + '/'
       + isnull(convert(varchar(6),i.Vendor),' ') + '/' + isnull(i.Truck,' ') + '/'
   	+ isnull(i.UM,' ') + '/' + isnull(i.Zone,' '),
       i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from inserted i join bMSCO c on c.MSCo = i.MSCo
   where i.MSCo = c.MSCo and c.AuditPayCodes = 'Y'
   
   return
   
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert into MSPR!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSPRu] on [dbo].[bMSPR] for UPDATE as
   

/*--------------------------------------------------------------
    * Created By:  GF 03/03/2000
    * Modified By: GF 10/10/2000
    *				GF 12/03/2003 - issue #23147 changes for ansi nulls
    *			   DAN SO 05/22/2008 - Issue #28688 - Add MinAmt to HQMA
    *
    *  Update trigger for MSPR
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
   
   IF UPDATE(PayCode)
       begin
       select @errmsg = 'Pay Code may not be updated'
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
   
   -- validate Vendor Group
   IF UPDATE(VendorGroup)
   BEGIN
       select @validcnt = count(*) from inserted i join bHQGP g on g.Grp = i.VendorGroup
       if @validcnt <> @numrows
   	   begin
   	   select @errmsg = 'Invalid Vendor Group'
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
       select @validcnt = count(*) from inserted i where Zone is null or Zone>''
       if @validcnt <> @numrows
           begin
           select @errmsg = 'Zone must be null or have a value!'
           goto error
           end
   END
   
   -- validate PayRate is not less than zero
   IF UPDATE(PayRate)
   BEGIN
       select @validcnt = count(*) from inserted where PayRate is not null and PayRate<0
       if @validcnt > 0
           begin
           select @errmsg = 'Invalid pay rate, cannot be less than zero.'
           goto error
           end
   END
   
   -- validate AP Vendor
   IF UPDATE(Vendor)
   BEGIN
       select @validcnt = count(*) from inserted i join bAPVM c on
       	c.VendorGroup = i.VendorGroup and c.Vendor=i.Vendor
       select @nullcnt = count(*) from inserted where Vendor is null
       IF @validcnt + @nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid AP Vendor!'
           goto error
           end
   END
   
   -- validate Vendor Truck
   IF UPDATE(Truck)
   BEGIN
       select @validcnt = count(*) from inserted i join bMSVT c on
       	c.VendorGroup=i.VendorGroup and c.Vendor=i.Vendor and c.Truck=i.Truck
       select @nullcnt = count(*) from inserted where Truck is null
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid Vendor Truck!'
           goto error
           end
   END
   
   -- Audit inserts
   IF UPDATE(LocGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSPR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C', 'Location Group', convert(varchar(3),d.LocGroup),
       convert(varchar(3),i.LocGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PayCode=i.PayCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       WHERE isnull(d.LocGroup,'') <> isnull(i.LocGroup,'')
   
   IF UPDATE(FromLoc)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSPR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C', 'From Location',  d.FromLoc, i.FromLoc, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PayCode=i.PayCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       WHERE isnull(d.FromLoc,'') <> isnull(i.FromLoc,'')
   
   IF UPDATE(MatlGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSPR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C', 'Material Group', convert(varchar(3),d.MatlGroup),
       convert(varchar(3),i.MatlGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PayCode=i.PayCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       WHERE isnull(d.MatlGroup,'') <> isnull(i.MatlGroup,'')
   
   IF UPDATE(Category)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSPR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C', 'Category',  d.Category, i.Category, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PayCode=i.PayCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       WHERE isnull(d.Category,'') <> isnull(i.Category,'')
   
   IF UPDATE(Material)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSPR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C', 'Material',  d.Material, i.Material, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PayCode=i.PayCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       WHERE isnull(d.Material,'') <> isnull(i.Material,'')
   
   IF UPDATE(VendorGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSPR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C', 'Vendor Group', convert(varchar(3),d.VendorGroup),
       convert(varchar(3),i.VendorGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PayCode=i.PayCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       WHERE isnull(d.VendorGroup,'') <> isnull(i.VendorGroup,'')
   
   IF UPDATE(Vendor)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSPR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C', 'Vendor', convert(varchar(8),d.Vendor),
       convert(varchar(8),i.Vendor), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PayCode=i.PayCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       WHERE isnull(d.Vendor,'') <> isnull(i.Vendor,'')
   
   IF UPDATE(Truck)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSPR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C', 'Truck',  d.Truck, i.Truck, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PayCode=i.PayCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       WHERE isnull(d.Truck,'') <> isnull(i.Truck,'')
   
   IF UPDATE(UM)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSPR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C', 'Unit of Measure',  d.UM, i.UM, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PayCode=i.PayCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       WHERE isnull(d.UM,'') <> isnull(i.UM,'')
   
   IF UPDATE(Zone)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSPR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C', 'Zone', d.Zone, i.Zone, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PayCode=i.PayCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       WHERE isnull(d.Zone,'') <> isnull(i.Zone,'')
   
   IF UPDATE(PayRate)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSPR', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C', 'Pay Rate', convert(varchar(10), d.PayRate),
       convert(varchar(10), i.PayRate), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PayCode=i.PayCode
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       WHERE isnull(d.PayRate,'') <> isnull(i.PayRate,'')
   
   IF UPDATE(MinAmt)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		    SELECT 'bMSPR', 'MS Co#: ' + CONVERT(varchar(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
				   i.MSCo, 'C', 'MinAmt', CONVERT(varchar(10), d.MinAmt),
		           CONVERT(VARCHAR(10), i.MinAmt), GETDATE(), SUSER_SNAME()
              FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PayCode=i.PayCode
              JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
             WHERE ISNULL(d.MinAmt,'') <> ISNULL(i.MinAmt,'')
   
   return
   
   
   error:
      select @errmsg = @errmsg + ' - cannot update into MSPR'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSPR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSPR] ON [dbo].[bMSPR] ([MSCo], [PayCode], [LocGroup], [FromLoc], [MatlGroup], [Category], [Material], [TruckType], [VendorGroup], [Vendor], [Truck], [UM], [Zone]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biMSPRSeq] ON [dbo].[bMSPR] ([MSCo], [PayCode], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
