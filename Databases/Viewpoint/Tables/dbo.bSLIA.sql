CREATE TABLE [dbo].[bSLIA]
(
[SLCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[BatchSeq] [int] NOT NULL,
[SLItem] [dbo].[bItem] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[ItemType] [tinyint] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[ChangeUnits] [dbo].[bUnits] NOT NULL,
[ChangeCost] [dbo].[bDollar] NOT NULL,
[JCUM] [dbo].[bUM] NOT NULL,
[JCUnits] [dbo].[bUnits] NOT NULL,
[TotalCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLIA_TotalCmtdTax] DEFAULT ((0.00)),
[RemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLIA_RemCmtdTax] DEFAULT ((0.00))
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biSLIA] ON [dbo].[bSLIA] ([SLCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [BatchSeq], [SLItem], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
