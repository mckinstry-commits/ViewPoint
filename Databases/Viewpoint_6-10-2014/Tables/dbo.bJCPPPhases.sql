CREATE TABLE [dbo].[bJCPPPhases]
(
[Co] [dbo].[bCompany] NOT NULL,
[Month] [dbo].[bMonth] NULL,
[BatchId] [dbo].[bBatchID] NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCPPPhases] ON [dbo].[bJCPPPhases] ([Co], [Month], [BatchId], [Job], [Phase]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
