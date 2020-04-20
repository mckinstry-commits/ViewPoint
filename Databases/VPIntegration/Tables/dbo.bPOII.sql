CREATE TABLE [dbo].[bPOII]
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
[OldNew] [tinyint] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[ChangeUnits] [dbo].[bUnits] NOT NULL,
[StdUM] [dbo].[bUM] NOT NULL,
[OnOrder] [dbo].[bUnits] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPOII] ON [dbo].[bPOII] ([POCo], [Mth], [BatchId], [INCo], [Loc], [MatlGroup], [Material], [BatchSeq], [POItem], [OldNew]) ON [PRIMARY]
GO
