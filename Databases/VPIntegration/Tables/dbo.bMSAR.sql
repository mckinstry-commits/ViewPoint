CREATE TABLE [dbo].[bMSAR]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[ARFields] [char] (125) COLLATE Latin1_General_BIN NOT NULL,
[MSTrans] [dbo].[bTrans] NOT NULL,
[FromLoc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[MatlUnits] [dbo].[bUnits] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NULL,
[MatlTotal] [dbo].[bDollar] NOT NULL,
[HaulTotal] [dbo].[bDollar] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxTotal] [dbo].[bDollar] NOT NULL,
[DiscOff] [dbo].[bDollar] NOT NULL,
[TaxDisc] [dbo].[bDollar] NOT NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSAR] ON [dbo].[bMSAR] ([MSCo], [Mth], [BatchId], [BatchSeq], [ARFields], [MSTrans]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSAR].[ECM]'
GO
