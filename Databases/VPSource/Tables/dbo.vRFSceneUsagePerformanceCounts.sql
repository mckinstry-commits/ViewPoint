CREATE TABLE [dbo].[vRFSceneUsagePerformanceCounts]
(
[PerformanceID] [bigint] NOT NULL IDENTITY(1, 1),
[SceneID] [bigint] NOT NULL,
[CategorySeconds] [decimal] (2, 0) NOT NULL,
[CategoryCount] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viRFSceneUsagePerformanceCounts] ON [dbo].[vRFSceneUsagePerformanceCounts] ([PerformanceID]) ON [PRIMARY]
GO
