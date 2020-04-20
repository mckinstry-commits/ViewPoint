USE [Viewpoint]
GO

/****** Object:  View [dbo].[brvSLSubContrByJob]    Script Date: 6/9/2017 3:45:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[brvSLSubContrByJob2] as                           
/**************************                              
Added the APTL.TaxAmt and APTL.MiscAmt to the view per issue 123475 CR 
Changed APTD.TaxAmount to GSTtaxAmt per issue #136500 - MV                             
                              
***************************/                                   
                          
select       
'1 SL Orig Entry' as 'U',      --1 of 3                         
SLIT.SLCo,                           
SLIT.SL,        --3                       
SLIT.SLItem,                       
SLIT.ItemType,                          
SLIT.JCCo,    --6                       
SLIT.Job,     --7   
SLIT.PhaseGroup,
SLIT.Phase,
SLIT.JCCType,     
Null as 'APTDStatus',                          
'01/01/1950' AS 'Mth',  --9---------------------------------------------                         
0 as 'APTDAmt',                          
0 as 'APTLAmt',                          
Null as 'PayType',         --12         
Null as 'PayCategory',                     
'01/01/2050' as APPaidMth,   --14             
SLIT.OrigTax as 'OrigItemTax',     --15                      
SLIT.OrigCost as 'OrigItemCost',       --16        
0 as 'ChangeOrderCost',                 
0 as 'ChangeOrderTax',  --18           
SLIT.TaxType as 'TaxType',                          
0 as 'APTaxAmt',         --20             
SLIT.CurTax as 'SLCurTax',    --21                     
SLIT.InvTax as 'SLInvTax',                           
SLIT.JCCmtdTax as 'JCCmtdTax',  --23             
0 as 'MiscAmt',               --24         
0 as 'APTDTaxAmt',    --25        
0 as 'JCCommittedVATtax',    --26                   
0 as 'JCUncommitVATtax',     --27           
0 as 'TotalChgToJCCmtdTax' ,                
isnull(SLIT.JCCmtdTax,0) - isnull(x.ChgToJCCmtdTax,0)  as 'OrigJCCmtdTax'        --29         
from SLIT                      
left join ( select SLCo,SL,SLItem,sum(isnull(ChgToJCCmtdTax, 0)) as 'ChgToJCCmtdTax'  
   from SLCD group by SLCo,SL,SLItem ) x												--issue 137422
 on SLIT.SLCo = x.SLCo                           
 and SLIT.SL = x.SL                           
 and SLIT.SLItem = x.SLItem        
  
        
union all         
                         
select                      
'2 Change Order Entry' as 'U',       --2 of 3                    
SLIT.SLCo,                           
SLIT.SL,       --3                    
SLIT.SLItem,                           
SLIT.ItemType,                          
SLIT.JCCo,   --6                        
SLIT.Job,              
SLIT.PhaseGroup,
SLIT.Phase,
SLIT.JCCType, 
Null as 'APTDStatus',                            
IsNull(TCO.Mth,'01/01/1950')   AS 'Mth', --9----------------------------------                
0 as 'APTDAmt',                         
0 as 'APTLAmt',                           
Null as 'PayType',     --12                
Null as 'PayCategory',                          
'01/01/2050' as 'APPaidMth',  --14              
0 as 'OrigItemTax',      --15                    
0 as 'OrigItemCost',                   
sum(TCO.ChangeCurCost) as 'ChangeOrderCost',        --17         
sum(TCO.ChgToJCCmtdTax) as 'ChangeOrderTax',  --18        
SLIT.TaxType as 'TaxType',                         
0 as 'APTaxAmt',    --20        
0 as 'SLCurTax',       --21                    
0 as 'SLInvTax',                         
0 as 'JCCmtdTax',      --23             
0 as 'MiscAmt',                 --24        
0 as 'APTDTaxAmt',    --25        
0 as  'JCCommittedVATtax',        --26                     
0 as 'JCUncommitVATtax',          --27        
sum( isnull(TCO.ChgToJCCmtdTax, 0)) as 'TotalChgToJCCmtdTax', --28        
0 as 'OrigJCCmtdTax'  --29         
from SLIT                            
left outer join ( select         
     SLCD.SLCo,         
     SLCD.SL,         
     SLCD.SLItem,         
     SLCD.Mth,        
     sum(SLCD.ChangeCurCost) as 'ChangeCurCost',                 
     sum(SLCD.ChgToJCCmtdTax) as 'ChgToJCCmtdTax'                            
     from SLCD SLCD                            
     group by SLCD.SLCo, SLCD.SL, SLCD.SLItem, SLCD.Mth) as TCO                          
    on SLIT.SLCo = TCO.SLCo                           
 and SLIT.SL = TCO.SL                           
 and SLIT.SLItem=TCO.SLItem                    
