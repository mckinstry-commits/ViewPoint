CREATE TABLE [dbo].[bAPIN]
(
[APCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[BatchSeq] [int] NOT NULL,
[APLine] [smallint] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[APTrans] [dbo].[bTrans] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[APRef] [dbo].[bAPReference] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[LineDesc] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[TotalCost] [dbo].[bDollar] NOT NULL,
[StdUM] [dbo].[bUM] NOT NULL,
[StdUnits] [dbo].[bUnits] NOT NULL,
[StdUnitCost] [dbo].[bUnitCost] NOT NULL,
[StdECM] [dbo].[bECM] NOT NULL,
[StdTotalCost] [dbo].[bDollar] NOT NULL,
[POItemLine] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biAPIN] ON [dbo].[bAPIN] ([APCo], [Mth], [BatchId], [INCo], [Loc], [MatlGroup], [Material], [BatchSeq], [APLine], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPIN].[UnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bAPIN].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bAPIN].[StdECM]'
GO
