CREATE TABLE [dbo].[vVPCanvasGridPartSettingsTemplate]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[PartId] [int] NOT NULL,
[LastQuery] [varchar] (128) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPCanvasGridPartSettingsTemplate] ADD CONSTRAINT [PK__vVPCanvasGridPar__1D6355FA] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
