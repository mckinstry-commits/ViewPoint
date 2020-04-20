CREATE TABLE [dbo].[bEMGL]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[EMTrans] [dbo].[bTrans] NULL,
[Equipment] [dbo].[bEquip] NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[TransDesc] [dbo].[bItemDesc] NULL,
[Source] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[EMTransType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCostType] [dbo].[bEMCType] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[INCo] [dbo].[bCompany] NULL,
[INLocation] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[WorkOrder] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[Amount] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMGL] ON [dbo].[bEMGL] ([EMCo], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMGL] WITH NOCHECK ADD CONSTRAINT [FK_bEMGL_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMGL] WITH NOCHECK ADD CONSTRAINT [FK_bEMGL_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bEMGL] WITH NOCHECK ADD CONSTRAINT [FK_bEMGL_bEMWH_WorkOrder] FOREIGN KEY ([EMCo], [WorkOrder]) REFERENCES [dbo].[bEMWH] ([EMCo], [WorkOrder])
GO
ALTER TABLE [dbo].[bEMGL] WITH NOCHECK ADD CONSTRAINT [FK_bEMGL_bEMWI_WOItem] FOREIGN KEY ([EMCo], [WorkOrder], [WOItem]) REFERENCES [dbo].[bEMWI] ([EMCo], [WorkOrder], [WOItem])
GO
ALTER TABLE [dbo].[bEMGL] WITH NOCHECK ADD CONSTRAINT [FK_bEMGL_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMGL] WITH NOCHECK ADD CONSTRAINT [FK_bEMGL_bEMCC_CostCode] FOREIGN KEY ([EMGroup], [CostCode]) REFERENCES [dbo].[bEMCC] ([EMGroup], [CostCode])
GO
ALTER TABLE [dbo].[bEMGL] WITH NOCHECK ADD CONSTRAINT [FK_bEMGL_bEMCT_EMCostType] FOREIGN KEY ([EMGroup], [EMCostType]) REFERENCES [dbo].[bEMCT] ([EMGroup], [CostType])
GO
ALTER TABLE [dbo].[bEMGL] WITH NOCHECK ADD CONSTRAINT [FK_bEMGL_bEMRT_RevBdownCode] FOREIGN KEY ([EMGroup], [RevBdownCode]) REFERENCES [dbo].[bEMRT] ([EMGroup], [RevBdownCode])
GO
ALTER TABLE [dbo].[bEMGL] WITH NOCHECK ADD CONSTRAINT [FK_bEMGL_bEMRC_RevCode] FOREIGN KEY ([EMGroup], [RevCode]) REFERENCES [dbo].[bEMRC] ([EMGroup], [RevCode])
GO
ALTER TABLE [dbo].[bEMGL] NOCHECK CONSTRAINT [FK_bEMGL_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMGL] NOCHECK CONSTRAINT [FK_bEMGL_bEMEM_Equipment]
GO
ALTER TABLE [dbo].[bEMGL] NOCHECK CONSTRAINT [FK_bEMGL_bEMWH_WorkOrder]
GO
ALTER TABLE [dbo].[bEMGL] NOCHECK CONSTRAINT [FK_bEMGL_bEMWI_WOItem]
GO
ALTER TABLE [dbo].[bEMGL] NOCHECK CONSTRAINT [FK_bEMGL_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMGL] NOCHECK CONSTRAINT [FK_bEMGL_bEMCC_CostCode]
GO
ALTER TABLE [dbo].[bEMGL] NOCHECK CONSTRAINT [FK_bEMGL_bEMCT_EMCostType]
GO
ALTER TABLE [dbo].[bEMGL] NOCHECK CONSTRAINT [FK_bEMGL_bEMRT_RevBdownCode]
GO
ALTER TABLE [dbo].[bEMGL] NOCHECK CONSTRAINT [FK_bEMGL_bEMRC_RevCode]
GO
