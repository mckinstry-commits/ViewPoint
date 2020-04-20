CREATE TABLE [dbo].[bARMT]
(
[ARCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [dbo].[bCustomer] NOT NULL,
[Invoiced] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARMT_Invoiced] DEFAULT ((0)),
[Retainage] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARMT_Retainage] DEFAULT ((0)),
[Paid] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARMT_Paid] DEFAULT ((0)),
[DiscountTaken] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARMT_DiscountTaken] DEFAULT ((0)),
[HighestCredit] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARMT_HighestCredit] DEFAULT ((0)),
[NumInvPaid] [smallint] NOT NULL CONSTRAINT [DF_bARMT_NumInvPaid] DEFAULT ((0)),
[PayDaysTrDt] [int] NOT NULL CONSTRAINT [DF_bARMT_PayDaysTrDt] DEFAULT ((0)),
[PayDaysDueDt] [int] NOT NULL CONSTRAINT [DF_bARMT_PayDaysDueDt] DEFAULT ((0)),
[LastInvDate] [dbo].[bDate] NULL,
[LastPayDate] [dbo].[bDate] NULL,
[FinanceChg] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARMT_FinanceChg] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biARMTCustomer] ON [dbo].[bARMT] ([ARCo], [CustGroup], [Customer], [Mth]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biABMT] ON [dbo].[bARMT] ([ARCo], [Mth], [CustGroup], [Customer]) WITH (FILLFACTOR=90) ON [PRIMARY]
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
