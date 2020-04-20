SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[brvPOPurchStats] as                  
---- Issue #25648  9/27/04  JRE POIT is not needed to be joined to                  
---- Issue #123432 1/8/07 CR add Status 4 to PaidAmount formula in detail sort 3                  
---- Issue #131470 3/19/09  MB Added APTaxType to procedure      
---- Issue #137459 MB: PO Purchase Order Status Report showing inflated InvAmt w tax      
----					In fourth Union, commented out APPD table in join.    
----					This is how 620 version worked      
----					AP Transaction now shows corectly on report on report      
---- Issue #132192 3/11/10 HH Added POIT.ChangeBOCost, POIT.RemCost, POIT.RemTax, APTL.UnitCost  
---- 13 Sept 2011 - DML - Add POItemLine table, general format cleanup
---- Issue #145424 TK-12288 02/12/12 HH Replaced Union1 with Union5 because of item 
---- 								 in POIT is captured in POItemLine already and change left 
---- 								 outer join to inner join for perfromance reasons
               
                  
select              
'U1' as U,                     
POItemLine.POCo,   --1              
POItemLine.PO,                 
POHD.VendorGroup,  --3               
POHD.Vendor,                 
POItemLine.POItem,                
POItemLine.ItemType,      --6              
Null as ChangeCurUnits,                 
Null as CurUnitCost,       
Null as APUnitCost,            
POItemLine.CurTax,    --9              
DetailSort = 1,                 
POIT.Description,                  
Null as ChangeOrder,   --12              
Null as Mth,                 
Null as ChangeCurCost,    
Null as ChangeBOCost,                 
Null as ChgTotCost,    --15              
Null as ChgToTax,--16       
Null as InvoiceDate,                 
Null as PaidMth,                 
Null as PaidDate,   --18              
Null as CMRef,                 
Null as APRef,                 
POItemLine.OrigCost,    ---21                  
POItemLine.OrigTax,              
Null as POJCCmtdTax,              
POItemLine.InvCost,                 
POItemLine.InvTax,                 
POItemLine.TaxType,   --24              
POItemLine.RemCost,  
POItemLine.RemTax,                 
Null as APMisc,                  
Null as InvAmount,                 
Null as PaidAmount,   --27              
Null as Retainage,                 
Null as APTrans,                 
Null as POTrans,  --30              
Null as APTax,                   
POIT.PostToCo as POITJCCo,                 
POItemLine.Job as POITJob,   --33              
Null as APTaxType,                
Null as DiscTaken,    
POItemLine.BOCost,
POItemLine.BOUnits,
POItemLine.Component,
POItemLine.CurCost,
POItemLine.CurUnits,
POItemLine.EMCo,
POItemLine.Equip,
POItemLine.INCo,
POItemLine.InvMiscAmt,
POItemLine.InvUnits,
POItemLine.Loc,
POItemLine.OrigUnits,
POItemLine.Phase,
POItemLine.POItemLine,
POItemLine.RecvdCost,
POItemLine.RecvdUnits,
POItemLine.RemUnits,
POItemLine.SMScope,
POItemLine.SMWorkOrder,
POItemLine.WO,
POItemLine.WOItem,
POItemLine.ItemType as POItemLineItemType,
POIT.UM,
POIT.CurECM
From POItemLine POItemLine              
Inner Join POIT               
 on POItemLine.POCo = POIT.POCo                 
 and POItemLine.PO = POIT.PO
 and POItemLine.POItem = POIT.POItem  
Inner Join POHD
 on POItemLine.POCo = POHD.POCo                 
 and POItemLine.PO = POHD.PO         
           
union all                    
                    
