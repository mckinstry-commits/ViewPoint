CREATE TABLE [dbo].[vDDGBc]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Tab] [tinyint] NOT NULL,
[GroupBox] [tinyint] NOT NULL,
[Title] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ControlPosition] [varchar] (20) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viDDGBc] ON [dbo].[vDDGBc] ([Form], [Tab], [GroupBox]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
