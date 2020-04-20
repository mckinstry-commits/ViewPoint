CREATE TABLE [dbo].[vVPCanvasGridGroupedColumnsUser]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[VPUserName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[QueryName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[CustomName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[Name] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[ColumnOrder] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPCanvasGridGroupedColumnsUser] ADD CONSTRAINT [PK_vVPCanvasGridGroupedColumnsUser] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vVPCanvasGridGroupedColumnsUser_VPUserName_QueryName_CustomName_Name] ON [dbo].[vVPCanvasGridGroupedColumnsUser] ([VPUserName], [QueryName], [CustomName], [Name]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
