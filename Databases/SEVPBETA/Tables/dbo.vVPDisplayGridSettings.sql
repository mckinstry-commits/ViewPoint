CREATE TABLE [dbo].[vVPDisplayGridSettings]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[DisplayID] [int] NOT NULL,
[QueryName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[MaximumNumberOfRows] [int] NULL,
[GridType] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPDisplayGridSettings] ADD CONSTRAINT [PK_vVPDisplayGridSettings] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
