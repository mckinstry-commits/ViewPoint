CREATE TABLE [dbo].[bPORE]
(
[POCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[EMCo] [dbo].[bCompany] NOT NULL,
[Equip] [dbo].[bEquip] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[CostCode] [dbo].[bCostCode] NOT NULL,
[EMCType] [dbo].[bEMCType] NOT NULL,
[BatchSeq] [int] NOT NULL,
[APLine] [smallint] NOT NULL CONSTRAINT [DF_bPORE_APLine] DEFAULT ((1)),
[OldNew] [tinyint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[POTrans] [dbo].[bTrans] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[Description] [dbo].[bDesc] NULL,
[RecDate] [dbo].[bDate] NULL,
[Receiver#] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPORE_UnitCost] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL,
[EMUM] [dbo].[bUM] NOT NULL,
[EMUnits] [dbo].[bUnits] NOT NULL,
[TotalCost] [dbo].[bDollar] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPORE_TaxBasis] DEFAULT ((0)),
[TaxAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPORE_TaxAmt] DEFAULT ((0)),
[POItemLine] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPORE] WITH NOCHECK ADD CONSTRAINT [CK_bPORE_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [biPORE] ON [dbo].[bPORE] ([POCo], [Mth], [BatchId], [EMCo], [Equip], [EMGroup], [CostCode], [EMCType], [BatchSeq], [POTrans], [APLine], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
