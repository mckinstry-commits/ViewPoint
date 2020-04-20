CREATE TABLE [dbo].[bPRSX]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Code] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Amt1] [dbo].[bDollar] NOT NULL,
[Amt2] [dbo].[bDollar] NOT NULL,
[Amt3] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRSX] ON [dbo].[bPRSX] ([PRCo], [PRGroup], [PREndDate], [Employee], [PaySeq], [Type], [Code], [Rate]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRSX].[Rate]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRSX].[Amt1]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRSX].[Amt2]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRSX].[Amt3]'
GO
