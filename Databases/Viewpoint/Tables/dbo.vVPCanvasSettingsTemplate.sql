CREATE TABLE [dbo].[vVPCanvasSettingsTemplate]
(
[TemplateName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPCanvasSettingsTemplate_IsStandard] DEFAULT ('Y'),
[NumberOfRows] [int] NULL,
[NumberOfColumns] [int] NULL,
[RefreshInterval] [int] NULL,
[TableLayout] [varbinary] (max) NULL,
[KeyID] [int] NOT NULL IDENTITY(1, 2),
[GroupID] [int] NULL CONSTRAINT [DF_vVPCanvasSettingsTemplate_GroupID] DEFAULT ((1)),
[GridLayout] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_vVPCanvasSettingsTemplate_TemplateName] ON [dbo].[vVPCanvasSettingsTemplate] ([TemplateName]) WITH (FILLFACTOR=80) ON [PRIMARY]

GO
ALTER TABLE [dbo].[vVPCanvasSettingsTemplate] ADD CONSTRAINT [PK_vVPCanvasSettingsTemplate] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
