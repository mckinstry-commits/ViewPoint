CREATE TABLE [dbo].[vDDFTc]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Tab] [tinyint] NOT NULL,
[Title] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[GridForm] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[LoadSeq] [tinyint] NULL,
[IsVisible] [dbo].[bYN] NULL,
[Type] [tinyint] NOT NULL CONSTRAINT [DF_vDDFTc_Type] DEFAULT ((0)),
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [viDDFTc] ON [dbo].[vDDFTc] ([Form], [Tab]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFTc].[IsVisible]'
GO