select              
'U2' as U,                     
POCD.POCo,   --1              
POCD.PO,                 
POHD.VendorGroup,  --3               
POHD.Vendor,                 
POCD.POItem,                
Null as ItemType,    --6              
POCD.ChangeCurUnits,                 
POCD.CurUnitCost,       
Null as APUnitCost,            
NULL as CurTax,    --9              
DetailSort = 2,                 
POCD.Description,                  
POCD.ChangeOrder,   --12              
POCD.Mth,                 
POCD.ChangeCurCost,    
POCD.ChangeBOCost,                 
POCD.ChgTotCost,    --15              
POCD.ChgToTax,--16            
NULL as InvoiceDate,                 
NULL as PaidMth,    --18     
NULL as PaidDate,          
NULL as CMRef,   --19            
NULL as APRef,                 
NULL as OrigCost,     --21             
0 as OrigTax,                          
0 as POJCCmtdTax,              
NULL as InvCost,                 
NULL as InvTax,                 
POIT.TaxType,  --24      
Null as RemCost,          
Null as RemTax,          
NULL as APMisc,                  
NULL as InvAmt,                 
Null as PaidAmount,   --27              
NULL as Retainage,                 
Null as APTrans,                   
POCD.POTrans,  --30                
Null as APTax,                 
POIT.PostToCo as POITJCCo,                 
POIT.Job as POITJob,   --33              
Null as APTaxType,                
Null as DiscTaken,    --35 
Null as BOCost,
Null as BOUnits,
Null as Component,
Null as CurCost,
Null as CurUnits,
Null as EMCo,
Null as Equip,
Null as INCo,
Null as InvMiscAmt,
Null as InvUnits,
Null as Loc,
Null as OrigUnits,
Null as Phase,
Null as POItemLine,
Null as RecvdCost,
Null as RecvdUnits,
Null as RemUnits,
Null as SMScope,
Null as SMWorkOrder,
Null as WO,
Null as WOItem,
Null as POItemLineItemType,
POIT.UM,
POIT.CurECM  
From POCD                  
Join POHD With (NoLock)                 
 on POCD.POCo = POHD.POCo                 
 and POCD.PO = POHD.PO                  
Join POIT With (NoLock)                 
 on POCD.POCo = POIT.POCo                 
 and POCD.PO = POIT.PO                 
 and POCD.POItem = POIT.POItem        
--where POIT.PO =  '2820'              
                      
          
union all            
              
--     --This union brings in the Paid Amounts from APTD by Sequence                  
select              
'U3' as U,                     
APTL.APCo,   --1              
APTL.PO,                 
APTH.VendorGroup,--3                 
APTH.Vendor,                 
APTL.POItem,                 
APTL.ItemType,     --6              
Null as ChangeCurUnits,                
Null as CurUnitCost,                 
Null as APUnitCost,  
POIT.CurTax,    --9       
DetailSort = 3,               
Max(APTL.Description) as Description,                  
Null as ChangeOrder,   --12              
APTD.Mth,                 
NULL as ChangeCurCost,       
Null as ChangeBOCost,             
Null as ChgTotCost,   --15               
Null as ChgToTax,            
min(APTH.InvDate) as InvoiceDate,                 
APTD.PaidMth,                 
APTD.PaidDate,     --18              
max(Case when APTD.Status = 4 then 'Cleared' else APTD.CMRef end) as CMRef,                 
min(APTH.APRef) as APRef,                 
NULL as OrigCost,    --21              
0 as OrigTax,              
0 as POJCCmtdTax,              
Null as InvCost,                 
Null as InvTax,                 
Null as TaxType,   --24              
Null as RemCost,  
Null as RemTax,                 
Null as APMisc,                  
Null as InvAmount,                 
Sum((case when APTD.Status in (3,4) then APTD.Amount else 0 end)) as PaidAmount,    --27              
sum(case when APTD.PayType=APCO.RetPayType then APTD.Amount else 0 end) as Retainage,                 
APTD.APTrans,                 
Null as POTrans,  --30              
Null as APTax,               
POIT.PostToCo as POITJCCo,                 
POIT.Job as POITJob,   --33              
APTL.TaxType as APTaxType,                      
APTD.DiscTaken,  --35
Null as BOCost,
Null as BOUnits,
Null as Component,
Null as CurCost,
Null as CurUnits,
Null as EMCo,
Null as Equip,
Null as INCo,
Null as InvMiscAmt,
Null as InvUnits,
Null as Loc,
Null as OrigUnits,
Null as Phase,
Null as POItemLine,
Null as RecvdCost,
Null as RecvdUnits,
Null as RemUnits,
Null as SMScope,
Null as SMWorkOrder,
Null as WO,
Null as WOItem,
Null as POItemLineItemType,
Null as UM,
Null as CurECM              
From APTL                   
Join APTH With (NoLock)                 
 on APTH.APCo = APTL.APCo                 
 and APTH.Mth = APTL.Mth                 
 and APTH.APTrans = APTL.APTrans                  
