CREATE TABLE [dbo].[bWDQFSave]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[TableColumn] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[EMailField] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[IsKeyField] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bWDQFSave_IsKeyField] DEFAULT ('N')
) ON [PRIMARY]
GO
