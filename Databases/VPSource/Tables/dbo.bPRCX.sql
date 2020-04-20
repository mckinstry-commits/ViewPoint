CREATE TABLE [dbo].[bPRCX]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Class] [dbo].[bClass] NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPRCX_Rate] DEFAULT ((0)),
[Basis] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRCX_Basis] DEFAULT ((0)),
[Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRCX_Amt] DEFAULT ((0)),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRCX] ON [dbo].[bPRCX] ([PRCo], [PRGroup], [PREndDate], [Employee], [PaySeq], [Craft], [Class], [EDLType], [EDLCode], [Rate]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCX].[Rate]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCX].[Basis]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCX].[Amt]'
GO
