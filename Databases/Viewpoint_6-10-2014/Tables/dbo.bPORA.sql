CREATE TABLE [dbo].[bPORA]
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
[OldNew] [tinyint] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[RecvdUnits] [dbo].[bUnits] NOT NULL,
[BOUnits] [dbo].[bUnits] NOT NULL,
[JCUM] [dbo].[bUM] NOT NULL,
[RNIUnits] [dbo].[bUnits] NOT NULL,
[RNICost] [dbo].[bDollar] NOT NULL,
[CmtdUnits] [dbo].[bUnits] NOT NULL,
[CmtdCost] [dbo].[bDollar] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[Description] [dbo].[bDesc] NULL,
[RecDate] [dbo].[bDate] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[JCUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bPORA_JCUnits] DEFAULT ((0)),
[JCUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPORA_JCUnitCost] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL,
[TotalCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPORA_TotalCost] DEFAULT ((0)),
[RemCmtdCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPORA_RemCmtdCost] DEFAULT ((0)),
[TotalCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPORA_TotalCmtdTax] DEFAULT ((0.00)),
[RemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPORA_RemCmtdTax] DEFAULT ((0.00)),
[POItemLine] [int] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxType] [tinyint] NULL,
[TaxCode] [dbo].[bTaxCode] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPORA] WITH NOCHECK ADD CONSTRAINT [CK_bPORA_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [biPORA] ON [dbo].[bPORA] ([POCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