-- Issue #25648  9/27/04  JRE POIT is not needed to be joined to                  
Join POIT With (NoLock)                 
 on APTL.APCo = POIT.POCo                 
 and APTL.PO = POIT.PO                 
 and APTL.POItem = POIT.POItem                  
Left Join APTD With (NoLock)                 
 on APTL.APCo = APTD.APCo                 
 and APTL.Mth = APTD.Mth                 
 and APTL.APTrans = APTD.APTrans                 
 and APTL.APLine = APTD.APLine                  
Inner Join APCO With (NoLock)                 
 on APCO.APCo=APTD.APCo                  
Where                 
APTL.PO is not null                   
and APTD.PaidMth is not NULL                  
--and  APTL.PO =  '2820'              
Group By APTL.APCo, APTD.Mth, APTD.APTrans, APTL.PO, APTL.POItem, APTL.ItemType, APTD.Mth,                  
 APTL.Description, POIT.PostToCo, POIT.Job, APTH.VendorGroup, APTH.Vendor,                     
 APTD.PaidMth, APTD.PaidDate, APTD.CMRef, APTL.TaxAmt,APTL.GrossAmt, APTL.TaxType, APTD.DiscTaken, POIT.CurTax                 
--                       
UNION ALL                  
              
-- This union gets the APTL Invoice, Misc/Frt, and Tax Amounts.                  
select     
distinct            
'U4' as U,                      
APTL.APCo,                 
APTL.PO,                 
APTH.VendorGroup,   --3              
APTH.Vendor,                 
APTL.POItem,                 
APTL.ItemType,     --6              
Null as ChangeCurUnits,                 
Null as CurUnitCost,               
APTL.UnitCost as APUnitCost,    
Null as CurTax,    --9              
DetailSort = 4,                 
NULL as Description,                  
Null as ChangeOrder,   --12              
APTL.Mth,                 
Null as ChangeCurCost,              
Null as ChangeBOCost,  
Null as ChgTotCost,     --15              
Null as ChgToTax,            
APTH.InvDate as InvoiceDate,                
NULL as PaidMth,                 
NULL as PaidDate,   --18              
NULL as CMRef,                 
APTH.APRef,                 
NULL as OrigCost,    --21              
0 as OrigTax,              
0 as POJCCmtdTax,              
Null as InvCost,                 
Null as InvTax,                 
Null as TaxType,   --24              
Null as RemCost,  
Null as RemTax,              
APTL.MiscAmt as APMisc,    
APTL.GrossAmt as InvAmount,                  
NULL as PaidAmount,   --27                
APTL.Retainage,                
APTL.APTrans,                 
Null as POTrans,   --30              
APTL.TaxAmt,                 
POIT.PostToCo as POITJCCo,                 
POIT.Job as POITJob,   --33              
APTL.TaxType as APTaxType,                               
Null as DiscTaken,    --35    
Null as BOCost,
Null as BOUnits,
Null as Component,
Null as CurCost,
Null as CurUnits,
Null as EMCo,
Null as Equip,
Null as INCo,
Null as InvMiscAmt,
Null as InvUnits,
Null as Loc,
Null as OrigUnits,
Null as Phase,
Null as POItemLine,
Null as RecvdCost,
Null as RecvdUnits,
Null as RemUnits,
Null as SMScope,
Null as SMWorkOrder,
Null as WO,
Null as WOItem,
Null as POItemLineItemType,
Null as UM,
Null as CurECM    
From APTL                 
Join APTH             
 on APTH.APCo = APTL.APCo                 
 and APTH.Mth = APTL.Mth                 
 and APTH.APTrans = APTL.APTrans                  
