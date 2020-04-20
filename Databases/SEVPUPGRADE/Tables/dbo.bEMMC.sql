CREATE TABLE [dbo].[bEMMC]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[CostCode] [dbo].[bCostCode] NOT NULL,
[CostType] [dbo].[bEMCType] NOT NULL,
[Month] [dbo].[bMonth] NOT NULL,
[ActUnits] [dbo].[bUnits] NOT NULL,
[ActCost] [dbo].[bDollar] NOT NULL,
[EstUnits] [dbo].[bUnits] NOT NULL,
[EstCost] [dbo].[bDollar] NOT NULL,
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMMC] ON [dbo].[bEMMC] ([EMCo], [Equipment], [EMGroup], [CostCode], [CostType], [Month]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
