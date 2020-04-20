CREATE TABLE [dbo].[bPREM]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[CostCode] [dbo].[bCostCode] NOT NULL,
[EMCType] [dbo].[bEMCType] NOT NULL,
[EMFields] [char] (39) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[PostSeq] [smallint] NOT NULL,
[PostDate] [dbo].[bDate] NOT NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[Hrs] [dbo].[bHrs] NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL,
[OldHrs] [dbo].[bHrs] NOT NULL,
[OldAmt] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPREM] ON [dbo].[bPREM] ([PRCo], [PRGroup], [PREndDate], [Mth], [EMCo], [Equipment], [EMGroup], [CostCode], [EMCType], [EMFields], [Employee], [PaySeq], [PostSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
