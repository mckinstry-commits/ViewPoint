CREATE TABLE [dbo].[bMSHH]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[HaulTrans] [dbo].[bTrans] NOT NULL,
[FreightBill] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SaleDate] [dbo].[bDate] NOT NULL,
[HaulerType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[HaulVendor] [dbo].[bVendor] NULL,
[Truck] [dbo].[bTruck] NULL,
[Driver] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Purge] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSHH_Purge] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btMSHHd] on [dbo].[bMSHH] for DELETE as
   

/*-----------------------------------------------------------------
    * Created: GG 11/07/00
    * Modified: GF 01/16/2001 - Added purge flag
	*			DAN SO 05/18/09 - Issue: #133441 - Handle Attachment deletion differently
    *
    * Inserts HQ Master Audit entries if Hauler Time Sheets flagged for auditing.
    */----------------------------------------------------------------
   declare  @numrows int, @errmsg varchar(255), @rcode int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   --check for Haul Lines, must be deleted before Haul Header
   if (select count(*) from bMSTD t join deleted d on d.MSCo = t.MSCo and d.Mth = t.Mth and d.HaulTrans = t.HaulTrans) > 0
       begin
       select @errmsg = 'Line detail exists for Haul Transaction'
       goto error
       end
   

	-- ISSUE: #133441
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	INSERT vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		SELECT AttachmentID, suser_name(), 'Y' 
          FROM bHQAT h join deleted d 
			ON h.UniqueAttchID = d.UniqueAttchID                  
         WHERE d.UniqueAttchID IS NOT NULL  


   -- Audit HQ deletions
   insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSHH',' MS Co#:' + convert(varchar(3),d.MSCo) + ' Haul Trans#:' + convert(varchar(6),d.HaulTrans),
       d.MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   from deleted d join bMSCO c on d.MSCo = c.MSCo
   where c.AuditHaulers = 'Y' and d.Purge = 'N'
   
   return
   
   error:
       select @errmsg = @errmsg +  ' - cannot delete Hauler Time Sheet Header!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSHHi] on [dbo].[bMSHH] for INSERT as
   

