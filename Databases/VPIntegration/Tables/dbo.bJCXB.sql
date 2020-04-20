CREATE TABLE [dbo].[bJCXB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Job] [dbo].[bJob] NULL,
[LastContractMth] [dbo].[bMonth] NULL,
[LastJobMth] [dbo].[bMonth] NULL,
[CloseDate] [dbo].[bDate] NOT NULL,
[SoftFinal] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CloseStatus] [tinyint] NULL,
[BatchSeq] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bJCXB] ADD CONSTRAINT [PK_bJCXB] PRIMARY KEY CLUSTERED  ([Co], [Mth], [BatchId], [BatchSeq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biJCXB] ON [dbo].[bJCXB] ([Co], [Mth], [BatchId], [Contract], [Job]) ON [PRIMARY]
GO
