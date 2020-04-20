CREATE TABLE [dbo].[boldINMT20140115]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[LastVendor] [dbo].[bVendor] NULL,
[LastCost] [dbo].[bUnitCost] NOT NULL,
[LastECM] [dbo].[bECM] NOT NULL,
[LastCostUpdate] [dbo].[bDate] NULL,
[AvgCost] [dbo].[bUnitCost] NOT NULL,
[AvgECM] [dbo].[bECM] NOT NULL,
[StdCost] [dbo].[bUnitCost] NOT NULL,
[StdECM] [dbo].[bECM] NOT NULL,
[StdPrice] [dbo].[bUnitCost] NOT NULL,
[PriceECM] [dbo].[bECM] NOT NULL,
[LowStock] [dbo].[bUnits] NOT NULL,
[ReOrder] [dbo].[bUnits] NOT NULL,
[WeightConv] [dbo].[bUnits] NOT NULL,
[PhyLoc] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[LastCntDate] [dbo].[bDate] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[CostPhase] [dbo].[bPhase] NULL,
[Active] [dbo].[bYN] NOT NULL,
[AutoProd] [dbo].[bYN] NOT NULL,
[GLSaleUnits] [dbo].[bYN] NOT NULL,
[CustRate] [dbo].[bRate] NOT NULL,
[JobRate] [dbo].[bRate] NOT NULL,
[InvRate] [dbo].[bRate] NOT NULL,
[EquipRate] [dbo].[bRate] NOT NULL,
[OnHand] [dbo].[bUnits] NOT NULL,
[RecvdNInvcd] [dbo].[bUnits] NOT NULL,
[Alloc] [dbo].[bUnits] NOT NULL,
[OnOrder] [dbo].[bUnits] NOT NULL,
[AuditYN] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Booked] [dbo].[bUnits] NOT NULL,
[GLProdUnits] [dbo].[bYN] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AllowNegWarnMSTickets] [dbo].[bYN] NOT NULL,
[ServiceRate] [dbo].[bRate] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO