CREATE TABLE [dbo].[bEMIN]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[INCo] [dbo].[bCompany] NOT NULL,
[INLocation] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[EMTrans] [dbo].[bTrans] NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[Equip] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCType] [dbo].[bEMCType] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[Description] [dbo].[bItemDesc] NULL,
[PostedUM] [dbo].[bUM] NOT NULL,
[PostedUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bEMIN_PostedUnits] DEFAULT ((0)),
[PostedUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bEMIN_PostedUnitCost] DEFAULT ((0)),
[PostECM] [dbo].[bECM] NOT NULL,
[PostedTotalCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bEMIN_PostedTotalCost] DEFAULT ((0)),
[StkUM] [dbo].[bUM] NOT NULL,
[StkUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bEMIN_StkUnits] DEFAULT ((0)),
[StkUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bEMIN_StkUnitCost] DEFAULT ((0)),
[StkECM] [dbo].[bECM] NOT NULL,
[StkTotalCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bEMIN_StkTotalCost] DEFAULT ((0)),
[UnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bEMIN_UnitPrice] DEFAULT ((0)),
[PECM] [dbo].[bECM] NOT NULL,
[TotalPrice] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bEMIN_TotalPrice] DEFAULT ((0))
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMIN] ADD
CONSTRAINT [CK_bEMIN_PECM] CHECK (([PECM]='M' OR [PECM]='C' OR [PECM]='E'))
ALTER TABLE [dbo].[bEMIN] ADD
CONSTRAINT [CK_bEMIN_PostECM] CHECK (([PostECM]='M' OR [PostECM]='C' OR [PostECM]='E'))
ALTER TABLE [dbo].[bEMIN] ADD
CONSTRAINT [CK_bEMIN_StkECM] CHECK (([StkECM]='M' OR [StkECM]='C' OR [StkECM]='E'))
ALTER TABLE [dbo].[bEMIN] ADD
CONSTRAINT [FK_bEMIN_bEMCC_CostCode] FOREIGN KEY ([EMGroup], [CostCode]) REFERENCES [dbo].[bEMCC] ([EMGroup], [CostCode])
ALTER TABLE [dbo].[bEMIN] ADD
CONSTRAINT [FK_bEMIN_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
ALTER TABLE [dbo].[bEMIN] ADD
CONSTRAINT [FK_bEMIN_bEMEM_Component] FOREIGN KEY ([EMCo], [Component]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment])
ALTER TABLE [dbo].[bEMIN] ADD
CONSTRAINT [FK_bEMIN_bEMEM_Equip] FOREIGN KEY ([EMCo], [Equip]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
ALTER TABLE [dbo].[bEMIN] ADD
CONSTRAINT [FK_bEMIN_bEMWH_WorkOrder] FOREIGN KEY ([EMCo], [WO]) REFERENCES [dbo].[bEMWH] ([EMCo], [WorkOrder])
ALTER TABLE [dbo].[bEMIN] ADD
CONSTRAINT [FK_bEMIN_bEMWI_WOItem] FOREIGN KEY ([EMCo], [WO], [WOItem]) REFERENCES [dbo].[bEMWI] ([EMCo], [WorkOrder], [WOItem])
ALTER TABLE [dbo].[bEMIN] ADD
CONSTRAINT [FK_bEMIN_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
ALTER TABLE [dbo].[bEMIN] ADD
CONSTRAINT [FK_bEMIN_bEMCT_EMCType] FOREIGN KEY ([EMGroup], [EMCType]) REFERENCES [dbo].[bEMCT] ([EMGroup], [CostType])
GO
CREATE UNIQUE CLUSTERED INDEX [biEMIN] ON [dbo].[bEMIN] ([EMCo], [Mth], [BatchId], [INCo], [INLocation], [MatlGroup], [Material], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bEMIN].[PostECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bEMIN].[StkECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bEMIN].[PECM]'
GO
