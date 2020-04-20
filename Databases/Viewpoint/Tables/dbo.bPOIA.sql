CREATE TABLE [dbo].[bPOIA]
(
[POCo] [dbo].[bCompany] NULL,
[Mth] [dbo].[bMonth] NULL,
[BatchId] [dbo].[bBatchID] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[JCCType] [dbo].[bJCCType] NULL,
[BatchSeq] [int] NULL,
[POItem] [dbo].[bItem] NULL,
[OldNew] [tinyint] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[UM] [dbo].[bUM] NULL,
[CurrentUnits] [dbo].[bUnits] NULL,
[JCUM] [dbo].[bUM] NULL,
[CmtdUnits] [dbo].[bUnits] NULL,
[CmtdCost] [dbo].[bDollar] NULL,
[RemUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bPOIA_RemUnits] DEFAULT ((0)),
[RemCmtdUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bPOIA_RemCmtdUnits] DEFAULT ((0)),
[RemCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOIA_RemCost] DEFAULT ((0)),
[TotalCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOIA_TotalCmtdTax] DEFAULT ((0.00)),
[RemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOIA_RemCmtdTax] DEFAULT ((0.00))
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPOIA] ON [dbo].[bPOIA] ([POCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [BatchSeq], [POItem], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
