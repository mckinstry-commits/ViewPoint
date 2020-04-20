CREATE TABLE [dbo].[vPOPendingPurchaseOrder]
(
[POCo] [dbo].[bCompany] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[ExpDate] [dbo].[bDate] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[OrderDate] [dbo].[bDate] NULL,
[OrderedBy] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[HoldCode] [dbo].[bHoldCode] NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[CompGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ShipLoc] [dbo].[bShipLoc] NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ShipIns] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Attention] [dbo].[bDesc] NULL,
[PayAddressSeq] [tinyint] NULL,
[POAddressSeq] [tinyint] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtPOPendingPurchaseOrderd] on [dbo].[vPOPendingPurchaseOrder] for DELETE as
/*********************************************************
* Created:		GP 3/22/12
* Modified: 
*
* Delete trigger for Pending Purchase Order
*
***********************************************************/
declare @errmsg varchar(255)

set nocount on

begin try

	--insert audit record
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(d.POCo as varchar(3)) + ' PO: ' + d.PO, d.POCo, 'D', NULL, NULL, NULL, getdate(), suser_sname()
	from deleted d

end try


begin catch

	select @errmsg = @errmsg + ' - cannot delete PO Penindg Purchase Order'
	RAISERROR(@errmsg, 11, -1);
	
end catch



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtPOPendingPurchaseOrderi] on [dbo].[vPOPendingPurchaseOrder] for INSERT as
/*********************************************************
* Created:		GP 3/22/12
* Modified: 
*
* Insert trigger for Pending Purchase Order
*
***********************************************************/
declare @errmsg varchar(255)

set nocount on

begin try

	--insert audit record
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'A', NULL, NULL, NULL, getdate(), suser_sname()
	from inserted i

end try


begin catch

	select @errmsg = @errmsg + ' - cannot insert PO Penindg Purchase Order'
	RAISERROR(@errmsg, 11, -1);
	
end catch



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[vtPOPendingPurchaseOrderu] on [dbo].[vPOPendingPurchaseOrder] for UPDATE as
/*********************************************************
* Created:		GP 3/22/12
* Modified: 
*
* Update trigger for Pending Purchase Order
*
***********************************************************/
declare @errmsg varchar(255)

set nocount on

begin try

	if update(VendorGroup)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'VendorGroup', d.VendorGroup, i.VendorGroup, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(Vendor)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'Vendor', d.Vendor, i.Vendor, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update([Description])
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'Description', d.[Description], i.[Description], getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(ExpDate)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'ExpDate', d.ExpDate, i.ExpDate, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(JCCo)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'JCCo', d.JCCo, i.JCCo, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(Job)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'Job', d.Job, i.Job, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(INCo)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'INCo', d.INCo, i.INCo, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(Loc)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'Loc', d.Loc, i.Loc, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(OrderDate)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'OrderDate', d.OrderDate, i.OrderDate, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(OrderedBy)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'OrderedBy', d.OrderedBy, i.OrderedBy, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(HoldCode)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'HoldCode', d.HoldCode, i.HoldCode, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(PayTerms)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'PayTerms', d.PayTerms, i.PayTerms, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(CompGroup)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'CompGroup', d.CompGroup, i.CompGroup, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(ShipLoc)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'ShipLoc', d.ShipLoc, i.ShipLoc, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update([Address])
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'Address', d.[Address], i.[Address], getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(City)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'City', d.City, i.City, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update([State])
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'State', d.[State], i.[State], getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(Zip)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'Zip', d.Zip, i.Zip, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(Country)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'Country', d.Country, i.Country, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(Address2)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'Address2', d.Address2, i.Address2, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(ShipIns)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'ShipIns', d.ShipIns, i.ShipIns, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(Attention)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'Attention', d.Attention, i.Attention, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(PayAddressSeq)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'PayAddressSeq', d.PayAddressSeq, i.PayAddressSeq, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	
	
	if update(POAddressSeq)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrder', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO, i.POCo, 'C', 'POAddressSeq', d.POAddressSeq, i.POAddressSeq, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO
	end	

end try


begin catch

	select @errmsg = @errmsg + ' - cannot update PO Penindg Purchase Order'
	RAISERROR(@errmsg, 11, -1);
	
end catch




GO
ALTER TABLE [dbo].[vPOPendingPurchaseOrder] ADD CONSTRAINT [PK_vPOPendingPurchaseOrder] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vPOPendingPurchaseOrder_PO] ON [dbo].[vPOPendingPurchaseOrder] ([POCo], [PO]) ON [PRIMARY]
GO
