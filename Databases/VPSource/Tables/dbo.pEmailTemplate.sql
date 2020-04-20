CREATE TABLE [dbo].[pEmailTemplate]
(
[EmailTemplateID] [int] NOT NULL IDENTITY(1, 1),
[Name] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[FromAddress] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ToAddress] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CCAddress] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BCCAddress] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Subject] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Body] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[pEmailTemplate] ADD CONSTRAINT [PK_pEmailTemplate] PRIMARY KEY CLUSTERED  ([EmailTemplateID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[pEmailTemplate] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pEmailTemplate] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pEmailTemplate] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pEmailTemplate] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pEmailTemplate] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pEmailTemplate] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pEmailTemplate] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pEmailTemplate] TO [viewpointcs]
GO
