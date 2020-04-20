CREATE TABLE [dbo].[vPOPendingPurchaseOrderItem]
(
[POCo] [dbo].[bCompany] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[ItemType] [tinyint] NOT NULL CONSTRAINT [DF_vPOPendingPurchaseOrderItem_ItemType] DEFAULT ((1)),
[PostToCo] [dbo].[bCompany] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NULL,
[VendMatId] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[RecvYN] [dbo].[bYN] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[ReqDate] [dbo].[bDate] NULL,
[PayCategory] [int] NULL,
[PayType] [tinyint] NULL,
[UM] [dbo].[bUM] NOT NULL,
[OrigUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_vPOPendingPurchaseOrderItem_OrigUnits] DEFAULT ((0)),
[OrigUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_vPOPendingPurchaseOrderItem_OrigUnitCost] DEFAULT ((0)),
[OrigECM] [dbo].[bECM] NULL,
[OrigCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOPendingPurchaseOrderItem_OrigCost] DEFAULT ((0)),
[OrigTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOPendingPurchaseOrderItem_OrigTax] DEFAULT ((0)),
[TaxType] [tinyint] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_vPOPendingPurchaseOrderItem_TaxRate] DEFAULT ((0)),
[GSTRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_vPOPendingPurchaseOrderItem_GSTRate] DEFAULT ((0)),
[SupplierGroup] [dbo].[bGroup] NULL,
[Supplier] [dbo].[bVendor] NULL,
[RequisitionNum] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[JCCType] [dbo].[bJCCType] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[EMCo] [dbo].[bCompany] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[Equip] [dbo].[bEquip] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCType] [dbo].[bEMCType] NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[SMCo] [dbo].[bCompany] NULL,
[SMWorkOrder] [int] NULL,
[SMScope] [int] NULL,
[SMPhaseGroup] [dbo].[bGroup] NULL,
[SMPhase] [dbo].[bPhase] NULL,
[SMJCCostType] [dbo].[bJCCType] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE trigger [dbo].[vtPOPendingPurchaseOrderItemd] on [dbo].[vPOPendingPurchaseOrderItem] for DELETE as
/*********************************************************
* Created:		GP 3/30/12
* Modified: 
*
* Delete trigger for Pending Purchase Order Item
*
***********************************************************/
declare @errmsg varchar(255)

set nocount on

begin try

	--insert audit record
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(d.POCo as varchar(3)) + ' PO: ' + d.PO + ' POItem: ' + cast(d.POItem as varchar(7)), d.POCo, 'D', NULL, NULL, NULL, getdate(), suser_sname()
	from deleted d

end try


begin catch

	select @errmsg = @errmsg + ' - cannot delete PO Penindg Purchase Order Item'
	RAISERROR(@errmsg, 11, -1);
	
end catch





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE trigger [dbo].[vtPOPendingPurchaseOrderItemi] on [dbo].[vPOPendingPurchaseOrderItem] for INSERT as
/*********************************************************
* Created:		GP 3/30/12
* Modified: 
*
* Insert trigger for Pending Purchase Order Item
*
***********************************************************/
declare @errmsg varchar(255)

set nocount on

begin try

	--insert audit record
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'A', NULL, NULL, NULL, getdate(), suser_sname()
	from inserted i

end try


begin catch

	select @errmsg = @errmsg + ' - cannot insert PO Penindg Purchase Order Item'
	RAISERROR(@errmsg, 11, -1);
	
end catch





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE trigger [dbo].[vtPOPendingPurchaseOrderItemu] on [dbo].[vPOPendingPurchaseOrderItem] for UPDATE as
/*********************************************************
* Created:		GP 3/30/12
* Modified: 
*
* Update trigger for Pending Purchase Order Item
*
***********************************************************/
declare @errmsg varchar(255)

set nocount on

