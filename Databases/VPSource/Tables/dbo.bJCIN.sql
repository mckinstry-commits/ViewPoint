CREATE TABLE [dbo].[bJCIN]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[PstUM] [dbo].[bUM] NOT NULL,
[PstUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCIN_PstUnits] DEFAULT ((0)),
[PstUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCIN_PstUnitCost] DEFAULT ((0)),
[PstECM] [dbo].[bECM] NOT NULL,
[PstTotal] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCIN_PstTotal] DEFAULT ((0)),
[StdUM] [dbo].[bUM] NOT NULL,
[StdUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCIN_StdUnits] DEFAULT ((0)),
[StdUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCIN_StdUnitCost] DEFAULT ((0)),
[StdECM] [dbo].[bECM] NOT NULL,
[StdTotalCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCIN_StdTotalCost] DEFAULT ((0)),
[UnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCIN_UnitPrice] DEFAULT ((0)),
[TotalPrice] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCIN_TotalPrice] DEFAULT ((0))
) ON [PRIMARY]
ALTER TABLE [dbo].[bJCIN] ADD
CONSTRAINT [CK_bJCIN_PstECM] CHECK (([PstECM]='E' OR [PstECM]='C' OR [PstECM]='M'))
ALTER TABLE [dbo].[bJCIN] ADD
CONSTRAINT [CK_bJCIN_StdECM] CHECK (([StdECM]='E' OR [StdECM]='C' OR [StdECM]='M'))
GO
CREATE UNIQUE CLUSTERED INDEX [biJCIN] ON [dbo].[bJCIN] ([JCCo], [Mth], [BatchId], [INCo], [Loc], [MatlGroup], [Material], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIN].[PstUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIN].[PstUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bJCIN].[PstECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIN].[PstTotal]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIN].[StdUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIN].[StdUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bJCIN].[StdECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIN].[StdTotalCost]'
GO
