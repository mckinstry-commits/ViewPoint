SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   
   
   CREATE            View  [dbo].[brvARInvCreditNotes] as
      
      /*******
      * View that returns rows of AR Transactions only
      * and also selects Customer Credit Notes assigned to invoices but without AR
      * Transaction Detail.  View solves many to many relationship between ARTH (AR Transaction Header)
      * and ARCN (AR Credit Notes)
       
      * Usage:  Used by the AR Credit Inquiry DrillDown report  
      * Mod: 6/21/02 DH
     
       Modified 9/17/03 added TaxDisc, TaxAmount, DiscTaken and FinanceChg fields CR
       Mod 7/2/04 issue 24785 Added ApplyMth, ApplyTrans and Sort to Credit Notes section DH
     
      *********/
      
      
        Select 
        e.ARCo,e.CustGroup,e.Customer,m.Name,e.Invoice,e.Description,e.Contract,e.CheckNo,
        Status = case when e.Invoice <> '' then 'Applied' else 'Unapplied' end,
        e.Mth,e.ARTrans,e.TransDate,e.ARTransType,e.DueDate ,e.DiscDate,/*iAppliedMth = null,iAppliedTrans = null,*/
        iPaid = null,
        e.AppliedMth,e.AppliedTrans,
        
        theMth=e.Mth,theARTrans =e.ARTrans,theARTransType=e.ARTransType,
        
        thcMth =c.Mth,thcARTrans=c.ARTrans,c.ApplyMth,c.ApplyTrans,bARline = Null,c.ApplyLine,
        c.ARLine,c.Amount,c.Retainage,c.DiscOffered,DetailTransDate = d.TransDate,DetailDescription = d.Description,
        DetailTransType = d.ARTransType, ARTLDescription=c.Description,TaxAmount=c.TaxAmount, TaxDisc=c.TaxDisc,
        DiscTaken=c.DiscTaken, FinanceChg=c.FinanceChg,
        
        Seq = Null,Date = Null,Contact = Null,Followup = Null,Resolved = Null,
        UserID = Null,Summary = Null,Notes = Null,Sort=1
        
        From ARTL c
        Inner Join ARTH d On c.ARCo = d.ARCo and c.Mth = d.Mth and c.ARTrans = d.ARTrans
        Inner Join ARTH e On c.ARCo = e.ARCo and c.ApplyMth = e.Mth and c.ApplyTrans = e.ARTrans and
        d.CustGroup = e.CustGroup and d.Customer = e.Customer
        Inner Join ARCM m On d.CustGroup=m.CustGroup and d.Customer=m.Customer
        --Where d.ARTransType  IN ('C','A','W','P','R') and e.ARTransType <> 'R'
        
        Union ALL
        
        Select f.ARCo,g.CustGroup,g.Customer,null,g.Invoice,ddescription = null,null,null,
        aStatus = Null,
        cnMth = '1/1/2050',ARTrans = 9999999,TransDate,ARTransType = 'N',DueDate,DiscDate = Null,
        /*AppliedMth = '1/1/2050',AppliedTrans = 9999999 ,*/
        Paid = Null,
        bAppliedMth = '1/1/2050', bAppliedTrans = 9999999,
        
        cMth =Null,cARTrans = Null, cARTransType = null,
        
        aMth = Null,aARTrans = Null,f.ApplyMth,f.ApplyTrans,bARline = Null,aApplyLine = Null,
        aARLine = Null,aAmount = Null,aRetainage = Null,aDiscOffered = Null,f.TransDate,aDescription = Null,
        aARTransType=Null, aARTLDescription=Null,aARTLTaxAmount=Null, aARTLTaxDisc=Null, aARTLDiscTaken=Null,
        aARTLFinanceChg=Null,
        
        Seq,Date,Contact,Followup,Resolved,
        UserID,Summary,g.Notes,2
        
        From ARCN g
        Join (select ARTH.ARCo, ARTH.CustGroup, ARTH.Customer, ARTH.Invoice, ARTL.ApplyMth, ARTL.ApplyTrans, TransDate=min(ARTH.TransDate), DueDate=min(ARTH.DueDate) From ARTL
               Join ARTH on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans
              Group By ARTH.ARCo, ARTH.CustGroup, ARTH.Customer, ARTH.Invoice, ARTL.ApplyMth, ARTL.ApplyTrans)
             as f on f.CustGroup=g.CustGroup and f.Customer=g.Customer and f.Invoice=g.Invoice
          --Where  isnull(g.Invoice,'') <> ''
        
        
        
       
       
       
       
       
      
      
      
      
      
      
      
      
      
      
     
     
    
    
    
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvARInvCreditNotes] TO [public]
GRANT INSERT ON  [dbo].[brvARInvCreditNotes] TO [public]
GRANT DELETE ON  [dbo].[brvARInvCreditNotes] TO [public]
GRANT UPDATE ON  [dbo].[brvARInvCreditNotes] TO [public]
GO
