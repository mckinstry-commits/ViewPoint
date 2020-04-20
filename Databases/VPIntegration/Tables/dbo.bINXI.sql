CREATE TABLE [dbo].[bINXI]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[BatchSeq] [int] NOT NULL,
[MOItem] [dbo].[bItem] NOT NULL,
[MO] [dbo].[bMO] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[RemainUnits] [dbo].[bUnits] NOT NULL,
[StdUM] [dbo].[bUM] NOT NULL,
[Alloc] [dbo].[bUnits] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biINXI] ON [dbo].[bINXI] ([INCo], [Mth], [BatchId], [Loc], [MatlGroup], [Material], [BatchSeq], [MOItem]) ON [PRIMARY]
GO
