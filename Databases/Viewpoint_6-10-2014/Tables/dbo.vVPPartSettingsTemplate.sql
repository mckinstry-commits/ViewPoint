CREATE TABLE [dbo].[vVPPartSettingsTemplate]
(
[TemplateName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPPartSettingsTemplate_IsStandard] DEFAULT ('Y'),
[PartName] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[ColumnNumber] [int] NOT NULL,
[RowNumber] [int] NOT NULL,
[Height] [int] NULL,
[Width] [int] NULL,
[ConfigurationSettings] [varbinary] (max) NULL,
[KeyID] [int] NOT NULL IDENTITY(1, 2),
[CollapseDirection] [tinyint] NULL,
[ShowConfiguration] [dbo].[bYN] NULL,
[CanCollapse] [dbo].[bYN] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPPartSettingsTemplate] ADD CONSTRAINT [PK_vVPPartSettingsTemplate] PRIMARY KEY CLUSTERED  ([TemplateName], [ColumnNumber], [RowNumber]) ON [PRIMARY]
GO
