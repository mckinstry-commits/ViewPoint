CREATE TABLE [dbo].[vGLEntryBatchInterfacing]
(
[GLEntryBatchInterfacingID] [bigint] NOT NULL IDENTITY(1, 1),
[GLEntrySource] [dbo].[bSource] NOT NULL,
[BatchCo] [dbo].[bCompany] NOT NULL,
[BatchMth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[InterfacingCo] [dbo].[bCompany] NOT NULL,
[InterfaceLevel] [tinyint] NOT NULL,
[Journal] [dbo].[bJrnl] NULL,
[SummaryDescription] [dbo].[bTransDesc] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vGLEntryBatchInterfacing] ADD CONSTRAINT [PK_vGLEntryBatchInterfacing] PRIMARY KEY CLUSTERED  ([GLEntryBatchInterfacingID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vGLEntryBatchInterfacing] ADD CONSTRAINT [IX_vGLEntryBatchInterfacing] UNIQUE NONCLUSTERED  ([GLEntrySource], [BatchCo], [BatchMth], [BatchId], [InterfacingCo]) ON [PRIMARY]
GO
