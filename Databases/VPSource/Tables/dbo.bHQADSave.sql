CREATE TABLE [dbo].[bHQADSave]
(
[RecID] [int] NOT NULL,
[ColumnName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ParentColumn] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Custom] [dbo].[bYN] NOT NULL,
[Module] [char] (2) COLLATE Latin1_General_BIN NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SkipIndex] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
GO
