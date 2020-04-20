CREATE TABLE [dbo].[vVPDisplayTabNavigation]
(
[KeyID] [int] NOT NULL,
[Description] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[TemplateName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPDisplayTabNavigation] ADD CONSTRAINT [PK_vVPDisplayTabNavigation] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
