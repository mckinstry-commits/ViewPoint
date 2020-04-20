CREATE TABLE [dbo].[vSMEMUsageBatch]
(
[SMEMUsageBatchID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SMWorkCompletedID] [bigint] NULL,
[IsReversingEntry] [bit] NOT NULL,
[WorkOrder] [int] NOT NULL,
[Scope] [int] NOT NULL,
[EMCo] [dbo].[bCompany] NOT NULL,
[EMTransMth] [dbo].[bMonth] NULL,
[EMTrans] [dbo].[bTrans] NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[OffsetGLCo] [dbo].[bCompany] NOT NULL,
[OffsetGLAcct] [dbo].[bGLAcct] NOT NULL,
[Category] [dbo].[bCat] NULL,
[RevBasis] [char] (1) COLLATE Latin1_General_BIN NULL,
[WorkUM] [dbo].[bUM] NULL,
[WorkUnits] [dbo].[bUnits] NOT NULL,
[TimeUM] [dbo].[bUM] NULL,
[TimeUnits] [dbo].[bUnits] NOT NULL,
[Dollars] [dbo].[bDollar] NOT NULL,
[RevRate] [dbo].[bDollar] NOT NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMEMUsageBatch] WITH NOCHECK ADD CONSTRAINT [CK_vSMEMUsageBatchBatchTransType] CHECK (([BatchTransType]='A' AND [IsReversingEntry]=(0) OR [BatchTransType]='C' OR [BatchTransType]='D' AND [IsReversingEntry]=(1)))
GO
ALTER TABLE [dbo].[vSMEMUsageBatch] WITH NOCHECK ADD CONSTRAINT [CK_vSMEMUsageBatchTrans] CHECK (([IsReversingEntry]=case when [EMTransMth] IS NULL then (0) else (1) end AND [IsReversingEntry]=case when [EMTrans] IS NULL then (0) else (1) end))
GO
ALTER TABLE [dbo].[vSMEMUsageBatch] ADD CONSTRAINT [PK_vSMEMUsageBatch] PRIMARY KEY CLUSTERED  ([SMEMUsageBatchID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMEMUsageBatch] ADD CONSTRAINT [IX_vSMEMUsageBatch_SMCo_Mth_BatchId_BatchSeq] UNIQUE NONCLUSTERED  ([SMCo], [Mth], [BatchId], [BatchSeq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMEMUsageBatch] ADD CONSTRAINT [IX_vSMEMUsageBatch_SMWorkCompletedID_IsReversingEntry] UNIQUE NONCLUSTERED  ([SMWorkCompletedID], [IsReversingEntry]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMEMUsageBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMEMUsageBatch_bHQBC] FOREIGN KEY ([SMCo], [Mth], [BatchId]) REFERENCES [dbo].[bHQBC] ([Co], [Mth], [BatchId])
GO
ALTER TABLE [dbo].[vSMEMUsageBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMEMUsageBatch_vSMWorkOrderScope] FOREIGN KEY ([SMCo], [WorkOrder], [Scope]) REFERENCES [dbo].[vSMWorkOrderScope] ([SMCo], [WorkOrder], [Scope])
GO
ALTER TABLE [dbo].[vSMEMUsageBatch] NOCHECK CONSTRAINT [FK_vSMEMUsageBatch_bHQBC]
GO
ALTER TABLE [dbo].[vSMEMUsageBatch] NOCHECK CONSTRAINT [FK_vSMEMUsageBatch_vSMWorkOrderScope]
GO
