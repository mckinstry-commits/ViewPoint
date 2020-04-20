SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvPOMaxMatUC] as select a.MatlGroup,a.Material,MaxUnitCost=Max(a.CurUnitCost),a.POCo from POIT a, POHD b
    where a.POCo=b.POCo and a.PO=b.PO 
    and b.OrderDate = 
    (select Max(p.OrderDate) from POHD p, POIT t
    where p.POCo=t.POCo and p.PO=t.PO
    and a.POCo=t.POCo
    and  a.MatlGroup=t.MatlGroup and a.Material=t.Material)
    group by a.MatlGroup,a.Material,a.POCo

GO
GRANT SELECT ON  [dbo].[brvPOMaxMatUC] TO [public]
GRANT INSERT ON  [dbo].[brvPOMaxMatUC] TO [public]
GRANT DELETE ON  [dbo].[brvPOMaxMatUC] TO [public]
GRANT UPDATE ON  [dbo].[brvPOMaxMatUC] TO [public]
GRANT SELECT ON  [dbo].[brvPOMaxMatUC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPOMaxMatUC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPOMaxMatUC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPOMaxMatUC] TO [Viewpoint]
GO
