CREATE TABLE [dbo].[vVPCanvasGridSettingsTemplate]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[PartId] [int] NOT NULL,
[QueryName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[GridLayout] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Sort] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[MaximumNumberOfRows] [int] NULL,
[ShowFilterBar] [dbo].[bYN] NOT NULL,
[QueryId] [int] NULL,
[GridType] [int] NOT NULL CONSTRAINT [DF__vVPCanvas__GridT__6EE9298A] DEFAULT ((0)),
[ShowConfiguration] [dbo].[bYN] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPCanvasGridSettingsTemplate] ADD CONSTRAINT [PK__vVPCanvasGridSet__1F4B9E6C] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
