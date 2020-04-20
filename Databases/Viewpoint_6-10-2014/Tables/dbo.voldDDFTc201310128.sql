CREATE TABLE [dbo].[voldDDFTc201310128]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Tab] [tinyint] NOT NULL,
[Title] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[GridForm] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[LoadSeq] [tinyint] NULL,
[IsVisible] [dbo].[bYN] NULL,
[Type] [tinyint] NOT NULL,
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
