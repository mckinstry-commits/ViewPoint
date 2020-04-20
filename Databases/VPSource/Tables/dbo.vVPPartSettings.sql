CREATE TABLE [dbo].[vVPPartSettings]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[VPUserName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[PartName] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[ColumnNumber] [int] NULL,
[RowNumber] [int] NULL,
[Height] [int] NULL,
[Width] [int] NULL,
[ConfigurationSettings] [varbinary] (max) NULL,
[CollapseDirection] [tinyint] NULL,
[ShowConfiguration] [dbo].[bYN] NULL,
[CanCollapse] [dbo].[bYN] NULL,
[IsCollapsed] [dbo].[bYN] NULL,
[CanvasId] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
