CREATE TABLE [dbo].[bMSTX]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[MSTrans] [dbo].[bTrans] NULL,
[SaleDate] [dbo].[bDate] NULL,
[Ticket] [dbo].[bTic] NULL,
[FromLoc] [dbo].[bLoc] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[MatlVendor] [dbo].[bVendor] NULL,
[SaleType] [char] (1) COLLATE Latin1_General_BIN NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[PaymentType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[CheckNo] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Hold] [dbo].[bYN] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[INCo] [dbo].[bCompany] NULL,
[ToLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[UM] [dbo].[bUM] NULL,
[MatlPhase] [dbo].[bPhase] NULL,
[MatlJCCType] [dbo].[bJCCType] NULL,
[GrossWght] [dbo].[bUnits] NULL,
[TareWght] [dbo].[bUnits] NULL,
[WghtUM] [dbo].[bUM] NULL,
[MatlUnits] [dbo].[bUnits] NULL,
[UnitPrice] [dbo].[bUnitCost] NULL,
[ECM] [dbo].[bECM] NULL,
[MatlTotal] [dbo].[bDollar] NULL,
[MatlCost] [dbo].[bDollar] NULL,
[HaulerType] [char] (1) COLLATE Latin1_General_BIN NULL,
[HaulVendor] [dbo].[bVendor] NULL,
[Truck] [dbo].[bTruck] NULL,
[Driver] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[TruckType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[StartTime] [smalldatetime] NULL,
[StopTime] [smalldatetime] NULL,
[Loads] [smallint] NULL,
[Miles] [dbo].[bUnits] NULL,
[Hours] [dbo].[bHrs] NULL,
[Zone] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[HaulCode] [dbo].[bHaulCode] NULL,
[HaulPhase] [dbo].[bPhase] NULL,
[HaulJCCType] [dbo].[bJCCType] NULL,
[HaulBasis] [dbo].[bUnits] NULL,
[HaulRate] [dbo].[bUnitCost] NULL,
[HaulTotal] [dbo].[bDollar] NULL,
[PayCode] [dbo].[bPayCode] NULL,
[PayBasis] [dbo].[bUnits] NULL,
[PayRate] [dbo].[bUnitCost] NULL,
[PayTotal] [dbo].[bDollar] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[RevBasis] [dbo].[bUnits] NULL,
[RevRate] [dbo].[bUnitCost] NULL,
[RevTotal] [dbo].[bDollar] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NULL,
[TaxTotal] [dbo].[bDollar] NULL,
[DiscBasis] [dbo].[bUnits] NULL,
[DiscRate] [dbo].[bUnitCost] NULL,
[DiscOff] [dbo].[bDollar] NULL,
[TaxDisc] [dbo].[bDollar] NULL,
[Void] [dbo].[bYN] NULL,
[APRef] [dbo].[bAPReference] NULL,
[VerifyHaul] [dbo].[bYN] NULL,
[Changed] [dbo].[bYN] NULL,
[ReasonCode] [dbo].[bReasonCode] NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[DeleteDate] [smalldatetime] NOT NULL,
[VPUserName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[ShipAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[APCo] [dbo].[bCompany] NULL,
[APMth] [dbo].[bMonth] NULL,
[MatlAPCo] [dbo].[bCompany] NULL,
[MatlAPMth] [dbo].[bMonth] NULL,
[MatlAPRef] [dbo].[bAPReference] NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bMSTX] ADD
CONSTRAINT [CK_bMSTX_Changed] CHECK (([Changed]='Y' OR [Changed]='N'))
ALTER TABLE [dbo].[bMSTX] ADD
CONSTRAINT [CK_bMSTX_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M'))
ALTER TABLE [dbo].[bMSTX] ADD
CONSTRAINT [CK_bMSTX_Hold] CHECK (([Hold]='Y' OR [Hold]='N'))
ALTER TABLE [dbo].[bMSTX] ADD
CONSTRAINT [CK_bMSTX_VerifyHaul] CHECK (([VerifyHaul]='Y' OR [VerifyHaul]='N'))
ALTER TABLE [dbo].[bMSTX] ADD
CONSTRAINT [CK_bMSTX_Void] CHECK (([Void]='N' OR [Void]='Y'))
GO
CREATE CLUSTERED INDEX [biMSTX] ON [dbo].[bMSTX] ([MSCo], [Mth], [MSTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSTX].[Hold]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSTX].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSTX].[Void]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSTX].[VerifyHaul]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSTX].[Changed]'
GO
