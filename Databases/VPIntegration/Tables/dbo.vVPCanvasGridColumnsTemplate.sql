CREATE TABLE [dbo].[vVPCanvasGridColumnsTemplate]
(
[ColumnId] [int] NOT NULL IDENTITY(1, 1),
[GridConfigurationId] [int] NULL,
[Name] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[IsVisible] [dbo].[bYN] NOT NULL,
[Position] [int] NULL
) ON [PRIMARY]
GO
