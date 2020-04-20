CREATE TABLE [dbo].[bMSMX]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[MiscDistCode] [char] (10) COLLATE Latin1_General_BIN NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSMD] ON [dbo].[bMSMX] ([MSCo], [Mth], [BatchId], [BatchSeq], [MiscDistCode]) ON [PRIMARY]
GO
