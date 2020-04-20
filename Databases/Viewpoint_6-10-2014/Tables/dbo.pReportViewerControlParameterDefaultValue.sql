CREATE TABLE [dbo].[pReportViewerControlParameterDefaultValue]
(
[PageSiteControlID] [int] NOT NULL,
[ReportID] [int] NOT NULL,
[ParameterName] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ParameterDefaultValue] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[pReportViewerControlParameterDefaultValue] ADD CONSTRAINT [PK_pReportViewerControlParameterDefaultValue_1] PRIMARY KEY CLUSTERED  ([PageSiteControlID], [ReportID], [ParameterName]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[pReportViewerControlParameterDefaultValue] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pReportViewerControlParameterDefaultValue] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pReportViewerControlParameterDefaultValue] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pReportViewerControlParameterDefaultValue] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pReportViewerControlParameterDefaultValue] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pReportViewerControlParameterDefaultValue] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pReportViewerControlParameterDefaultValue] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pReportViewerControlParameterDefaultValue] TO [viewpointcs]
GO
