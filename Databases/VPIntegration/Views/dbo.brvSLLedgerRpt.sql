SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[brvSLLedgerRpt] as              
              
/*************************************              
Added the APTL.GrossAmt but then realized this would not work and changed back to APTD.Amount               
and added in the APTL.TaxAmt and the APTL.MiscAmt instead for issue 121628 CR              
Added SLIT.TaxType and APTD.TotTaxAmount     issue 128574 CR     
  
Issue #137577  see line #99   4/29/10  
  
           
************************************/              
            
                
Select             
SLIT.SLCo,              
SLIT.SL,              
Vendor=APVM.Vendor,              
SLIT.SLItem,              
SLIT.ItemType,              
ItemDesc=SLIT.Description,              
ItemUM=SLIT.UM,              
SLIT.JCCo,              
SLIT.Job,              
SLIT.PhaseGroup,    --10          
SLIT.Phase,              
SLIT.JCCType,              
OrigItemCost=SLIT.OrigCost,              
TaxType=SLIT.TaxType,              
OrigTax=SLIT.OrigTax,              
CurTax=SLIT.CurTax,              
OrigItemUnits=SLIT.OrigUnits,              
OrigItemUC=SLIT.OrigUnitCost,              
BackChargeAmt =(case when SLIT.ItemType=3 then SLIT.OrigCost else 0 end), --19        
BackChargeTax =(case when SLIT.ItemType=3 then SLIT.OrigTax else 0 end),              
BackChargeUnits=(case when SLIT.ItemType=3 then SLIT.OrigUnits else 0 end),    --20          
APMth='01/01/1950',              
APTrans=NULL,              
APRef=NULL,              
APInvDate=NULL,              
APLine=NULL,              
APSeq=NULL,              
APPayType=NULL,              
APUM=NULL,              
APBilledUnits = 0,              
APUnits=0,    --30          
APUnitCost=0,              
APLineType=NULL,              
APAmount=0,           
APRetTax=0,    --34          
APDiscount=0,               
APPaidAmt=0,              
APTaxAmt=0,              
APMiscAmt=0,              
APPaidMth=NULL,              
APBank=NULL,              
APCheck=NULL,              
APStatus=NULL,              
APPayCategory = 0,              
SLIT.VendorGroup,              
SLIT.Supplier,              
SupplierName = APVM_Supplier.Name,              
InternalChangeOrder=NULL,              
AppChangeOrder=NULL,              
CODate=NULL,              
COMonth='01/01/1950',              
COTrans=NULL,              
CODesc=NULL,              
COUM=NULL,              
COUnits=0,              
COUnitCost=0,              
COCost=0,             
ChgToTax=0,            
ReportSeq='SL ',              
JCCM.ContractStatus,              
APPdDate=NULL,              
CurUnitCost=SLIT.CurUnitCost              
            
from SLIT               
Left Join SLHD on SLIT.SLCo=SLHD.SLCo and SLIT.SL = SLHD.SL               
Join HQCO  on HQCO.HQCo=SLIT.SLCo              
Left Join JCJM on JCJM.JCCo=SLIT.JCCo and JCJM.Job=SLIT.Job              
Left join JCCM on JCCM.JCCo=JCJM.JCCo and JCCM.Contract=JCJM.Contract and JCCM.ContractStatus<>0              
Left Join APVM on APVM.VendorGroup=SLHD.VendorGroup and APVM.Vendor=SLHD.Vendor              
Left Join APVM as APVM_Supplier on APVM_Supplier.VendorGroup = SLIT.VendorGroup and APVM_Supplier.Vendor=SLIT.Supplier            
--where  SLIT.SL='sc99901'              
--             
  UNION ALL              
            
Select           
APTL.APCo,              
APTL.SL,              
APTH.Vendor,              
APTL.SLItem,              
SLIT.ItemType,              
SLIT.Description,              
SLIT.UM,              
SLIT.JCCo,              
SLIT.Job,              
SLIT.PhaseGroup,  --10            
SLIT.Phase,              
SLIT.JCCType,              
0,              
APTL.TaxType,   -- Issue #137577 ---Changed from SLIT.TaxType----------------------------------------------------------------           
0,              
0,              
0,              
0,              
0,      --19        
0 as 'BackChargeTax',         
0,    --20          
APTH.Mth,              
APTL.APTrans,              
APTH.APRef,              
APTH.InvDate,              
APTL.APLine,              
APTD.APSeq,              
APTD.PayType,              
APTL.UM,              
0,              
APTL.Units,    --30          
APTL.UnitCost,              
APTL.LineType,              
APTD.Amount, --APTL.GrossAmt,--issue 121628 CR              
APTD.TotTaxAmount, -- issue 128574 CR    --34          
APTD.DiscTaken,               
APPaidAmt=(case when APTD.Status>2  or APTD.PaidMth is not null then (APTD.Amount) else 0 end),              
APTL.TaxAmt,              
APTL.MiscAmt,              
APTD.PaidMth,              
APTD.CMAcct,              
APTD.CMRef,              
APTD.Status,              
APTD.PayCategory,              
APTD.VendorGroup,              
APTD.Supplier,              
SupplierName = APVM_Supplier.Name,              
Null,              
Null,              
Null,              
'01/01/1950',              
Null,              
Null,              
Null,              
0,              
0,              
0,              
ChgToTax=0,            
ReportSeq='AP',              
NULL,              
APPdDate=APTD.PaidDate,              
SLIT.CurUnitCost              
            
