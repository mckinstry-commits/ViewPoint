SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
       
CREATE view [dbo].[vrvPRAUBASGSTRec] as                
                
/*******************************************************************                
*	Created:	DML - 15 June 2011 - Issue # 144033, B-04906 (for the AP section of the PR BAS GST Reconciliation Report)
*	Modified:	DML - 24 Oct 2013 - Issue #146778 / D-05624 / Bug 39032 / (RPT - (AUS) BAS Reconciliation report does not include Status 4 (Cleared) transactions)                  
********************************************************************/                
                
select src = 'AP'                
, H.APCo    --APTH                
, H.Mth                
, H.APTrans                 
, H.Vendor                
, H.APRef                
, H.InvDate                
, Null as Source                
, L.APLine    --APTL                
, L.LineType                
, D.APSeq    --APTD                
, D.Amount                
, Amount1 = case when ((D.Status <> 4) and (D.PayType <> O.RetPayType)) OR (D.Status = 4) then D.Amount else 0 end --added "OR (D.Status = 4)" - DML 10/24/2013           
, Amount2 = case when ((D.PayType = O.RetPayType)) then D.Amount else 0 end                
, Amount3 = case when ((D.Status = 3) and (D.PayType = O.RetPayType)) then D.Amount else 0 end               
, D.Status              
, D.PaidDate                
, D.PaidMth             
, D.CMRef                 
, L.Retainage                
, D.GSTtaxAmt as 'APTDGSTtaxAmt'               
, GSTtaxAmt1 = case when ((D.Status <> 4) and (D.PayType <> O.RetPayType)) OR (D.Status = 4) then D.GSTtaxAmt else 0 end --added "OR (D.Status = 4)" - DML 10/24/2013                          
, GSTtaxAmt2 = case when ((D.PayType = O.RetPayType)) then D.GSTtaxAmt else 0 end                
, GSTtaxAmt3 = case when ((D.Status = 3) and (D.PayType = O.RetPayType)) then D.GSTtaxAmt else 0 end                
, D.TotTaxAmount                
, D.ExpenseGST                
, D.PayType                
, O.RetPayType --= case when C.RetPayType is null then 0 else C.RetPayType end                
, B.TaxYear    --PRAUEmployerBAS                
, B.Seq                
, B.GSTStartDate                
, B.GSTEndDate                
, A.Item                
, L.TaxGroup                
, L.TaxCode    --PRAUEmployerBASAmounts                
, A.SalesOrPurchAmt                
, A.SalesOrPurchAmtGST                
, A.GSTTaxAmt                
, A.WithholdingAmt                
, T.ItemDesc                
From APTH H                
                
Left Outer Join APTL L on H.APCo = L.APCo   --1                
 and H.Mth = L.Mth                
 and H.APTrans = L.APTrans                
                 
Left Outer Join APTD D on L.APCo = D.APCo   --2                
 and L.Mth = D.Mth                
 and L.APTrans = D.APTrans                
 and L.APLine = D.APLine                
 and H.APCo = D.APCo                
 and H.Mth = D.Mth                 
 and H.APTrans = D.APTrans                
                 
Join PRAUEmployerBAS B on H.APCo = B.PRCo   --5                
                
Left Outer Join PRAUEmployerBASGSTTaxCodes T on L.APCo = T.PRCo                  
 and L.TaxCode = T.TaxCode                
 and L.TaxGroup = T.TaxGroup                
                 
Join PRAUEmployerBASAmounts A on H.APCo = A.PRCo   --4                
 and B.PRCo = A.PRCo                
 and B.TaxYear = A.TaxYear                
 and B.Seq = A.Seq                
 --and T.TaxYear = A.TaxYear                
 and T.Seq = A.Seq                
 and T.Item = A.Item                 
                
Left Outer Join APCO O on H.APCo = O.APCo --6                
                
Where A.Item in ('G10','G11')                
and H.Mth between B.GSTStartDate and B.GSTEndDate                    
               
UNION                
                
select distinct src = 'CM'                 
, CM.CMCo                    
, CM.Mth                
, CM.CMTrans                 
, Null as Vendor                
, Null as APRef                
, CM.ActDate as InvDate                
, CM.Source                
, Null as APLine                    
, Null as LineType    
, Null as APSeq                    
, CM.Amount                
, Null as Amount1                
, Null as Amount2                
, Null as Amount3                
, -1 as Status                
, CM.PostedDate as PdDate           
, Null as PaidMth             
, CM.CMRef             
, Null as Retainage                
, Null as APTDGSTtaxAmt                
, Null as GSTtaxAmt1                
, Null as GSTtaxAmt2                
, Null as GSTtaxAmt3                
, Null as TotTaxAmount                
, Null as ExpenseGST                
, Null as PayType                
, Null as RetPayType                   
, B.TaxYear                    
, B.Seq                
, B.GSTStartDate                
, B.GSTEndDate                
, C.Item                
, C.TaxGroup                
, C.TaxCode                    
, Null as SalesOrPurchAmt                
, Null as SalesOrPurchAmtGST                
, Null as GSTTaxAmt                
, Null as WithholdingAmt                
, Null as ItemDesc                
From CMDT CM                
                
inner join PRAUEmployerBASGSTTaxCodes C                 
 on CM.CMCo=C.PRCo                
  and CM.TaxCode = C.TaxCode                
  and CM.TaxGroup = C.TaxGroup                   
