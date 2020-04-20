CREATE TABLE [dbo].[vSMWIPTransferBatch]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[SMWorkCompletedID] [bigint] NOT NULL,
[TransferType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[NewGLCo] [dbo].[bCompany] NOT NULL,
[NewGLAcct] [dbo].[bGLAcct] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWIPTransferBatch] ADD CONSTRAINT [CK_vSMWIPTransferBatch] CHECK (([TransferType]='R' OR [TransferType]='C'))
GO
ALTER TABLE [dbo].[vSMWIPTransferBatch] ADD CONSTRAINT [IX_vSMWIPTransferBatch] UNIQUE NONCLUSTERED  ([SMWorkCompletedID], [TransferType]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWIPTransferBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMWIPTransferBatch_vSMWorkCompleted] FOREIGN KEY ([SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompleted] ([SMWorkCompletedID])
GO
ALTER TABLE [dbo].[vSMWIPTransferBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMWIPTransferBatch_vSMWorkCompletedGL] FOREIGN KEY ([SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompletedGL] ([SMWorkCompletedID])
GO
