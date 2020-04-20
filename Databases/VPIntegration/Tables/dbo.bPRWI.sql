CREATE TABLE [dbo].[bPRWI]
(
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Item] [tinyint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[AmtType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[W2Code] [varchar] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRWI] ON [dbo].[bPRWI] ([TaxYear], [Item]) ON [PRIMARY]
GO
