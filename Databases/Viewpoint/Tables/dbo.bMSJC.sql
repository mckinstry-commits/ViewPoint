CREATE TABLE [dbo].[bMSJC]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[FromLoc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[BatchSeq] [int] NOT NULL,
[HaulLine] [smallint] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[MSTrans] [int] NULL,
[Ticket] [dbo].[bTic] NULL,
[SaleDate] [dbo].[bDate] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Hrs] [dbo].[bHrs] NOT NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[JCUM] [dbo].[bUM] NULL,
[JCUnits] [dbo].[bUnits] NOT NULL,
[JCUnitCost] [dbo].[bUnitCost] NOT NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxTotal] [dbo].[bDollar] NOT NULL,
[CostTrans] [dbo].[bTrans] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[RevCode] [dbo].[bRevCode] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biMSJC] ON [dbo].[bMSJC] ([MSCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [FromLoc], [MatlGroup], [Material], [BatchSeq], [HaulLine], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO

EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSJC].[ECM]'
GO
