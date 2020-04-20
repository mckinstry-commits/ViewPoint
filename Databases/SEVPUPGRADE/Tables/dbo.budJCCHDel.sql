CREATE TABLE [dbo].[budJCCHDel]
(
[CostType] [dbo].[bJCCType] NOT NULL,
[DateTime] [dbo].[bDate] NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biudJCCHDel] ON [dbo].[budJCCHDel] ([JCCo], [Project], [Phase], [CostType]) ON [PRIMARY]
GO
