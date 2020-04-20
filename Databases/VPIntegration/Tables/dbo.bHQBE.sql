CREATE TABLE [dbo].[bHQBE]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Seq] [int] NOT NULL,
[ErrorText] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQBE] ON [dbo].[bHQBE] ([Co], [Mth], [BatchId], [Seq]) ON [PRIMARY]
GO
