CREATE TABLE [dbo].[bPOXI]
(
[POCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[BatchSeq] [int] NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[POUnits] [dbo].[bUnits] NOT NULL,
[StdUM] [dbo].[bUM] NOT NULL,
[OnOrder] [dbo].[bUnits] NOT NULL,
[POItemLine] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPOXI] ON [dbo].[bPOXI] ([POCo], [Mth], [BatchId], [INCo], [Loc], [MatlGroup], [Material], [BatchSeq], [POItem], [POItemLine]) ON [PRIMARY]
GO
