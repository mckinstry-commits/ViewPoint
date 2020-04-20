CREATE TABLE [dbo].[bMSRB]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[SaleType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[BatchSeq] [int] NOT NULL,
[HaulLine] [smallint] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSRB] ON [dbo].[bMSRB] ([MSCo], [Mth], [BatchId], [EMCo], [Equipment], [EMGroup], [RevCode], [SaleType], [RevBdownCode], [BatchSeq], [HaulLine], [OldNew]) ON [PRIMARY]
GO
