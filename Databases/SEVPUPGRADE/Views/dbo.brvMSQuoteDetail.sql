SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvMSQuoteDetail] as
/**************************
brvMSQuoteDetail view is used in 
MS Customer Quotes Drilldown, MS Inventory Quotes Drilldown, MS Job Quotes Drilldown, MS Quotes, and MS Quote Form


*****************************/
     select MSCo, Quote, Sort=1, QuoteOverrideDefaultDesc='Quote Header', Seq=NULL, LocGroup=NULL, GrpDesc=NULL, Loc=NULL, LocDesc=Null, MatlGroup=NULL, Category=NULL, Material=NULL, UM=NULL,
     MSQD_QuoteUnits=0, MSQD_UnitPrice=0, MSQD_ECM=NULL, MSQD_ReqDate=NULL, Status=NULL, 
     MSQD_OrderUnits=0, MSQD_SoldUnits=0, MSQD_AuditYN=NULL,
     MSMD_Rate=0.00, MSMD_UnitPrice=0.00, MSMD_ECM=NULL, MSMD_MinAmt=0.00, MSJP_PhaseGroup=NULL, MSJP_MatlPhase=NULL,
     MSJP_MatlCostType=0, MSJP_HaulPhase=NULL, MSJP_HaulCostType=0, MSHX_TruckType=NULL, MSHX_Truck=NULL,
     MSHX_HaulCode=NULL, MSHX_Override=NULL, MSHO_HaulRate=0.00, MSHO_MinAmt=0.00, MSZD_Zone=NULL, MSDX_PayDiscRate=0.00,		/* MSHX_Override=NULL,Issue 21141*/
     MSPX_TruckType=NULL, MSPX_VendorGroup=NULL, MSPX_Vendor=NULL, MSPX_Truck=NULL, MSPX_PayCode=NULL, MSPX_Override=NULL,
     MSPX_PayRate=0.00, MSPX_PayMinAmt=0.00, MSQD_PhaseGroup=NULL, MSQD_Phase=NULL
     From MSQH 
     Union all 
     select MSCo, Quote, Sort=1, QuoteOverrideDefaultDesc='Quote Detail', Seq, LocGroup=NULL, GrpDesc=NULL, Loc=FromLoc, LocDesc=INLM.Description, MatlGroup, Category=NULL, Material, UM,
     MSQD_QuoteUnits=QuoteUnits, MSQD_UnitPrice=UnitPrice, MSQD_ECM=ECM, MSQD_ReqDate=ReqDate, Status, 
     MSQD_OrderUnits=OrderUnits, MSQD_SoldUnits=SoldUnits, MSQD_AuditYN=AuditYN,
     MSMD_Rate=0.00, MSMD_UnitPrice=0.00, MSMD_ECM=NULL, MSMD_MinAmt=0.00, MSJP_PhaseGroup=NULL, MSJP_MatlPhase=NULL,
     MSJP_MatlCostType=0, MSJP_HaulPhase=NULL, MSJP_HaulCostType=0, MSHX_TruckType=NULL, MSHX_Truck=NULL,
     MSHX_HaulCode=NULL, MSHX_Override=NULL, MSHX_HaulRate=0.00, MSHX_MinAmt=0.00, MSZD_Zone=NULL, MSDX_PayDiscRate=0.00,        /* MSHO_Override=NULL, Issue 21141*/
     MSPX_TruckType=NULL, MSPX_VendorGroup=NULL, MSPX_Vendor=NULL, MSPX_Truck=NULL, MSPX_PayCode=NULL, MSPX_Override=NULL,
     MSPX_PayRate=0.00, MSPX_PayMinAmt=0.00, PhaseGroup, Phase
     From MSQD
     left outer join INLM with (nolock) on INLM.INCo=MSQD.MSCo and INLM.Loc=MSQD.FromLoc
     
     
     union all
     select MSCo, Quote, Sort=2, 'Price Overrides', Seq, MSMD.LocGroup, GrpDesc=INLG.Description, MSMD.Loc, INLM.Description, MatlGroup, Category, Material=NULL, UM,
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, Rate, UnitPrice, ECM, MinAmt, NULL, NULL, NULL, NULL, NULL, 
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,PhaseGroup, Phase
     From MSMD
      Inner Join INLG with (nolock) on MSMD.MSCo=INLG.INCo and MSMD.LocGroup=INLG.LocGroup
      left outer join INLM with (nolock) on INLM.INCo=MSMD.MSCo and INLM.Loc=MSMD.Loc
     union all
     select MSCo, Quote, Sort=3, 'Discount Overrides', Seq, MSDX.LocGroup, GrpDesc=INLG.Description, MSDX.Loc, INLM.Description, MatlGroup, Category, Material, UM, NULL, NULL, NULL, NULL, NULL, NULL, 
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, PayDiscRate, NULL, NULL, NULL, NULL, NULL, NULL,
     NULL , NULL, NULL, NULL
     From MSDX
      Inner Join INLG with (nolock) on MSDX.MSCo=INLG.INCo and MSDX.LocGroup=INLG.LocGroup
      left outer join INLM with (nolock) on INLM.INCo=MSDX.MSCo and INLM.Loc=MSDX.Loc
     union all
     select MSHX.MSCo, Quote, Sort=4, 'Haul Code Defaults', MSHX.Seq, MSHX.LocGroup, GrpDesc=INLG.Description, MSHX.FromLoc, INLM.Description, MSHX.MatlGroup, MSHX.Category, MSHX.Material, MSHX.UM,
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, MSHX.TruckType, Truck=NULL,
     MSHX.HaulCode, MSHX.Override, MSHR.HaulRate, MSHX.MinAmt, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL 
     From MSHX
      Inner Join INLG with (nolock) on MSHX.MSCo=INLG.INCo and MSHX.LocGroup=INLG.LocGroup   
      left outer join INLM with (nolock) on INLM.INCo=MSHX.MSCo and INLM.Loc=MSHX.FromLoc
      Inner Join MSHR with (nolock) on MSHX.MSCo=MSHR.MSCo and MSHX.HaulCode = MSHR.HaulCode and MSHX.Seq=MSHR.Seq
     union all
     select MSCo, Quote, Sort=5, 'Haul Zones', NULL,NULL, Null, FromLoc, INLM.Description, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
     NULL,  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, Zone, NULL, NULL, NULL, NULL, 
     NULL, NULL, NULL, NULL, NULL, NULL, NULL
     From MSZD
       left outer join INLM with (nolock) on INLM.INCo=MSZD.MSCo and INLM.Loc=MSZD.FromLoc
     union all
     select MSCo, Quote, Sort=6, 'Pay Codes', Seq, MSPX.LocGroup, GrpDesc=INLG.Description, FromLoc, INLM.Description, MatlGroup, Category, Material, UM, NULL, NULL, NULL, NULL, NULL, 
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
     NULL, NULL, NULL, TruckType, VendorGroup, Vendor, Truck, PayCode, Override, PayRate, PayMinAmt, NULL, NULL 
     From MSPX
        Inner Join INLG with (nolock) on MSPX.MSCo=INLG.INCo and MSPX.LocGroup=INLG.LocGroup   
        left outer join INLM with (nolock) on INLM.INCo=MSPX.MSCo and INLM.Loc=MSPX.FromLoc 
     union all
     select MSCo, Quote, Sort=7, 'Haul Code Overrides', Seq, MSHO.LocGroup, INLG.Description, FromLoc, INLM.Description, MatlGroup, Category, Material, UM,
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, TruckType, Truck=NULL,
     HaulCode, NULL, HaulRate, MinAmt, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, PhaseGroup, Phase 
     From MSHO
       Inner Join INLG with (nolock) on MSHO.MSCo=INLG.INCo and MSHO.LocGroup=INLG.LocGroup 
       left outer join INLM with (nolock) on INLM.INCo=MSHO.MSCo and INLM.Loc=MSHO.FromLoc  
     union all
     select MSCo, Quote, Sort=8, 'Job Phases', Seq, MSJP.LocGroup, INLG.Description, FromLoc, INLM.Description, MatlGroup, Category, Material, NULL, 
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, PhaseGroup, MatlPhase, MatlCostType, HaulPhase,
     HaulCostType, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,NULL,NULL, NULL, NULL 
     From MSJP
        Inner Join INLG with (nolock) on MSJP.MSCo=INLG.INCo and MSJP.LocGroup=INLG.LocGroup   
        left outer join INLM with (nolock) on INLM.INCo=MSJP.MSCo and INLM.Loc=MSJP.FromLoc

GO
GRANT SELECT ON  [dbo].[brvMSQuoteDetail] TO [public]
GRANT INSERT ON  [dbo].[brvMSQuoteDetail] TO [public]
GRANT DELETE ON  [dbo].[brvMSQuoteDetail] TO [public]
GRANT UPDATE ON  [dbo].[brvMSQuoteDetail] TO [public]
GO
