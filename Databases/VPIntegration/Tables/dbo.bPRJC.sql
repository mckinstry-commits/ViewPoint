CREATE TABLE [dbo].[bPRJC]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCostType] [dbo].[bJCCType] NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[JCFields] [varchar] (70) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[PostSeq] [smallint] NOT NULL,
[PostDate] [dbo].[bDate] NOT NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Factor] [dbo].[bRate] NULL,
[EarnType] [dbo].[bEarnType] NULL,
[Shift] [tinyint] NULL,
[LiabType] [dbo].[bLiabilityType] NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[JCGLCo] [dbo].[bCompany] NULL,
[JCGLAcct] [dbo].[bGLAcct] NULL,
[TimeUM] [dbo].[bUM] NULL,
[TimeUnits] [dbo].[bUnits] NOT NULL,
[WorkUM] [dbo].[bUM] NULL,
[WorkUnits] [dbo].[bUnits] NOT NULL,
[Hrs] [dbo].[bHrs] NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL,
[JCUM] [dbo].[bUM] NULL,
[JCUnits] [dbo].[bUnits] NOT NULL,
[OldWorkUnits] [dbo].[bUnits] NOT NULL,
[OldHrs] [dbo].[bHrs] NOT NULL,
[OldAmt] [dbo].[bDollar] NOT NULL,
[OldJCUnits] [dbo].[bUnits] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bPRJC_JCCo] ON [dbo].[bPRJC] ([JCCo]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bPRJC_MthJCCoJOBPhaseGroup] ON [dbo].[bPRJC] ([Mth], [JCCo], [Job], [PhaseGroup], [Phase]) INCLUDE ([Employee], [PaySeq], [PostSeq], [PRCo], [PREndDate], [PRGroup]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRJC] ON [dbo].[bPRJC] ([PRCo], [PRGroup], [PREndDate], [Mth], [JCCo], [Job], [PhaseGroup], [Phase], [JCCostType], [Type], [JCFields], [Employee], [PaySeq], [PostSeq]) ON [PRIMARY]
GO
