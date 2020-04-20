CREATE TABLE [dbo].[bARBJ]
(
[ARCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[ARLine] [smallint] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CT] [dbo].[bJCCType] NOT NULL,
[ARTrans] [dbo].[bTrans] NULL,
[CheckNo] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ActualUM] [dbo].[bUM] NULL,
[ActualUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bARBJ_ActualUnits] DEFAULT ((0)),
[ActualHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bARBJ_ActualHours] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biARBJ] ON [dbo].[bARBJ] ([ARCo], [Mth], [BatchId], [JCCo], [Job], [Phase], [CT], [BatchSeq], [ARLine], [GLCo], [GLAcct], [OldNew]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARBJ].[Units]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARBJ].[Hours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARBJ].[Amount]'
GO
