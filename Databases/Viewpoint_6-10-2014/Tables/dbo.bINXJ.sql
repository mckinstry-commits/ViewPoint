CREATE TABLE [dbo].[bINXJ]
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
[MO] [dbo].[bMO] NOT NULL,
[MOItem] [dbo].[bItem] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[RemainUnits] [dbo].[bUnits] NOT NULL,
[JCUM] [dbo].[bUM] NULL,
[JCRemCmtdUnits] [dbo].[bUnits] NOT NULL,
[RemCmtdCost] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biINXJ] ON [dbo].[bINXJ] ([INCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [BatchSeq], [MOItem]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
