CREATE TABLE [dbo].[bPOXA]
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
[POItem] [dbo].[bItem] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[Description] [dbo].[bDesc] NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[POUnits] [dbo].[bUnits] NOT NULL,
[JCUM] [dbo].[bUM] NOT NULL,
[CmtdUnits] [dbo].[bUnits] NOT NULL,
[CmtdCost] [dbo].[bDollar] NOT NULL,
[POItemLine] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPOXA] ON [dbo].[bPOXA] ([POCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [BatchSeq], [POItem], [POItemLine]) ON [PRIMARY]
GO
