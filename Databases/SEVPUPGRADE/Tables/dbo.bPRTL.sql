CREATE TABLE [dbo].[bPRTL]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[PostSeq] [smallint] NOT NULL,
[LiabCode] [dbo].[bEDLCode] NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRTL] ON [dbo].[bPRTL] ([PRCo], [PRGroup], [PREndDate], [Employee], [PaySeq], [PostSeq], [LiabCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRTL].[Rate]'
GO
