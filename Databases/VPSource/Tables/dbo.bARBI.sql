CREATE TABLE [dbo].[bARBI]
(
[ARCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[BatchSeq] [int] NOT NULL,
[ARTrans] [dbo].[bTrans] NULL,
[ARLine] [smallint] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ActualDate] [dbo].[bDate] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[Invoice] [char] (10) COLLATE Latin1_General_BIN NULL,
[CheckNo] [char] (10) COLLATE Latin1_General_BIN NULL,
[BilledUnits] [dbo].[bUnits] NULL CONSTRAINT [DF_bARBI_BilledUnits] DEFAULT ((0)),
[BilledAmt] [dbo].[bDollar] NULL CONSTRAINT [DF_bARBI_BilledAmt] DEFAULT ((0)),
[RecvdAmt] [dbo].[bDollar] NULL CONSTRAINT [DF_bARBI_RecvdAmt] DEFAULT ((0)),
[Retainage] [dbo].[bDollar] NULL CONSTRAINT [DF_bARBI_Retainage] DEFAULT ((0)),
[BilledTax] [dbo].[bDollar] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biARBI] ON [dbo].[bARBI] ([ARCo], [Mth], [BatchId], [BatchSeq], [ARLine], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biARBIContract] ON [dbo].[bARBI] ([Contract], [Item], [JCCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARBI].[BilledUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARBI].[BilledAmt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARBI].[RecvdAmt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARBI].[Retainage]'
GO
