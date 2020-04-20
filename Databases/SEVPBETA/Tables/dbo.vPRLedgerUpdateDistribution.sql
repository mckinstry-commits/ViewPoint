CREATE TABLE [dbo].[vPRLedgerUpdateDistribution]
(
[PRLedgerUpdateDistributionID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Posted] [bit] NOT NULL CONSTRAINT [DF_vPRLedgerUpdateDistribution_Posted] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRLedgerUpdateDistribution] ADD CONSTRAINT [PK_vPRLedgerUpdateDistribution] PRIMARY KEY CLUSTERED  ([PRLedgerUpdateDistributionID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRLedgerUpdateDistribution] ADD CONSTRAINT [IX_vPRLedgerUpdateDistribution_PRLedgerUpdateDistributionID_Posted] UNIQUE NONCLUSTERED  ([PRLedgerUpdateDistributionID], [Posted]) ON [PRIMARY]
GO
