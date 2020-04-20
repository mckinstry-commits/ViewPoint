CREATE TABLE [dbo].[vSMWorkCompletedJCCostEntry]
(
[JCCostEntryID] [bigint] NOT NULL,
[SMWorkCompletedID] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedJCCostEntry] ADD CONSTRAINT [PK_vSMWorkCompletedJCCostEntry] PRIMARY KEY CLUSTERED  ([JCCostEntryID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedJCCostEntry] ADD CONSTRAINT [IX_vSMWorkCompletedJCCostEntry] UNIQUE NONCLUSTERED  ([JCCostEntryID], [SMWorkCompletedID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedJCCostEntry] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedJCCostEntry_vJCCostEntry] FOREIGN KEY ([JCCostEntryID]) REFERENCES [dbo].[vJCCostEntry] ([JCCostEntryID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMWorkCompletedJCCostEntry] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedJCCostEntry_vSMWorkCompleted] FOREIGN KEY ([SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompleted] ([SMWorkCompletedID]) ON DELETE CASCADE
GO
