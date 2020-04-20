CREATE TABLE [dbo].[pPortalDetailsFieldCustom]
(
[DetailsFieldID] [int] NOT NULL,
[DetailsID] [int] NOT NULL,
[ColumnName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[LabelText] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Editable] [int] NULL,
[Required] [bit] NULL,
[TextMode] [int] NULL,
[MaxLength] [int] NULL,
[DetailsFieldOrder] [int] NULL,
[Visible] [bit] NULL,
[DataFormatID] [int] NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Seq] [smallint] NULL,
[TextID] [int] NULL,
[HasLookup] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[pPortalDetailsFieldCustom] ADD CONSTRAINT [PK_pDetailsFieldCustom] PRIMARY KEY CLUSTERED  ([DetailsFieldID]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[pPortalDetailsFieldCustom] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pPortalDetailsFieldCustom] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pPortalDetailsFieldCustom] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pPortalDetailsFieldCustom] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pPortalDetailsFieldCustom] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pPortalDetailsFieldCustom] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pPortalDetailsFieldCustom] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pPortalDetailsFieldCustom] TO [viewpointcs]
GO
