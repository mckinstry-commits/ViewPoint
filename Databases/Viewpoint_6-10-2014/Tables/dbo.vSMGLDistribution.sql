CREATE TABLE [dbo].[vSMGLDistribution]
(
[SMGLDistributionID] [bigint] NOT NULL IDENTITY(1, 1),
[SMWorkCompletedID] [bigint] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[BatchMonth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[CostOrRevenue] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[IsAccountTransfer] [bit] NOT NULL,
[SMGLEntryID] [bigint] NULL,
[SMGLDetailTransactionID] [bigint] NULL,
[ReversingSMGLEntryID] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMGLDistribution] WITH NOCHECK ADD CONSTRAINT [CK_vSMGLDistribution_CostOrRevenue] CHECK (([CostOrRevenue]='R' OR [CostOrRevenue]='C'))
GO
ALTER TABLE [dbo].[vSMGLDistribution] ADD CONSTRAINT [PK_vSMGLDistribution] PRIMARY KEY CLUSTERED  ([SMGLDistributionID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMGLDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vSMGLDistribution_vSMGLEntry_ReversingSMGLEntry] FOREIGN KEY ([ReversingSMGLEntryID]) REFERENCES [dbo].[vSMGLEntry] ([SMGLEntryID])
GO
ALTER TABLE [dbo].[vSMGLDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vSMGLDistribution_vSMGLDetailTransaction] FOREIGN KEY ([SMGLDetailTransactionID], [SMGLEntryID]) REFERENCES [dbo].[vSMGLDetailTransaction] ([SMGLDetailTransactionID], [SMGLEntryID])
GO
ALTER TABLE [dbo].[vSMGLDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vSMGLDistribution_vSMGLEntry] FOREIGN KEY ([SMGLEntryID]) REFERENCES [dbo].[vSMGLEntry] ([SMGLEntryID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMGLDistribution] NOCHECK CONSTRAINT [FK_vSMGLDistribution_vSMGLEntry_ReversingSMGLEntry]
GO
ALTER TABLE [dbo].[vSMGLDistribution] NOCHECK CONSTRAINT [FK_vSMGLDistribution_vSMGLDetailTransaction]
GO
ALTER TABLE [dbo].[vSMGLDistribution] NOCHECK CONSTRAINT [FK_vSMGLDistribution_vSMGLEntry]
GO
