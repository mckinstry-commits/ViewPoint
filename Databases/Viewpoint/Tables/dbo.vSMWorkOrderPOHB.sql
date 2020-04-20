CREATE TABLE [dbo].[vSMWorkOrderPOHB]
(
[SMWorkOrderPOHBID] [bigint] NOT NULL IDENTITY(1, 1),
[POCo] [dbo].[bCompany] NOT NULL,
[BatchMth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[WorkOrder] [int] NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vSMWorkOrderPOHB] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkOrderPOHB_bPOHB] FOREIGN KEY ([POCo], [BatchMth], [BatchId], [BatchSeq]) REFERENCES [dbo].[bPOHB] ([Co], [Mth], [BatchId], [BatchSeq]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMWorkOrderPOHB] ADD CONSTRAINT [PK_vSMWorkOrderPOHB] PRIMARY KEY CLUSTERED  ([SMWorkOrderPOHBID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vSMWorkOrderPOHB_POCo_BatchId_BatchMth_BatchSeq] ON [dbo].[vSMWorkOrderPOHB] ([POCo], [BatchId], [BatchMth], [BatchSeq]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vSMWorkOrderPOHB] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderPOHB_vSMWorkOrder] FOREIGN KEY ([WorkOrder], [SMCo]) REFERENCES [dbo].[vSMWorkOrder] ([WorkOrder], [SMCo]) ON DELETE CASCADE
GO
