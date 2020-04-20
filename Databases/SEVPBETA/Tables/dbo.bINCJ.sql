CREATE TABLE [dbo].[bINCJ]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[MO] [dbo].[bMO] NOT NULL,
[MOItem] [dbo].[bItem] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[ConfirmDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ConfirmUnits] [dbo].[bUnits] NOT NULL,
[RemainUnits] [dbo].[bUnits] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[ConfirmTotal] [dbo].[bDollar] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxAmt] [dbo].[bDollar] NOT NULL,
[StkUM] [dbo].[bUM] NOT NULL,
[StkUnitCost] [dbo].[bUnitCost] NOT NULL,
[StkECM] [dbo].[bECM] NOT NULL,
[JCUM] [dbo].[bUM] NULL,
[JCConfirmUnits] [dbo].[bUnits] NOT NULL,
[JCRemUnits] [dbo].[bUnits] NOT NULL,
[JCTotalCmtdCost] [dbo].[bDollar] NOT NULL,
[JCRemainCmtdCost] [dbo].[bDollar] NOT NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bINCJ_TaxBasis] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biINCJ] ON [dbo].[bINCJ] ([INCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINCJ].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINCJ].[StkECM]'
GO
