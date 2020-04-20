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
[ActualHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCHJ_ActualHours] DEFAULT ((0)),
[ActualUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCHJ_ActualUnits] DEFAULT ((0)),
[ActualCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCHJ_ActualCost] DEFAULT ((0)),
[OrigEstHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCHJ_OrigEstHours] DEFAULT ((0)),
[OrigEstUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCHJ_OrigEstUnits] DEFAULT ((0)),
[OrigEstCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCHJ_OrigEstCost] DEFAULT ((0)),
[CurrEstHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCHJ_CurrEstHours] DEFAULT ((0)),
[CurrEstUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCHJ_CurrEstUnits] DEFAULT ((0)),
[CurrEstCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCHJ_CurrEstCost] DEFAULT ((0)),
[ProjHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCHJ_ProjHours] DEFAULT ((0)),
[ProjUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCHJ_ProjUnits] DEFAULT ((0)),
[ProjCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCHJ_ProjCost] DEFAULT ((0)),
[ItemUnitFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCHJ_ItemUnitFlag] DEFAULT ('N')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bJCHJ] WITH NOCHECK ADD CONSTRAINT [CK_bJCHJ_ItemUnitFlag] CHECK (([ItemUnitFlag]='Y' OR [ItemUnitFlag]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biJCHJ] ON [dbo].[bJCHJ] ([JCCo], [Contract], [Item], [Job], [PhaseGroup], [Phase], [CostType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
