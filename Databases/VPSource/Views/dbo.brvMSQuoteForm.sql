SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[brvMSQuoteForm] as
select MSCo, Quote, Sort='5A', QuoteOverrideDefaultDesc='Quote Header', Seq=NULL, LocGroup=NULL, Loc=NULL, MatlGroup=NULL, 
     Category=NULL, Material=NULL, UM=NULL,
     MSQD_QuoteUnits=0, MSQD_UnitPrice=0, MSQD_ECM=NULL, MSQD_ReqDate=NULL, Status=NULL, 
     MSQD_OrderUnits=0, MSQD_SoldUnits=0, MSQD_AuditYN=NULL,
     MSMD_Rate=0.00, MSMD_UnitPrice=0.00, MSMD_ECM=NULL, MSMD_MinAmt=0.00, MSJP_PhaseGroup=NULL, MSJP_MatlPhase=NULL,
     MSJP_MatlCostType=0, MSJP_HaulPhase=NULL, MSJP_HaulCostType=0, MSHX_TruckType=NULL, MSHX_Truck=NULL,
     MSHX_HaulCode=NULL, MSHX_Override=NULL, MSHO_HaulRate=0.00, MSHO_MinAmt=0.00, MSZD_Zone=NULL, MSDX_PayDiscRate=0.00,	
     MSQD_PhaseGroup=NULL, MSQD_Phase=NULL
From MSQH 
Union all 
select MSCo, Quote, Sort='1A', QuoteOverrideDefaultDesc='Quote Detail', Seq, LocGroup=NULL, Loc=FromLoc, MatlGroup, 
     Category=NULL, Material, UM,
     MSQD_QuoteUnits=QuoteUnits, MSQD_UnitPrice=UnitPrice, MSQD_ECM=ECM, MSQD_ReqDate=ReqDate, Status, 
     MSQD_OrderUnits=OrderUnits, MSQD_SoldUnits=SoldUnits, MSQD_AuditYN=AuditYN,
     MSMD_Rate=0.00, MSMD_UnitPrice=0.00, MSMD_ECM=NULL, MSMD_MinAmt=0.00, MSJP_PhaseGroup=NULL, MSJP_MatlPhase=NULL,
     MSJP_MatlCostType=0, MSJP_HaulPhase=NULL, MSJP_HaulCostType=0, MSHX_TruckType=NULL, MSHX_Truck=NULL,
     MSHX_HaulCode=NULL, MSHX_Override=NULL, MSHX_HaulRate=0.00, MSHX_MinAmt=0.00, MSZD_Zone=NULL, MSDX_PayDiscRate=0.00,        
     PhaseGroup, Phase
From MSQD 
     
union all
select MSCo, Quote, Sort='1B', 'Price Overrides', Seq, LocGroup, Loc, MatlGroup, Category, Material=NULL, UM,
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, Rate, UnitPrice, ECM, MinAmt, NULL, NULL, NULL, NULL, NULL, 
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, PhaseGroup, Phase
From MSMD
union all
select MSCo, Quote, Sort='3A', 'Discount Overrides', Seq, LocGroup, Loc, MatlGroup, Category, Material, UM, NULL, NULL, NULL, 
     NULL, NULL, NULL, 
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, PayDiscRate, NULL, 
     NULL
From MSDX
union all
select MSCo, Quote, Sort='2A', 'Haul Code Defaults', Seq, LocGroup, FromLoc, MatlGroup, Category, Material, UM,
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, TruckType, Truck=NULL,
     HaulCode, Override, HaulRate, MinAmt, NULL, NULL, NULL, NULL 
     From MSHX 
  
union all

select MSCo, Quote, Sort='2B', 'Haul Code Overrides', Seq, LocGroup, FromLoc, MatlGroup, Category, Material, UM,
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, TruckType, Truck=NULL,
     HaulCode, NULL, HaulRate, MinAmt, NULL, NULL,  PhaseGroup, Phase 
From MSHO
union all
select MSCo, Quote, Sort='4A', 'Job Phases', Seq, LocGroup, FromLoc, MatlGroup, Category, Material, NULL, 
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, PhaseGroup, MatlPhase, MatlCostType, HaulPhase,
     HaulCostType, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,NULL, NULL 
From MSJP

GO
GRANT SELECT ON  [dbo].[brvMSQuoteForm] TO [public]
GRANT INSERT ON  [dbo].[brvMSQuoteForm] TO [public]
GRANT DELETE ON  [dbo].[brvMSQuoteForm] TO [public]
GRANT UPDATE ON  [dbo].[brvMSQuoteForm] TO [public]
GO