begin try

	if update(ItemType)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'ItemType', d.ItemType, i.ItemType, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(PostToCo)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'PostToCo', d.PostToCo, i.PostToCo, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(MatlGroup)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'MatlGroup', d.MatlGroup, i.MatlGroup, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(Material)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'Material', d.Material, i.Material, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(VendMatId)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'VendMatId', d.VendMatId, i.VendMatId, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(RecvYN)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'RecvYN', d.RecvYN, i.RecvYN, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update([Description])
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'Description', d.[Description], i.[Description], getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(GLCo)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'GLCo', d.GLCo, i.GLCo, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(GLAcct)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'GLAcct', d.GLAcct, i.GLAcct, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(ReqDate)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'ReqDate', d.ReqDate, i.ReqDate, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(PayCategory)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'PayCategory', d.PayCategory, i.PayCategory, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(PayType)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'PayType', d.PayType, i.PayType, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(UM)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'UM', d.UM, i.UM, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(OrigUnits)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'OrigUnits', d.OrigUnits, i.OrigUnits, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(OrigUnitCost)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'OrigUnitCost', d.OrigUnitCost, i.OrigUnitCost, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(OrigECM)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'OrigECM', d.OrigECM, i.OrigECM, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(OrigTax)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'OrigTax', d.OrigTax, i.OrigTax, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(TaxType)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'TaxType', d.TaxType, i.TaxType, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(TaxGroup)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'TaxGroup', d.TaxGroup, i.TaxGroup, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(TaxCode)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'TaxCode', d.TaxCode, i.TaxCode, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(TaxRate)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'TaxRate', d.TaxRate, i.TaxRate, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(GSTRate)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'GSTRate', d.GSTRate, i.GSTRate, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(SupplierGroup)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'SupplierGroup', d.SupplierGroup, i.SupplierGroup, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(Supplier)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'Supplier', d.Supplier, i.Supplier, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(RequisitionNum)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'RequisitionNum', d.RequisitionNum, i.RequisitionNum, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	

	if update(JCCo)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'JCCo', d.JCCo, i.JCCo, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(Job)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'Job', d.Job, i.Job, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(PhaseGroup)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'PhaseGroup', d.PhaseGroup, i.PhaseGroup, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(Phase)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'Phase', d.Phase, i.Phase, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(JCCType)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'JCCType', d.JCCType, i.JCCType, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end	
	
	if update(INCo)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'INCo', d.INCo, i.INCo, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(Loc)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'Loc', d.Loc, i.Loc, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(EMCo)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'EMCo', d.EMCo, i.EMCo, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(EMGroup)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'EMGroup', d.EMGroup, i.EMGroup, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(Equip)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'Equip', d.Equip, i.Equip, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(CompType)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'CompType', d.CompType, i.CompType, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(Component)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'Component', d.Component, i.Component, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(CostCode)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'CostCode', d.CostCode, i.CostCode, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(EMCType)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'EMCType', d.EMCType, i.EMCType, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(WO)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'WO', d.WO, i.WO, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(WOItem)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'WOItem', d.WOItem, i.WOItem, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(SMCo)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'SMCo', d.SMCo, i.SMCo, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(SMWorkOrder)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'SMWorkOrder', d.SMWorkOrder, i.SMWorkOrder, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(SMScope)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'SMScope', d.SMScope, i.SMScope, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(SMPhaseGroup)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'SMPhaseGroup', d.SMPhaseGroup, i.SMPhaseGroup, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(SMPhase)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'SMPhase', d.SMPhase, i.SMPhase, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end
	
	if update(SMJCCostType)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vPOPendingPurchaseOrderItem', 'POCo: ' + cast(i.POCo as varchar(3)) + ' PO: ' + i.PO + ' POItem: ' + cast(i.POItem as varchar(7)), i.POCo, 'C', 'SMJCCostType', d.SMJCCostType, i.SMJCCostType, getdate(), suser_sname()
		from inserted i
		join deleted d on d.POCo = i.POCo and d.PO = i.PO and d.POItem = i.POItem
	end

end try


begin catch

	select @errmsg = @errmsg + ' - cannot update PO Penindg Purchase Order Item'
	RAISERROR(@errmsg, 11, -1);
	
end catch





GO
ALTER TABLE [dbo].[vPOPendingPurchaseOrderItem] ADD CONSTRAINT [CK_vPOPendingPurchaseOrderItem_ItemType] CHECK (([ItemType]>(0) AND [ItemType]<(6)))
GO
ALTER TABLE [dbo].[vPOPendingPurchaseOrderItem] ADD CONSTRAINT [CK_vPOPendingPurchaseOrderItem_OrigECM] CHECK (([OrigECM]='E' OR [OrigECM]='C' OR [OrigECM]='M'))
GO
ALTER TABLE [dbo].[vPOPendingPurchaseOrderItem] ADD CONSTRAINT [CK_vPOPendingPurchaseOrderItem_RecvYN] CHECK (([RecvYN]='Y' OR [RecvYN]='N'))
GO
ALTER TABLE [dbo].[vPOPendingPurchaseOrderItem] ADD CONSTRAINT [PK_vPOPendingPurchaseOrderItem] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [IX_vPOPendingPurchaseOrderItem_POItem] ON [dbo].[vPOPendingPurchaseOrderItem] ([POCo], [PO], [POItem]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPOPendingPurchaseOrderItem] WITH NOCHECK ADD CONSTRAINT [FK_vPOPendingPurchaseOrderItem_vPOPendingPurchaseOrderItem_Equip] FOREIGN KEY ([EMCo], [Equip]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment])
GO
ALTER TABLE [dbo].[vPOPendingPurchaseOrderItem] WITH NOCHECK ADD CONSTRAINT [FK_vPOPendingPurchaseOrderItem_bEMWH_WorkOrder] FOREIGN KEY ([EMCo], [WO]) REFERENCES [dbo].[bEMWH] ([EMCo], [WorkOrder])
GO
ALTER TABLE [dbo].[vPOPendingPurchaseOrderItem] WITH NOCHECK ADD CONSTRAINT [FK_vPOPendingPurchaseOrderItem_bINLM_Loc] FOREIGN KEY ([INCo], [Loc]) REFERENCES [dbo].[bINLM] ([INCo], [Loc])
GO
ALTER TABLE [dbo].[vPOPendingPurchaseOrderItem] WITH NOCHECK ADD CONSTRAINT [FK_vPOPendingPurchaseOrderItem_vPOPendingPurchaseOrder_PO] FOREIGN KEY ([POCo], [PO]) REFERENCES [dbo].[vPOPendingPurchaseOrder] ([POCo], [PO])
GO
ALTER TABLE [dbo].[vPOPendingPurchaseOrderItem] WITH NOCHECK ADD CONSTRAINT [FK_vPOPendingPurchaseOrderItem_vSMWorkOrder_WorkOrder] FOREIGN KEY ([SMWorkOrder], [SMCo]) REFERENCES [dbo].[vSMWorkOrder] ([WorkOrder], [SMCo])
GO
