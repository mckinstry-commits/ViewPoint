CREATE TABLE [dbo].[bJCHC]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[MthClosed] [dbo].[bMonth] NOT NULL,
[ContractDesc] [dbo].[bItemDesc] NULL,
[ItemDesc] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[SIRegion] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[SICode] [varchar] (16) COLLATE Latin1_General_BIN NULL,
[Department] [dbo].[bDept] NULL,
[OrigContractAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCHC_OrigContractAmt] DEFAULT ((0)),
[OrigContractUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCHC_OrigContractUnits] DEFAULT ((0)),
[OrigUnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCHC_OrigUnitPrice] DEFAULT ((0)),
[FinalContractAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCHC_FinalContractAmt] DEFAULT ((0)),
[FinalContractUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCHC_FinalContractUnits] DEFAULT ((0)),
[FinalUnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCHC_FinalUnitPrice] DEFAULT ((0)),
[ActualHours] [dbo].[bHrs] NOT NULL,
[ActualUnits] [dbo].[bUnits] NOT NULL,
[ActualCost] [dbo].[bDollar] NOT NULL,
[OrigEstHours] [dbo].[bHrs] NOT NULL,
[OrigEstUnits] [dbo].[bUnits] NOT NULL,
[OrigEstCost] [dbo].[bDollar] NOT NULL,
[CurrEstHours] [dbo].[bHrs] NOT NULL,
[CurrEstUnits] [dbo].[bUnits] NOT NULL,
[CurrEstCost] [dbo].[bDollar] NOT NULL,
[ProjHours] [dbo].[bHrs] NOT NULL,
[ProjUnits] [dbo].[bUnits] NOT NULL,
[ProjCost] [dbo].[bDollar] NOT NULL,
[BilledUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCHC_BilledUnits] DEFAULT ((0)),
[BilledAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCHC_BilledAmt] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCHC] ON [dbo].[bJCHC] ([JCCo], [Contract], [Item]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
