CREATE TABLE [dbo].[vVPCanvasGridColumns]
(
[ColumnId] [int] NOT NULL IDENTITY(1, 1),
[GridConfigurationId] [int] NULL,
[Name] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[IsVisible] [dbo].[bYN] NOT NULL,
[Position] [int] NULL,
[FilterValue] [varchar] (128) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vVPCanvasGridColumns_GridConfigurationIdName] ON [dbo].[vVPCanvasGridColumns] ([GridConfigurationId], [Name]) ON [PRIMARY]
GO
