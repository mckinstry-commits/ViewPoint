CREATE TABLE [dbo].[vVPCanvasTemplateGroup]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[Description] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPCanvasTemplateGroup] ADD CONSTRAINT [PK_vVPCanvasTemplateGroup] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
