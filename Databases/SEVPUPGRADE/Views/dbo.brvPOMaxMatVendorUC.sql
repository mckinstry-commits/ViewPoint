SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvPOMaxMatVendorUC] as select a.MatlGroup,a.Material,MaxUnitCost=Max(a.CurUnitCost),a.POCo,b.VendorGroup,b.Vendor
     from POIT a, POHD b
    where a.POCo=b.POCo and a.PO=b.PO 
    and b.OrderDate = 
    (select Max(p.OrderDate) from POHD p, POIT t
    where p.POCo=t.POCo and p.PO=t.PO
    and a.POCo=t.POCo
    and  a.MatlGroup=t.MatlGroup and a.Material=t.Material
    and b.VendorGroup=p.VendorGroup and b.Vendor=p.Vendor)
    group by a.MatlGroup,a.Material,a.POCo,b.VendorGroup,b.Vendor

GO
GRANT SELECT ON  [dbo].[brvPOMaxMatVendorUC] TO [public]
GRANT INSERT ON  [dbo].[brvPOMaxMatVendorUC] TO [public]
GRANT DELETE ON  [dbo].[brvPOMaxMatVendorUC] TO [public]
GRANT UPDATE ON  [dbo].[brvPOMaxMatVendorUC] TO [public]
GO
