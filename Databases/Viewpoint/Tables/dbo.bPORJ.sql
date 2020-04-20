CREATE TABLE [dbo].[bPORJ]
(
[POCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[BatchSeq] [int] NOT NULL,
[APLine] [smallint] NOT NULL CONSTRAINT [DF_bPORJ_APLine] DEFAULT ((1)),
[OldNew] [tinyint] NOT NULL,
[POTrans] [dbo].[bTrans] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[Description] [dbo].[bDesc] NULL,
[RecDate] [dbo].[bDate] NULL,
[Receiver#] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NOT NULL,
[JCUM] [dbo].[bUM] NULL,
[JCUnits] [dbo].[bUnits] NOT NULL,
[JCUnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NULL,
[TotalCost] [dbo].[bDollar] NOT NULL,
[RNIUnits] [dbo].[bUnits] NOT NULL,
[RNICost] [dbo].[bDollar] NOT NULL,
[RemCmtdCost] [dbo].[bDollar] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPORJ_TaxBasis] DEFAULT ((0)),
[TaxAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPORJ_TaxAmt] DEFAULT ((0)),
[TotalCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPORJ_TotalCmtdTax] DEFAULT ((0.00)),
[RemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPORJ_RemCmtdTax] DEFAULT ((0.00)),
[POItemLine] [int] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPORJ] ON [dbo].[bPORJ] ([POCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [BatchSeq], [APLine], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPORJ].[JCUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bPORJ].[ECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPORJ].[RNIUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPORJ].[RNICost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPORJ].[RemCmtdCost]'
GO
