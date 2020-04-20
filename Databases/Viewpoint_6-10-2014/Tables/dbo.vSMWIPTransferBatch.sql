CREATE TABLE [dbo].[vSMWIPTransferBatch]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[TransferType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[NewGLCo] [dbo].[bCompany] NOT NULL,
[NewGLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[WorkOrder] [int] NOT NULL,
[WorkCompleted] [int] NULL,
[Scope] [int] NULL,
[FlatPriceRevenueSplitSeq] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWIPTransferBatch] WITH NOCHECK ADD CONSTRAINT [CK_vSMWIPTransferBatch] CHECK (([TransferType]='R' OR [TransferType]='C'))
GO
ALTER TABLE [dbo].[vSMWIPTransferBatch] WITH NOCHECK ADD CONSTRAINT [CK_vSMWIPTransferBatch_Scope_WorkCompleted] CHECK (([dbo].[vfEqualsNull]([WorkCompleted])<>[dbo].[vfEqualsNull]([Scope]) AND [dbo].[vfEqualsNull]([Scope])=[dbo].[vfEqualsNull]([FlatPriceRevenueSplitSeq])))
GO
ALTER TABLE [dbo].[vSMWIPTransferBatch] ADD CONSTRAINT [PK_vSMWIPTransferBatch] PRIMARY KEY CLUSTERED  ([Co], [Mth], [BatchId], [BatchSeq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWIPTransferBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMWIPTransferBatch_vSMWorkOrderScope] FOREIGN KEY ([Co], [WorkOrder], [Scope]) REFERENCES [dbo].[vSMWorkOrderScope] ([SMCo], [WorkOrder], [Scope])
GO
ALTER TABLE [dbo].[vSMWIPTransferBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMWIPTransferBatch_vSMWorkCompleted] FOREIGN KEY ([Co], [WorkOrder], [WorkCompleted]) REFERENCES [dbo].[vSMWorkCompleted] ([SMCo], [WorkOrder], [WorkCompleted])
GO
ALTER TABLE [dbo].[vSMWIPTransferBatch] NOCHECK CONSTRAINT [FK_vSMWIPTransferBatch_vSMWorkOrderScope]
GO
ALTER TABLE [dbo].[vSMWIPTransferBatch] NOCHECK CONSTRAINT [FK_vSMWIPTransferBatch_vSMWorkCompleted]
GO