/*-----------------------------------------------------------------
    * Created:	 GG 11/07/00
    * Modified: GF 12/03/2003 - issue #23147 changes for ansi nulls
    *
    * Validates critical column values
    *
    * Inserts HQ Master Audit entry if Hauler Time Sheets flagged for auditing.
    */----------------------------------------------------------------
   
   declare  @numrows int, @errmsg varchar(255), @msglco bCompany, @rcode int
   
   --bMSHH declares
   declare @msco bCompany, @mth bMonth, @haultrans bTrans, @saledate bDate, @haultype char(1),
       	@vendorgroup bGroup, @haulvendor bVendor, @truck bTruck, @driver varchar(30), 
   		@emco bCompany, @equipment bEquip, @emgroup bGroup, @prco bCompany, @employee bEmployee
   
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   SET nocount on
   
   if @numrows = 1
   	select @msco = MSCo, @mth = Mth, @haultrans = HaulTrans, @saledate = SaleDate, @haultype = HaulerType,
           @vendorgroup = VendorGroup, @haulvendor = HaulVendor, @truck = Truck, @driver = Driver, @emco = EMCo,
           @equipment = Equipment, @emgroup = EMGroup, @prco = PRCo, @employee = Employee
       from inserted
   else
       begin
   	-- use a cursor to process each inserted row
   	declare bMSHH_insert cursor LOCAL FAST_FORWARD
   	for select MSCo, Mth, HaulTrans, SaleDate, HaulerType, VendorGroup, HaulVendor, Truck, Driver, 
   			EMCo, Equipment, EMGroup, PRCo, Employee
       from inserted
   
   	open bMSHH_insert
   
       fetch next from bMSHH_insert into @msco, @mth, @haultrans, @saledate, @haultype, @vendorgroup,
   			@haulvendor, @truck, @driver, @emco, @equipment, @emgroup, @prco, @employee
   
       if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   
   insert_check:
   --validate MS Co#
   select @msglco = GLCo from bMSCO where MSCo = @msco
   if @@rowcount <> 1
   	begin
   	select @errmsg = 'Invalid MS Co#: ' + convert(varchar(3),isnull(@msco,''))
   	goto error
   	end
   
   --validate Month
   exec @rcode = dbo.bspHQBatchMonthVal @msglco, @mth, 'MS', @errmsg output
   if @rcode = 1 goto error
   
   --validate Hauler Type
   if @haultype not in ('E','H')
   	begin
   	select @errmsg = 'Invalid Hauler Type - must be (E or H)'
   	goto error
   	end
   
   --validate Equipment Haul
   if @haultype = 'E'
   	begin
   	--validate Equipment
   	if not exists(select top 1 1 from bEMEM where EMCo=@emco and Equipment=@equipment and Type<>'C' and Status='A')
   		begin
   		select @errmsg = 'Invalid or inactive Equipment: ' + isnull(@equipment,'')
   		goto error
   		end
   
   	--validate Employee
   	if @employee is not null
   		begin
   		if not exists(select top 1 1 from bPREH where PRCo = @prco and Employee = @employee)
   			begin
   			select @errmsg = 'Invalid Employee: ' + convert(varchar(6),isnull(@employee,''))
   			goto error
   			end
   		end
   
   	if @haulvendor is not null or @truck is not null
   		begin
   		select @errmsg = 'Haul Vendor and Truck must be null when Hauler Type is (E)'
   		end
   	end
   
   --validate Haul Vendor info (Truck not validated)
   if @haultype = 'H'
   	begin
   	if not exists(select top 1 1 from bAPVM where VendorGroup=@vendorgroup and Vendor=@haulvendor and ActiveYN='Y')
   		begin
   		select @errmsg = 'Invalid or inactive Haul Vendor: ' + convert(varchar(6),isnull(@haulvendor,''))
   		goto error
   		end
   
   	if @emco is not null or @equipment is not null or @employee is not null
   		begin
   		select @errmsg = 'Equipment and Employee values must be null when Hauler Type is (H)'
   		goto error
   		end
   	end
   
   
   
   if @numrows > 1
   	begin
   	fetch next from bMSHH_insert into @msco, @mth, @haultrans, @saledate, @haultype, @vendorgroup,
   			@haulvendor, @truck, @driver, @emco, @equipment, @emgroup, @prco, @employee
   	if @@fetch_status = 0 goto insert_check
   
   	close bMSHH_insert
   	deallocate bMSHH_insert
   	end
   
   
   
   -- Audit inserts
   insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSHH',' Mth: ' + convert(varchar(8),i.Mth,1) + ' HaulTrans: ' + convert(varchar(6),i.HaulTrans),
   	i.MSCo, 'A', null, null, null, getdate(), suser_sname()
   from inserted i join bMSCO c on c.MSCo = i.MSCo
   where c.AuditHaulers = 'Y'
   
   
   return
   
   
   
   error:
       select @errmsg = @errmsg +  ' - cannot insert MS Haul Header Transaction!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSHHu] on [dbo].[bMSHH] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created By:	GG 11/08/00
    * Modified By:	GF 12/03/2003 - issue #23147 changes for ansi nulls
    *    			JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
    *
    * Validates critical column values
    *
    * Inserts HQ Master Audit entries for changed values if Hauler Time Sheets flagged for auditing.
    */----------------------------------------------------------------
   declare @numrows int, @errmsg varchar(255), @msco bCompany, @mth bMonth, @haultrans bTrans, 
   		@saledate bDate, @haultype char(1), @vendorgroup bGroup, @haulvendor bVendor, 
   		@truck bTruck, @driver varchar(30), @emco bCompany, @equipment bEquip, @emgroup bGroup, 
   		@prco bCompany, @employee bEmployee
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
    --If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bMSHH', 'UniqueAttchID') = 1
	BEGIN 
		goto Trigger_Skip
	END    
   
   --check for primary key changes
   if update(MSCo)
       begin
       select @errmsg = 'Cannot change MS Co#'
       goto error
       end
   if update(Mth)
       begin
       select @errmsg = 'Cannot change Month'
       goto error
       end
   if update(HaulTrans)
       begin
       select @errmsg = 'Cannot change Haul Trans#'
       goto error
       end
   
   if @numrows = 1
   	select @msco = MSCo, @mth = Mth, @haultrans = HaulTrans, @saledate = SaleDate, @haultype = HaulerType,
           @vendorgroup = VendorGroup, @haulvendor = HaulVendor, @truck = Truck, @driver = Driver, @emco = EMCo,
           @equipment = Equipment, @emgroup = EMGroup, @prco = PRCo, @employee = Employee
       from inserted
   else
      begin
   	-- use a cursor to process each updated row
   	declare bMSHH_update cursor LOCAL FAST_FORWARD
   	for select MSCo, Mth, HaulTrans, SaleDate, HaulerType, VendorGroup, HaulVendor, Truck, Driver, 
   			EMCo, Equipment, EMGroup, PRCo, Employee
       from inserted
   
   	open bMSHH_update
   
       fetch next from bMSHH_update into @msco, @mth, @haultrans, @saledate, @haultype, @vendorgroup,
           	@haulvendor, @truck, @driver, @emco, @equipment, @emgroup, @prco, @employee
   
       if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   
   update_check:
   --validate Hauler Type
   if update(HaulerType)
       begin
       if @haultype not in ('E','H')
           begin
           select @errmsg = 'Invalid Hauler Type - must be (E or H)'
           goto error
           end
       end
   
   --validate Equipment Haul
   if @haultype = 'E'
       begin
       --validate Equipment
       if not exists(select top 1 1 from bEMEM where EMCo = @emco and Equipment = @equipment and Type <> 'C' and Status = 'A')
           begin
           select @errmsg = 'Invalid or inactive Equipment: ' + isnull(@equipment,'')
           goto error
           end
       --validate Employee
       if @employee is not null
           begin
           if not exists(select top 1 1 from bPREH where PRCo = @prco and Employee = @employee)
               begin
               select @errmsg = 'Invalid Employee: ' + convert(varchar(6),isnull(@employee,''))
               goto error
               end
           end
   
       if @haulvendor is not null or @truck is not null
           begin
           select @errmsg = 'Haul Vendor and Truck must be null when Hauler Type is (E)'
           end
       end
   
   --validate Haul Vendor info (Truck not validated)
   if @haultype = 'H'
       begin
       if not exists(select top 1 1 from bAPVM where VendorGroup = @vendorgroup and Vendor = @haulvendor and ActiveYN = 'Y')
           begin
           select @errmsg = 'Invalid or inactive Haul Vendor: ' + convert(varchar(6),isnull(@haulvendor,''))
           goto error
           end
   
       if @emco is not null or @equipment is not null or @employee is not null
           begin
           select @errmsg = 'Equipment and Employee must be null when Hauler Type is (H)'
           goto error
           end
       end
   
   -- finished with validation and updates (except HQ Audit)
   if @numrows > 1
   	begin
   	fetch next from bMSHH_update into @msco, @mth, @haultrans, @saledate, @haultype, @vendorgroup,
   			@haulvendor, @truck, @driver, @emco, @equipment, @emgroup, @prco, @employee
   	if @@fetch_status = 0 goto update_check
   
   	close bMSHH_update
   	deallocate bMSHH_update
   	end
   
   
   -- Insert records into HQMA for changes made to audited fields
   if exists(select * from inserted i join bMSCO c on i.MSCo = c.MSCo where c.AuditHaulers = 'Y')
   BEGIN
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       select 'bMSHH', ' Mth: ' + convert(char(8), i.Mth,1) + ' HaulTrans: ' + convert(varchar(6), i.HaulTrans),
           i.MSCo, 'C', 'FreightBill', d.FreightBill, i.FreightBill, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.HaulTrans = i.HaulTrans
       join bMSCO c on c.MSCo = i.MSCo
       where isnull(d.FreightBill,'') <> isnull(i.FreightBill,'') and c.AuditHaulers = 'Y'
   
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSHH', ' Mth: ' + convert(char(8), i.Mth,1) + ' Haul Trans: ' + convert(varchar(6), i.HaulTrans),
           i.MSCo, 'C', 'SaleDate', convert(char(8),d.SaleDate,1), convert(char(8),i.SaleDate,1), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.HaulTrans = i.HaulTrans
       join bMSCO c on c.MSCo = i.MSCo
       where isnull(d.SaleDate,'') <> isnull(i.SaleDate,'') and c.AuditHaulers = 'Y'
   
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSHH', ' Mth: ' + convert(char(8), i.Mth,1) + ' Haul Trans: ' + convert(varchar(6), i.HaulTrans),
           i.MSCo, 'C', 'HaulerType', d.HaulerType, i.HaulerType, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.HaulTrans = i.HaulTrans
       join bMSCO c on c.MSCo = i.MSCo
       where isnull(d.HaulerType,'') <> isnull(i.HaulerType,'') and c.AuditHaulers = 'Y'
   
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSHH', ' Mth: ' + convert(char(8), i.Mth,1) + ' HaulTrans: ' + convert(varchar(6), i.HaulTrans),
           i.MSCo, 'C', 'HaulVendor', convert(varchar(6),d.HaulVendor), convert(varchar(6),i.HaulVendor), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.HaulTrans = i.HaulTrans
       join bMSCO c on c.MSCo = i.MSCo
       where isnull(d.HaulVendor,'') <> isnull(i.HaulVendor,'') and c.AuditHaulers = 'Y'
   
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSHH', ' Mth: ' + convert(char(8), i.Mth,1) + ' HaulTrans: ' + convert(varchar(6), i.HaulTrans),
           i.MSCo, 'C', 'Truck', d.Truck, i.Truck, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.HaulTrans = i.HaulTrans
       join bMSCO c on c.MSCo = i.MSCo
       where isnull(d.Truck,'') <> isnull(i.Truck,'') and c.AuditHaulers = 'Y'
   
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSHH', ' Mth: ' + convert(char(8), i.Mth,1) + ' HaulTrans: ' + convert(varchar(6), i.HaulTrans),
           i.MSCo, 'C', 'Driver', d.Driver, i.Driver, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.HaulTrans = i.HaulTrans
       join bMSCO c on c.MSCo = i.MSCo
       where isnull(d.Driver,'') <> isnull(i.Driver,'') and c.AuditHaulers = 'Y'
   
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSHH', ' Mth: ' + convert(char(8), i.Mth,1) + ' HaulTrans: ' + convert(varchar(6), i.HaulTrans),
           i.MSCo, 'C', 'EMCo', convert(varchar(3),d.EMCo), convert(varchar(3),i.EMCo), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.HaulTrans = i.HaulTrans
       join bMSCO c on c.MSCo = i.MSCo
       where isnull(d.EMCo,'') <> isnull(i.EMCo,'') and c.AuditHaulers = 'Y'
   
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSHH', ' Mth: ' + convert(char(8), i.Mth,1) + ' HaulTrans: ' + convert(varchar(6), i.HaulTrans),
           i.MSCo, 'C', 'Equipment', d.Equipment, i.Equipment, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.HaulTrans = i.HaulTrans
       join bMSCO c on c.MSCo = i.MSCo
       where isnull(d.Equipment,'') <> isnull(i.Equipment,'') and c.AuditHaulers = 'Y'
   
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSHH', ' Mth: ' + convert(char(8), i.Mth,1) + ' HaulTrans: ' + convert(varchar(6), i.HaulTrans),
           i.MSCo, 'C', 'PRCo', convert(varchar(3),d.PRCo), convert(varchar(3),i.PRCo), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.HaulTrans = i.HaulTrans
       join bMSCO c on c.MSCo = i.MSCo
       where isnull(d.PRCo,'') <> isnull(i.PRCo,'') and c.AuditHaulers = 'Y'
   
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSHH', ' Mth: ' + convert(char(8), i.Mth,1) + ' HaulTrans: ' + convert(varchar(6), i.HaulTrans),
           i.MSCo, 'C', 'Employee', convert(varchar(6),d.Employee), convert(varchar(6),i.Employee), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.HaulTrans = i.HaulTrans
       join bMSCO c on c.MSCo = i.MSCo
       where isnull(d.Employee,'') <> isnull(i.Employee,'') and c.AuditHaulers = 'Y'
   
   END
   
   Trigger_Skip:
   
   return
   
   
   error:
       select @errmsg = @errmsg +  ' - cannot update Haul Transaction Header!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
ALTER TABLE [dbo].[bMSHH] WITH NOCHECK ADD CONSTRAINT [CK_bMSHH_Purge] CHECK (([Purge]='Y' OR [Purge]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSHH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSHH] ON [dbo].[bMSHH] ([MSCo], [Mth], [HaulTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
