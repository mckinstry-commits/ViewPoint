CREATE TABLE [dbo].[budXRefPayTerms]
(
[CGCCode] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[PaymentTerms] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[DiscountOptions] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[DaystilDisc] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[DiscDay] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[DueDateOptions] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[DaystilDue] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[DueDay] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[CutOffDay] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[DiscRate] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[RollAhead] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[DiscMatl] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (50) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
