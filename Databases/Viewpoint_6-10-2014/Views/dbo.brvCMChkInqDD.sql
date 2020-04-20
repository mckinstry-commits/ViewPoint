SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[brvCMChkInqDD] 
AS
    
/********************************************************************************************

Created 07/31/2003 NF
   
This view joins CMDT with AP and PR records to provide a drilldown on CM Checks to their sources.
For AP it was necessary to process records for both CMTransType 1 checks and CMTransType 4 EFT payments.
To avoid cartesian results, the AP records are separated into two select statements.
   
Reports:  CMPaymentDD.rpt (formerly known as CMCheckInquiryDD.rpt)
   
Revisions:

01/18/2006 NF Issue 119765 Removed the join between PRPH Payroll Group and PREH Payroll Group so that 
employees reassigned to different payroll group will still display on the report.

04/30/2012 Czeslaw B-09179 (No CL issue) Added new Select statement to handle AP credit service payments.
Also added column APCo to criteria in joins between APPH and APPD to insure data integrity (pre-existing
defect). Also, for AP EFTs, changed data source for selected columns PayMethod and EFTSeq from APPD to APPH 
in order to display values properly for voided payments (pre-existing defect).
   
********************************************************************************************/

--PR checks

    select a.CMCo, a.CMAcct, a.CMTransType, a.SourceCo, a.Source, a.ActDate, a.Description, a.Amount, a.ClearedAmt, a.CMRef, a.CMRefSeq, a.Payee, a.Void, a.ClearDate, 
     b.PayMethod,b.EFTSeq, b.PRGroup, b.PREndDate, b.PaidDate,b.Employee, Name=(c.LastName+', '+ c.FirstName+' '+IsNull(c.MidName,'')),Vendor=0,b.PaySeq,b.PaidAmt,b.Hours,b.Earnings,b.NonTrueAmt,b.Dedns,b.VoidMemo,
     APMth=Null, APTrans=0, APRef=null, InvDate=null, Gross=0, Retg=0, DiscountsTaken=0,OtherDeducts=0,Net =0,
     RecType = 'PR'
     From CMDT a  With (NoLock)
     Inner Join PRPH  b With (NoLock) on a.CMCo=b.CMCo and a.CMAcct = b.CMAcct and a.CMRef = b.CMRef and a.CMRefSeq = b.CMRefSeq and a.CMTransType = 1
     Inner Join PREH c With (NoLock) on b.PRCo = c.PRCo and b.Employee=c.Employee --and b.PRGroup = c.PRGroup
    Where b.PayMethod = 'C' and  a.Source like 'PR%'
    
    Union All

--PR EFTs

    select a.CMCo, a.CMAcct, a.CMTransType, a.SourceCo, a.Source, a.ActDate, a.Description, a.Amount, a.ClearedAmt, a.CMRef, a.CMRefSeq, a.Payee, a.Void, a.ClearDate, 
     e.PayMethod,e.EFTSeq, e.PRGroup, e.PREndDate, e.PaidDate,e.Employee, Name=(f.LastName+', '+ f.FirstName+' '+IsNull(f.MidName,'')),Vendor=0,e.PaySeq,e.PaidAmt,e.Hours,e.Earnings,e.NonTrueAmt,e.Dedns,e.VoidMemo,
     APMth=Null, APTrans=0, APRef=null, InvDate=null, Gross=0, Retg=0, DiscountsTaken=0,OtherDeducts=0,Net =0,
     RecType = 'PR'
     From CMDT a  With (NoLock)
     Inner Join PRPH  e With (NoLock) on a.CMCo=e.CMCo and a.CMAcct = e.CMAcct and a.CMRef = e.CMRef and a.CMRefSeq = e.CMRefSeq and a.CMTransType = 4
     Inner Join PREH f With (NoLock) on e.PRCo = f.PRCo and e.Employee=f.Employee --and e.PRGroup = f.PRGroup
    Where e.PayMethod = 'E' and a.Source like 'PR%'
    
    Union All

--AP checks

     select a.CMCo, a.CMAcct, a.CMTransType, a.SourceCo, a.Source, a.ActDate, a.Description, a.Amount, a.ClearedAmt, a.CMRef, a.CMRefSeq, a.Payee, a.Void, a.ClearDate,
     h.PayMethod,h.EFTSeq, PRGroup=0, PREndDate=Null, PaidDate=Null,Employee=0, 
     h.Name, h.Vendor, 
     PaySeq=0,  PaidAmt=0,Hours=0,Earnings=0,NonTrueAmt=0,Dedns=0,
     h.VoidMemo,
     APMth=d.Mth, d.APTrans,d.APRef,d.InvDate, d.Gross, d.Retainage, d.DiscTaken,OtherDeducts=(d.PrevPaid +d.PrevDiscTaken+d.Balance),Net = d.Gross - (d.Retainage + d.PrevPaid+d.PrevDiscTaken+d.Balance+d.DiscTaken),
     RecType = 'AP'
     From CMDT a With (NoLock)
       Inner Join APPH h With (NoLock) on a.CMCo=h.CMCo and a.CMAcct = h.CMAcct and a.CMRef = h.CMRef and a.CMRefSeq = h.CMRefSeq and a.CMTransType = 1
       Left Outer Join APPD d With (NoLock) on h.APCo=d.APCo and h.CMCo=d.CMCo and h.CMAcct = d.CMAcct and h.PayMethod = d.PayMethod and h.CMRef = d.CMRef and h.CMRefSeq = d.CMRefSeq and h.EFTSeq = d.EFTSeq
     Where h.PayMethod = 'C' and a.Source like 'AP%'
    
     Union All

