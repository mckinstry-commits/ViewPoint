CREATE TABLE [dbo].[vSMGLEntry]
(
[SMGLEntryID] [bigint] NOT NULL IDENTITY(1, 1),
[SMWorkCompletedID] [bigint] NOT NULL,
[Journal] [dbo].[bJrnl] NULL,
[TransactionsShouldBalance] [bit] NOT NULL CONSTRAINT [DF_vSMGLEntry_TransactionsShouldBalance] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMGLEntry] ADD CONSTRAINT [PK_vSMGLEntry] PRIMARY KEY CLUSTERED  ([SMGLEntryID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMGLEntry] ADD CONSTRAINT [IX_vSMGLEntry] UNIQUE NONCLUSTERED  ([SMGLEntryID], [SMWorkCompletedID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vSMGLEntry_vSMWorkCompletedGL] FOREIGN KEY ([SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompletedGL] ([SMWorkCompletedID]) ON DELETE CASCADE
GO