--join APPD                
-- on APTH.APCo = APPD.APCo                
-- and APTH.CMCo = APPD.CMCo                
-- and APTH.CMAcct = APPD.CMAcct                
-- and APTH.PayMethod = APPD.PayMethod                
-- and APTH.APRef = APPD.APRef                
Join POIT               
 on APTL.APCo = POIT.POCo                 
 and APTL.PO = POIT.PO                 
 and APTL.POItem = POIT.POItem                  
Where APTL.PO is not null                    
--and  APTL.PO =  '2820'               
 /*Group By APTL.APCo, APTL.Mth, APTL.APTrans, APTL.PO, APTL.POItem, APTL.ItemType,                   
           POIT.PostToCo, POIT.Job, APTH.VendorGroup, APTH.Vendor,  APTL.MiscAmt,                   
      APTL.TaxAmt,APTL.GrossAmt, APTL.Retainage*/       
      

                   

--where  POItemLine.POCo = 1 and POItemLine.PO = '2820'                
    
  
/*** PRE-DML VERSION BELOW ***  
  
  CREATE view [dbo].[brvPOPurchStats] as                  
---- Issue #25648  9/27/04  JRE POIT is not needed to be joined to                  
---- Issue #123432 1/8/07 CR add Status 4 to PaidAmount formula in detail sort 3                  
---- Issue #131470 3/19/09  MB Added APTaxType to procedure      
---- Issue #137459 MB: PO Purchase Order Status Report showing inflated InvAmt w tax      
                 -- In fourth Union, commented out APPD table in join.    
        -- This is how 620 version worked      
        -- AP Transaction now shows corectly on report on report      
---- Issue #132192 3/11/10 HH Added POIT.ChangeBOCost, POIT.RemCost, POIT.RemTax, APTL.UnitCost  
               
                  
select            
'U1' as 'U',                   
POIT.POCo,                 
POIT.PO,                 
POHD.VendorGroup,   --3              
POHD.Vendor,                 
POIT.POItem,                
POIT.ItemType,    --6              
ChangeCurUnits=Null,                
CurUnitCost=Null,                 
APUnitCost = Null,  
POIT.CurTax,    --9              
DetailSort = 1,                 
Description =  POIT.Description,                  
ChangeOrder = Null,--12                 
Mth = Null,                 
ChangeCurCost= Null,                 
ChangeBOCost= Null,                 
ChgTotCost = Null,    --15              
Null as 'ChgToTax',            
InvoiceDate=NULL,                 
PaidMth=NULL,                 
PaidDate=NULL,   --18              
CMRef=NULL,                 
APRef=NULL,                 
POIT.OrigCost,    ---21              
POIT.OrigTax as 'OrigTax',              
POIT.JCCmtdTax as 'POJCCmtdTax',              
POIT.InvCost,                 
POIT.InvTax,                 
POIT.TaxType,   --24              
POIT.RemCost,  
POIT.RemTax,                 
APMisc=NULL,                  
InvAmount=NULL,                 
PaidAmount=Null,   --27              
Retainage=NULL,                 
APTrans = Null,                 
POTrans = Null,  --30              
APTax = Null,                   
POITJCCo=POIT.PostToCo,                 
POITJob=POIT.Job,   --33              
APTaxType=Null,                
DiscTaken = Null    --35              
From POIT With (NoLock)                  
Join POHD With (NoLock)                 
 on POIT.POCo = POHD.POCo                 
 and POIT.PO = POHD.PO                 
--where POIT.PO =  '2105      '              
            
                   
union all                    
                    
select              
'U2' as 'U',                     
POCD.POCo,   --1              
POCD.PO,                 
POHD.VendorGroup,  --3               
POHD.Vendor,                 
POCD.POItem,                
Null,    --6              
POCD.ChangeCurUnits,                 
POCD.CurUnitCost,       
Null,            
NULL,    --9              
DetailSort = 2,                 
POCD.Description,                  
POCD.ChangeOrder,   --12              
POCD.Mth,                 
POCD.ChangeCurCost,    
POCD.ChangeBOCost,                 
POCD.ChgTotCost,    --15              
POCD.ChgToTax,--16            
NULL,                 
NULL,    --18               
NULL,   --19            
NULL,                 
NULL,     --21             
Null,                 
0 as 'OrigTax',              
0 as 'POJCCmtdTax',              
NULL,                 
NULL,                 
POIT.TaxType as 'TaxType',  --24      
Null,          
Null,          
NULL,                  
NULL,                 
Null,   --27              
NULL,                 
Null,                   
POCD.POTrans,  --30                
Null,                 
POITJCCo=POIT.PostToCo,                 
POITJob=POIT.Job,   --33              
APTaxType=Null,                
DiscTaken = Null    --35              
From POCD With (NoLock)                  
Join POHD With (NoLock)                 
 on POCD.POCo = POHD.POCo                 
 and POCD.PO = POHD.PO                  
Join POIT With (NoLock)                 
 on POCD.POCo = POIT.POCo                 
 and POCD.PO = POIT.PO                 
 and POCD.POItem = POIT.POItem        
--where POIT.PO =  '2105      '              
--                       
          
union all            
              
--     --This union brings in the Paid Amounts from APTD by Sequence                  
select              
'U3' as 'U',                     
APTL.APCo,   --1              
APTL.PO,                 
APTH.VendorGroup,--3                 
APTH.Vendor,                 
APTL.POItem,                 
APTL.ItemType,     --6              
Null,                 
Null,     
Null,             
Null,    --9              
DetailSort = 3,               
Description=Max(APTL.Description),                  
Null,   --12              
APTD.Mth,                 
NULL,       
Null,             
Null,   --15               
Null as 'ChgToTax',            
InvoiceDate= min(APTH.InvDate),                 
APTD.PaidMth,                 
APTD.PaidDate,     --18              
CMRef=max(Case when APTD.Status = 4 then 'Cleared' else APTD.CMRef end),                 
APRef=min(APTH.APRef),                 
NULL,    --21              
0 as 'OrigTax',              
0 as 'POJCCmtdTax',              
NULL,                 
NULL,                 
NULL,   --24      
Null,          
Null,                  
NULL,                  
InvAmount=NULL,                   
PaidAmount = Sum((case when APTD.Status in (3,4) then APTD.Amount else 0 end)),    --27              
Retainage=sum(case when APTD.PayType=APCO.RetPayType then APTD.Amount else 0 end),                 
APTD.APTrans,                 
Null,   --30              
NULL,                 
POITJCCo=POIT.PostToCo,                 
POITJob=POIT.Job,   --33              
APTaxType=APTL.TaxType,                
--DiscTaken = null                  
APTD.DiscTaken  --35              
From APTL With (NoLock)                  
Join APTH With (NoLock)                 
 on APTH.APCo = APTL.APCo                 
 and APTH.Mth = APTL.Mth                 
 and APTH.APTrans = APTL.APTrans                  
-- Issue #25648  9/27/04  JRE POIT is not needed to be joined to                  
Join POIT With (NoLock)                 
 on APTL.APCo = POIT.POCo                 
 and APTL.PO = POIT.PO                 
 and APTL.POItem = POIT.POItem                  
Left Join APTD With (NoLock)                 
 on APTL.APCo = APTD.APCo                 
 and APTL.Mth = APTD.Mth                 
 and APTL.APTrans = APTD.APTrans                 
 and APTL.APLine = APTD.APLine                  
Inner Join APCO With (NoLock)                 
 on APCO.APCo=APTD.APCo                  
Where                 
APTL.PO is not null                   
and APTD.PaidMth is not NULL                  
--and  APTL.PO =  '2105      '              
Group By APTL.APCo, APTD.Mth, APTD.APTrans, APTL.PO, APTL.POItem, APTL.ItemType, APTD.Mth,                  
 APTL.Description, POIT.PostToCo, POIT.Job, APTH.VendorGroup, APTH.Vendor,                     
 APTD.PaidMth, APTD.PaidDate, APTD.CMRef, APTL.TaxAmt,APTL.GrossAmt, APTL.TaxType, APTD.DiscTaken                 
--                       
UNION ALL                  
              
-- This union gets the APTL Invoice, Misc/Frt, and Tax Amounts.                  
select     
distinct            
'U4' as 'U',                      
APTL.APCo,                 
APTL.PO,                 
APTH.VendorGroup,   --3              
APTH.Vendor,                 
APTL.POItem,                 
APTL.ItemType,     --6              
Null,                 
Null,               
APTL.UnitCost as APUnitCost,    
Null,    --9              
DetailSort = 4,                 
NULL,                  
Null,   --12              
APTL.Mth,                 
Null,              
Null,  
Null,     --15              
Null as 'ChgToTax',            
InvoiceDate= APTH.InvDate,                
NULL,                 
NULL,   --18              
NULL,                 
APRef=APTH.APRef,                 
NULL,    --21              
0 as 'OrigTax',              
0 as 'POJCCmtdTax',              
NULL,                 
NULL,                 
NULL,   --24         
Null,          
Null,               
APMisc=APTL.MiscAmt,    
InvAmount=APTL.GrossAmt,                  
NULL,   --27                
Retainage=APTL.Retainage,                
APTL.APTrans,                 
Null,   --30              
APTL.TaxAmt,                 
POITJCCo=POIT.PostToCo,                 
POITJob=POIT.Job,   --33              
APTaxType=APTL.TaxType,                
--APPD.DiscTaken                  
DiscTaken = null    --35              
From APTL With (NoLock)                  
Join APTH With (NoLock)                 
 on APTH.APCo = APTL.APCo                 
 and APTH.Mth = APTL.Mth                 
 and APTH.APTrans = APTL.APTrans                  
--join APPD                
-- on APTH.APCo = APPD.APCo                
-- and APTH.CMCo = APPD.CMCo                
-- and APTH.CMAcct = APPD.CMAcct                
-- and APTH.PayMethod = APPD.PayMethod                
-- and APTH.APRef = APPD.APRef                
Join POIT With (NoLock)                 
 on APTL.APCo = POIT.POCo                 
 and APTL.PO = POIT.PO                 
 and APTL.POItem = POIT.POItem                  
Where APTL.PO is not null                    
--and  APTL.PO =  '2105      '               
 /*Group By APTL.APCo, APTL.Mth, APTL.APTrans, APTL.PO, APTL.POItem, APTL.ItemType,                   
           POIT.PostToCo, POIT.Job, APTH.VendorGroup, APTH.Vendor,  APTL.MiscAmt,                   
      APTL.TaxAmt,APTL.GrossAmt, APTL.Retainage*/   
      
***/   
 
GO
GRANT SELECT ON  [dbo].[brvPOPurchStats] TO [public]
GRANT INSERT ON  [dbo].[brvPOPurchStats] TO [public]
GRANT DELETE ON  [dbo].[brvPOPurchStats] TO [public]
GRANT UPDATE ON  [dbo].[brvPOPurchStats] TO [public]
GRANT SELECT ON  [dbo].[brvPOPurchStats] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPOPurchStats] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPOPurchStats] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPOPurchStats] TO [Viewpoint]
GO