join PRAUEmployerBAS B                
 on CM.CMCo = B.PRCo                
  and C.PRCo=B.PRCo  --rem                
  and C.TaxYear=B.TaxYear  -- rem                
  and C.Seq=B.Seq                  
                
WHERE  C.Item in ('G10','G11')                
and CM.Mth >= B.GSTStartDate                
and CM.Mth <= B.GSTEndDate                      
            
UNION            
            
select src = 'APpd'                  
, H.APCo    --APTH                  
, H.Mth                  
, H.APTrans                   
, H.Vendor                  
, H.APRef                  
, H.InvDate                  
, Null as Source                  
, L.APLine    --APTL                  
, L.LineType                  
, D.APSeq    --APTD                  
, D.Amount                  
, Amount1 = case when ((D.Status <> 4) and (D.PayType <> O.RetPayType)) OR (D.Status = 4) then D.Amount else 0 end --added "OR (D.Status = 4)" - DML 10/24/2013                            
, Amount2 = case when ((D.PayType = O.RetPayType)) then D.Amount else 0 end                  
, Amount3 = case when ((D.Status = 3) and (D.PayType = O.RetPayType)) then D.Amount else 0 end                  
, D.Status                  
, D.PaidDate                  
, D.PaidMth               
, D.CMRef                   
, L.Retainage                  
, D.GSTtaxAmt as 'APTDGSTtaxAmt'                    
, GSTtaxAmt1 = case when ((D.Status <> 4) and (D.PayType <> O.RetPayType)) OR (D.Status = 4) then D.GSTtaxAmt else 0 end --added "OR (D.Status = 4)" - DML 10/24/2013                            
, GSTtaxAmt2 = case when ((D.PayType = O.RetPayType)) then D.GSTtaxAmt else 0 end                  
, GSTtaxAmt3 = case when ((D.Status = 3) and (D.PayType = O.RetPayType)) then D.GSTtaxAmt else 0 end                  
, D.TotTaxAmount                  
, D.ExpenseGST                  
, D.PayType                  
, O.RetPayType --= case when C.RetPayType is null then 0 else C.RetPayType end                  
, B.TaxYear    --PRAUEmployerBAS                  
, B.Seq                  
, B.GSTStartDate                  
, B.GSTEndDate                  
, A.Item                  
, L.TaxGroup                  
, L.TaxCode    --PRAUEmployerBASAmounts                  
, A.SalesOrPurchAmt                  
, A.SalesOrPurchAmtGST                  
, A.GSTTaxAmt                  
, A.WithholdingAmt                  
, T.ItemDesc                  
From APTH H                  
                  
Left Outer Join APTL L on H.APCo = L.APCo   --1                  
 and H.Mth = L.Mth                  
 and H.APTrans = L.APTrans                  
                   
Left Outer Join APTD D on L.APCo = D.APCo   --2                  
 and L.Mth = D.Mth                  
 and L.APTrans = D.APTrans                  
 and L.APLine = D.APLine                  
 and H.APCo = D.APCo                  
 and H.Mth = D.Mth                   
 and H.APTrans = D.APTrans                  
            
Join PRAUEmployerBAS B on H.APCo = B.PRCo   --5                  
                  
Left Outer Join PRAUEmployerBASGSTTaxCodes T on L.APCo = T.PRCo                    
 and L.TaxCode = T.TaxCode                  
 and L.TaxGroup = T.TaxGroup                  
                   
Join PRAUEmployerBASAmounts A on H.APCo = A.PRCo   --4                  
 and B.PRCo = A.PRCo                  
 and B.TaxYear = A.TaxYear             
 and B.Seq = A.Seq                  
 --and T.TaxYear = A.TaxYear                  
 and T.Seq = A.Seq                  
 and T.Item = A.Item                   
                  
Left Outer Join APCO O on H.APCo = O.APCo --6                  
                  
Where A.Item in ('G10','G11')                  
and ((D.Status = 3) and (D.PaidMth between B.GSTStartDate and B.GSTEndDate))            
and D.PayType = O.RetPayType            
and D.Status  = 3            
    
       
            
            
--AP:   ({vrvPRAUBASGSTRec.Amount2}-{vrvPRAUBASGSTRec.GSTtaxAmt2}) 100-10 = 90            
             
--APpd: if (({vrvPRAUBASGSTRec.Amount3}-{vrvPRAUBASGSTRec.GSTtaxAmt3}) -         
--  if (200-20 - 100-10) = 0 then 0 else 100-10             
--      (({vrvPRAUBASGSTRec.Amount2}-{vrvPRAUBASGSTRec.GSTtaxAmt2})) = 0)             
--      then 0 else ({vrvPRAUBASGSTRec.Amount3}-{vrvPRAUBASGSTRec.GSTtaxAmt3})            
                      
--CM :  if (({vrvPRAUBASGSTRec.Amount3}-{vrvPRAUBASGSTRec.GSTtaxAmt3}) -             
--      (({vrvPRAUBASGSTRec.Amount2}-{vrvPRAUBASGSTRec.GSTtaxAmt2})) = 0)             
--      then 0 else ({vrvPRAUBASGSTRec.Amount3}-{vrvPRAUBASGSTRec.GSTtaxA 
GO
GRANT SELECT ON  [dbo].[vrvPRAUBASGSTRec] TO [public]
GRANT INSERT ON  [dbo].[vrvPRAUBASGSTRec] TO [public]
GRANT DELETE ON  [dbo].[vrvPRAUBASGSTRec] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRAUBASGSTRec] TO [public]
GO
