CREATE TABLE [dbo].[vSMJobCostDistribution]
(
[SMWorkCompletedID] [bigint] NOT NULL,
[IsReversingEntry] [bit] NOT NULL,
[IsTaxRedirect] [bit] NOT NULL,
[BatchCo] [dbo].[bCompany] NOT NULL,
[BatchMth] [dbo].[bMonth] NOT NULL,
[BatchID] [dbo].[bBatchID] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[SMWorkOrder] [int] NOT NULL,
[SMScope] [int] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[JobPhaseCostTypeUM] [dbo].[bUM] NULL,
[Description] [dbo].[bItemDesc] NULL,
[PostedDate] [dbo].[bDate] NOT NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[PostedUM] [dbo].[bUM] NULL,
[PECM] [dbo].[bECM] NULL,
[ActualUnitCost] [dbo].[bUnitCost] NULL CONSTRAINT [DF_vSMJobCostDistribution_ActualUnitCost] DEFAULT ((0)),
[ActualUnits] [dbo].[bUnits] NULL CONSTRAINT [DF_vSMJobCostDistribution_ActualUnits] DEFAULT ((0)),
[ActualHours] [dbo].[bHrs] NULL CONSTRAINT [DF_vSMJobCostDistribution_ActualHours] DEFAULT ((0)),
[ActualCost] [dbo].[bDollar] NULL CONSTRAINT [DF_vSMJobCostDistribution_ActualCost] DEFAULT ((0)),
[PostedUnits] [dbo].[bUnits] NULL CONSTRAINT [DF_vSMJobCostDistribution_PostedUnits] DEFAULT ((0)),
[PostedUnitCost] [dbo].[bUnitCost] NULL CONSTRAINT [DF_vSMJobCostDistribution_PostedUnitCost] DEFAULT ((0)),
[PostedECM] [dbo].[bECM] NULL,
[INStkUnitCost] [dbo].[bUnitCost] NULL CONSTRAINT [DF_vSMJobCostDistribution_INStkUnitCost] DEFAULT ((0)),
[INStkUM] [dbo].[bUM] NULL,
[INStkUnits] [dbo].[bUnits] NULL CONSTRAINT [DF_vSMJobCostDistribution_INStkUnits] DEFAULT ((0)),
[INStkECM] [dbo].[bECM] NULL,
[TaxType] [tinyint] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxBasis] [dbo].[bDollar] NULL CONSTRAINT [DF_vSMJobCostDistribution_TaxBasis] DEFAULT ((0)),
[TaxAmt] [dbo].[bDollar] NULL CONSTRAINT [DF_vSMJobCostDistribution_TaxAmt] DEFAULT ((0)),
[POCo] [dbo].[bCompany] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[POItemLine] [int] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[PostRemCmUnits] [dbo].[bUnits] NULL CONSTRAINT [DF_vSMJobCostDistribution_PostRemCmUnits] DEFAULT ((0)),
[RemainCmtdCost] [dbo].[bDollar] NULL CONSTRAINT [DF_vSMJobCostDistribution_RemainCmtdCost] DEFAULT ((0)),
[RemCmtdTax] [dbo].[bDollar] NULL CONSTRAINT [DF_vSMJobCostDistribution_RemCmtdTax] DEFAULT ((0)),
[RemainCmtdUnits] [dbo].[bUnits] NULL CONSTRAINT [DF_vSMJobCostDistribution_RemainCmtdUnits] DEFAULT ((0)),
[JCTransType] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[BatchSeq] [int] NULL,
[Line] [smallint] NULL,
[CostTrans] [dbo].[bTrans] NULL,
[OffsetGLCo] [dbo].[bCompany] NULL,
[OffsetGLAcct] [dbo].[bGLAcct] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMJobCostDistribution] ADD CONSTRAINT [PK_vSMJobCostDistribution] PRIMARY KEY CLUSTERED  ([SMWorkCompletedID], [IsReversingEntry], [IsTaxRedirect]) ON [PRIMARY]
GO
