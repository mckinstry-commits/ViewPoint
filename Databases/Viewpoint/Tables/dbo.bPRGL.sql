CREATE TABLE [dbo].[bPRGL]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL,
[OldAmt] [dbo].[bDollar] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPRGL_Hours] DEFAULT ((0)),
[OldHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPRGL_OldHours] DEFAULT ((0))
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRGL] ON [dbo].[bPRGL] ([PRCo], [PRGroup], [PREndDate], [Mth], [GLCo], [GLAcct], [Employee], [PaySeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
