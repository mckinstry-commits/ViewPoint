CREATE TABLE [dbo].[bEMJC]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[EMTrans] [dbo].[bTrans] NULL,
[Equipment] [dbo].[bEquip] NULL,
[TransDesc] [dbo].[bItemDesc] NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[EMGroup] [dbo].[bGroup] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[PRCo] [dbo].[bCompany] NULL,
[PREmployee] [dbo].[bEmployee] NULL,
[WorkUM] [dbo].[bUM] NULL,
[WorkUnits] [numeric] (12, 3) NULL,
[TimeUM] [dbo].[bUM] NOT NULL,
[TimeUnits] [numeric] (12, 3) NULL,
[UnitCost] [numeric] (16, 5) NOT NULL,
[TotalCost] [numeric] (12, 2) NOT NULL,
[PRCrew] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMJC] ON [dbo].[bEMJC] ([EMCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [BatchSeq], [OldNew]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bEMJC].[UnitCost]'
GO
