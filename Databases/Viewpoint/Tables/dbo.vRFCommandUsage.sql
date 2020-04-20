CREATE TABLE [dbo].[vRFCommandUsage]
(
[CommandID] [bigint] NOT NULL IDENTITY(1, 1),
[SceneID] [bigint] NOT NULL,
[CommandName] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[AllExecutionsSeconds] [decimal] (2, 0) NOT NULL,
[MaximumExecutionSeconds] [decimal] (2, 0) NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viRFCommandUsage] ON [dbo].[vRFCommandUsage] ([CommandID]) ON [PRIMARY]
GO
