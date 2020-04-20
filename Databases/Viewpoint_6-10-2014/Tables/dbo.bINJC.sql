CREATE TABLE [dbo].[bINJC]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[BatchSeq] [int] NOT NULL,
[MOItem] [dbo].[bItem] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[MO] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [char] (3) COLLATE Latin1_General_BIN NOT NULL,
[OrderedUnits] [dbo].[bUnits] NOT NULL,
[RemainUnits] [dbo].[bUnits] NOT NULL,
[TotalCmtdCost] [dbo].[bDollar] NOT NULL,
[RemainCmtdCost] [dbo].[bDollar] NOT NULL,
[JCUM] [char] (3) COLLATE Latin1_General_BIN NULL,
[JCUnits] [dbo].[bUnits] NOT NULL,
[JCRemainUnits] [dbo].[bUnits] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biINJC] ON [dbo].[bINJC] ([INCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [BatchSeq], [MOItem], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
