CREATE TABLE [dbo].[bMSIN]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[INTransType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[BatchSeq] [int] NOT NULL,
[HaulLine] [smallint] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[MSTrans] [dbo].[bTrans] NULL,
[SaleDate] [dbo].[bDate] NOT NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[MatlPhase] [dbo].[bPhase] NULL,
[MatlJCCType] [dbo].[bJCCType] NULL,
[SalesINCo] [dbo].[bCompany] NULL,
[SalesLoc] [dbo].[bLoc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[PostedUM] [dbo].[bUM] NOT NULL,
[PostedUnits] [dbo].[bUnits] NOT NULL,
[PostedUnitCost] [dbo].[bUnitCost] NOT NULL,
[PostECM] [dbo].[bECM] NOT NULL,
[PostedTotalCost] [dbo].[bDollar] NOT NULL,
[StkUM] [dbo].[bUM] NOT NULL,
[StkUnits] [dbo].[bUnits] NOT NULL,
[StkUnitCost] [dbo].[bUnitCost] NOT NULL,
[StkECM] [dbo].[bECM] NOT NULL,
[StkTotalCost] [dbo].[bDollar] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[PECM] [dbo].[bECM] NOT NULL,
[TotalPrice] [dbo].[bDollar] NOT NULL,
[INTrans] [dbo].[bTrans] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bMSIN] ADD
CONSTRAINT [CK_bMSIN_PECM] CHECK (([PECM]='E' OR [PECM]='C' OR [PECM]='M'))
ALTER TABLE [dbo].[bMSIN] ADD
CONSTRAINT [CK_bMSIN_PostECM] CHECK (([PostECM]='E' OR [PostECM]='C' OR [PostECM]='M'))
ALTER TABLE [dbo].[bMSIN] ADD
CONSTRAINT [CK_bMSIN_StkECM] CHECK (([StkECM]='E' OR [StkECM]='C' OR [StkECM]='M'))
GO
CREATE UNIQUE CLUSTERED INDEX [biMSIN] ON [dbo].[bMSIN] ([MSCo], [Mth], [BatchId], [INCo], [Loc], [MatlGroup], [Material], [INTransType], [BatchSeq], [HaulLine], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSIN].[PostECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSIN].[StkECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSIN].[PECM]'
GO
