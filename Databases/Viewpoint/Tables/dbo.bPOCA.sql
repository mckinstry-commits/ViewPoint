CREATE TABLE [dbo].[bPOCA]
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
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[Description] [dbo].[bItemDesc] NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[POUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bPOCA_POUnits] DEFAULT ((0.000)),
[JCUM] [dbo].[bUM] NOT NULL,
[CmtdUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bPOCA_CmtdUnits] DEFAULT ((0.000)),
[TotalCmtdCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOCA_TotalCmtdCost] DEFAULT ((0.00)),
[RemainCmtdCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOCA_RemainCmtdCost] DEFAULT ((0.00)),
[RecvdNInvd] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOCA_RecvdNInvd] DEFAULT ((0.00)),
[TotalCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOCA_TotalCmtdTax] DEFAULT ((0.00)),
[RemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOCA_RemCmtdTax] DEFAULT ((0.00))
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPOCA] ON [dbo].[bPOCA] ([POCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
