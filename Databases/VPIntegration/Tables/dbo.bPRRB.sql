CREATE TABLE [dbo].[bPRRB]
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
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[PostSeq] [smallint] NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLRevAcct] [dbo].[bGLAcct] NOT NULL,
[OldAmt] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRRB] ON [dbo].[bPRRB] ([PRCo], [PRGroup], [PREndDate], [Mth], [EMCo], [Equipment], [EMGroup], [RevCode], [EMFields], [RevBdownCode], [Employee], [PaySeq], [PostSeq]) ON [PRIMARY]
GO
