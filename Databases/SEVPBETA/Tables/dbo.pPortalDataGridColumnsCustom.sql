CREATE TABLE [dbo].[pPortalDataGridColumnsCustom]
(
[DataGridColumnID] [int] NOT NULL,
[HeaderText] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Visible] [bit] NULL,
[ColumnOrder] [int] NULL,
[DefaultValue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ColumnWidth] [int] NULL,
[IsRequired] [bit] NULL,
[DataFormatID] [int] NULL,
[MaxLength] [int] NULL,
[DataGridID] [int] NOT NULL,
[ColumnName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[HasLookup] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[pPortalDataGridColumnsCustom] ADD CONSTRAINT [PK_pPortalDataGridColumnsCustom] PRIMARY KEY CLUSTERED  ([DataGridColumnID]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[pPortalDataGridColumnsCustom] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pPortalDataGridColumnsCustom] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pPortalDataGridColumnsCustom] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pPortalDataGridColumnsCustom] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pPortalDataGridColumnsCustom] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pPortalDataGridColumnsCustom] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pPortalDataGridColumnsCustom] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pPortalDataGridColumnsCustom] TO [viewpointcs]
GO
