CREATE TABLE [dbo].[bEMAH]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[SelectEquip] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SelectCatgy] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SelectDept] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[AllocBasis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[BasisCol] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AmtRateFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[AllocAmount] [dbo].[bDollar] NULL,
[EquipAmtCol] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AllocRate] [dbo].[bRate] NULL CONSTRAINT [DF_bEMAH_AllocRate] DEFAULT ((0)),
[EquipRateCol] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MthDateFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[LastPosted] [dbo].[bDate] NULL,
[LastMonth] [dbo].[bMonth] NULL,
[LastEndDate] [dbo].[bDate] NULL,
[LastBeginDate] [dbo].[bDate] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[CostType] [dbo].[bEMCType] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLDebitAcct] [dbo].[bGLAcct] NULL,
[GLCreditAcct] [dbo].[bGLAcct] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[PrevPosted] [dbo].[bDate] NULL,
[PrevMonth] [dbo].[bMonth] NULL,
[PrevBeginDate] [dbo].[bDate] NULL,
[PrevEndDate] [dbo].[bDate] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMAH] ON [dbo].[bEMAH] ([EMCo], [AllocCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMAH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMAH] WITH NOCHECK ADD CONSTRAINT [FK_bEMAH_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMAH] WITH NOCHECK ADD CONSTRAINT [FK_bEMAH_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMAH] WITH NOCHECK ADD CONSTRAINT [FK_bEMAH_bEMCC_CostCode] FOREIGN KEY ([EMGroup], [CostCode]) REFERENCES [dbo].[bEMCC] ([EMGroup], [CostCode])
GO
ALTER TABLE [dbo].[bEMAH] WITH NOCHECK ADD CONSTRAINT [FK_bEMAH_bEMCT_CostType] FOREIGN KEY ([EMGroup], [CostType]) REFERENCES [dbo].[bEMCT] ([EMGroup], [CostType])
GO
ALTER TABLE [dbo].[bEMAH] NOCHECK CONSTRAINT [FK_bEMAH_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMAH] NOCHECK CONSTRAINT [FK_bEMAH_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMAH] NOCHECK CONSTRAINT [FK_bEMAH_bEMCC_CostCode]
GO
ALTER TABLE [dbo].[bEMAH] NOCHECK CONSTRAINT [FK_bEMAH_bEMCT_CostType]
GO
