CREATE TABLE [dbo].[vJCCostEntry]
(
[JCCostEntryID] [bigint] NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[HQBatchDistributionID] [bigint] NULL,
[PRLedgerUpdateMonthID] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vJCCostEntry] ADD CONSTRAINT [PK_vJCCostEntry] PRIMARY KEY CLUSTERED  ([JCCostEntryID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vJCCostEntry] WITH NOCHECK ADD CONSTRAINT [FK_vJCCostEntry_vHQBatchDistribution] FOREIGN KEY ([HQBatchDistributionID]) REFERENCES [dbo].[vHQBatchDistribution] ([HQBatchDistributionID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vJCCostEntry] WITH NOCHECK ADD CONSTRAINT [FK_vJCCostEntry_vPRLedgerUpateMonth] FOREIGN KEY ([PRLedgerUpdateMonthID]) REFERENCES [dbo].[vPRLedgerUpdateMonth] ([PRLedgerUpdateMonthID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vJCCostEntry] NOCHECK CONSTRAINT [FK_vJCCostEntry_vHQBatchDistribution]
GO
ALTER TABLE [dbo].[vJCCostEntry] NOCHECK CONSTRAINT [FK_vJCCostEntry_vPRLedgerUpateMonth]
GO
