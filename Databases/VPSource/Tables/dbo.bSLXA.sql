CREATE TABLE [dbo].[bSLXA]
(
[SLCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[SLItem] [dbo].[bItem] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[SLUnits] [dbo].[bUnits] NULL,
[JCUM] [dbo].[bUM] NOT NULL,
[CmtdUnits] [dbo].[bUnits] NOT NULL,
[CmtdCost] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biSLXA] ON [dbo].[bSLXA] ([SLCo], [Mth], [BatchId], [BatchSeq], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [SLItem]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
