CREATE TABLE [dbo].[vVPPartSettingsTemplatec]
(
[TemplateName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPPartSettingsTemplatec_IsStandard] DEFAULT ('N'),
[PartName] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[ColumnNumber] [int] NULL,
[RowNumber] [int] NULL,
[Height] [int] NULL,
[Width] [int] NULL,
[ConfigurationSettings] [varbinary] (max) NULL,
[KeyID] [int] NOT NULL IDENTITY(2, 2),
[CollapseDirection] [tinyint] NULL,
[ShowConfiguration] [dbo].[bYN] NULL,
[CanCollapse] [dbo].[bYN] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
