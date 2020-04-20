CREATE TABLE [dbo].[bINRO]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[OutMth] [dbo].[bMonth] NOT NULL,
[InDate] [dbo].[bDate] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[InMth] [dbo].[bMonth] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biINRO] ON [dbo].[bINRO] ([INCo], [Loc], [MatlGroup], [Material], [OutMth], [InDate], [UnitCost], [InMth]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
