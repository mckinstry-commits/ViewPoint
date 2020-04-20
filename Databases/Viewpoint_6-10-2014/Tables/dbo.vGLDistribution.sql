CREATE TABLE [dbo].[vGLDistribution]
(
[GLDistributionID] [bigint] NOT NULL IDENTITY(1, 1),
[Source] [dbo].[bSource] NOT NULL,
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NULL,
[BatchSeq] [int] NULL,
[Line] [smallint] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLAccount] [dbo].[bGLAcct] NULL,
[GLAccountSubType] [char] (1) COLLATE Latin1_General_BIN NULL,
[Amount] [dbo].[bDollar] NULL,
[ActDate] [dbo].[bDate] NULL,
[Description] [dbo].[bTransDesc] NULL,
[DetailDescriptionTrans] [dbo].[bTrans] NULL,
[GLEntry] [int] NULL,
[GLEntryTransaction] [int] NULL,
[Posted] [bit] NOT NULL CONSTRAINT [DF_vGLDistribution_Posted] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vGLDistribution] WITH NOCHECK ADD CONSTRAINT [CK_vGLDistribution_BatchId] CHECK (([BatchId] IS NOT NULL))
GO
ALTER TABLE [dbo].[vGLDistribution] ADD CONSTRAINT [PK_vGLDistribution] PRIMARY KEY CLUSTERED  ([GLDistributionID]) ON [PRIMARY]
GO
