CREATE TABLE [dbo].[vVPCanvasGridPartSettings]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[PartId] [int] NOT NULL,
[LastQuery] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[Seq] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPCanvasGridPartSettings] ADD CONSTRAINT [PK_vVPCanvasGridPar] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
