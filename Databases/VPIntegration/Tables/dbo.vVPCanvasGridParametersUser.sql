CREATE TABLE [dbo].[vVPCanvasGridParametersUser]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[VPUserName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[QueryName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[CustomName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[Name] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[SqlType] [int] NOT NULL,
[ParameterValue] [varchar] (256) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPCanvasGridParametersUser] ADD CONSTRAINT [PK_vVPCanvasGridParametersUser] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vVPCanvasGridParametersUser_VPUserName_QueryName_CustomName_Name] ON [dbo].[vVPCanvasGridParametersUser] ([VPUserName], [QueryName], [CustomName], [Name]) ON [PRIMARY]
GO
