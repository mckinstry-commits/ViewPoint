CREATE TABLE [dbo].[bAPJC]
(
[APCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[BatchSeq] [int] NOT NULL,
[APLine] [smallint] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[APTrans] [dbo].[bTrans] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[APRef] [dbo].[bAPReference] NULL,
[TransDesc] [dbo].[bDesc] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[LineDesc] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NOT NULL,
[JCUM] [dbo].[bUM] NULL,
[JCUnits] [dbo].[bUnits] NOT NULL,
[JCUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bAPJC_JCUnitCost] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL,
[TotalCost] [dbo].[bDollar] NOT NULL,
[RNIUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bAPJC_RNIUnits] DEFAULT ((0)),
[RNICost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPJC_RNICost] DEFAULT ((0)),
[RemCmtdCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPJC_RemCmtdCost] DEFAULT ((0)),
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPJC_TaxBasis] DEFAULT ((0)),
[TaxAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPJC_TaxAmt] DEFAULT ((0)),
[RemCmtdUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bAPJC_RemCmtdUnits] DEFAULT ((0)),
[TotalCmtdUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bAPJC_TotalCmtdUnits] DEFAULT ((0)),
[TotalCmtdCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPJC_TotalCmtdCost] DEFAULT ((0)),
[TotalCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPJC_TotalCmtdTax] DEFAULT ((0.00)),
[RemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPJC_RemCmtdTax] DEFAULT ((0.00)),
[POItemLine] [int] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bAPJC] ADD
CONSTRAINT [CK_bAPJC_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [biAPJC] ON [dbo].[bAPJC] ([APCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [BatchSeq], [APLine], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPJC].[JCUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bAPJC].[ECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPJC].[RNIUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPJC].[RNICost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPJC].[RemCmtdCost]'
GO
