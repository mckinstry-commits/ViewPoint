CREATE TABLE [dbo].[vWFProcessHeader]
(
[SourceView] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[SourceKeyID] [bigint] NOT NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFProcessHeader] ADD CONSTRAINT [PK_vWFProcessHeader] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
