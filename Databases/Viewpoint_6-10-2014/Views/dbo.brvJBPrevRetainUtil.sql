SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvJBPrevRetainUtil] as select a.JBCo,a.BillMonth, a.BillNumber, a.Item, 
           ThisBillsPrevWCRetg = min(a.PrevWCRetg),
           TruePrevWCRetg = isnull(sum(b.WCRetg),0), 
           Diff = min(a.PrevWCRetg) - isnull(sum(b.WCRetg),0)
    from JBIT a
    join JBIT b on b.JBCo = a.JBCo and b.Contract = a.Contract and b.Item = a.Item
    where isnull(a.BillGroup,'') = isnull(b.BillGroup,'') and
             ((b.BillMonth < a.BillMonth) or (b.BillMonth = a.BillMonth and b.BillNumber < a.BillNumber)) 
    group by  a.JBCo,a.BillMonth, a.BillNumber,a.Item
    having (min(a.PrevWCRetg) - isnull(sum(b.WCRetg),0)) <> 0

GO
GRANT SELECT ON  [dbo].[brvJBPrevRetainUtil] TO [public]
GRANT INSERT ON  [dbo].[brvJBPrevRetainUtil] TO [public]
GRANT DELETE ON  [dbo].[brvJBPrevRetainUtil] TO [public]
GRANT UPDATE ON  [dbo].[brvJBPrevRetainUtil] TO [public]
GRANT SELECT ON  [dbo].[brvJBPrevRetainUtil] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJBPrevRetainUtil] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJBPrevRetainUtil] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJBPrevRetainUtil] TO [Viewpoint]
GO
