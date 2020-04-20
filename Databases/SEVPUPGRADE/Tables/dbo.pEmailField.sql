CREATE TABLE [dbo].[pEmailField]
(
[EmailFieldID] [int] NOT NULL IDENTITY(1, 1),
[FieldKey] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Lookup] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[BuiltIn] [dbo].[bYN] NOT NULL CONSTRAINT [DF_pEmailField_BuiltIn] DEFAULT (N'N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[pEmailField] ADD CONSTRAINT [PK_pEmailField] PRIMARY KEY CLUSTERED  ([EmailFieldID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[pEmailField] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pEmailField] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pEmailField] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pEmailField] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pEmailField] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pEmailField] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pEmailField] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pEmailField] TO [viewpointcs]
GO