--AP EFTs

    select a.CMCo, a.CMAcct, a.CMTransType, a.SourceCo, a.Source, a.ActDate, a.Description, a.Amount, a.ClearedAmt, a.CMRef, a.CMRefSeq, a.Payee, a.Void, a.ClearDate,
     f.PayMethod, f.EFTSeq, PRGroup=0, PREndDate=Null, PaidDate=Null,Employee=0, 
    f.Name, f.Vendor, 
     PaySeq=0,  PaidAmt=0,Hours=0,Earnings=0,NonTrueAmt=0,Dedns=0,
    f.VoidMemo,
     APMth=e.Mth, e.APTrans,e.APRef,e.InvDate, e.Gross, e.Retainage, e.DiscTaken,OtherDeducts=(e.PrevPaid +e.PrevDiscTaken+e.Balance),Net = e.Gross - (e.Retainage + e.PrevPaid+e.PrevDiscTaken+e.Balance+e.DiscTaken),
     RecType = 'AP'
     From CMDT a With (NoLock)
      Inner Join APPH f With (NoLock) on a.CMCo=f.CMCo and a.CMAcct = f.CMAcct and a.CMRef = f.CMRef and a.CMRefSeq = f.CMRefSeq and a.CMTransType = 4
       Left Outer Join APPD e With (NoLock) on f.APCo=e.APCo and f.CMCo=e.CMCo and f.CMAcct = e.CMAcct and f.PayMethod = e.PayMethod and f.CMRef = e.CMRef and f.CMRefSeq = e.CMRefSeq and f.EFTSeq = e.EFTSeq
    Where f.PayMethod = 'E' and a.Source like 'AP%'
    Union All
    
--AP credit service payments

    select a.CMCo, a.CMAcct, a.CMTransType, a.SourceCo, a.Source, a.ActDate, a.Description, a.Amount, a.ClearedAmt, a.CMRef, a.CMRefSeq, a.Payee, a.Void, a.ClearDate,
     f.PayMethod, f.EFTSeq, PRGroup=0, PREndDate=Null, PaidDate=Null, Employee=0, 
    f.Name, f.Vendor, 
     PaySeq=0,  PaidAmt=0,Hours=0,Earnings=0,NonTrueAmt=0,Dedns=0,
    f.VoidMemo,
     APMth=e.Mth, e.APTrans,e.APRef,e.InvDate, e.Gross, e.Retainage, e.DiscTaken,OtherDeducts=(e.PrevPaid +e.PrevDiscTaken+e.Balance),Net = e.Gross - (e.Retainage + e.PrevPaid+e.PrevDiscTaken+e.Balance+e.DiscTaken),
     RecType = 'AP'
     From CMDT a With (NoLock)
      Inner Join APPH f With (NoLock) on a.CMCo=f.CMCo and a.CMAcct = f.CMAcct and a.CMRef = f.CMRef and a.CMRefSeq = f.CMRefSeq and a.CMTransType = 4
       Left Outer Join APPD e With (NoLock) on f.APCo=e.APCo and f.CMCo=e.CMCo and f.CMAcct = e.CMAcct and f.PayMethod = e.PayMethod and f.CMRef = e.CMRef and f.CMRefSeq = e.CMRefSeq and f.EFTSeq = e.EFTSeq
    Where f.PayMethod = 'S' and a.Source like 'AP%'
    
    Union All   

--CM transactions

    select CMCo, CMAcct, CMTransType, SourceCo, Source, ActDate, Description, Amount, ClearedAmt, CMRef, CMRefSeq, Payee, Void, ClearDate,
     PayMethod=NULL,EFTSeq=NULL, PRGroup=0, PREndDate=Null, PaidDate=Null,Employee=0, Name=NULL, Vendor=NULL, PaySeq=0,  PaidAmt=0,Hours=0,Earnings=0,NonTrueAmt=0,Dedns=0,VoidMemo=NULL,
     APMth=NULL, APTrans=0,APRef=NULL,InvDate=NULL, Gross=0, Retg=0, DiscountsTaken=0,OtherDeducts=0,Net = 0,
     RecType = 'CM'
     From CMDT With (NoLock)
    Where CMTransType in (1,4) and Source like 'CM%'
GO
GRANT SELECT ON  [dbo].[brvCMChkInqDD] TO [public]
GRANT INSERT ON  [dbo].[brvCMChkInqDD] TO [public]
GRANT DELETE ON  [dbo].[brvCMChkInqDD] TO [public]
GRANT UPDATE ON  [dbo].[brvCMChkInqDD] TO [public]
GRANT SELECT ON  [dbo].[brvCMChkInqDD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvCMChkInqDD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvCMChkInqDD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvCMChkInqDD] TO [Viewpoint]
GO
