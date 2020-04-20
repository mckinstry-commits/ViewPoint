CREATE TABLE [dbo].[vRFScenePerformanceCategories]
(
[CategoryID] [bigint] NOT NULL IDENTITY(1, 1),
[EpisodeID] [bigint] NOT NULL,
[Seconds] [decimal] (2, 0) NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viRFScenePerformanceCategories] ON [dbo].[vRFScenePerformanceCategories] ([CategoryID]) ON [PRIMARY]
GO
