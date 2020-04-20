CREATE TABLE [dbo].[vHQBatchDistribution]
(
[HQBatchDistributionID] [bigint] NOT NULL IDENTITY(1, 1),
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NULL,
[Line] [smallint] NULL,
[Posted] [bit] NOT NULL CONSTRAINT [DF_vHQBatchDistribution_Posted] DEFAULT ((0)),
[InterfacingCo] [dbo].[bCompany] NOT NULL,
[IsReversing] [bit] NOT NULL CONSTRAINT [DF_vHQBatchDistribution_IsReversing] DEFAULT ((0)),
[DistributionXML] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQBatchDistribution] ADD CONSTRAINT [PK_vHQBatchDistributionID] PRIMARY KEY CLUSTERED  ([HQBatchDistributionID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQBatchDistribution] ADD CONSTRAINT [IX_vHQBatchDistribution_HQBatchDistributionID_Posted] UNIQUE NONCLUSTERED  ([HQBatchDistributionID], [Posted]) ON [PRIMARY]
GO
