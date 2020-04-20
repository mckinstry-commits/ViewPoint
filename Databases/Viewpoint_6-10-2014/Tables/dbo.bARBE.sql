CREATE TABLE [dbo].[bARBE]
(
[ARCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[EMCo] [dbo].[bCompany] NOT NULL,
[Equip] [dbo].[bEquip] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[CostCode] [dbo].[bCostCode] NOT NULL,
[EMCType] [dbo].[bEMCType] NOT NULL,
[BatchSeq] [int] NOT NULL,
[ARLine] [smallint] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[ARTrans] [dbo].[bTrans] NULL,
[TransDesc] [dbo].[bDesc] NULL,
[TransDate] [dbo].[bDate] NOT NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[LineDesc] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bARBE_UnitCost] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL,
[EMUM] [dbo].[bUM] NOT NULL,
[EMUnits] [dbo].[bUnits] NOT NULL,
[TotalCost] [dbo].[bDollar] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxAmt] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bARBE] WITH NOCHECK ADD CONSTRAINT [CK_bARBE_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [biARBE] ON [dbo].[bARBE] ([ARCo], [Mth], [BatchId], [EMCo], [Equip], [EMGroup], [CostCode], [EMCType], [BatchSeq], [ARLine], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
