CREATE TABLE [dbo].[vGLEntryBatch]
(
[GLEntryID] [bigint] NOT NULL,
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NULL,
[Line] [smallint] NULL,
[InterfacingCo] [dbo].[bCompany] NOT NULL,
[Trans] [dbo].[bTrans] NULL,
[ReadyToProcess] [bit] NOT NULL CONSTRAINT [DF_vGLEntryBatch_ReadyToProcess] DEFAULT ((0)),
[PostedToGL] [bit] NOT NULL CONSTRAINT [DF_vGLEntryBatch_PostedToGL] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vGLEntryBatch] ADD CONSTRAINT [PK_vGLEntryBatch] PRIMARY KEY CLUSTERED  ([GLEntryID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vGLEntryBatch] WITH NOCHECK ADD CONSTRAINT [FK_vGLEntryBatch_vGLEntry] FOREIGN KEY ([GLEntryID]) REFERENCES [dbo].[vGLEntry] ([GLEntryID]) ON DELETE CASCADE
GO
