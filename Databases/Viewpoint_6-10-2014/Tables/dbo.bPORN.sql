CREATE TABLE [dbo].[bPORN]
(
[POCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[BatchSeq] [int] NOT NULL,
[APLine] [smallint] NOT NULL CONSTRAINT [DF_bPORN_APLine] DEFAULT ((1)),
[OldNew] [tinyint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[POTrans] [dbo].[bTrans] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[Description] [dbo].[bDesc] NULL,
[RecDate] [dbo].[bDate] NULL,
[Receiver#] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPORN_UnitCost] DEFAULT ((0)),
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
ALTER TABLE [dbo].[bPORN] WITH NOCHECK ADD CONSTRAINT [CK_bPORN_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M'))
GO
ALTER TABLE [dbo].[bPORN] WITH NOCHECK ADD CONSTRAINT [CK_bPORN_StdECM] CHECK (([StdECM]='E' OR [StdECM]='C' OR [StdECM]='M'))
GO
CREATE UNIQUE CLUSTERED INDEX [biPORN] ON [dbo].[bPORN] ([POCo], [Mth], [BatchId], [INCo], [Loc], [MatlGroup], [Material], [BatchSeq], [APLine], [POTrans], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
