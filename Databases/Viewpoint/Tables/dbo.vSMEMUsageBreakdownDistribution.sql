CREATE TABLE [dbo].[vSMEMUsageBreakdownDistribution]
(
[SMEMUsageBreakdownDistributionID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[EMCo] [dbo].[bCompany] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[RevBdownCode] [char] (10) COLLATE Latin1_General_BIN NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[Total] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vSMEMUsageBreakdownDistribution] WITH NOCHECK ADD
CONSTRAINT [FK_vSMEMUsageBreakdownDistribution_bHQBC] FOREIGN KEY ([SMCo], [Mth], [BatchId]) REFERENCES [dbo].[bHQBC] ([Co], [Mth], [BatchId])
GO
ALTER TABLE [dbo].[vSMEMUsageBreakdownDistribution] ADD CONSTRAINT [PK_vSMEMUsageBreakdownDistribution] PRIMARY KEY CLUSTERED  ([SMEMUsageBreakdownDistributionID]) ON [PRIMARY]
GO
