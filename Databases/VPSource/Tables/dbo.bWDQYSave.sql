CREATE TABLE [dbo].[bWDQYSave]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Title] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SelectClause] [varchar] (8000) COLLATE Latin1_General_BIN NOT NULL,
[FromWhereClause] [varchar] (8000) COLLATE Latin1_General_BIN NULL,
[Standard] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[IsEventQuery] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bWDQYSave_IsEventQuery] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bWDQYSave].[Standard]'
GO
