CREATE TABLE [dbo].[bDDUD_Archive]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Identifier] [int] NOT NULL,
[TableName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Seq] [int] NULL,
[ColumnName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bDesc] NULL,
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ColType] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BidtekDefaultValue] [dbo].[bYN] NULL,
[RequiredValue] [dbo].[bYN] NULL,
[UpdateKeyYN] [dbo].[bYN] NOT NULL,
[ArchiveDate] [datetime] NULL CONSTRAINT [DF__bDDUD_Arc__Archi__08EF1B9D] DEFAULT (getdate()),
[ArchiveID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
