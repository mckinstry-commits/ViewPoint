CREATE TABLE [dbo].[bMSPX]
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
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[Truck] [dbo].[bTruck] NULL,
[UM] [dbo].[bUM] NOT NULL,
[PayCode] [dbo].[bPayCode] NOT NULL,
[Override] [dbo].[bYN] NOT NULL,
[PayRate] [dbo].[bUnitCost] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PayMinAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bMSPX_PayMinAmt] DEFAULT ((0.00))
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biMSPX] ON [dbo].[bMSPX] ([MSCo], [Quote], [LocGroup], [FromLoc], [MatlGroup], [Category], [Material], [TruckType], [VendorGroup], [Vendor], [Truck], [UM]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSPX] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biMSPXSeq] ON [dbo].[bMSPX] ([MSCo], [Quote], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSPXd] on [dbo].[bMSPX] for DELETE as
   

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
   select 'bMSPX', ' Key: ' + convert(varchar(3),d.MSCo) + '/' + d.Quote + '/'
       + convert(varchar(3),d.LocGroup) + '/' + isnull(d.FromLoc,'') + '/' + convert(varchar(3),d.MatlGroup)
       + '/' + isnull(d.Category,'') + '/' + isnull(d.Material,'') + '/' + isnull(d.TruckType,'') + '/'
       + convert(varchar(3),d.VendorGroup) + '/' + convert(varchar(8),isnull(d.Vendor,0)) + '/'
       + isnull(d.TruckType,'') + '/' + isnull(d.UM,''),
   	d.MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   from deleted d join bMSCO p on p.MSCo = d.MSCo
   where d.MSCo = p.MSCo and p.AuditQuotes='Y'
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MSPX!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSPXi] on [dbo].[bMSPX] for INSERT as
    

