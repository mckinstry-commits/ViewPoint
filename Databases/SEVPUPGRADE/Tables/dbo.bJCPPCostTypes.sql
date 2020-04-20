CREATE TABLE [dbo].[bJCPPCostTypes]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[LinkProgress] [dbo].[bJCCType] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bJCPPCostTypes] ADD CONSTRAINT [PK_JCPPCostTypes] PRIMARY KEY CLUSTERED  ([Co], [Mth], [BatchId], [PhaseGroup], [CostType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
