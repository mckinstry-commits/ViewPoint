CREATE TABLE [dbo].[vCurrency]
(
[CurrencyID] [int] NOT NULL IDENTITY(1, 1),
[CurrencyName] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[CurrencySymbol] [char] (250) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vCurrency] ADD CONSTRAINT [PK_vCurrency] PRIMARY KEY CLUSTERED  ([CurrencyID]) ON [PRIMARY]
GO
