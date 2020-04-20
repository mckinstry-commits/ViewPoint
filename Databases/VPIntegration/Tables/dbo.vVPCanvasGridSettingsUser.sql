CREATE TABLE [dbo].[vVPCanvasGridSettingsUser]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[VPUserName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[QueryName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[CustomName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[GridLayout] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Sort] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[MaximumNumberOfRows] [int] NULL,
[ShowFilterBar] [dbo].[bYN] NOT NULL,
[QueryId] [int] NULL,
[ShowConfiguration] [dbo].[bYN] NULL,
[ShowTotals] [dbo].[bYN] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPCanvasGridSettingsUser] ADD CONSTRAINT [PK_vVPCanvasGridSettingsUser] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vVPCanvasGridSettingsUser_VPUserName_QueryName_CustomName] ON [dbo].[vVPCanvasGridSettingsUser] ([VPUserName], [QueryName], [CustomName]) ON [PRIMARY]
GO
