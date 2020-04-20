CREATE TABLE [dbo].[bMSMA]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[UnitCost] [dbo].[bDollar] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TransMth] [dbo].[bMonth] NOT NULL,
[MSTrans] [dbo].[bTrans] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[TotalCost] [dbo].[bDollar] NOT NULL,
[DiscOff] [dbo].[bDollar] NOT NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxAmt] [dbo].[bDollar] NOT NULL,
[TaxType] [tinyint] NULL,
[GSTTaxAmt] [dbo].[bDollar] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSMA] ON [dbo].[bMSMA] ([MSCo], [Mth], [BatchId], [BatchSeq], [MatlGroup], [Material], [UM], [UnitCost], [ECM], [GLCo], [GLAcct], [TaxGroup], [TaxCode], [TransMth], [MSTrans]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSMA].[ECM]'
GO
