CREATE TABLE [dbo].[vVPCanvasSettingsTemplatec]
(
[TemplateName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPCanvasSettingsTemplatec_IsStandard] DEFAULT ('N'),
[NumberOfRows] [int] NULL,
[NumberOfColumns] [int] NULL,
[RefreshInterval] [int] NULL,
[TableLayout] [varbinary] (max) NULL,
[KeyID] [int] NOT NULL IDENTITY(2, 2),
[GroupID] [int] NULL,
[GridLayout] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
