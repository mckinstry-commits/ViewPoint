CREATE TABLE [dbo].[bARMT]
(
[ARCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [dbo].[bCustomer] NOT NULL,
[Invoiced] [dbo].[bDollar] NOT NULL,
[Retainage] [dbo].[bDollar] NOT NULL,
[Paid] [dbo].[bDollar] NOT NULL,
[DiscountTaken] [dbo].[bDollar] NOT NULL,
[HighestCredit] [dbo].[bDollar] NOT NULL,
[NumInvPaid] [smallint] NOT NULL,
[PayDaysTrDt] [int] NOT NULL,
[PayDaysDueDt] [int] NOT NULL,
[LastInvDate] [dbo].[bDate] NULL,
[LastPayDate] [dbo].[bDate] NULL,
[FinanceChg] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARMT_FinanceChg] DEFAULT ((0))
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biABMT] ON [dbo].[bARMT] ([ARCo], [Mth], [CustGroup], [Customer]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biARMTCustomer] ON [dbo].[bARMT] ([ARCo], [CustGroup], [Customer], [Mth]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARMT].[Invoiced]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARMT].[Retainage]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARMT].[Paid]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARMT].[DiscountTaken]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARMT].[HighestCredit]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARMT].[NumInvPaid]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARMT].[PayDaysTrDt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARMT].[PayDaysDueDt]'
GO