/*-----------------------------------------------------------------
     *  Created By:  GF 03/27/2000
     *  Modified By: GF 10/10/2000
     *				 GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
     *
     *  Validates MSPX columns.
     *  If Quotes flagged for auditing, inserts HQ Master Audit entry.
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
    
    -- validate Quote
    select @validcnt = count(*) from inserted i join bMSQH c on
        c.MSCo = i.MSCo and c.Quote=i.Quote
    IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Quote!'
       goto error
       end
    
    -- validate Material Group
    select @validcnt = count(*) from inserted i join bHQGP g on g.Grp = i.MatlGroup
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Material Group'
    	goto error
    	end
    
    -- validate Vendor Group
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
    
    -- validate truck type
    select @validcnt = count(*) from inserted i join bMSTT c on
        c.MSCo = i.MSCo and c.TruckType = i.TruckType
    select @nullcnt = count(*) from inserted where TruckType is null
    if @validcnt+@nullcnt <> @numrows
        begin
        select @errmsg = 'Invalid Truck Type!'
        goto error
        end
    
    -- validate vendor
    select @validcnt = count(*) from inserted i join bAPVM c on
        c.VendorGroup = i.VendorGroup and c.Vendor = i.Vendor
    select @nullcnt = count(*) from inserted where Vendor is null
    if @validcnt+@nullcnt <> @numrows
   
        begin
        select @errmsg = 'Invalid Vendor!'
        goto error
        end
    
    -- validate Vendor Truck
    select @validcnt = count(*) from inserted i join bMSVT c on
        c.VendorGroup = i.VendorGroup and c.Vendor = i.Vendor and c.Truck = i.Truck
    select @nullcnt = count(*) from inserted where Truck is null
    if @validcnt+@nullcnt <> @numrows
        begin
        select @errmsg = 'Invalid Vendor Truck!'
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
    
    -- validate Pay Code
    select @validcnt = count(*) from inserted i join bMSPC c on
        c.MSCo = i.MSCo and c.PayCode = i.PayCode
    if @validcnt <> @numrows
        begin
        select @errmsg = 'Invalid Pay Code!'
        goto error
        end
    
    -- validate Override Flag
    select @validcnt = Count(*) from inserted where Override in ('Y','N')
    if @validcnt <> @numrows
        begin
        select @errmsg = 'Invalid Override Flag!'
        goto error
        end
    
    -- validate PayRate is not less than zero
    select @validcnt = count(*) from inserted where PayRate is not null and PayRate<0
    if @validcnt > 0
        begin
        select @errmsg = 'Invalid pay rate, cannot be less than zero.'
        goto error
        end
    
   -- Audit inserts
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSPX', ' Key: ' + convert(char(3), i.MSCo) + '/' + i.Quote + '/' + convert(varchar(3),i.LocGroup)
        + '/' + isnull(i.FromLoc,'') + '/' + convert(varchar(3),i.MatlGroup) + '/' + isnull(i.Category,'') + '/'
        + isnull(i.Material,'') + '/' + isnull(i.TruckType,'') + '/' + convert(varchar(3),isnull(i.VendorGroup,0)) + '/'
        + isnull(convert(varchar(8),i.Vendor),'') + '/' + isnull(i.Truck,'') + '/' + isnull(i.UM,''),
        i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from inserted i join bMSCO c on c.MSCo = i.MSCo
   where i.MSCo = c.MSCo and c.AuditQuotes = 'Y'
    
   return
   
   
   error:
        SELECT @errmsg = @errmsg +  ' - cannot insert into MSPX!'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE     trigger [dbo].[btMSPXu] on [dbo].[bMSPX] for UPDATE as
    

/*--------------------------------------------------------------
     * Created By:  GF 03/27/2000
     * Modified By: GF 10/10/2000
     *				GF 12/03/2003 - issue #23147 changes for ansi nulls
     *				GF 06/11/2004 - issue #24801 - ansi null problem with HQMA update for PayRate
	 *			    DAN SO 05/22/2008 - Issue #28688 - Add PayMinAmt to HQMA
     *
     *
     *  Update trigger for MSPX
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
    
    -- validate vendor
    IF UPDATE(Vendor)
    BEGIN
        select @validcnt = count(*) from inserted i join bAPVM c on
        c.VendorGroup = i.VendorGroup and c.Vendor = i.Vendor
        select @nullcnt = count(*) from inserted where Vendor is null
        if @validcnt+@nullcnt <> @numrows
            begin
            select @errmsg = 'Invalid Vendor!'
            goto error
            end
    END
    
    -- validate Vendor Truck
    IF UPDATE(Truck)
    BEGIN
        select @validcnt = count(*) from inserted i join bMSVT c on
        c.VendorGroup = i.VendorGroup and c.Vendor = i.Vendor and c.Truck = i.Truck
        select @nullcnt = count(*) from inserted where Truck is null
        if @validcnt+@nullcnt <> @numrows
            begin
            select @errmsg = 'Invalid Vendor Truck!'
            goto error
            end
    END
    
    -- validate Pay Code
    IF UPDATE(PayCode)
    BEGIN
        select @validcnt = count(*) from inserted i join bMSPC c on
        c.MSCo = i.MSCo and c.PayCode = i.PayCode
        if @validcnt <> @numrows
            begin
            select @errmsg = 'Invalid Pay Code!'
           goto error
            end
    END
    
    -- validate Override Flag
    IF UPDATE(Override)
    BEGIN
        select @validcnt = Count(*) from inserted where Override in ('Y','N')
        if @validcnt <> @numrows
            begin
            select @errmsg = 'Invalid Override Flag!'
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
    
    -- Audit updates
    IF UPDATE(LocGroup)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSPX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
        i.MSCo, 'C', 'Location Group', convert(varchar(3),d.LocGroup),
        convert(varchar(3),i.LocGroup), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
        JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
        WHERE isnull(d.LocGroup,'') <> isnull(i.LocGroup,'')
    
    IF UPDATE(FromLoc)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSPX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
        i.MSCo, 'C', 'Location',  d.FromLoc, i.FromLoc, getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
        JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
        WHERE isnull(d.FromLoc,'') <> isnull(i.FromLoc,'')
    
    IF UPDATE(MatlGroup)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSPX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
        i.MSCo, 'C', 'Material Group', convert(varchar(3),d.MatlGroup),
        convert(varchar(3),i.MatlGroup), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
        JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
        WHERE isnull(d.MatlGroup,'') <> isnull(i.MatlGroup,'')
    
    IF UPDATE(Category)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSPX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
        i.MSCo, 'C', 'Category',  d.Category, i.Category, getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
        JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
        WHERE isnull(d.Category,'') <> isnull(i.Category,'')
    
    IF UPDATE(Material)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSPX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
        i.MSCo, 'C', 'Material',  d.Material, i.Material, getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
        JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
        WHERE isnull(d.Material,'') <> isnull(i.Material,'')
    
    IF UPDATE(TruckType)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSPX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
        i.MSCo, 'C', 'Truck Type',  d.TruckType, i.TruckType, getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
        JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
        WHERE isnull(d.TruckType,'') <> isnull(i.TruckType,'')
    
    IF UPDATE(VendorGroup)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSPX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
        i.MSCo, 'C', 'Vendor Group', convert(varchar(3),d.VendorGroup),
        convert(varchar(3),i.VendorGroup), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
        JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
        WHERE isnull(d.VendorGroup,'') <> isnull(i.VendorGroup,'')
    
    IF UPDATE(Vendor)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSPX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
        i.MSCo, 'C', 'Vendor', convert(varchar(8),d.Vendor),
        convert(varchar(8),i.Vendor), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
        JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
        WHERE isnull(d.Vendor,'') <> isnull(i.Vendor,'')
    
    IF UPDATE(Truck)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSPX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
        i.MSCo, 'C', 'Vendor Truck',  d.Truck, i.Truck, getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
        JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
        WHERE isnull(d.Truck,'') <> isnull(i.Truck,'')
    
    IF UPDATE(UM)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSPX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
        i.MSCo, 'C', 'Unit of Measure',  d.UM, i.UM, getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
        JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
        WHERE isnull(d.UM,'') <> isnull(i.UM,'')
    
    IF UPDATE(Override)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSPX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
        i.MSCo, 'C', 'Material', d.Override, i.Override, getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
        JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
        WHERE isnull(d.Override,'') <> isnull(i.Override,'')
    
    IF UPDATE(PayRate)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSPX', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
        i.MSCo, 'C', 'Pay Rate', convert(varchar(13),isnull(d.PayRate,0)),
        convert(varchar(13),isnull(i.PayRate,0)), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
        JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
        WHERE isnull(d.PayRate,0) <> isnull(i.PayRate,0)
    
    IF UPDATE(PayMinAmt)
        INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	     SELECT 'bMSPX', 'MS Co#: ' + CONVERT(VARCHAR(3), i.MSCo) + ' Quote: ' + i.Quote,
                    i.MSCo, 'C', 'PayMinAmt', CONVERT(VARCHAR(13),ISNULL(d.PayMinAmt,0)),
                    CONVERT(VARCHAR(13),ISNULL(i.PayMinAmt,0)), GETDATE(), SUSER_SNAME()
               FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
               JOIN bMSCO ON i.MSCo=bMSCO.MSCo AND bMSCO.AuditQuotes='Y'
              WHERE ISNULL(d.PayMinAmt,0) <> ISNULL(i.PayMinAmt,0)
    
    return
    
    
    error:
       select @errmsg = @errmsg + ' - cannot update into MSPX'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
    
   
   
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSPX].[Override]'
GO
