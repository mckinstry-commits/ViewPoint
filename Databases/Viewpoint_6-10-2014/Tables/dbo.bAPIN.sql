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
[UnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bAPIN_UnitCost] DEFAULT ((0)),
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
ALTER TABLE [dbo].[bAPIN] WITH NOCHECK ADD CONSTRAINT [CK_bAPIN_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M'))
GO
ALTER TABLE [dbo].[bAPIN] WITH NOCHECK ADD CONSTRAINT [CK_bAPIN_StdECM] CHECK (([StdECM]='E' OR [StdECM]='C' OR [StdECM]='M'))
GO
CREATE UNIQUE CLUSTERED INDEX [biAPIN] ON [dbo].[bAPIN] ([APCo], [Mth], [BatchId], [INCo], [Loc], [MatlGroup], [Material], [BatchSeq], [APLine], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
