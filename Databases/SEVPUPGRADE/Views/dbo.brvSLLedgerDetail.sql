SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[brvSLLedgerDetail] as             
          
          
--Issue #136705          
--12/29/09 MB          
--In second Union, Took PaidAmount out of Group by clause and summed paid amount in select clause.         
      
--Issue #136983      
--1/28/10      
--Added isnull function to several calculations      
  
--Issue #137577  
--4/29/10 changed SLIT.TaxType to APTL.TaxType in second Union, MB     

-- #TK13103
-- Added additional union to bring in Original Cost and Original Tax
-- These values are to be summed in the SL Subcontract Status RPT file
-- They will also have discreet values summed and hidded in the RPT as well
                                
select                               
SLIT.SLCo,                               
SLIT.SL,                               
SLIT.SLItem,                               
ItemType=(case when SLIT.ItemType<>3 then 0 else 1 end),                         
ItemTypeReal=SLIT.ItemType,                                
DetailSort=(case when SLChangeOrder is not null then 1 else 0 end),                                  
SLChangeOrder,                               
Mth=isnull(SLCD.Mth,'1/1/1950'),                               
InvoiceDate=NULL,                                 
PaidMth=NULL,                               
PaidDate=NULL,                        
PaidAmount = Null,                                
CMRef=NULL,                               
APRef=NULL, 
APStatus = NULL,                         
AppChangeOrder,                               
CODesc=SLCD.Description,                               
ChangeCurUnits,                                 
ChangeCurUnitCost,                               
ChangeCurCost,                               
SLCD.ChgToTax,                               
ActualDate=SLCD.ActDate,                               
InvAmount=NULL,                               
TotTaxAmount=NULL,                              
Retainage=NULL,                             
RetainageTax =NULL,                            
APTrans=NULL,                    
SLIT.TaxType,
OrigCost	= SLIT.OrigCost,
OrigTax		= SLIT.OrigTax
                              
From SLIT                                
Left Outer Join SLCD                               
 on SLCD.SLCo=SLIT.SLCo                               
 and SLCD.SL=SLIT.SL                               
 and SLCD.SLItem=SLIT.SLItem    
 
 
   
 
UNION ALL 

SELECT    
		SLIT.SLCo,                               
		SLIT.SL,                               
		SLIT.SLItem,                               
		ItemType=(case when SLIT.ItemType<>3 then 0 else 1 end),                         
		ItemTypeReal=SLIT.ItemType,                                
		NULL,
		NULL,                               
		NULL,                               
		NULL,                                 
		NULL,                               
		NULL,                        
		Null,                                
		NULL,                               
		NULL, 
		NULL,                         
		NULL,                               
		NULL,                               
		NULL,                                 
		NULL,                               
		NULL,                               
		NULL,                               
		NULL,                               
		NULL,                               
		NULL,                              
		NULL,                             
		NULL,                            
		NULL,                    
		SLIT.TaxType,
		OrigCost	= SLIT.OrigCost,
		OrigTax		= SLIT.OrigTax                        

FROM SLIT



                                      
union all                                
                              
select                     
APTL.APCo,                               
APTL.SL,                               
APTL.SLItem,                               
ItemType=(case when SLIT.ItemType<>3 then 0 else 1 end),                          
Null,                             
DetailSort=2,                               
NULL,                               
APTH.Mth,                               
APTH.InvDate,                               
APTD.PaidMth,                               
APTD.PaidDate,                        
PaidAmount = sum(APTD.Amount),                            
APTD.CMRef,                               
APTH.APRef,   
APTD.Status,                            
NULL,                               
NULL,                               
NULL,                                
NULL,                               
NULL,                               
NULL,                               
NULL,                               
InvAmount=sum(APTD.Amount),                               
TotTaxAmount=sum(isnull(APTD.TotTaxAmount,0)),                              
Retainage=sum(case when  APTD.PayCategory Is NULL                               
    then (case when APTD.PayType = APCO.RetPayType then isnull(APTD.Amount,0) - isnull(APTD.TotTaxAmount,0) else 0 end)                               
    else (case when APTD.PayType = APPC.RetPayType then isnull(APTD.Amount,0) - isnull(APTD.TotTaxAmount, 0) else 0 end) end),                              
RetainageTax=sum(case when  APTD.PayCategory Is NULL                               
    then (case when APTD.PayType=APCO.RetPayType then isnull(APTD.TotTaxAmount, 0) else 0 end)                               
    else (case when APTD.PayType = APPC.RetPayType then isnull(APTD.TotTaxAmount, 0) else 0 end) end),      
APTH.APTrans,                    
APTL.TaxType,
NULL,
NULL     --Issue #137577, changed SLIT.TaxType to APTL.TaxType   
                         
From                                 
APTH                                
Join APTL                               
 on APTL.APCo=APTH.APCo                               
 and APTL.Mth=APTH.Mth                               
 and APTL.APTrans=APTH.APTrans                                
Join SLIT                               
 on SLIT.SLCo=APTL.APCo                      
 and SLIT.SL=APTL.SL                               
 and SLIT.SLItem=APTL.SLItem                                
Join APTD                               
 on APTD.APCo=APTL.APCo                               
 and APTD.Mth=APTL.Mth                               
 and APTD.APTrans=APTL.APTrans                               
 and APTD.APLine=APTL.APLine                                
Join APCO                               
 on APCO.APCo=APTD.APCo                                
Left Outer Join APPC                               
 on APPC.APCo=APTD.APCo                               
 and APPC.PayCategory=APTD.PayCategory                     
Group By                               
APTL.APCo,                               
APTL.SL,                               
APTL.SLItem,                               
SLIT.ItemType,                               
APTH.Mth,                       
APTH.InvDate,                               
APTD.PaidMth,                               
APTD.PaidDate,                      
APTD.CMRef,                               
APTH.APRef,
APTD.Status,                               
APTH.APTrans,                     
APTL.TaxType 

GO
GRANT SELECT ON  [dbo].[brvSLLedgerDetail] TO [public]
GRANT INSERT ON  [dbo].[brvSLLedgerDetail] TO [public]
GRANT DELETE ON  [dbo].[brvSLLedgerDetail] TO [public]
GRANT UPDATE ON  [dbo].[brvSLLedgerDetail] TO [public]
GO