from APTL            
Join SLIT on APTL.APCo = SLIT.SLCo and APTL.SL = SLIT.SL  and APTL.SLItem = SLIT.SLItem              
Join APTD  on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and APTD.APTrans=APTL.APTrans and APTD.APLine=APTL.APLine              
Join APTH  on APTH.APCo=APTL.APCo and APTH.Mth=APTL.Mth and APTH.APTrans =APTL.APTrans               
Join APCO on APTL.APCo = APCO.APCo              
Left Join APVM as APVM_Supplier on APVM_Supplier.VendorGroup = APTD.VendorGroup and APVM_Supplier.Vendor=APTD.Supplier              
--where  SLIT.SL='sc99901'               
            
UNION ALL              
            
select           
SLCD.SLCo,              
SLCD.SL,              
SLHD.Vendor,              
SLCD.SLItem,              
SLIT.ItemType,              
SLIT.Description,              
SLIT.UM,              
SLIT.JCCo,              
SLIT.Job,              
SLIT.PhaseGroup,--10              
SLIT.Phase,              
SLIT.JCCType,              
0,              
SLIT.TaxType,              
0,              
0,              
0,              
0,              
0,             
0 as 'BackChargeTax',          
0,    --20          
'01/01/1950',              
NULL,              
NULL,              
NULL,              
NULL,              
NULL,              
NULL,              
NULL,              
0,              
0,    --30          
0,              
NULL,              
0,              
0,    --34          
0,               
0,              
0,              
0,              
NULL,              
NULL,              
NULL,              
NULL,              
0,              
SLIT.VendorGroup,              
NULL,              
NULL,              
SLCD.SLChangeOrder,              
SLCD.AppChangeOrder,              
SLCD.ActDate,              
SLCD.Mth,              
SLCD.SLTrans,              
SLCD.Description,              
SLCD.UM,              
SLCD.ChangeCurUnits,              
SLCD.ChangeCurUnitCost,              
SLCD.ChangeCurCost,            
SLCD.ChgToTax,              
ReportSeq='CO',              
NULL,              
NULL,              
SLIT.CurUnitCost              
            
from SLCD              
Join SLIT  on SLIT.SLCo=SLCD.SLCo and SLIT.SL=SLCD.SL and SLIT.SLItem=SLCD.SLItem              
Join SLHD on SLIT.SLCo = SLHD.SLCo and SLIT.SL = SLHD.SL              
--where  SLIT.SL='sc99901'            
              
UNION ALL              
            
select           
APTL.APCo,              
APTL.SL,              
APTH.Vendor,              
APTL.SLItem,              
max(SLIT.ItemType),              
max(SLIT.Description),              
APTL.UM,              
APTL.JCCo,              
APTL.Job,              
max(SLIT.PhaseGroup),   --10           
max(SLIT.Phase),              
max(SLIT.JCCType),              
0,              
max(SLIT.TaxType),              
0,              
0,              
0,              
0,              
0,           
0 as 'BackChargeTax',            
0,    --20          
APTL.Mth,              
NULL,              
NULL,              
NULL,              
NULL,              
NULL,              
NULL,              
NULL,              
sum(APTL.Units),              
0,    --30          
0,              
NULL,              
0,              
0,    --34          
0,              
0,              
0,              
0,              
NULL,              
NULL,              
NULL,              
NULL,              
0,              
APTH.VendorGroup,              
NULL,              
NULL,              
NULL,              
Null,              
Null,              
'01/01/1950',              
Null,              
Null,              
Null,              
0,              
0,              
0,              
ChgToTax=0,            
ReportSeq='APSL',              
NULL,              
NULL,              
sum(SLIT.CurUnitCost)             
from APTL              
Join SLIT on APTL.APCo = SLIT.SLCo and APTL.SL = SLIT.SL  and APTL.SLItem = SLIT.SLItem              
Join APTH  on APTH.APCo=APTL.APCo and APTH.Mth=APTL.Mth and APTH.APTrans =APTL.APTrans               
--where  SLIT.SL='sc99901'               
group by APTL.APCo, APTL.SL, APTL.SLItem, APTL.UM, APTL.JCCo,APTL.Job, APTH.VendorGroup,APTH.Vendor, APTL.Mth     
    
    
GO
GRANT SELECT ON  [dbo].[brvSLLedgerRpt] TO [public]
GRANT INSERT ON  [dbo].[brvSLLedgerRpt] TO [public]
GRANT DELETE ON  [dbo].[brvSLLedgerRpt] TO [public]
GRANT UPDATE ON  [dbo].[brvSLLedgerRpt] TO [public]
GO
