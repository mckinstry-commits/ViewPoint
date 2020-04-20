CREATE TABLE [dbo].[bINMA]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BeginQty] [dbo].[bUnits] NOT NULL,
[BeginValue] [dbo].[bDollar] NOT NULL,
[BeginLastCost] [dbo].[bUnitCost] NOT NULL,
[BeginLastECM] [dbo].[bECM] NOT NULL,
[BeginAvgCost] [dbo].[bUnitCost] NOT NULL,
[BeginAvgECM] [dbo].[bECM] NOT NULL,
[BeginStdCost] [dbo].[bUnitCost] NOT NULL,
[BeginStdECM] [dbo].[bECM] NOT NULL,
[PurchaseQty] [dbo].[bUnits] NOT NULL,
[PurchaseCost] [dbo].[bDollar] NOT NULL,
[ProdQty] [dbo].[bUnits] NOT NULL,
[ProdCost] [dbo].[bDollar] NOT NULL,
[UsageQty] [dbo].[bUnits] NOT NULL,
[UsageCost] [dbo].[bDollar] NOT NULL,
[ARSalesQty] [dbo].[bUnits] NOT NULL,
[ARSalesCost] [dbo].[bDollar] NOT NULL,
[ARSalesRev] [dbo].[bDollar] NOT NULL,
[JCSalesQty] [dbo].[bUnits] NOT NULL,
[JCSalesCost] [dbo].[bDollar] NOT NULL,
[JCSalesRev] [dbo].[bDollar] NOT NULL,
[INSalesQty] [dbo].[bUnits] NOT NULL,
[INSalesCost] [dbo].[bDollar] NOT NULL,
[INSalesRev] [dbo].[bDollar] NOT NULL,
[EMSalesQty] [dbo].[bUnits] NOT NULL,
[EMSalesCost] [dbo].[bDollar] NOT NULL,
[EMSalesRev] [dbo].[bDollar] NOT NULL,
[TrnsfrInQty] [dbo].[bUnits] NOT NULL,
[TrnsfrInCost] [dbo].[bDollar] NOT NULL,
[TrnsfrOutQty] [dbo].[bUnits] NOT NULL,
[TrnsfrOutCost] [dbo].[bDollar] NOT NULL,
[AdjQty] [dbo].[bUnits] NOT NULL,
[AdjCost] [dbo].[bDollar] NOT NULL,
[ExpQty] [dbo].[bUnits] NOT NULL,
[ExpCost] [dbo].[bDollar] NOT NULL,
[EndQty] [dbo].[bUnits] NOT NULL,
[EndValue] [dbo].[bDollar] NOT NULL,
[EndLastCost] [dbo].[bUnitCost] NOT NULL,
[EndLastECM] [dbo].[bECM] NOT NULL,
[EndAvgCost] [dbo].[bUnitCost] NOT NULL,
[EndAvgECM] [dbo].[bECM] NOT NULL,
[EndStdCost] [dbo].[bUnitCost] NOT NULL,
[EndStdECM] [dbo].[bECM] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biINMA] ON [dbo].[bINMA] ([INCo], [Loc], [MatlGroup], [Material], [Mth]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biINMAINCoMth] ON [dbo].[bINMA] ([INCo], [Mth]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINMA] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMA].[BeginLastECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMA].[BeginAvgECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMA].[BeginStdECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMA].[EndLastECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMA].[EndAvgECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMA].[EndStdECM]'
GO
