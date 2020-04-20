CREATE TABLE [dbo].[vWFMailSources]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[Source] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFMailSources] ADD CONSTRAINT [PK_vWFMailSources] PRIMARY KEY CLUSTERED  ([Source], [KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
