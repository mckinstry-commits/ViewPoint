CREATE TABLE [dbo].[vVPCanvasGridGroupedColumnsTemplate]
(
[ColumnId] [int] NOT NULL IDENTITY(1, 1),
[GridConfigurationId] [int] NULL,
[Name] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[ColumnOrder] [int] NOT NULL
) ON [PRIMARY]
GO
