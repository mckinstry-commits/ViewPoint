CREATE TABLE [dbo].[vSMWorkCompletedGLEntry]
(
[GLEntryID] [bigint] NOT NULL,
[GLTransactionForSMDerivedAccount] [int] NOT NULL,
[SMWorkCompletedID] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedGLEntry] ADD CONSTRAINT [PK_vSMWorkCompletedGLEntry] PRIMARY KEY CLUSTERED  ([GLEntryID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedGLEntry] ADD CONSTRAINT [IX_vSMWorkCompletedGLEntry] UNIQUE NONCLUSTERED  ([GLEntryID], [SMWorkCompletedID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedGLEntry_vGLEntry] FOREIGN KEY ([GLEntryID]) REFERENCES [dbo].[vGLEntry] ([GLEntryID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMWorkCompletedGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedGLEntry_vGLEntryTransaction] FOREIGN KEY ([GLEntryID], [GLTransactionForSMDerivedAccount]) REFERENCES [dbo].[vGLEntryTransaction] ([GLEntryID], [GLTransaction])
GO
ALTER TABLE [dbo].[vSMWorkCompletedGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedGLEntry_vSMWorkCompleted] FOREIGN KEY ([SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompleted] ([SMWorkCompletedID]) ON DELETE CASCADE
GO
