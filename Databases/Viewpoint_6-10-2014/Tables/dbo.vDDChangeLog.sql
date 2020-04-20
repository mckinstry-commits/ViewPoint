CREATE TABLE [dbo].[vDDChangeLog]
(
[LogID] [int] NOT NULL IDENTITY(1, 1),
[TableName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[KeyString] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[Action] [char] (1) COLLATE Latin1_General_BIN NULL,
[FieldName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[OldValue] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[NewValue] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DateTime] [datetime] NULL,
[MachineName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[CommandText] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[ExcludeRecord] [dbo].[bYN] NULL CONSTRAINT [DF_vDDChangeLog_ExcludeRecord] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDChangeLog] ADD CONSTRAINT [PK_vDDChangeLog] PRIMARY KEY CLUSTERED  ([LogID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
