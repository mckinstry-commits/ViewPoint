CREATE TABLE [dbo].[vVPCanvasGridColumnsUser]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[VPUserName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[QueryName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[CustomName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[Name] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[IsVisible] [dbo].[bYN] NOT NULL,
[Position] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPCanvasGridColumnsUser] ADD CONSTRAINT [PK_vVPCanvasGridColumnsUser] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vVPCanvasGridColumnsUser_VPUserName_QueryName_CustomName_Name] ON [dbo].[vVPCanvasGridColumnsUser] ([VPUserName], [QueryName], [CustomName], [Name]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
