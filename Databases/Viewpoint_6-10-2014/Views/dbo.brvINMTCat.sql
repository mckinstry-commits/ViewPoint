SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvINMTCat]
    
    /**********
     Created 2/22/2002 DH
    
     View selects all fields from IN Location Materials plus the Category field from HQMT.  
     View is needed to link INMT to INLO in IN Inventory Price List Report.
    
     Usage:  IN Inventory Price List report
    
    ***********/
    
    as 
    
    select a.INCo, a.Loc, a.MatlGroup, a.Material, MatlCatgy=HQMT.Category, a.VendorGroup, a.LastVendor, a.LastCost, a.LastECM,
      a.LastCostUpdate, a.AvgCost, a.AvgECM, a.StdCost, a.StdECM, a.StdPrice, a.PriceECM, a.LowStock, a.ReOrder, a.WeightConv, a.PhyLoc,
      a.LastCntDate, a.PhaseGroup, a.CostPhase, a.Active, a.AutoProd, a.GLSaleUnits, a.CustRate, a.JobRate, a.InvRate, a.EquipRate, a.OnHand,
      a.RecvdNInvcd, a.Alloc, a.OnOrder, a.AuditYN, a.Notes, a.GLProdUnits
    From INMT a
    Join HQMT on HQMT.MatlGroup=a.MatlGroup and HQMT.Material=a.Material

GO
GRANT SELECT ON  [dbo].[brvINMTCat] TO [public]
GRANT INSERT ON  [dbo].[brvINMTCat] TO [public]
GRANT DELETE ON  [dbo].[brvINMTCat] TO [public]
GRANT UPDATE ON  [dbo].[brvINMTCat] TO [public]
GRANT SELECT ON  [dbo].[brvINMTCat] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvINMTCat] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvINMTCat] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvINMTCat] TO [Viewpoint]
GO