--where SLIT.SL  like '%sc1023D'                
group by SLIT.SLCo, SLIT.SL, SLIT.SLItem, SLIT.ItemType,         
 SLIT.JCCo, SLIT.Job, TCO.Mth, SLIT.TaxType, TCO.ChgToJCCmtdTax, SLIT.PhaseGroup,
SLIT.Phase,
SLIT.JCCType            
           
      
Union All               
                           
select                        
'3 AP Trans Entry' as 'U',           --  3 of 3                       
APTL.APCo,                             
APTL.SL,        --3                      
APTL.SLItem,                           
SLIT.ItemType,                            
APTL.JCCo,     --6                         
APTL.Job,
APTL.PhaseGroup,
APTL.Phase,
APTL.JCCType,               
APTD.Status as 'APTDStatus',                             
APTD.Mth,                    --9--------------------------------------------------------           
APTDAmt=sum(APTD.Amount),                         
APTLAmt=sum(APTL.GrossAmt),                             
APTD.PayType,                     --12          
IsNull(APTD.PayCategory,0),                           
IsNull(APTD.PaidMth,'01/01/2050'),  --14             
0 as 'OrigItemTax',      --15                    
0 as 'OrigItemCost',         --16              
0 as  'ChangeOrderCost',     --17               
0 as 'ChangeOrderTax',        --18           
APTL.TaxType as 'TaxType',     --19             
APTaxAmt=sum(APTL.TaxAmt),         --20         
0,        --21               
0,            --22        
0 as 'JCCmtdTax',                  --23            
sum(APTL.MiscAmt) as 'MiscAmt',               --24          
sum(APTD.TotTaxAmount) as 'APTDTaxAmount',           --25        
sum(APTD.TotTaxAmount)- sum(APTD.GSTtaxAmt) as 'JCCommittedVATtax',   --26                    
sum(APTD.GSTtaxAmt) as 'JCUncommitVATtax',      --27               
0 as  'TotalChgToJCCmtdTax',        --28        
0 as 'OrigJCCmtdTax'         --29         
from APTD                              
join APTL                             
 on APTD.APCo=APTL.APCo                             
 and APTD.Mth=APTL.Mth                             
 and APTD.APTrans=APTL.APTrans                             
 and APTD.APLine = APTL.APLine                              
join SLIT                             
 on APTL.APCo = SLIT.SLCo                             
 and APTL.SL = SLIT.SL                             
 and APTL.SLItem = SLIT.SLItem                              
Where APTL.SL is not NULL       
--and SLIT.SL  like '%sc1023D'                     
group by APTL.APCo, APTL.SL, APTL.SLItem, SLIT.ItemType,        
 APTL.JCCo, APTL.Job, APTD.Status, APTD.Mth, APTD.PayType,         
 APTD.PayCategory, APTD.PaidMth, APTL.TaxType, APTL.PhaseGroup,
APTL.Phase,
APTL.JCCType             
        
        


GO


