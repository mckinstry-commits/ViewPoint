CREATE TABLE [dbo].[vRFCommandUsagePerformanceCounts]
(
[PerformanceID] [bigint] NOT NULL IDENTITY(1, 1),
[CommandID] [bigint] NOT NULL,
[CategorySeconds] [decimal] (6, 2) NOT NULL,
[CategoryCount] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viRFCommandUsagePerformanceCounts] ON [dbo].[vRFCommandUsagePerformanceCounts] ([PerformanceID]) ON [PRIMARY]
GO
