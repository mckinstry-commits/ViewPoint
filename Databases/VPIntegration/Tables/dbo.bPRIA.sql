CREATE TABLE [dbo].[bPRIA]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[InsCode] [dbo].[bInsCode] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[Earnings] [dbo].[bDollar] NOT NULL,
[SubjectAmt] [dbo].[bDollar] NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL,
[EligibleAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRIA_EligibleAmt] DEFAULT ((0)),
[BasisEarnings] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRIA_BasisEarnings] DEFAULT ((0)),
[CalcBasis] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRIA_CalcBasis] DEFAULT ((0)),
[Hours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPRIA_Hours] DEFAULT ((0)),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRIA] ON [dbo].[bPRIA] ([PRCo], [PRGroup], [PREndDate], [Employee], [PaySeq], [State], [InsCode], [DLCode]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRIA].[Rate]'
GO
