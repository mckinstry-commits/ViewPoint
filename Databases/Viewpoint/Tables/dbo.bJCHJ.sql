CREATE TABLE [dbo].[bJCHJ]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[JobDesc] [dbo].[bItemDesc] NULL,
[PhaseDesc] [dbo].[bItemDesc] NULL,
[ProjMgr] [int] NULL,
[UM] [dbo].[bUM] NOT NULL,
[ActualHours] [dbo].[bHrs] NOT NULL,
[ActualUnits] [dbo].[bUnits] NOT NULL,
[ActualCost] [dbo].[bDollar] NOT NULL,
[OrigEstHours] [dbo].[bHrs] NOT NULL,
[OrigEstUnits] [dbo].[bUnits] NOT NULL,
[OrigEstCost] [dbo].[bDollar] NOT NULL,
[CurrEstHours] [dbo].[bHrs] NOT NULL,
[CurrEstUnits] [dbo].[bUnits] NOT NULL,
[CurrEstCost] [dbo].[bDollar] NOT NULL,
[ProjHours] [dbo].[bHrs] NOT NULL,
[ProjUnits] [dbo].[bUnits] NOT NULL,
[ProjCost] [dbo].[bDollar] NOT NULL,
[ItemUnitFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCHJ_ItemUnitFlag] DEFAULT ('N')
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJCHJ] ON [dbo].[bJCHJ] ([JCCo], [Contract], [Item], [Job], [PhaseGroup], [Phase], [CostType]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCHJ].[ActualHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCHJ].[ActualUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCHJ].[ActualCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCHJ].[OrigEstHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCHJ].[OrigEstUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCHJ].[OrigEstCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCHJ].[CurrEstHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCHJ].[CurrEstUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCHJ].[CurrEstCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCHJ].[ProjHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCHJ].[ProjUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCHJ].[ProjCost]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCHJ].[ItemUnitFlag]'
GO
