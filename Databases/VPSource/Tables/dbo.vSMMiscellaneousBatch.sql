CREATE TABLE [dbo].[vSMMiscellaneousBatch]
(
[SMMiscBatchID] [bigint] NOT NULL IDENTITY(1, 1),
[SMWorkCompletedID] [bigint] NOT NULL,
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMMiscellaneousBatch] ADD CONSTRAINT [PK_vSMMiscellaneousBatch] PRIMARY KEY CLUSTERED  ([SMMiscBatchID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMMiscellaneousBatch] ADD CONSTRAINT [IX_vSMMiscellaneousBatch] UNIQUE NONCLUSTERED  ([SMWorkCompletedID]) ON [PRIMARY]
GO
