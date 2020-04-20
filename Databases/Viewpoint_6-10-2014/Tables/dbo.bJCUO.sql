CREATE TABLE [dbo].[bJCUO]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[UserName] [dbo].[bVPUserName] NOT NULL,
[ChangedOnly] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_ChangedOnly] DEFAULT ('N'),
[ItemUnitsOnly] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_ItemUnitsOnly] DEFAULT ('N'),
[PhaseUnitsOnly] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_PhaseUnitsOnly] DEFAULT ('N'),
[ShowLinkedCT] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_ShowLinkedCT] DEFAULT ('N'),
[ShowFutureCO] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_ShowFutureCO] DEFAULT ('N'),
[RemainUnits] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_RemainUnits] DEFAULT ('N'),
[RemainHours] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_RemainHours] DEFAULT ('N'),
[RemainCosts] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_RemainCosts] DEFAULT ('N'),
[OpenForm] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_OpenForm] DEFAULT ('N'),
[PhaseOption] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCUO_PhaseOption] DEFAULT ('0'),
[BegPhase] [dbo].[bPhase] NULL,
[EndPhase] [dbo].[bPhase] NULL,
[CostTypeOption] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCUO_CostTypeOption] DEFAULT ('0'),
[SelectedCostTypes] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[VisibleColumns] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[ColumnOrder] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[ThruPriorMonth] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_ThruPriorMonth] DEFAULT ('N'),
[NoLinkedCT] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_NoLinkedCT] DEFAULT ('N'),
[ProjMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCUO_ProjMethod] DEFAULT ('1'),
[Production] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCUO_Production] DEFAULT ('0'),
[ProjInitOption] [char] (1) COLLATE Latin1_General_BIN NULL CONSTRAINT [DF_bJCUO_ProjInitOption] DEFAULT ('0'),
[ProjWriteOverPlug] [char] (1) COLLATE Latin1_General_BIN NULL CONSTRAINT [DF_bJCUO_ProjWriteOverPlug] DEFAULT ('0'),
[RevProjFilterBegItem] [dbo].[bContractItem] NULL,
[RevProjFilterEndItem] [dbo].[bContractItem] NULL,
[RevProjFilterBillType] [char] (1) COLLATE Latin1_General_BIN NULL,
[RevProjCalcWriteOverPlug] [char] (1) COLLATE Latin1_General_BIN NULL,
[RevProjCalcMethod] [char] (1) COLLATE Latin1_General_BIN NULL,
[RevProjCalcMethodMarkup] [dbo].[bPct] NULL,
[RevProjCalcBillType] [char] (1) COLLATE Latin1_General_BIN NULL,
[RevProjCalcBegContract] [dbo].[bContract] NULL,
[RevProjCalcEndContract] [dbo].[bContract] NULL,
[RevProjCalcBegItem] [dbo].[bContractItem] NULL,
[RevProjCalcEndItem] [dbo].[bContractItem] NULL,
[ProjInactivePhases] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_ProjInactivePhases] DEFAULT ('N'),
[OrderBy] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCUO_OrderBy] DEFAULT ('P'),
[CycleMode] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCUO_CycleMode] DEFAULT ('N'),
[RevProjFilterBegDept] [dbo].[bDept] NULL,
[RevProjFilterEndDept] [dbo].[bDept] NULL,
[RevProjCalcBegDept] [dbo].[bDept] NULL,
[RevProjCalcEndDept] [dbo].[bDept] NULL,
[ColumnWidth] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[bJCUO] WITH NOCHECK ADD CONSTRAINT [CK_bJCUO_ChangedOnly] CHECK (([ChangedOnly]='Y' OR [ChangedOnly]='N'))
GO
ALTER TABLE [dbo].[bJCUO] WITH NOCHECK ADD CONSTRAINT [CK_bJCUO_ItemUnitsOnly] CHECK (([ItemUnitsOnly]='Y' OR [ItemUnitsOnly]='N'))
GO
ALTER TABLE [dbo].[bJCUO] WITH NOCHECK ADD CONSTRAINT [CK_bJCUO_NoLinkedCT] CHECK (([NoLinkedCT]='Y' OR [NoLinkedCT]='N'))
GO
ALTER TABLE [dbo].[bJCUO] WITH NOCHECK ADD CONSTRAINT [CK_bJCUO_OpenForm] CHECK (([OpenForm]='Y' OR [OpenForm]='N'))
GO
ALTER TABLE [dbo].[bJCUO] WITH NOCHECK ADD CONSTRAINT [CK_bJCUO_PhaseUnitsOnly] CHECK (([PhaseUnitsOnly]='Y' OR [PhaseUnitsOnly]='N'))
GO
ALTER TABLE [dbo].[bJCUO] WITH NOCHECK ADD CONSTRAINT [CK_bJCUO_ProjInactivePhases] CHECK (([ProjInactivePhases]='Y' OR [ProjInactivePhases]='N'))
GO
ALTER TABLE [dbo].[bJCUO] WITH NOCHECK ADD CONSTRAINT [CK_bJCUO_RemainCosts] CHECK (([RemainCosts]='Y' OR [RemainCosts]='N'))
GO
ALTER TABLE [dbo].[bJCUO] WITH NOCHECK ADD CONSTRAINT [CK_bJCUO_RemainHours] CHECK (([RemainHours]='Y' OR [RemainHours]='N'))
GO
ALTER TABLE [dbo].[bJCUO] WITH NOCHECK ADD CONSTRAINT [CK_bJCUO_RemainUnits] CHECK (([RemainUnits]='Y' OR [RemainUnits]='N'))
GO
ALTER TABLE [dbo].[bJCUO] WITH NOCHECK ADD CONSTRAINT [CK_bJCUO_ShowFutureCO] CHECK (([ShowFutureCO]='Y' OR [ShowFutureCO]='N'))
GO
ALTER TABLE [dbo].[bJCUO] WITH NOCHECK ADD CONSTRAINT [CK_bJCUO_ShowLinkedCT] CHECK (([ShowLinkedCT]='Y' OR [ShowLinkedCT]='N'))
GO
ALTER TABLE [dbo].[bJCUO] WITH NOCHECK ADD CONSTRAINT [CK_bJCUO_ThruPriorMonth] CHECK (([ThruPriorMonth]='Y' OR [ThruPriorMonth]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biJCUO] ON [dbo].[bJCUO] ([JCCo], [Form], [UserName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
