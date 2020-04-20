CREATE TABLE [dbo].[vGLEntry]
(
[GLEntryID] [bigint] NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[TransactionsShouldBalance] [bit] NOT NULL CONSTRAINT [DF_vGLEntry_TransactionsShouldBalance] DEFAULT ((0)),
[HQBatchDistributionID] [bigint] NULL,
[PRLedgerUpdateMonthID] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vGLEntry] ADD CONSTRAINT [PK_vGLEntry] PRIMARY KEY CLUSTERED  ([GLEntryID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vGLEntry_vHQBatchDistribution] FOREIGN KEY ([HQBatchDistributionID]) REFERENCES [dbo].[vHQBatchDistribution] ([HQBatchDistributionID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vGLEntry_vPRLedgerUpdateMonth] FOREIGN KEY ([PRLedgerUpdateMonthID]) REFERENCES [dbo].[vPRLedgerUpdateMonth] ([PRLedgerUpdateMonthID]) ON DELETE CASCADE
GO
