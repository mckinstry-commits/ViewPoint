CREATE TABLE [dbo].[bPORI]
(
[POCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[RecvdUnits] [dbo].[bUnits] NOT NULL,
[BOUnits] [dbo].[bUnits] NOT NULL,
[StdUM] [dbo].[bUM] NOT NULL,
[RecvdNInvcd] [dbo].[bUnits] NOT NULL,
[OnOrder] [dbo].[bUnits] NOT NULL,
[POItemLine] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPORI] ON [dbo].[bPORI] ([POCo], [Mth], [BatchId], [INCo], [Loc], [MatlGroup], [Material], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
