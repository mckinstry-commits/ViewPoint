CREATE TABLE [dbo].[McKTempPRStatesEmp]
(
[Employee] [float] NULL,
[TaxState] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[UnempState] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[InsState] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[LocalCode] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[WOTaxState] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[UseState ] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[UseUnempState] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[UseInsState] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[UseLocal] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[UseIns] [nvarchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
