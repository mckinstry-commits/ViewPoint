CREATE TABLE [dbo].[bAPEM]
(
[APCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[EMCo] [dbo].[bCompany] NOT NULL,
[Equip] [dbo].[bEquip] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[CostCode] [dbo].[bCostCode] NOT NULL,
[EMCType] [dbo].[bEMCType] NOT NULL,
[BatchSeq] [int] NOT NULL,
[APLine] [smallint] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[APTrans] [dbo].[bTrans] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[APRef] [dbo].[bAPReference] NULL,
[TransDesc] [dbo].[bDesc] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[LineDesc] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NULL,
[EMUM] [dbo].[bUM] NOT NULL,
[EMUnits] [dbo].[bUnits] NOT NULL,
[TotalCost] [dbo].[bDollar] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPEM_TaxBasis] DEFAULT ((0)),
[TaxAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPEM_TaxAmt] DEFAULT ((0)),
[POItemLine] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biAPEM] ON [dbo].[bAPEM] ([APCo], [Mth], [BatchId], [EMCo], [Equip], [EMGroup], [CostCode], [EMCType], [BatchSeq], [APLine], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPEM].[UnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bAPEM].[ECM]'
GO
