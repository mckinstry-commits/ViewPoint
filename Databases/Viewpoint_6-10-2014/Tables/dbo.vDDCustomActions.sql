CREATE TABLE [dbo].[vDDCustomActions]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[Name] [varchar] (64) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[ImageKey] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[ActionType] [int] NOT NULL,
[Action] [varchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[KeyID] [int] NOT NULL,
[RequiresRecords] [dbo].[bYN] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDCustomActions] ADD CONSTRAINT [PK_vDDCustomActionsTEMP] PRIMARY KEY CLUSTERED  ([Id]) ON [PRIMARY]
GO
