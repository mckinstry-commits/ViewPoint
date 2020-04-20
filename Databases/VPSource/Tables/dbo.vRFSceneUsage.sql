CREATE TABLE [dbo].[vRFSceneUsage]
(
[SceneID] [bigint] NOT NULL IDENTITY(1, 1),
[EpisodeID] [bigint] NOT NULL,
[Module] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[SceneName] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[ActivationCount] [int] NOT NULL,
[ShownSeconds] [decimal] (2, 0) NOT NULL,
[ActiveSeconds] [decimal] (2, 0) NOT NULL,
[IdleSeconds] [decimal] (2, 0) NOT NULL,
[AllStartupSeconds] [decimal] (2, 0) NOT NULL,
[MaxStartupSeconds] [decimal] (2, 0) NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viRFSceneUsage] ON [dbo].[vRFSceneUsage] ([SceneID]) ON [PRIMARY]
GO
