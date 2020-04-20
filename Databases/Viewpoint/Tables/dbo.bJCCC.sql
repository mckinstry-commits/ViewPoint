CREATE TABLE [dbo].[bJCCC]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Job] [dbo].[bJob] NULL,
[Status] [tinyint] NOT NULL,
[CloseDate] [dbo].[bDate] NOT NULL,
[LastRevMth] [dbo].[bMonth] NULL,
[LastCostMth] [dbo].[bMonth] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJCCC] ON [dbo].[bJCCC] ([Co], [Mth], [BatchId], [Contract], [Job]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
