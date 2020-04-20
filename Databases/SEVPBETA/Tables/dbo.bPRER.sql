CREATE TABLE [dbo].[bPRER]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[EMGroup] [tinyint] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[EMFields] [char] (54) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[PostSeq] [smallint] NOT NULL,
[PostDate] [dbo].[bDate] NOT NULL,
[EMGLCo] [dbo].[bCompany] NOT NULL,
[RevGLAcct] [dbo].[bGLAcct] NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[JCGLCo] [dbo].[bCompany] NOT NULL,
[JCExpGLAcct] [dbo].[bGLAcct] NOT NULL,
[TimeUM] [dbo].[bUM] NULL,
[TimeUnits] [dbo].[bUnits] NOT NULL,
[WorkUM] [dbo].[bUM] NULL,
[WorkUnits] [dbo].[bUnits] NOT NULL,
[Rate] [dbo].[bDollar] NOT NULL,
[Revenue] [dbo].[bDollar] NOT NULL,
[OldTimeUnits] [dbo].[bUnits] NOT NULL,
[OldWorkUnits] [dbo].[bUnits] NOT NULL,
[OldRevenue] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRER] ON [dbo].[bPRER] ([PRCo], [PRGroup], [PREndDate], [Mth], [EMCo], [Equipment], [EMGroup], [RevCode], [EMFields], [Employee], [PaySeq], [PostSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRER].[Rate]'
GO
