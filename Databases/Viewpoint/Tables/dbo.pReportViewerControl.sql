CREATE TABLE [dbo].[pReportViewerControl]
(
[PageSiteControlID] [int] NOT NULL,
[SiteID] [int] NOT NULL,
[IsPrintAvailable] [bit] NOT NULL CONSTRAINT [DF_pReportViewerControl_IsPrintAvailable] DEFAULT ((1)),
[IsExportAvailable] [bit] NOT NULL CONSTRAINT [DF_pReportViewerControl_IsExportAvailable] DEFAULT ((1)),
[IsRefreshAvailable] [bit] NOT NULL CONSTRAINT [DF_pReportViewerControl_IsRefreshAvailable] DEFAULT ((1)),
[IsPaginationAvailable] [bit] NOT NULL CONSTRAINT [DF_pReportViewerControl_IsPaginationAvailable] DEFAULT ((1)),
[IsBackButtonAvailable] [bit] NOT NULL CONSTRAINT [DF_pReportViewerControl_IsBackButtonAvailable] DEFAULT ((1)),
[IsSearchAvailable] [bit] NOT NULL CONSTRAINT [DF_pReportViewerControl_IsSearchAvailable] DEFAULT ((1)),
[IsZoomAvailable] [bit] NOT NULL CONSTRAINT [DF_pReportViewerControl_IsZoomAvailable] DEFAULT ((1)),
[IsParameterPromptCollapsed] [bit] NOT NULL CONSTRAINT [DF_pReportViewerControl_IsParameterPromptCollapsed] DEFAULT ((1)),
[DefaultZoomLevel] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[Height] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[ReportID] [int] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[pReportViewerControl] WITH NOCHECK ADD
CONSTRAINT [FK_pReportViewerControl_pPageSiteControls] FOREIGN KEY ([PageSiteControlID]) REFERENCES [dbo].[pPageSiteControls] ([PageSiteControlID]) ON DELETE CASCADE
ALTER TABLE [dbo].[pReportViewerControl] WITH NOCHECK ADD
CONSTRAINT [FK_pReportViewerControl_pSites] FOREIGN KEY ([SiteID]) REFERENCES [dbo].[pSites] ([SiteID])
GO
ALTER TABLE [dbo].[pReportViewerControl] ADD CONSTRAINT [PK_pReportViewerControl] PRIMARY KEY CLUSTERED  ([PageSiteControlID]) ON [PRIMARY]
GO

GRANT SELECT ON  [dbo].[pReportViewerControl] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pReportViewerControl] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pReportViewerControl] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pReportViewerControl] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pReportViewerControl] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pReportViewerControl] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pReportViewerControl] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pReportViewerControl] TO [viewpointcs]
GO
