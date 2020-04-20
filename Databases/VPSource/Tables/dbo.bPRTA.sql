CREATE TABLE [dbo].[bPRTA]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[PostSeq] [smallint] NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPRTA_Rate] DEFAULT ((0)),
[Amt] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRTA] ON [dbo].[bPRTA] ([PRCo], [PRGroup], [PREndDate], [Employee], [PaySeq], [PostSeq], [EarnCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRTA].[Rate]'
GO
