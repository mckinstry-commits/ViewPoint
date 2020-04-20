SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      view [dbo].[brvJBRetainageException]
    as
    /****** Script for Retainage Problems ***************
     Author JRE 5/7/02  
     Shows differences between retainage amounts and previous reatiange amounts 
     used on JB Retainage Exception Report 
     Rem'd out the Bill Group in the join statements per Issue 23375  NF 05/14/04 
     added Tax amounts to retainage amounts for International issue 129262 CR 10/15/08

    **************************/
    select a.JBCo, a.Contract, a.BillMonth, a.BillNumber, a.Item,
           ThisBillsPrevWCRetg = (min(a.PrevWCRetg)+ min(a.PrevRetgTax)),
           TruePrevWCRetg = isnull(sum(b.WCRetg),0)+isnull(sum(b.RetgTax),0), 
    	   DiffPrevWCRetg = (min(a.PrevWCRetg)+ min(a.PrevRetgTax)) - (isnull(sum(b.WCRetg),0)+isnull(sum(b.RetgTax),0)),
           ThisBillsPrevSMRetg = min(a.PrevSMRetg),
           TruePrevSMRetg = isnull(sum(b.SMRetg),0),
    	   DiffPrevSMRetg = min(a.PrevSMRetg) - isnull(sum(b.SMRetg),0),
           ThisBillsPrevRelRetg = (min(a.PrevRetgReleased) + min(a.PrevRetgTaxRel)),
           TruePrevRelRetg = (isnull(sum(b.RetgRel),0)+isnull(sum(b.RetgTaxRel),0)), 
           DiffPrevRelRetg = (min(a.PrevRetgReleased)++ min(a.PrevRetgTaxRel)) - (isnull(sum(b.RetgRel),0) +isnull(sum(b.RetgTaxRel),0))
    from JBIT a
    join JBIT b on b.JBCo = a.JBCo and b.Contract = a.Contract and b.Item = a.Item
            --and isnull(a.BillGroup,'') = isnull(b.BillGroup,'')
            and ((b.BillMonth < a.BillMonth) or (b.BillMonth = a.BillMonth and b.BillNumber < a.BillNumber))
   
    join (select JBCo, Contract, /*BillGroup=isnull(BillGroup,''),*/ BillMonth=max(BillMonth) 
          from JBIN  group by JBCo, Contract/*, BillGroup*/) as JBIN1 
          on JBIN1.JBCo = a.JBCo and JBIN1.Contract = a.Contract 
          /*and isnull(a.BillGroup,'') = JBIN1.BillGroup*/ and a.BillMonth=JBIN1.BillMonth
    
    join (select JBCo, Contract, /*BillGroup=isnull(BillGroup,''),*/ BillMonth=BillMonth , BillNumber=max(BillNumber)
          from JBIN  group by JBCo, Contract, /*BillGroup,*/ BillMonth) as JBIN2 
          on JBIN2.JBCo = a.JBCo and JBIN2.Contract = a.Contract 
          /* and isnull(a.BillGroup,'') = JBIN2.BillGroup*/ and a.BillMonth=JBIN2.BillMonth and a.BillNumber=JBIN2.BillNumber
   
   
    
    group by a.JBCo, a.Contract, a.BillMonth, a.BillNumber, a.Item
    having ((min(a.PrevWCRetg) - isnull(sum(b.WCRetg),0)) <> 0
         or (min(a.PrevSMRetg) - isnull(sum(b.SMRetg),0)) <> 0
         or (min(a.PrevRetgReleased) - isnull(sum(b.RetgRel),0)) <> 0)

GO
GRANT SELECT ON  [dbo].[brvJBRetainageException] TO [public]
GRANT INSERT ON  [dbo].[brvJBRetainageException] TO [public]
GRANT DELETE ON  [dbo].[brvJBRetainageException] TO [public]
GRANT UPDATE ON  [dbo].[brvJBRetainageException] TO [public]
GO
