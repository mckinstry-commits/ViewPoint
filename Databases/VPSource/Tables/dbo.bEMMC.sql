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
ALTER TABLE [dbo].[bEMMC] ADD
CONSTRAINT [FK_bEMMC_bEMCC_CostCode] FOREIGN KEY ([EMGroup], [CostCode]) REFERENCES [dbo].[bEMCC] ([EMGroup], [CostCode])
ALTER TABLE [dbo].[bEMMC] ADD
CONSTRAINT [FK_bEMMC_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
ALTER TABLE [dbo].[bEMMC] ADD
CONSTRAINT [FK_bEMMC_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
ALTER TABLE [dbo].[bEMMC] ADD
CONSTRAINT [FK_bEMMC_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
ALTER TABLE [dbo].[bEMMC] ADD
CONSTRAINT [FK_bEMMC_bEMCT_CostType] FOREIGN KEY ([EMGroup], [CostType]) REFERENCES [dbo].[bEMCT] ([EMGroup], [CostType])
GO
CREATE UNIQUE CLUSTERED INDEX [biEMMC] ON [dbo].[bEMMC] ([EMCo], [Equipment], [EMGroup], [CostCode], [CostType], [Month]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
