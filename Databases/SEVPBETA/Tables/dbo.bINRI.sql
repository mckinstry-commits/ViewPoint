CREATE TABLE [dbo].[bINRI]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[InDate] [dbo].[bDate] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[InMth] [dbo].[bMonth] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biINRI] ON [dbo].[bINRI] ([INCo], [Loc], [MatlGroup], [Material], [InDate], [UnitCost], [InMth]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
