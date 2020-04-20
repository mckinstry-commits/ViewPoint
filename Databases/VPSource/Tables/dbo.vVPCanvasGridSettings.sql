CREATE TABLE [dbo].[vVPCanvasGridSettings]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[QueryName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL CONSTRAINT [DF_vVPCanvasGridSettings_Seq] DEFAULT ((0)),
[CustomName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[GridLayout] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Sort] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[MaximumNumberOfRows] [int] NULL,
[ShowFilterBar] [dbo].[bYN] NOT NULL,
[PartId] [int] NOT NULL,
[QueryId] [int] NULL,
[GridType] [int] NOT NULL CONSTRAINT [DF_vVPCanvasGridSettings_GridType] DEFAULT ((0)),
[ShowConfiguration] [dbo].[bYN] NULL,
[ShowTotals] [dbo].[bYN] NULL,
[IsDrillThrough] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPCanvasGridSettings_IsDrillThrough] DEFAULT ('N'),
[SelectedRow] [int] NOT NULL CONSTRAINT [DF_vVPCanvasGridSettings_SelectedRow] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPCanvasGridSettings] ADD CONSTRAINT [PK_vVPCanvasGridSet] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
