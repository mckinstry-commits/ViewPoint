CREATE TABLE [dbo].[vSMWorkCompletedBatch]
(
[SMWorkCompletedID] [bigint] NOT NULL,
[BatchCo] [dbo].[bCompany] NOT NULL,
[BatchMonth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[IsProcessed] [bit] NOT NULL CONSTRAINT [DF_vSMWorkCompletedBatch_IsProcessed] DEFAULT ((0)),
[CurrentRevenueGLEntryID] [bigint] NULL,
[ReversingRevenueGLEntryID] [bigint] NULL,
[CurrentJCCostEntryID] [bigint] NULL,
[ReversingJCCostEntryID] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedBatch] ADD CONSTRAINT [PK_vSMWorkCompletedBatch] PRIMARY KEY CLUSTERED  ([SMWorkCompletedID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedBatch_vJCCostEntryCurrent] FOREIGN KEY ([CurrentJCCostEntryID]) REFERENCES [dbo].[vJCCostEntry] ([JCCostEntryID])
GO
ALTER TABLE [dbo].[vSMWorkCompletedBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedBatch_vGLEntryCurrentRevenue] FOREIGN KEY ([CurrentRevenueGLEntryID]) REFERENCES [dbo].[vGLEntry] ([GLEntryID])
GO
ALTER TABLE [dbo].[vSMWorkCompletedBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedBatch_vJCCostEntryReversing] FOREIGN KEY ([ReversingJCCostEntryID]) REFERENCES [dbo].[vJCCostEntry] ([JCCostEntryID])
GO
ALTER TABLE [dbo].[vSMWorkCompletedBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedBatch_vGLEntryReversingRevenue] FOREIGN KEY ([ReversingRevenueGLEntryID]) REFERENCES [dbo].[vGLEntry] ([GLEntryID])
GO
ALTER TABLE [dbo].[vSMWorkCompletedBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedBatch_vSMWorkCompleted] FOREIGN KEY ([SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompleted] ([SMWorkCompletedID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMWorkCompletedBatch] NOCHECK CONSTRAINT [FK_vSMWorkCompletedBatch_vJCCostEntryCurrent]
GO
ALTER TABLE [dbo].[vSMWorkCompletedBatch] NOCHECK CONSTRAINT [FK_vSMWorkCompletedBatch_vGLEntryCurrentRevenue]
GO
ALTER TABLE [dbo].[vSMWorkCompletedBatch] NOCHECK CONSTRAINT [FK_vSMWorkCompletedBatch_vJCCostEntryReversing]
GO
ALTER TABLE [dbo].[vSMWorkCompletedBatch] NOCHECK CONSTRAINT [FK_vSMWorkCompletedBatch_vGLEntryReversingRevenue]
GO
ALTER TABLE [dbo].[vSMWorkCompletedBatch] NOCHECK CONSTRAINT [FK_vSMWorkCompletedBatch_vSMWorkCompleted]
GO
