SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[vrvPOCurCostByVendorSMWO]        
       
/******************************    
*  
* View is used by report PO Purchase Orders by SMWO 
*  
* Revision history  
* Date  Author Issue  Description  
* 06 Oct 2011 DML *Blatantly plagiarized brvPOCurCostByVendor to make this view.  
*  
*  
*******************************/        
      
AS         
  
  
SELECT       
POHD.POCo, --1  
POHD.PO, --2  
PODesc = (POHD.Description), --3  
POHD.VendorGroup, --4  
POHD.Vendor, --5  
--POHD.JCCo, --6  
POHD.Status, --7  
ItemDesc = (POIT.Description), --8  
POItemLine.POItem, --POIT.POItem, --9  
POItemLine.POItemLine, --10  
--POItemLine.Job, --POIT.Job, --11  
POItemLine.TaxType, --POIT.TaxType, --12  
POItemLine.PhaseGroup, --POIT.PhaseGroup, --13  
POItemLine.Phase, --POIT.Phase, --14  
POItemLine.PostToCo, --POIT.PostToCo, --15  
SUM(POItemLine.CurCost) + SUM(POItemLine.CurTax) AS 'CurCost', --16  
 --SUM(POIT.CurCost) + SUM(POIT.CurTax) AS 'CurCost', --16  
SUM(POItemLine.CurTax) AS 'CurTax', --17  
 --SUM(POIT.CurTax) AS 'CurTax', --17  
SUM(POItemLine.InvCost) + SUM(POItemLine.InvTax) AS 'InvCost', --18  
 --SUM(POIT.InvCost) + SUM(POIT.InvTax) AS 'InvCost', --18  
SUM(POItemLine.InvTax) AS 'InvCostTax', --19  
 --SUM(POIT.InvTax) AS 'InvCostTax', --19  
SUM(POItemLine.JCCmtdTax) AS 'JCCmtdTax', --20  
 --SUM(POIT.JCCmtdTax) AS 'JCCmtdTax', --20  
0 AS 'APPaidAmt', --21  
0 AS 'APTaxAmount', --22  
0 AS 'APTotTaxAmount', --23  
0 AS 'APJCCommittedVATtax', --24  
SUM(POItemLine.JCRemCmtdTax) AS 'JCRemCmtdTax', --25  
 --SUM(POIT.JCRemCmtdTax) AS 'JCRemCmtdTax', --25  
RecType = 'PO' --26  
, POIT.SMCo --27  
, POIT.SMWorkOrder --28  
, POIT.SMScope --29  
  
FROM POHD  
  INNER JOIN  
  POIT ON POIT.POCo = POHD.POCo   
    AND POIT.PO = POHD.PO  
  INNER JOIN  
  POItemLine  
    ON POItemLine.POCo = POIT.POCo   
    AND POItemLine.PO = POIT.PO  
    AND POItemLine.POItem = POIT.POItem  
WHERE POIT.SMWorkOrder IS NOT NULL  
GROUP BY POHD.POCo, POHD.PO, POHD.Description,  
   POHD.VendorGroup, POHD.Vendor, POHD.JCCo,   
   POHD.Status, POIT.Description, POItemLine.POItem,   
   POItemLine.POItemLine, POItemLine.Job, POItemLine.TaxType,    
   POItemLine.PhaseGroup, POItemLine.Phase, POItemLine.PostToCo,  
   POIT.SMCo, POIT.SMWorkOrder, POIT.SMScope   
           
UNION ALL        
      
SELECT       
APTL.APCo, --1  
APTL.PO, --2  
NULL AS 'PODesc', --3  
APTH.VendorGroup, --4  
APTH.Vendor, --5  
--APTL.JCCo, --6  
NULL AS 'Status', --7  
NULL AS 'ItemDesc', --8  
APTL.POItem, --9  
APTL.POItemLine, --10  
--APTL.Job, --11  
APTL.TaxType, --12  
APTL.PhaseGroup, --13  
APTL.Phase, --14  
APTL.JCCo, --15  
0 AS 'CurCost', --16  
0 AS 'CurTax', --17  
0 AS 'InvCost', --18  
0 AS 'InvCostTax', --19  
0 AS 'JCCmtdTax', --20  
SUM(CASE WHEN APTD.Status > 2 THEN APTD.Amount ELSE 0 END) AS 'APPaidAmt', --21  
SUM(CASE WHEN APTD.Status > 2 THEN APTD.GSTtaxAmt ELSE 0 END) AS 'APTaxAmount', --22  
SUM(CASE WHEN APTD.Status > 2 THEN APTD.TotTaxAmount ELSE 0 END) AS 'APTotTaxAmount', --23  
SUM(CASE WHEN APTD.Status > 2 THEN (APTD.TotTaxAmount - APTD.GSTtaxAmt) ELSE 0 END)AS 'APJCCommittedVATtax', --24  
0 AS 'JCRemCmtdTax', --25  
RecType = 'AP' --26  
, null as SMCo --27  
, null as SMWorkOrder --28  
, null as SMScope --29  
  
FROM APTL   
  INNER JOIN   
  APTD ON APTL.APCo = APTD.APCo  
    AND APTL.Mth = APTD.Mth  
    AND APTL.APTrans = APTD.APTrans  
    AND APTL.APLine = APTD.APLine  
  INNER JOIN   
  APTH ON APTL.APCo = APTH.APCo  
    AND APTL.Mth = APTH.Mth  
    AND APTL.APTrans = APTH.APTrans  
WHERE APTL.PO IS NOT NULL  
AND APTL.Job IS NOT NULL  
GROUP BY APTL.APCo, APTL.PO, APTH.VendorGroup,   
   APTH.Vendor, APTL.JCCo, APTL.POItem,   
   APTL.POItemLine, APTL.Job, APTL.TaxType,   
   APTL.PhaseGroup, APTL.Phase, APTL.JCCo  
  
  
  
  
GO
GRANT SELECT ON  [dbo].[vrvPOCurCostByVendorSMWO] TO [public]
GRANT INSERT ON  [dbo].[vrvPOCurCostByVendorSMWO] TO [public]
GRANT DELETE ON  [dbo].[vrvPOCurCostByVendorSMWO] TO [public]
GRANT UPDATE ON  [dbo].[vrvPOCurCostByVendorSMWO] TO [public]
GRANT SELECT ON  [dbo].[vrvPOCurCostByVendorSMWO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPOCurCostByVendorSMWO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPOCurCostByVendorSMWO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPOCurCostByVendorSMWO] TO [Viewpoint]
GO
